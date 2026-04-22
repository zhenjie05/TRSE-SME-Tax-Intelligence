import base64, json, re
import google.generativeai as genai

VISION_PROMPT = """
You are an OCR agent for Malaysian tax receipts.
Extract fields and return ONLY valid JSON, no markdown, no explanation:
{
  "tin": "string or null",
  "sst_amount": number or null,
  "total_amount": number or null,
  "date": "YYYY-MM-DD or null",
  "vendor_name": "string or null",
  "msic_code": "string or null",
  "has_sst": true or false,
  "missing_fields": ["list any of: tin, sst_amount, msic_code that are absent"],
  "confidence": 0.0 to 1.0
}
"""

def run_vision_agent(image_bytes: bytes, mime_type: str) -> dict:
    model = genai.GenerativeModel(
        'gemini-2.5-flash',
        generation_config={"response_mime_type": "application/json"}
    )
    image_part = {"mime_type": mime_type, "data": image_bytes}
    response = model.generate_content([VISION_PROMPT, image_part])
    try:
        return json.loads(response.text)
    except Exception:
        return {"error": "Vision parse failed", "confidence": 0.0, "missing_fields": []}