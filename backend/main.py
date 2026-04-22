from fastapi.middleware.cors import CORSMiddleware
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import google.generativeai as genai
import json
import os
import uuid
from datetime import datetime
from dotenv import load_dotenv
from supabase import create_client, Client # <-- 1. Import Supabase

load_dotenv()

# Configure AI
genai.configure(api_key=os.environ.get("GEMINI_API_KEY"))
model = genai.GenerativeModel(
    'gemini-2.5-flash',
    generation_config={"response_mime_type": "application/json"}
)

# 2. Configure Database
SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_KEY")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

app = FastAPI(title="TSRE API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all connections (perfect for hackathon testing)
    allow_credentials=True,
    allow_methods=["*"],  # Allows POST, GET, OPTIONS, etc.
    allow_headers=["*"],
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.post("/upload")
async def analyze_receipt(file: UploadFile = File(...)):
    allowed_types = ["image/jpeg", "image/png", "image/webp", "application/pdf"]
    if file.content_type not in allowed_types:
        raise HTTPException(status_code=400, detail="File must be an image or PDF.")

    try:
        image_bytes = await file.read()
        image_part = {
            "mime_type": file.content_type,
            "data": image_bytes
        }

        # The Master Prompt
        prompt = """
        You are an expert Malaysian LHDN Tax Compliance AI. 
        First, verify what type of document this is. 
        If the document is NOT a receipt, NOT an invoice, or is completely unreadable, you must reject it.
        
        Strictly return a JSON object matching this structure exactly:
        {
          "status": "SAFE" or "REVIEW" or "DANGER" or "INVALID",
          "risk_score": an integer from 0 to 100 (use 0 if INVALID),
          "confidence_level": a float between 0.0 and 1.0,
          "extracted_data": {
            "merchant_name": "string (or 'UNKNOWN' if INVALID)",
            "tin": "string (or 'NOT_FOUND')",
            "total_amount": float (use 0.0 if INVALID),
            "tax_amount": float (use 0.0 if INVALID),
            "date": "YYYY-MM-DD (or '1970-01-01' if INVALID)",
            "currency": "MYR"
          },
          "ai_explanation": "If INVALID, explain what it is. Otherwise, explain the compliance status.",
          "lhdn_reference": "Cite LHDN rule (or 'N/A' if INVALID)",
          "action_recommendation": "What the user should do next",
          "impact_saved": float (use 0.0 if INVALID)
        }
        
        Rule reminder: If total_amount >= 10000, status must be DANGER.
        """

        response = model.generate_content([prompt, image_part])
        result_json = json.loads(response.text)
        
        # 3. Generate a secure ID and add the timestamp
        result_json["transaction_id"] = str(uuid.uuid4())

        # 4. Save to Database (The Audit Trail)
        # We tell Supabase to insert the entire AI response into the transaction_logs table
        db_response = supabase.table("transaction_logs").insert(result_json).execute()

        return result_json

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"System Error: {str(e)}")
    
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
        return {"status": "error", "message": f"Database Error: {str(e)}"}