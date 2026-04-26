import uuid
import os
import json
import io
from PIL import Image
from pydantic import BaseModel
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import google.generativeai as genai
from dotenv import load_dotenv
from supabase import create_client, Client

# Load environment variables from .env file
load_dotenv()

# 1. Initialize Gemini
genai.configure(api_key=os.environ.get("GEMINI_API_KEY"))

# 2. Initialize Supabase
supabase_url = os.environ.get("SUPABASE_URL")
supabase_key = os.environ.get("SUPABASE_KEY")
supabase: Client = create_client(supabase_url, supabase_key)

# 3. FastAPI & CORS Setup
app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],  
    allow_headers=["*"],
)

# 4. Request Models
class ChatRequest(BaseModel):
    user_query: str
    
# --- ROUTES ---

@app.post("/upload")
async def upload_receipt(file: UploadFile = File(...)):
    try:
        # STAGE 1: Load File
        file_bytes = await file.read()
        mime_type = file.content_type

        # STAGE 2: Prepare Document for Gemini
        document_part = None
        
        if mime_type.startswith("image/"):
            # It's an image, use PIL to safely resize if needed
            img = Image.open(io.BytesIO(file_bytes))
            if img.width > 2000:
                img = img.resize((2000, int(img.height * 2000 / img.width)))
            document_part = img
        elif mime_type == "application/pdf":
            # It's a PDF, Gemini takes the raw bytes natively!
            document_part = {
                "mime_type": "application/pdf",
                "data": file_bytes
            }
        else:
            raise HTTPException(status_code=400, detail="Only Images and PDFs are supported.")

        model = genai.GenerativeModel('gemini-2.5-flash')
        
        prompt = """
        You are a professional LHDN Tax Auditor. Analyze this Malaysian receipt or invoice document.
        Extract the data and return ONLY a strict JSON object. Do not use markdown blocks like ```json.
        
        INSTRUCTIONS:
        1. TIN: Look for TIN starting with T, C, or G followed by digits. If missing, put "NOT_FOUND".
        2. DATE: Format as DD/MM/YYYY.
        3. RISK SCORE: No TIN = +40 risk, No Date = +20 risk.
        
        REQUIRED FORMAT:
        {
            "status": "SAFE" | "REVIEW" | "DANGER",
            "risk_score": 0,
            "impact_saved": 0.0,
            "ai_explanation": "Brief 1-sentence audit note.",
            "lhdn_reference": "Extracted reference or empty",
            "action_recommendation": "Action to take",
            "extracted_data": {
                "merchant_name": "Name",
                "tin": "Extracted TIN here",
                "total_amount": 0.0,
                "date": "Extracted Date here"
            }
        }
        """

        print(f"📸 Document loaded ({mime_type}). Sending to Gemini...")
        # Send the document_part (either PIL Image or PDF Dict) to Gemini
        response = await model.generate_content_async([prompt, document_part])
        print("✅ Gemini finished thinking!")
        
        ai_response_text = response.text.strip()

        # Defensive programming: Strip markdown backticks if Gemini ignores the instruction
        if "```json" in ai_response_text:
            ai_response_text = ai_response_text.split("```json")[1]
        if "```" in ai_response_text:
            ai_response_text = ai_response_text.split("```")[0]
        ai_response_text = ai_response_text.strip()

        # Parse JSON safely
        try:
            parsed_data = json.loads(ai_response_text)
        except json.JSONDecodeError:
            print("🚨 Failed to parse Gemini response as JSON.")
            print(f"Raw Output: {ai_response_text}")
            raise HTTPException(status_code=500, detail="AI returned invalid JSON format.")

        # STAGE 3: Save to Supabase
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
        
        supabase.table("transaction_logs").insert(log_entry).execute()

        return parsed_data

    except Exception as e:
        print(f"System Error in /upload: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    
@app.get("/dashboard/summary")
async def get_dashboard_summary():
    try:
        response = supabase.table("transaction_logs").select("status, total_amount").execute()
        logs = response.data
        
        total = len(logs)
        safe = len([l for l in logs if l['status'] == 'SAFE'])
        review = len([l for l in logs if l['status'] == 'REVIEW'])
        danger = len([l for l in logs if l['status'] == 'DANGER'])
        
        health_score = int((safe / total * 100)) if total > 0 else 100
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
            context = f"The user just scanned a {r['status']} receipt from {r['merchant_name']} for RM{r['total_amount']}. Risk Score: {r['risk_score']} out of 100."

        # 2. Send to Gemini (Z.ai removed)
        model = genai.GenerativeModel('gemini-2.5-flash')
        chat_prompt = f"System Context: {context}\n\nYou are a helpful Malaysian LHDN tax assistant. Keep your answers brief and directly address the user's question.\n\nUser Question: {user_query}"
        
        response = await model.generate_content_async(chat_prompt)
        
        return {"reply": response.text.strip()}
    except Exception as e:
        print(f"Error in /ai-chat: {e}")
        return {"reply": "I'm having trouble accessing the receipt data right now."}
    
@app.get("/logs")
async def get_audit_history():
    try:
        response = supabase.table("transaction_logs").select("*").order("created_at", desc=True).limit(50).execute()
        
        return {
            "status": "success", 
            "count": len(response.data),
            "data": response.data
        }
    except Exception as e:
        print(f"Database Error in /logs: {e}")
        return {"status": "error", "message": f"Database Error: {str(e)}"}
    
@app.get("/calculate-tax")
async def calculate_tax(income: float):
    # Malaysia Progressive Tax Brackets (YA 2024)
    tax = 0.0
    
    if income <= 5000:
        tax = 0
    elif income <= 20000:
        tax = (income - 5000) * 0.01
    elif income <= 35000:
        tax = 150 + (income - 20000) * 0.03
    elif income <= 50000:
        tax = 600 + (income - 35000) * 0.06
    elif income <= 70000:
        tax = 1500 + (income - 50000) * 0.11
    elif income <= 100000:
        tax = 3700 + (income - 70000) * 0.19
    else:
        # Higher brackets for high earners
        tax = 9400 + (income - 100000) * 0.25

    return {"taxes_to_pay": tax}

@app.get("/tips")
async def get_dashboard_tips():
    try:
        # 1. Grab the latest 3 transactions to give the AI some context
        response = supabase.table("transaction_logs").select("status, merchant_name").order("created_at", desc=True).limit(3).execute()
        
        context = ""
        if response.data:
            scans = ", ".join([f"{r['merchant_name']} ({r['status']})" for r in response.data])
            context = f"The user recently scanned these receipts: {scans}."
        
        # 2. Ask Gemini to generate 3 contextual tips
        model = genai.GenerativeModel('gemini-2.5-flash')
        prompt = f"""
        You are a Malaysian LHDN Tax Advisor. 
        {context}
        Provide exactly 3 short, actionable tax-saving or compliance tips for an SME business regarding the upcoming 2026 e-Invoicing mandate.
        Return ONLY a raw JSON array of 3 strings. Example: ["Tip 1", "Tip 2", "Tip 3"]. Do not use markdown blocks.
        """
        
        ai_response = await model.generate_content_async(prompt)
        tips_text = ai_response.text.strip()
        
        # Clean up formatting if Gemini includes markdown
        if "```json" in tips_text:
            tips_text = tips_text.split("```json")[1]
        if "```" in tips_text:
            tips_text = tips_text.split("```")[0]
            
        tips_list = json.loads(tips_text.strip())
        
        return {"tips": tips_list}
        
    except Exception as e:
        print(f"Error generating tips: {e}")
        # Fallback static tips just in case the AI fails
        return {"tips": [
            "E-Invoicing becomes mandatory for all taxpayers by July 2026.",
            "Ensure all capital expenditures above RM10,000 have verified TINs.",
            "Regularly audit receipts for missing dates or TINs to lower your risk score."
        ]}