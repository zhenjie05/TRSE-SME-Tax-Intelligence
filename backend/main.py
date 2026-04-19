from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import google.generativeai as genai
import json
import os
from datetime import datetime
from dotenv import load_dotenv

load_dotenv()

genai.configure(api_key=os.environ.get("GEMINI_API_KEY"))

# Configure your Gemini API Key (Store this in a .env file, NEVER commit to GitHub)
genai.configure(api_key=os.environ.get("GEMINI_API_KEY"))

# Initialize the Vision Model and force JSON output
model = genai.GenerativeModel(
    'gemini-2.5-flash',
    generation_config={"response_mime_type": "application/json"}
)

app = FastAPI(title="TSRE API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ... (Keep your Pydantic Schemas here) ...

@app.post("/upload")
async def analyze_receipt(file: UploadFile = File(...)):
    """
    REAL VISION AGENT: Sends the receipt to Gemini 1.5 Flash 
    to extract tax data and evaluate LHDN 2026 compliance.
    """

    # Allow both images and PDFs for B2B e-invoicing
    allowed_types = ["image/jpeg", "image/png", "image/webp", "application/pdf"]
    if file.content_type not in allowed_types:
        raise HTTPException(status_code=400, detail="File must be an image or PDF.")
    
    try:
        # Read the image bytes
        image_bytes = await file.read()
        image_part = {
            "mime_type": file.content_type,
            "data": image_bytes
        }

        # The Master Prompt (This is where the magic happens)
        prompt = """
        You are an expert Malaysian LHDN Tax Compliance AI. 
        First, verify what type of document this is. 
        If the document is NOT a receipt, NOT an invoice, or is completely unreadable (e.g., a payslip, a selfie, a random object), you must reject it.
        
        Strictly return a JSON object matching this structure exactly:
        {
          "transaction_id": "generate-a-random-uuid",
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
          "ai_explanation": "If INVALID, explain what the document actually is. Otherwise, explain the compliance status.",
          "lhdn_reference": "Cite LHDN rule (or 'N/A' if INVALID)",
          "action_recommendation": "What the user should do next (e.g., 'Please upload a valid business receipt.')",
          "impact_saved": float (use 0.0 if INVALID)
        }
        
        Rule reminder: If total_amount >= 10000, status must be DANGER.
        """

        # Call the Gemini Vision API
        response = model.generate_content([prompt, image_part])
        
        # Parse the JSON response
        result_json = json.loads(response.text)
        
        # Add the server timestamp for your audit trail
        result_json["processed_at"] = datetime.utcnow().isoformat() + "Z"
        
        return result_json

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI Processing Error: {str(e)}")