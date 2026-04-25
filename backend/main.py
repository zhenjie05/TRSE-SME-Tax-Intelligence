import uuid
import os
import json
import io
import pytesseract
from PIL import Image
from pydantic import BaseModel
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from anthropic import AsyncAnthropic
from dotenv import load_dotenv
from supabase import create_client, Client

# --- WINDOWS TESSERACT FIX ---
# If you get a "tesseract is not installed or it's not in your PATH" error, 
# you will need to install Tesseract-OCR for Windows and uncomment the line below, 
# pointing it to where you installed it:
pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'

# Load environment variables from .env file
load_dotenv()

# 1. Initialize the Z.ai Client (Async with the official Auth Token method)
zai_client = AsyncAnthropic(
    auth_token=os.environ.get("ZAI_API_KEY", "sk-d34959db2c80725fe0b7a3cd37cc3504b1821451db6798cd"), # Replace with your real key if not in .env
    base_url="https://api.ilmu.ai/anthropic",
    timeout=30.0
)

# 2. Initialize Supabase Client
supabase_url = os.environ.get("SUPABASE_URL")
supabase_key = os.environ.get("SUPABASE_KEY")
supabase: Client = create_client(supabase_url, supabase_key)

# 3. Initialize FastAPI App & CORS
app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],  
    allow_headers=["*"],
)

class ChatRequest(BaseModel):
    user_query: str

# --- ROUTES ---

@app.post("/upload")
async def upload_receipt(file: UploadFile = File(...)):
    try:
        # STAGE 1: THE EYES (Fast Mode)
        image_bytes = await file.read()
        img = Image.open(io.BytesIO(image_bytes)).convert('L')
        
        # Resize image if it's too large (Massive photos slow down OCR)
        if img.width > 2000:
            img = img.resize((2000, int(img.height * 2000 / img.width)))

        # Use a faster configuration for Tesseract
        custom_config = r'--oem 3 --psm 6 -c tessedit_char_whitelist=01234567890ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz./-:'
        raw_receipt_text = pytesseract.image_to_string(img, config=custom_config)
        
        # STAGE 2: THE BRAIN (Explicit Extraction Instructions)
        response = await zai_client.messages.create(
            model="ilmu-glm-5.1",
            max_tokens=1500,
            temperature=0.0, # 0.0 makes it even more robotic and precise
            messages=[
                {
                    "role": "user",
                    "content": f"""
                    System: Extract LHDN tax data.
                    Context: Malaysian receipts usually have TIN starting with 'T', 'C', or 'G' followed by 10-12 digits.
                    
                    TEXT FROM OCR:
                    {raw_receipt_text}

                    INSTRUCTIONS:
                    1. TIN: Look for any sequence like 'T 1234567890' or 'TIN: 12345'. Even if characters are broken (e.g., 'T123 456'), fix it.
                    2. DATE: Find any DD/MM/YYYY or DD-MM-YY.
                    3. If you absolutely cannot find a TIN, return "NOT_FOUND" instead of leaving it null.

                    RETURN ONLY JSON:
                    {{
                        "status": "SAFE/REVIEW/DANGER",
                        "risk_score": 0,
                        "impact_saved": 0.0,
                        "ai_explanation": "Brief note.",
                        "lhdn_reference": "Ref",
                        "action_recommendation": "Action",
                        "extracted_data": {{
                            "merchant_name": "Name",
                            "tin": "Extracted TIN here",
                            "total_amount": 0.0,
                            "date": "Extracted Date here"
                        }}
                    }}
                    """
                }
            ],
        )

        # C. Extract the raw text from the AI response
        ai_response_text = response.content[0].text.strip()
        
        print("\n--- RAW AI RESPONSE ---")
        print(ai_response_text)
        print("-----------------------\n")

        # Defensive programming: Strip markdown backticks if they exist
        if "```json" in ai_response_text:
            ai_response_text = ai_response_text.split("```json")[1]
        if "```" in ai_response_text:
            ai_response_text = ai_response_text.split("```")[0]
        ai_response_text = ai_response_text.strip()

        # Parse string into a Python Dictionary with a Safety Net
        try:
            parsed_data = json.loads(ai_response_text)
        except Exception as e:
            print("JSON Parse Failed! The AI did not return strict JSON.")
            return {"status": "error", "message": "Failed to parse AI response", "raw_ai_text": ai_response_text}

        # D. Save to Supabase Database
        extracted = parsed_data.get("extracted_data", {})
        
        log_entry = {
            "transaction_id": str(uuid.uuid4()),
            "status": parsed_data.get("status", "UNKNOWN"),
            "risk_score": parsed_data.get("risk_score", 0),
            "impact_saved": parsed_data.get("impact_saved", 0.0),
            "ai_explanation": parsed_data.get("ai_explanation", ""),
            "lhdn_reference": parsed_data.get("lhdn_reference", ""),
            "action_recommendation": parsed_data.get("action_recommendation", ""),
            "merchant_name": extracted.get("merchant_name", "Unknown"),
            "tin": extracted.get("tin", ""),
            "total_amount": float(extracted.get("total_amount", 0.0) or 0.0),
            "date": extracted.get("date", ""),
            "extracted_data": extracted
        }
        
        # Insert into the transaction_logs table
        supabase.table("transaction_logs").insert(log_entry).execute()

        # E. Send the parsed data directly back to the Flutter App
        return parsed_data

    except Exception as e:
        print(f"System Error in /upload: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    
@app.get("/dashboard/summary")
async def get_dashboard_summary():
    try:
        # Fetch status of all logs
        response = supabase.table("transaction_logs").select("status, total_amount").execute()
        logs = response.data
        
        total = len(logs)
        safe = len([l for l in logs if l['status'] == 'SAFE'])
        review = len([l for l in logs if l['status'] == 'REVIEW'])
        danger = len([l for l in logs if l['status'] == 'DANGER'])
        
        # Calculate health score for the gauge in the video
        health_score = int((safe / total * 100)) if total > 0 else 100
        
        # Calculate Estimated Fine Exposure (The big RM3000 box in the video)
        # Assuming RM3000 fine per DANGER receipt for demo purposes
        fine_exposure = danger * 3000 

        return {
            "total_scanned": total,
            "safe_count": safe,
            "review_count": review,
            "danger_count": danger,
            "health_score": health_score,
            "fine_exposure": fine_exposure
        }
    except Exception as e:
        print(f"Error in summary: {e}")
        return {"error": str(e)}
    
@app.get("/calculate-tax")
async def calculate_tax(income: float):
    # Standard Malaysian Corporate/SME rate demo (e.g., 15% or tiered)
    # The video shows ~11%, so let's match that logic for the demo
    tax_rate = 0.11 
    taxes_to_pay = income * tax_rate
    return {"taxes_to_pay": taxes_to_pay}

@app.post("/ai-chat")
async def ai_chat(request: ChatRequest):
    user_query = request.user_query
    try:
        # 1. Get the very last scanned receipt for context
        last_receipt = supabase.table("transaction_logs")\
            .select("*").order("created_at", desc=True).limit(1).execute()
        
        context = ""
        if last_receipt.data:
            r = last_receipt.data[0]
            context = f"The user just scanned a {r['status']} receipt from {r['merchant_name']} for RM{r['total_amount']}. Risk Score: {r['risk_score']}."

        # 2. Send to Z.ai
        response = await zai_client.messages.create(
            model="ilmu-glm-5.1",
            max_tokens=300,
            messages=[{
                "role": "user", 
                "content": f"System Context: {context}\n\nUser Question: {user_query}"
            }]
        )
        return {"reply": response.content[0].text}
    except Exception as e:
        return {"reply": "I'm having trouble accessing the receipt data right now."}
    

@app.get("/logs")
async def get_audit_history():
    try:
        # Fetch the latest 50 receipts from Supabase, newest first
        response = supabase.table("transaction_logs").select("*").order("created_at", desc=True).limit(50).execute()
        
        return {
            "status": "success", 
            "count": len(response.data),
            "data": response.data
        }
    except Exception as e:
        print(f"Database Error in /logs: {e}")
        return {"status": "error", "message": f"Database Error: {str(e)}"}