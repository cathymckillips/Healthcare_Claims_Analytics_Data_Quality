# Healthcare Claims Analytics — Data Quality Rules

## Overview

This document defines the SQL-based data-quality framework used in the Healthcare Claims Analytics portfolio project.

The synthetic claims dataset intentionally contains data-quality problems so that validation, exception management, and governance concepts can be demonstrated before the data reaches Power BI.

The framework currently contains **10 data-quality rules: DQ01 through DQ10**.

The primary principle behind the framework is:

> **Failed records should be visible and explainable rather than silently removed.**

---

# Data Quality Framework

The validation process follows:

```text
Source Claims
     |
     v
SQL Validation Rules
     |
     v
DQ01 - DQ10
     |
     v
Exception Layer
     |
     +---- Rule ID
     +---- Failed Rule
     +---- Severity
     +---- Claim Line ID
     |
     v
Power BI Data Quality Reporting
```

---

# Rule Summary

| Rule | Rule Name | Dimension | Severity |
|---|---|---|---|
| DQ01 | Duplicate Claim Line | Uniqueness | High |
| DQ02 | Paid Amount Exceeds Allowed Amount | Financial Consistency | High |
| DQ03 | Missing Allowed Amount | Completeness | Medium |
| DQ04 | Orphan Member ID | Referential Integrity | High |
| DQ05 | Orphan Provider ID | Referential Integrity | High |
| DQ06 | Orphan Payer ID | Referential Integrity | High |
| DQ07 | Denied Claim With Payment | Business Rule Consistency | High |
| DQ08 | Received Date Before Service Date | Temporal Consistency | High |
| DQ09 | Negative Billed Amount | Financial Validity | High |
| DQ10 | Missing Diagnosis Code | Completeness | Medium |

---

# DQ01 — Duplicate Claim Line

## Objective

Identify duplicate `Claim_Line_ID` values.

## Dimension

**Uniqueness**

## Severity

**High**

## SQL Logic

```sql
SELECT
    Claim_Line_ID,
    COUNT(*) AS DuplicateCount
FROM dbo.Claims
GROUP BY Claim_Line_ID
HAVING COUNT(*) > 1;
```

## Business Rationale

Duplicate claim-line records may result in overstated:

- Claim volume
- Billed amounts
- Allowed amounts
- Paid amounts
- Utilization
- Denials

## Production Consideration

Real healthcare claims systems may legitimately contain multiple transactions related to the same claim or service because of:

- Adjustments
- Reversals
- Replacement claims
- Corrected claims
- Claim versioning

A production implementation would therefore incorporate transaction and version identifiers before classifying records as true duplicates.

---

# DQ02 — Paid Amount Exceeds Allowed Amount

## Objective

Identify records where:

```text
Paid Amount > Allowed Amount
```

## Dimension

**Financial Consistency**

## Severity

**High**

## SQL Logic

```sql
SELECT *
FROM dbo.Claims
WHERE Paid_Amount > Allowed_Amount;
```

## Business Rationale

Unexpected relationships between paid and allowed values can indicate:

- Incorrect transformation logic
- Source-data problems
- Mapping errors
- Adjustment activity requiring investigation

---

# DQ03 — Missing Allowed Amount

## Objective

Identify adjudicated claims where `Allowed_Amount` is missing.

## Dimension

**Completeness**

## Severity

**Medium**

## SQL Logic

```sql
SELECT *
FROM dbo.Claims
WHERE Allowed_Amount IS NULL
  AND Claim_Status IN ('Paid', 'Denied');
```

## Business Rationale

Missing allowed amounts may affect:

- Allowed-rate calculations
- Reimbursement reporting
- Financial reconciliation
- Payer comparisons
- Contract analysis

---

# DQ04 — Orphan Member ID

## Objective

Identify claims containing a Member ID that does not resolve to the member reference table.

## Dimension

**Referential Integrity**

## Severity

**High**

## SQL Logic

```sql
SELECT c.*
FROM dbo.Claims c
LEFT JOIN dbo.Members m
    ON c.Member_ID = m.Member_ID
WHERE m.Member_ID IS NULL;
```

## Business Rationale

An unmatched member identifier can prevent:

- Member attribution
- Demographic analysis
- Plan analysis
- Eligibility-related reporting

---

# DQ05 — Orphan Provider ID

## Objective

Identify claims whose Provider ID does not resolve to the provider reference table.

## Dimension

**Referential Integrity**

## Severity

**High**

## SQL Logic

```sql
SELECT c.*
FROM dbo.Claims c
LEFT JOIN dbo.Providers p
    ON c.Provider_ID = p.Provider_ID
WHERE p.Provider_ID IS NULL;
```

## Business Rationale

An unmatched provider can affect:

- Provider performance analysis
- Specialty reporting
- Network analysis
- Financial attribution

---

# DQ06 — Orphan Payer ID

## Objective

Identify claims whose Payer ID does not resolve to the payer reference table.

## Dimension

**Referential Integrity**

## Severity

**High**

## SQL Logic

```sql
SELECT c.*
FROM dbo.Claims c
LEFT JOIN dbo.Payers p
    ON c.Payer_ID = p.Payer_ID
WHERE p.Payer_ID IS NULL;
```

## Business Rationale

An unresolved payer relationship can affect:

- Payer-level reporting
- Denial analysis
- Reimbursement analysis
- Financial reconciliation
- Operational comparisons

---

# DQ07 — Denied Claim With Payment

## Objective

Identify denied claim lines containing a positive payment.

## Dimension

**Business Rule Consistency**

## Severity

**High**

## SQL Logic

```sql
SELECT *
FROM dbo.Claims
WHERE Claim_Status = 'Denied'
  AND Paid_Amount > 0;
```

## Business Rationale

In the simplified project model, a denied claim line is expected to have no positive payment.

A contradiction between status and payment should therefore be investigated.

## Production Consideration

Real claims environments may include:

- Partial denials
- Partial payments
- Adjustments
- Reversals
- Multiple adjudication transactions

Production logic would need additional fields before determining whether the record is actually invalid.

---

# DQ08 — Received Date Before Service Date

## Objective

Identify claims whose receipt date occurs before the service date.

## Dimension

**Temporal Consistency**

## Severity

**High**

## SQL Logic

```sql
SELECT *
FROM dbo.Claims
WHERE Received_Date < Service_Date;
```

## Expected Lifecycle

```text
Service Date
     ↓
Received Date
     ↓
Adjudication Date
     ↓
Payment Date
```

## Business Rationale

An invalid date sequence can distort:

- Turnaround-time metrics
- Aging analysis
- Operational reporting
- Claims-lifecycle KPIs

---

# DQ09 — Negative Billed Amount

## Objective

Identify negative billed amounts.

## Dimension

**Financial Validity**

## Severity

**High**

## SQL Logic

```sql
SELECT *
FROM dbo.Claims
WHERE Billed_Amount < 0;
```

## Business Rationale

Negative amounts require investigation to determine whether they represent:

- Data-entry problems
- Transformation errors
- Adjustments
- Reversals
- Incorrect transaction classification

The simplified portfolio model treats negative billed amounts as exceptions.

---

# DQ10 — Missing Diagnosis Code

## Objective

Identify missing, blank, or whitespace-only diagnosis codes.

## Dimension

**Completeness**

## Severity

**Medium**

## SQL Logic

```sql
SELECT *
FROM dbo.Claims
WHERE Diagnosis_Code IS NULL
   OR LTRIM(RTRIM(Diagnosis_Code)) = '';
```

## Business Rationale

Missing diagnosis information can affect:

- Clinical categorization
- Claims analysis
- Reporting completeness
- Downstream analytical use

---

# Consolidated Exception Layer

Individual rule failures are consolidated into:

```text
dq.vw_Claims_Exceptions
```

The view contains fields including:

- Claim_Line_ID
- Claim_ID
- Member_ID
- Provider_ID
- Payer_ID
- Rule_ID
- Failed_Rule
- Severity

The use of `UNION ALL` allows one claim line to appear multiple times when it fails multiple rules.

Example:

```text
Claim Line 12345
|
+-- DQ02 Paid Amount Exceeds Allowed
|
+-- DQ10 Missing Diagnosis Code
```

This represents:

```text
1 affected claim line
2 data quality exceptions
```

---

# Data Quality Summary

The project also creates:

```text
dq.vw_DataQuality_Summary
```

This summarizes:

```text
Rule_ID
Failed_Rule
Severity
Exception_Count
```

and provides a reporting-ready source for Power BI.

---

# Quality Status

The project creates:

```text
dq.vw_Claims_Quality_Status
```

Each claim line is classified as:

```text
Pass
```

or:

```text
Exception
```

depending on whether the Claim Line ID appears in the consolidated exception layer.

---

# Power BI Data Quality Measures

## Total DQ Exceptions

```DAX
Total DQ Exceptions =
COUNTROWS(
    'dq vw_Claims_Exceptions'
)
```

This counts **failed rules**.

---

## Affected Claim Lines

```DAX
Affected Claim Lines =
DISTINCTCOUNT(
    'dq vw_Claims_Exceptions'[Claim_Line_ID]
)
```

This counts **unique claim lines with at least one failed rule**.

These measures intentionally answer different questions.

---

# Governance Principle

The project does not assume that failed records should automatically be deleted.

Instead:

```text
Detect
   ↓
Classify
   ↓
Expose
   ↓
Investigate
   ↓
Determine appropriate treatment
```

This preserves transparency and makes it possible for analysts and stakeholders to understand why a record may or may not be suitable for reporting.

---

# Limitations

These validation rules were created for a synthetic portfolio dataset and intentionally simplify healthcare claims processing.

They are not intended to represent comprehensive production claims-edit logic.

A production framework would likely include additional validation for:

- Eligibility
- Provider effective dates
- Member coverage dates
- Duplicate transaction logic
- Claim adjustments
- Reversals
- Corrected claims
- Procedure validity
- Diagnosis validity
- Diagnosis/procedure relationships
- CARC/RARC combinations
- Claim header versus line status
- Contract terms
- Authorization
- Timely filing
- Coordination of benefits
- Medical necessity
- Payer-specific rules

---

## Disclaimer

All data used in this framework is synthetic.

No PHI, PII, real patient data, or real healthcare claims are included.