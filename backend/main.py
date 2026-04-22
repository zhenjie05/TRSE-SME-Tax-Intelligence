from fastapi import FastAPI, File, UploadFile, HTTPException
from pydantic import BaseModel
from google import genai
from google.genai import types
import json
import os
import uuid
from datetime import datetime
from dotenv import load_dotenv
from supabase import create_client, Client # <-- 1. Import Supabase

load_dotenv()

# Configure AI (Updated to the new google.genai SDK)
client = genai.Client(api_key=os.environ.get("GEMINI_API_KEY"))

# 2. Configure Database
SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_KEY")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
# print("Supabase client initialized successfully.")

app = FastAPI(title="TSRE API")

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
        
        # Updated to use the new types.Part format for images
        image_part = types.Part.from_bytes(
            data=image_bytes, 
            mime_type=file.content_type
        )

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

        # Updated to use the new client.models.generate_content call
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=[prompt, image_part],
            config=types.GenerateContentConfig(response_mime_type="application/json")
        )
        
        # Clean the Markdown formatting just in case Gemini sends it
        raw_text = response.text.strip()
        if raw_text.startswith("```json"):
            raw_text = raw_text.replace("```json", "").replace("```", "").strip()
        elif raw_text.startswith("```"):
            raw_text = raw_text.replace("```", "").strip()

        result_json = json.loads(raw_text)
        
        # 3. Generate a secure ID and add the timestamp
        result_json["transaction_id"] = str(uuid.uuid4())

        # 4. Save to Database (The Audit Trail)
        # We tell Supabase to insert the entire AI response into the transaction_logs table
        db_response = supabase.table("transaction_logs").insert(result_json).execute()

        return result_json

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"System Error: {str(e)}")