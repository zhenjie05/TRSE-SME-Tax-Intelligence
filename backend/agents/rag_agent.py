import chromadb
from chromadb.utils import embedding_functions

_client = chromadb.PersistentClient(path="./chroma_store")
_ef = embedding_functions.SentenceTransformerEmbeddingFunction(model_name="all-MiniLM-L6-v2")
_col = _client.get_or_create_collection("lhdn_2026", embedding_function=_ef)

def run_rag_agent(vision_output: dict) -> dict:
    parts = []
    if not vision_output.get("tin"):        parts.append("missing TIN invoice violation")
    if vision_output.get("has_sst"):        parts.append("SST compliance receipt tax")
    if vision_output.get("msic_code"):      parts.append(f"MSIC code {vision_output['msic_code']}")
    if "tin" in vision_output.get("missing_fields", []):  parts.append("TIN missing e-invoice")
    query = " ".join(parts) if parts else "LHDN e-invoice compliance 2026 general"

    results = _col.query(query_texts=[query], n_results=2)
    rules = [
        {"rule": doc, "citation": meta["source"]}
        for doc, meta in zip(results["documents"][0], results["metadatas"][0])
    ]
    return {"relevant_rules": rules, "citations": [r["citation"] for r in rules]}