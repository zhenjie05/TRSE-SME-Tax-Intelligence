# 📊 TRSE SME Tax Intelligence
**UMHackathon 2026 | Universiti Malaya**

TRSE SME Tax Intelligence is an AI-powered financial compliance dashboard built specifically for the Malaysian market. It acts as an automated tax auditor that instantly scans business receipts, cross-checks them against LHDN (Lembaga Hasil Dalam Negeri) e-Invoicing rules, and identifies potential tax risks before they result in financial penalties.

---

## 📌 Submission Artifacts for Judges

All required evaluation artifacts for the KitaHack 2026 submission are accessible below:

* **🎥 Pitching Video:** [INSERT_YOUR_GOOGLE_DRIVE_VIDEO_LINK_HERE] *(Note: Link access is set to "Anyone with the link")*
* **📄 System Documentation:** The three required project documents, including our comprehensive Quality Assurance Testing Documentation (QATD), are located in the `/docs` folder of this repository.

---

## 🚀 The Problem

With the upcoming 2026 LHDN e-Invoicing mandates, Malaysian Small and Medium Enterprises (SMEs) face increasingly strict compliance requirements. A simple missing Tax Identification Number (TIN) or an illegible date on a high-value receipt can lead to rejected tax deductions and severe fines. Manually auditing every transaction is labor-intensive, error-prone, and unsustainable for small business owners.

## 💡 Our Solution

TRSE automates the entire compliance check process. By leveraging advanced multimodal AI vision, our system reads physical receipts just like a human auditor would, instantly extracts the critical tax data, and calculates the business's real-time financial risk exposure.

### Core Features
* **📸 AI Vision Scanner:** Bypasses traditional, fragile OCR. Users simply upload an image, and Gemini 1.5 Flash natively reads the document to extract the Merchant Name, Date, Total Amount, and the critical LHDN TIN.
* **⚠️ Automated Risk Dashboard:** Receipts are instantly graded as **SAFE**, **REVIEW**, or **DANGER** based on strict LHDN logic. The dashboard visualizes the overall Document Health Score and calculates the Estimated Fine Exposure in MYR.
* **💬 Context-Aware Tax Assistant:** An intelligent chatbot that retains the memory of the most recently scanned document. Users can ask exactly why a receipt was flagged, and the AI will explain the specific LHDN regulation violated.

---

## 🏗️ Architecture & Tech Stack

Our system utilizes a decoupled, asynchronous architecture to ensure rapid processing and high stability:

* **Frontend:** **Flutter** - Provides a fluid, cross-platform UI with robust state management.
* **Backend:** **Python (FastAPI)** - Handles secure image routing, API communication, and data sanitization.
* **AI Engine:** **Google Gemini 2.5 Flash** - Powers both the multimodal receipt extraction and the conversational NLP context engine.
* **Database:** **Supabase (PostgreSQL)** - Manages the transaction logs for real-time dashboard updates and contextual chat retrieval.

---

## ⚙️ Local Setup & Execution

### Prerequisites
1. Flutter SDK installed
2. Python 3.9+ installed
3. A `.env` file in the `/backend` directory containing:
   ```env
   GEMINI_API_KEY="your_api_key_here"
   SUPABASE_URL="your_supabase_url_here"
   SUPABASE_KEY="your_supabase_key_here"
