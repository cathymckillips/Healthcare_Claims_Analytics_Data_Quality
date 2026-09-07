# Healthcare Claims Analytics — Data Dictionary

## Overview

This data dictionary documents the primary fields used in the Healthcare Claims Analytics portfolio project.

The project uses entirely synthetic healthcare claims data and contains no PHI, PII, or real patient information.

The primary analytical grain is:

> **One row = one claim line**

The solution combines four source datasets:

- Claims
- Members
- Providers
- Payers

These datasets are integrated into the analytics-ready SQL view:

`reporting.vw_ClaimsAnalytics`

---

# Claims Data

## Claim_ID

**Data Type:** VARCHAR

**Definition:**  
Synthetic identifier representing a healthcare claim.

**Business Use:**  
Used to group one or more claim lines belonging to the same claim.

**Important:**  
`Claim_ID` is not necessarily unique because one claim may contain multiple claim lines.

---

## Claim_Line_ID

**Data Type:** VARCHAR

**Definition:**  
Synthetic identifier representing an individual service line within a claim.

**Business Use:**  
Primary identifier used for claim-line-level analytics and data-quality validation.

**Expected Rule:**  
Claim Line ID should be unique within the simplified project model.

**Related DQ Rule:**  
DQ01 — Duplicate Claim Line

---

## Member_ID

**Data Type:** VARCHAR

**Definition:**  
Synthetic identifier representing the member associated with the claim line.

**Reference Dataset:**  
`dbo.Members`

**Business Use:**  
Supports demographic and plan analysis.

**Related DQ Rule:**  
DQ04 — Orphan Member ID

---

## Provider_ID

**Data Type:** VARCHAR

**Definition:**  
Synthetic identifier representing the provider associated with the claim line.

**Reference Dataset:**  
`dbo.Providers`

**Business Use:**  
Supports provider, specialty, state, and network analysis.

**Related DQ Rule:**  
DQ05 — Orphan Provider ID

---

## Payer_ID

**Data Type:** VARCHAR

**Definition:**  
Synthetic identifier representing the payer responsible for adjudicating the claim.

**Reference Dataset:**  
`dbo.Payers`

**Business Use:**  
Supports payer-level financial, denial, and operational analysis.

**Related DQ Rule:**  
DQ06 — Orphan Payer ID

---

# Claims Lifecycle Dates

## Service_Date

**Data Type:** DATE

**Definition:**  
Date on which the healthcare service was provided.

**Business Use:**  
Beginning of the claims lifecycle.

---

## Received_Date

**Data Type:** DATE

**Definition:**  
Date the claim was received for processing.

**Business Use:**  
Used to calculate service-to-receipt processing time.

**Related DQ Rule:**  
DQ08 — Received Date Before Service Date

---

## Adjudication_Date

**Data Type:** DATE

**Definition:**  
Date on which the claim was adjudicated.

**Business Use:**  
Used to calculate claim-processing turnaround time.

---

## Payment_Date

**Data Type:** DATE

**Definition:**  
Date payment was issued for applicable claims.

**Business Use:**  
Used to calculate adjudication-to-payment lag.

**Expected Behavior:**  
May be NULL for claims that have not resulted in payment.

---

# Claim Classification

## Claim_Status

**Data Type:** VARCHAR

**Definition:**  
Current status assigned to the claim line.

**Example Values:**

- Paid
- Denied
- Pending

**Business Use:**  
Supports status distribution, denial analysis, and pending-claim monitoring.

---

## Place_of_Service

**Data Type:** VARCHAR

**Definition:**  
Synthetic classification describing where the healthcare service occurred.

**Business Use:**  
Supports utilization and service-location analysis.

---

## Diagnosis_Code

**Data Type:** VARCHAR

**Definition:**  
Synthetic diagnosis code associated with the claim line.

**Business Use:**  
Supports diagnosis-based analysis and completeness validation.

**Related DQ Rule:**  
DQ10 — Missing Diagnosis Code

---

## Procedure_Code

**Data Type:** VARCHAR

**Definition:**  
Synthetic procedure/service code associated with the claim line.

**Business Use:**  
Supports procedure-level analysis.

---

# Financial Fields

## Billed_Amount

**Data Type:** DECIMAL

**Definition:**  
Amount submitted as the billed charge for the claim line.

**Business Use:**

- Total billed reporting
- Payer financial analysis
- Billed-to-allowed variance
- Denied billed amount

**Related DQ Rule:**  
DQ09 — Negative Billed Amount

---

## Allowed_Amount

**Data Type:** DECIMAL

**Definition:**  
Amount recognized as allowable under the simplified payer adjudication model.

**Business Use:**

- Total allowed reporting
- Allowed rate
- Billed-to-allowed variance
- Reimbursement analysis

**Related DQ Rule:**  
DQ03 — Missing Allowed Amount

---

## Paid_Amount

**Data Type:** DECIMAL

**Definition:**  
Amount paid for the claim line.

**Business Use:**

- Total paid reporting
- Paid-to-allowed rate
- Payer analysis
- Provider analysis

**Related DQ Rules:**

- DQ02 — Paid Amount Exceeds Allowed Amount
- DQ07 — Denied Claim With Payment

---

## Patient_Responsibility

**Data Type:** DECIMAL

**Definition:**  
Amount assigned as patient responsibility within the synthetic claim.

**Business Use:**  
Supports financial analysis of payer versus patient responsibility.

---

## Denial_Reason

**Data Type:** VARCHAR

**Definition:**  
Reason associated with a denied claim line.

**Example Synthetic Values:**

- CO-16 Missing Information
- CO-50 Non-Covered Service
- CO-97 Bundled Service
- PR-204 Not Covered

**Business Use:**

- Denial-driver analysis
- Denial counts
- Payer comparisons
- Operational investigation

---

# Member Reference Data

## Age_Band

**Definition:**  
Synthetic age grouping used for demographic analysis.

---

## Gender

**Definition:**  
Synthetic demographic category.

---

## Member_State

**Definition:**  
State associated with the synthetic member record.

**Source:**  
`dbo.Members.State`

---

## Plan_Type

**Definition:**  
Synthetic member plan classification.

**Business Use:**  
Supports plan-level analysis.

---

## Effective_Date

**Definition:**  
Beginning date of the synthetic member coverage period.

---

## Termination_Date

**Definition:**  
Ending date of the synthetic member coverage period when applicable.

---

# Provider Reference Data

## Provider_Name

**Definition:**  
Synthetic provider name associated with the Provider ID.

---

## Specialty

**Definition:**  
Provider specialty classification.

**Example Uses:**

- Total paid by specialty
- Denial rate by specialty
- Claim volume by specialty

---

## Provider_State

**Definition:**  
State associated with the provider.

**Source:**  
`dbo.Providers.State`

---

## Network_Status

**Definition:**  
Classification indicating the provider's synthetic network relationship.

**Example Values:**

- In Network
- Out of Network

**Business Use:**

- Allowed-rate comparison
- Paid-amount comparison
- Denial-rate analysis

---

# Payer Reference Data

## Payer_Name

**Definition:**  
Synthetic name associated with a payer.

**Business Use:**

- Payer financial analysis
- Denial analysis
- Adjudication analysis

---

## Payer_Type

**Definition:**  
Classification of payer.

**Synthetic Categories:**

- Commercial
- Medicare Advantage
- Medicaid Managed Care

---

# Derived Reporting Fields

## Data_Quality_Status

**Definition:**  
Indicates whether a claim line has been identified by the project's SQL data-quality framework.

**Example Values:**

- Pass
- Exception

---

## Adjudication_Days

**Definition:**  
Number of days between claim receipt and adjudication.

**Calculation:**

```text
Adjudication Date - Received Date
```

**SQL Logic:**

```sql
DATEDIFF(
    DAY,
    Received_Date,
    Adjudication_Date
)
```

**Business Use:**

- Average adjudication days
- Payer turnaround analysis
- Claims operations reporting

---

## Billed_to_Allowed_Variance

**Definition:**  
Difference between billed and allowed amounts.

**Calculation:**

```text
Billed Amount - Allowed Amount
```

**Business Use:**  
Measures the difference between submitted charges and the payer-allowed amount.

**Important:**  
This is described as a variance rather than automatically as lost revenue.

---

## Allowed_to_Paid_Variance

**Definition:**  
Difference between allowed and paid amounts.

**Calculation:**

```text
Allowed Amount - Paid Amount
```

**Business Use:**  
Supports reimbursement and financial analysis.

---

# Data Quality Fields

## Rule_ID

**Definition:**  
Unique identifier assigned to each data-quality rule.

**Values:**  
DQ01 through DQ10

---

## Failed_Rule

**Definition:**  
Business-readable description of the validation rule failed by a claim line.

---

## Severity

**Definition:**  
Classification indicating the relative importance of an exception.

**Current Values:**

- High
- Medium

---

# Analytical Grain Reminder

The most important modeling principle in this project is:

> **Claim count and claim-line count are not automatically interchangeable.**

A single claim may contain multiple claim lines.

Measures should therefore explicitly identify whether they are counting:

- Physical records
- Unique Claim IDs
- Unique Claim Line IDs
- DQ exceptions
- Claim lines affected by exceptions

This distinction prevents accidental double counting and improves reporting transparency.

---

## Disclaimer

All data and identifiers documented here are synthetic and were created exclusively for portfolio and educational purposes.