import chromadb
from chromadb.utils import embedding_functions

LHDN_RULES = [
    {"id": "ITA-39", "text": "Section 39 Income Tax Act 1967: Expenses not deductible include private expenses, capital expenditure, and domestic expenses unrelated to the production of income.", "source": "Income Tax Act 1967, Section 39"},
    {"id": "ITA-33", "text": "Section 33 Income Tax Act 1967: Gross income from a business shall be the total of all gains or profits derived from the business in the basis period.", "source": "Income Tax Act 1967, Section 33"},
    {"id": "SST-10", "text": "SST Act 2018 Section 10: Taxable person must charge SST at 8% on taxable services. Failure to account for SST collected is an offence.", "source": "SST Act 2018, Section 10"},
    {"id": "SST-38", "text": "SST Act 2018 Section 38: Penalty for failure to collect or remit SST is RM10,000 to RM50,000 or imprisonment not exceeding 3 years or both.", "source": "SST Act 2018, Section 38"},
    {"id": "EI-2026-01", "text": "LHDN e-Invoice Guideline 2026: All B2B transactions above RM500 must be issued as a validated e-Invoice via MyInvois portal effective January 2026.", "source": "LHDN e-Invoice Guideline 2026, Clause 1"},
    {"id": "EI-2026-02", "text": "LHDN e-Invoice Guideline 2026: Each e-Invoice must contain Supplier TIN, Buyer TIN, MSIC code, item description, SST amount, and total amount.", "source": "LHDN e-Invoice Guideline 2026, Clause 2"},
    {"id": "EI-2026-03", "text": "LHDN e-Invoice Guideline 2026: Non-compliance with e-invoicing requirements may result in fines of up to RM20,000 per transaction.", "source": "LHDN e-Invoice Guideline 2026, Clause 7"},
    {"id": "ITA-110", "text": "Section 110 Income Tax Act 1967: Tax deducted at source from payments to non-residents must be remitted to LHDN within one month of payment.", "source": "Income Tax Act 1967, Section 110"},
    {"id": "MSIC-01", "text": "MSIC Code Requirement: Every invoice must reflect the correct Malaysia Standard Industrial Classification (MSIC) code that matches the business registration category.", "source": "LHDN e-Invoice Guideline 2026, Clause 3"},
    {"id": "DEDUCT-01", "text": "Allowable deductions under ITA 1967 include: business premise rental, staff salaries, utilities directly used in business, and equipment depreciation under Schedule 3.", "source": "Income Tax Act 1967, Schedule 3 & Section 33"},
    {"id": "DEDUCT-02", "text": "Entertainment expenses are only 50% deductible under ITA 1967 Section 39(1)(l) unless they are for staff welfare or promotional activities with proper documentation.", "source": "Income Tax Act 1967, Section 39(1)(l)"},
    {"id": "PENALTY-01", "text": "Late payment of tax under ITA 1967 Section 103 incurs a 10% penalty on the outstanding amount, with an additional 5% if unpaid after 60 days.", "source": "Income Tax Act 1967, Section 103"},
    {"id": "TIN-01", "text": "Every taxable entity must display a valid Tax Identification Number (TIN) on all invoices. Missing or incorrect TIN constitutes a compliance violation.", "source": "LHDN e-Invoice Guideline 2026, Clause 2"},
    {"id": "RECORD-01", "text": "Under ITA 1967 Section 82, all businesses must retain financial records for a minimum of 7 years for audit purposes.", "source": "Income Tax Act 1967, Section 82"},
    {"id": "SST-REG", "text": "Businesses with annual taxable turnover exceeding RM500,000 are required to register for SST under SST Act 2018 Section 13.", "source": "SST Act 2018, Section 13"},
]

def seed():
    client = chromadb.PersistentClient(path="./chroma_store")

    sentence_transformer_ef = embedding_functions.SentenceTransformerEmbeddingFunction(model_name="all-MiniLM-L6-v2")
    
    col = client.get_or_create_collection(
        name="lhdn_2026", 
        embedding_function=sentence_transformer_ef
    )

    col.add(
        documents=[r["text"] for r in LHDN_RULES],
        metadatas=[{"source": r["source"]} for r in LHDN_RULES],
        ids=[r["id"] for r in LHDN_RULES],
    )
    print(f"✅ Seeded {len(LHDN_RULES)} LHDN rules into ChromaDB")

if __name__ == "__main__":
    seed()