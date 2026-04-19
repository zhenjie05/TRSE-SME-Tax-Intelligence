from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
from datetime import datetime

# 1. Initialize the FastAPI App
app = FastAPI(
    title="TSRE API",
    description="Tax-Smart SME Resilience Engine Backend",
    version="1.0.0"
)

# 2. Setup CORS (Crucial for Flutter integration)
# Communication with backend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # In production, restrict this to your actual domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 3. Define Pydantic Schemas (The API Contract)
class ExtractedData(BaseModel):
    merchant_name: str
    tin: str
    total_amount: float
    tax_amount: float
    date: str
    currency: str

class ComplianceResponse(BaseModel):
    transaction_id: str
    status: str
    risk_score: int
    confidence_level: float
    extracted_data: ExtractedData
    ai_explanation: str
    lhdn_reference: str
    action_recommendation: str
    impact_saved: float
    processed_at: str

# 4. Health Check Endpoint
@app.get("/")
async def root():
    return {"status": "online", "message": "TSRE API is running"}

# 5. The Mock Upload Endpoint
@app.post("/upload", response_model=ComplianceResponse)
async def analyze_receipt(file: UploadFile = File(...)):
    """
    MOCK ENDPOINT: Receives an image and returns a simulated Z.AI analysis.
    This unblocks the frontend team while the actual AI logic is built.
    """
    
    # In the future, you will pass 'file' to your Z.AI Vision Agent here.
    # For now, we return the agreed-upon Mock JSON.
    
    mock_response = {
        "transaction_id": "uuid-12345",
        "status": "DANGER",
        "risk_score": 85,
        "confidence_level": 0.92,
        "extracted_data": {
            "merchant_name": "Kedai Ali Sdn Bhd",
            "tin": "C123456789",
            "total_amount": 10500.00,
            "tax_amount": 630.00,
            "date": "2026-04-19",
            "currency": "MYR"
        },
        "ai_explanation": "This transaction exceeds the RM10,000 threshold for consolidated e-invoicing.",
        "lhdn_reference": "Section 3.2: Individual e-Invoice Requirements",
        "action_recommendation": "Request a separate individual e-invoice from the supplier immediately.",
        "impact_saved": 10000.00,
        "processed_at": datetime.utcnow().isoformat() + "Z"
    }
    
    return mock_response
