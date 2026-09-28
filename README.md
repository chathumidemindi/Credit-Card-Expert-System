# Retail Banking Credit Card Eligibility Expert System

An automated, rule-based expert system developed in SWI-Prolog to assess applicant creditworthiness, enforce lending risk regulations (Debt Burden Ratio & Credit Bureau limits), and automatically allocate card tiers with calculated credit limits.

---

## 1. Prerequisites
- **SWI-Prolog** (Version 8.x, 9.x, or 10.x)
- Download link: [https://www.swi-prolog.org/download/stable](https://www.swi-prolog.org/download/stable)

---

## 2. Important Syntax Note (Read Before Running)
> **CRITICAL:** Prolog uses standard term parsing (`read/1`).  
> **EVERY input you enter MUST end with a full stop / period (`.`) followed by Enter.**  
> If an input is typed without a dot, the prompt will hang at `| :` waiting for the closing period.

- Correct: `29.` | `salaried.` | `no.`
- Incorrect: `29` | `salaried` | `no`

---

## 3. How to Run Locally

### Method A: Using SWI-Prolog Desktop App (Recommended for GUI Users)
1. Launch the **SWI-Prolog** application.
2. In the top navigation bar, click **File** -> **Consult...**
3. Select `expert_system.pl` from the file explorer.
4. In the console window at the `?-` prompt, type:
   ```prolog
   start.
