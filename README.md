# Splendor Analytics — Trial Activation Intelligence

**Author:** Freda Erinmwingbovo  
**Challenge:** Splendor Analytics Data Analyst Community Challenge  
**Prize:** ₦100,000  
**Submission:** [(https://x.com/FredaUzorchim)]

---

## Project Overview

This project investigates trial activation for Splendor Analytics —
a workforce management SaaS platform offering 30-day free trials
to new organisations.

**The core question:** What does a "good" trial look like, and which
behaviours predict conversion to a paying customer?

**The honest answer:** This analysis reveals that standard behavioural
metrics, event volume, feature breadth, activity frequency, do not
significantly predict conversion in this dataset. The real findings
are more nuanced and more valuable.

---

## Key Findings

- **21.3%** overall conversion rate across 966 trialling organisations
- **49%** of all conversions happen *after* the 30-day trial ends
- **64%** of organisations were active for only a single day
- **Zero** of 28 activities showed statistically significant association
  with conversion (chi-square and Mann-Whitney tests)
- **ML models** achieved ROC-AUC of ~0.5, no better than random
- **Module adoption** is heavily skewed, Scheduling used by 98.8%,
  all other modules below 23%
- **March 2024 cohort** converts at 18.2%, 3.1pp below baseline

---

## Repo Structure
```
splendor-trial-activation/
│
├── data/
│   ├── DA_task.csv              ← Raw dataset
│   ├── clean_events.csv         ← Cleaned event log
│   └── org_features.csv         ← Org-level feature matrix
│
├── sql/
│   ├── staging/
│   │   └── stg_events.sql       ← Staging layer
│   └── marts/
│       ├── trial_goals.sql      ← Trial goals mart
│       └── trial_activation.sql ← Trial activation mart
│
├── assets/                      ← All chart outputs
│
├── notebook.ipynb               ← Full analysis notebook
├── report.qmd                   ← Quarto source report
├── report.html                  ← Rendered HTML report
├── splendor.scss                ← Custom theme
├── requirements.txt
└── README.md
```

---

## Tasks Completed

### Task 1: Data Cleaning & Exploration
- Identified and removed 67,631 duplicate rows (39.7% of raw data)
- Engineered trial-relative time features
- Built organisation-level feature matrix (966 orgs × 41 features)
- Conducted multi-method conversion driver analysis

### Task 2: SQL Models
- **`stg_events`**: staging view with deduplication and derived fields
- **`trial_goals`**: mart tracking goal completion per organisation
- **`trial_activation`**: mart tracking full activation status

### Task 3: Trial Goal Definition

Three evidence-informed trial goals defined:

| Goal | Definition | Completion Rate |
|------|-----------|----------------|
| Goal 1 | 5+ shifts created in first 14 days | 44.6% |
| Goal 2 | 2+ product modules used | 35.1% |
| Goal 3 | End-to-end workflow completed | 43.5% |
| **Activated** | **All 3 goals met** | **24.3%** |

Activated organisations convert at **23.4%** vs **20.7%** for
non-activated, a 1.13x lift.

---

## How to Run
```bash
# Install dependencies
pip install -r requirements.txt

# Run the notebook
jupyter notebook notebook.ipynb

# Render the Quarto report
quarto render report.qmd
```

---

## Portfolio

All projects: [freda-erinmwingbovo.github.io](https://freda-erinmwingbovo.github.io)
