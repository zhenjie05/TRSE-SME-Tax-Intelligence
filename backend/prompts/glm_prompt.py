import json, re, os
from zhipuai import ZhipuAI   # pip install zhipuai

client = ZhipuAI(api_key=os.environ.get("ZAI_API_KEY"))

SYSTEM_PROMPT = """
You are the TSRE Tax Strategist powered by Z.AI GLM — a Malaysian tax compliance expert.
You receive structured data from an OCR Vision Agent and a LHDN RAG Agent.
CRITICAL RULES:
- Only cite the LHDN sections given to you. Never invent citations.
- Use plain language suitable for a non-accountant SME owner.
- Always include the disclaimer in your response.

Return ONLY valid JSON (no markdown fences):
{
  "verdict": "SAFE" | "REVIEW" | "DANGER",
  "confidence": 0-100,
  "summary": "2 sentence plain-language explanation",
  "risk_score": 0-100,
  "estimated_fine_rm": number,
  "sst_discrepancy_pct": number,
  "citations": ["citation 1", "citation 2"],
  "tax_saving_tips": ["tip 1", "tip 2"],
  "disclaimer": "For pre-audit analysis only. Consult a licensed tax advisor."
}

Verdict logic:
- SAFE:   TIN present, SST correct, no missing required fields
- REVIEW: 1 minor issue OR confidence < 0.7 OR small discrepancy < 5%
- DANGER: Missing TIN, SST discrepancy > 5%, total > RM10,000 without e-invoice
"""

def run_glm_agent(vision_output: dict, rag_output: dict) -> dict:
    user_msg = f"""
VISION AGENT OUTPUT:
{json.dumps(vision_output, indent=2)}

RAG AGENT OUTPUT (use ONLY these citations, do not invent others):
{json.dumps(rag_output, indent=2)}

Provide your compliance verdict now.
"""
    response = client.chat.completions.create(
        model="glm-4v-flash",
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user",   "content": user_msg}
        ],
        max_tokens=1000,
    )
    raw = response.choices[0].message.content.strip()
    raw = re.sub(r"```json|```", "", raw).strip()
    try:
        return json.loads(raw)
    except Exception:
        return {"error": "GLM parse failed", "raw": raw, "verdict": "REVIEW"}