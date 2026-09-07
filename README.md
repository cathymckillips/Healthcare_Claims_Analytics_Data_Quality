# Healthcare Claims Analytics & Data Quality Platform

## End-to-End SQL Server, Data Quality, Governance, and Power BI Portfolio Project

![Project Status](https://img.shields.io/badge/Status-Complete-success)
![SQL Server](https://img.shields.io/badge/SQL_Server-Analytics-blue)
![Power BI](https://img.shields.io/badge/Power_BI-Dashboard-yellow)
![Data Quality](https://img.shields.io/badge/Data_Quality-10_Rules-teal)
![Healthcare](https://img.shields.io/badge/Domain-Healthcare_Claims-blue)

---

## Project Overview

Healthcare reporting depends on more than building dashboards.

Before a claims KPI can be trusted, analysts need to understand the grain of the data, validate identifiers and financial relationships, identify data-quality exceptions, reconcile source and reporting results, and establish a reporting layer that supports consistent business definitions.

This portfolio project demonstrates an **end-to-end healthcare claims analytics workflow**, beginning with synthetic source data and progressing through SQL-based data validation, data-quality testing, exception management, an analytics-ready reporting layer, DAX measures, and a multi-page Power BI report.

The project was designed to answer two related questions:

> **Can the underlying claims data be trusted?**

and, once validated:

> **What can the data tell us about claims volume, denials, reimbursement, payer/provider performance, and claims-processing efficiency?**

The solution intentionally includes data-quality problems so that the project demonstrates not only how to visualize clean data, but also how to identify, document, and expose records that fail business and data-quality rules.

---

# Business Objectives

The project was designed around several common healthcare claims analytics objectives:

- Monitor claim-line volume and status
- Analyze billed, allowed, and paid amounts
- Calculate denial rates
- Identify leading denial reasons
- Compare payer performance
- Evaluate provider specialty performance
- Compare in-network and out-of-network results
- Measure claims-processing turnaround times
- Monitor pending claims
- Identify data-quality exceptions
- Measure affected claim lines
- Categorize exceptions by severity
- Preserve visibility into records that fail validation
- Provide an analytics-ready dataset for Power BI

The goal was not simply to create a dashboard.

The goal was to build a small but complete **analytics pipeline in which reporting is the final layer of a controlled data process**.

---

# Technology Stack

| Technology | Purpose |
|---|---|
| SQL Server | Relational database and analytics environment |
| T-SQL | Data validation, joins, business rules, exception detection, and reporting views |
| Power BI | Data modeling, DAX measures, KPI reporting, and interactive visualization |
| DAX | Business metrics, rates, operational calculations, and filter-context analysis |
| Excel / CSV | Initial synthetic source-data delivery |
| GitHub | Project documentation and version-controlled portfolio presentation |

---

# Data Privacy

**All data used in this project is synthetic.**

The project contains:

- No Protected Health Information (PHI)
- No Personally Identifiable Information (PII)
- No real patients
- No real claims
- No real providers
- No real payer transactions

Member IDs, provider IDs, payer information, claim identifiers, diagnosis codes, procedure codes, dates, and financial values exist only for educational and portfolio purposes.

This project is intended to demonstrate analytics methodology and should not be interpreted as a production healthcare claims system or as a complete implementation of HIPAA, X12 837/835, or payer-specific adjudication requirements.

---

# Solution Architecture

The project follows a layered analytics design.

```text
Synthetic Healthcare Claims Data
              |
              v
       Source Data Import
              |
              v
        SQL Server Tables
              |
              v
      Source Validation
              |
              v
    Data Quality Rules
        DQ01 - DQ10
              |
              v
      Exception Layer
              |
       +------+------+
       |             |
       v             v
DQ Reporting     Claims Reporting
   Views              View
       |               |
       +-------+-------+
               |
               v
          Power BI
               |
               v
   Business & Operational
          Insights
```

The architecture separates **source records**, **data-quality findings**, and **analytics-ready reporting** rather than embedding all logic directly inside Power BI.

---

# Dataset

The synthetic model contains four primary source datasets.

## Claims

The claims dataset contains **306 claim-line records**.

The grain of the primary dataset is:

> **One row = one claim line**

This distinction is important because one claim may contain multiple claim lines.

Example fields include:

- Claim_ID
- Claim_Line_ID
- Member_ID
- Provider_ID
- Payer_ID
- Service_Date
- Received_Date
- Adjudication_Date
- Payment_Date
- Claim_Status
- Place_of_Service
- Diagnosis_Code
- Procedure_Code
- Billed_Amount
- Allowed_Amount
- Paid_Amount
- Patient_Responsibility
- Denial_Reason

---

## Members

The member reference dataset contains **80 synthetic member records**.

Example attributes include:

- Member_ID
- Age_Band
- Gender
- State
- Plan_Type
- Effective_Date
- Termination_Date

---

## Providers

The provider reference dataset contains **12 synthetic provider records**.

Example attributes include:

- Provider_ID
- Provider_Name
- Specialty
- State
- Network_Status

---

## Payers

The payer reference dataset contains **3 synthetic payer records**.

Example attributes include:

- Payer_ID
- Payer_Name
- Payer_Type

The synthetic payer categories include:

- Commercial
- Medicare Advantage
- Medicaid Managed Care

---

# Source Validation

Before performing business analysis, the source datasets were validated in SQL.

Initial record-count validation confirmed:

| Dataset | Expected Records |
|---|---:|
| Claims | 306 |
| Members | 80 |
| Providers | 12 |
| Payers | 3 |

Example:

```sql
SELECT COUNT(*) AS Claims
FROM dbo.Claims;

SELECT COUNT(*) AS Members
FROM dbo.Members;

SELECT COUNT(*) AS Providers
FROM dbo.Providers;

SELECT COUNT(*) AS Payers
FROM dbo.Payers;
```

This step establishes a reconciliation point before transformations and reporting logic are introduced.

---

# Understanding the Data Grain

One of the first analytical decisions in the project was identifying the correct grain.

`Claim_ID` represents a claim.

`Claim_Line_ID` represents an individual service line within a claim.

Because claims may contain multiple service lines, simply counting claim IDs and counting physical claim-line records answer different business questions.

This distinction was carried throughout the project when defining metrics such as:

- Claim-line volume
- Unique claim lines
- Denied claim lines
- Data-quality exceptions
- Affected claim lines

Understanding the grain before creating KPIs helps prevent double counting and misleading reporting.

---

# Data Quality Framework

A central component of this project is the SQL-based data-quality framework.

The synthetic dataset intentionally contains invalid or questionable records so that validation logic can be developed independently of the source's preassigned issue labels.

Ten data-quality rules were implemented.

---

## DQ01 — Duplicate Claim Line

### Purpose

Identify duplicate `Claim_Line_ID` values.

```sql
SELECT
    Claim_Line_ID,
    COUNT(*) AS DuplicateCount
FROM dbo.Claims
GROUP BY Claim_Line_ID
HAVING COUNT(*) > 1;
```

### Business Risk

Uncontrolled duplicate claim lines can inflate:

- Claim volume
- Billed amounts
- Allowed amounts
- Paid amounts
- Utilization
- Denial counts

In a production claims environment, duplicate logic would also need to account for adjustments, reversals, replacement claims, and transaction/version identifiers.

---

## DQ02 — Paid Amount Exceeds Allowed Amount

### Purpose

Identify records where:

```text
Paid Amount > Allowed Amount
```

```sql
SELECT *
FROM dbo.Claims
WHERE Paid_Amount > Allowed_Amount;
```

### Business Risk

Unexpected relationships between allowed and paid amounts may indicate:

- Data errors
- Transformation problems
- Incorrect financial mapping
- Adjustment logic requiring additional investigation

---

## DQ03 — Missing Allowed Amount

### Purpose

Identify adjudicated claims with missing allowed amounts.

```sql
SELECT *
FROM dbo.Claims
WHERE Allowed_Amount IS NULL
  AND Claim_Status IN ('Paid', 'Denied');
```

### Business Risk

Missing financial values can affect:

- Reimbursement analysis
- Allowed-rate calculations
- Financial reconciliation
- Payer comparisons

---

## DQ04 — Orphan Member ID

### Purpose

Identify claim records whose `Member_ID` cannot be found in the member reference dataset.

```sql
SELECT c.*
FROM dbo.Claims c
LEFT JOIN dbo.Members m
    ON c.Member_ID = m.Member_ID
WHERE m.Member_ID IS NULL;
```

### Data Quality Dimension

**Referential Integrity**

---

## DQ05 — Orphan Provider ID

### Purpose

Identify claims whose provider identifier does not resolve to the provider reference dataset.

```sql
SELECT c.*
FROM dbo.Claims c
LEFT JOIN dbo.Providers p
    ON c.Provider_ID = p.Provider_ID
WHERE p.Provider_ID IS NULL;
```

### Business Risk

Missing provider relationships can affect:

- Specialty analysis
- Network analysis
- Provider performance reporting
- Payment attribution

---

## DQ06 — Orphan Payer ID

### Purpose

Identify claims whose payer identifier does not resolve to the payer reference dataset.

```sql
SELECT c.*
FROM dbo.Claims c
LEFT JOIN dbo.Payers p
    ON c.Payer_ID = p.Payer_ID
WHERE p.Payer_ID IS NULL;
```

### Business Risk

Unmatched payer identifiers can prevent accurate:

- Payer reporting
- Reimbursement analysis
- Denial analysis
- Financial reconciliation

---

## DQ07 — Denied Claim With Payment

### Purpose

Identify records marked as denied that also contain a positive payment.

```sql
SELECT *
FROM dbo.Claims
WHERE Claim_Status = 'Denied'
  AND Paid_Amount > 0;
```

### Data Quality Dimension

**Cross-Field Business Rule Consistency**

The rule intentionally simplifies real claims behavior for portfolio purposes. Production logic would account for partial payments, claim adjustments, reversals, and line-level adjudication.

---

## DQ08 — Received Date Before Service Date

### Purpose

Identify claims received before the documented date of service.

```sql
SELECT *
FROM dbo.Claims
WHERE Received_Date < Service_Date;
```

### Data Quality Dimension

**Temporal Consistency**

This rule validates the logical sequence:

```text
Service
   ↓
Claim Receipt
   ↓
Adjudication
   ↓
Payment
```

---

## DQ09 — Negative Billed Amount

### Purpose

Identify negative billed amounts in the simplified claims model.

```sql
SELECT *
FROM dbo.Claims
WHERE Billed_Amount < 0;
```

### Business Risk

Negative amounts may require investigation to determine whether they represent:

- Data errors
- Reversals
- Adjustments
- Incorrect transaction classification

The synthetic project treats them as exceptions for validation purposes.

---

## DQ10 — Missing Diagnosis Code

### Purpose

Identify claims with NULL, blank, or whitespace-only diagnosis codes.

```sql
SELECT *
FROM dbo.Claims
WHERE Diagnosis_Code IS NULL
   OR LTRIM(RTRIM(Diagnosis_Code)) = '';
```

### Data Quality Dimension

**Completeness**

---

# Exception Management Layer

A major design decision was to avoid silently removing records that fail validation.

Instead, the project creates an exception layer that preserves visibility into:

- Claim Line ID
- Claim ID
- Failed Rule
- Rule ID
- Severity
- Related business identifiers

The consolidated exception view uses `UNION ALL` to combine results from the individual DQ rules.

Conceptually:

```text
Claim Line
    |
    +---- DQ02: Paid > Allowed
    |
    +---- DQ10: Missing Diagnosis
```

A single claim line can therefore generate multiple exceptions.

This creates an important distinction between:

### Total DQ Exceptions

The total number of failed rule evaluations.

and:

### Affected Claim Lines

The number of unique claim lines with at least one exception.

For example:

```text
1 Claim Line
2 Failed Rules
```

equals:

```text
1 Affected Claim Line
2 Data Quality Exceptions
```

This distinction is preserved in the Power BI data-quality reporting.

---

# Exception Severity

Exceptions are categorized by severity to help prioritize investigation.

The project currently uses:

- **High**
- **Medium**

Severity allows data-quality reporting to move beyond simply counting failed records.

A consolidated summary view provides:

```text
Rule ID
Failed Rule
Severity
Exception Count
```

This supports Power BI visuals such as:

- Exceptions by rule
- Exceptions by severity
- Affected claim lines
- Overall exception volume

---

# Analytics-Ready Reporting Layer

After source validation and data-quality logic were established, an analytics-ready SQL view was created:

```text
reporting.vw_ClaimsAnalytics
```

The reporting view combines claim-line data with member, provider, payer, and data-quality attributes.

The view includes fields such as:

```text
Claim_ID
Claim_Line_ID

Member_ID
Age_Band
Gender
Member_State
Plan_Type

Provider_ID
Provider_Name
Specialty
Provider_State
Network_Status

Payer_ID
Payer_Name
Payer_Type

Service_Date
Received_Date
Adjudication_Date
Payment_Date

Claim_Status
Place_of_Service
Diagnosis_Code
Procedure_Code

Billed_Amount
Allowed_Amount
Paid_Amount
Patient_Responsibility
Denial_Reason

Data_Quality_Status
Adjudication_Days
Billed_to_Allowed_Variance
Allowed_to_Paid_Variance
```

This approach moves important integration and business logic upstream into SQL instead of recreating it independently in every Power BI visual.

---

# Derived Operational Metrics

The reporting layer supports several claims-lifecycle calculations.

## Adjudication Days

```text
Received Date → Adjudication Date
```

Calculated using SQL:

```sql
DATEDIFF(
    DAY,
    Received_Date,
    Adjudication_Date
)
```

---

## Billed-to-Allowed Variance

```text
Billed Amount - Allowed Amount
```

This measures the difference between submitted charges and the payer-allowed amount.

The variance is intentionally described as a **variance**, not automatically as "lost revenue," because billed charges and contractually allowed amounts represent different concepts.

---

## Allowed-to-Paid Variance

```text
Allowed Amount - Paid Amount
```

This supports further analysis of the relationship between allowed reimbursement and actual payment.

---

# Power BI Report

The final Power BI solution transforms the governed reporting layer into a multi-page analytical report.

The report is organized around different business questions rather than simply presenting a collection of charts.

---

# Page 1 — Claims Executive Overview

### Purpose

Provide leadership with a high-level view of claims volume, financial performance, status, and processing activity.

### Key KPIs

- Claim Line Records
- Total Billed
- Total Allowed
- Total Paid
- Denial Rate
- Average Adjudication Days

### Visuals

- Claim Status
- Financial Funnel
- Claims Over Time
- Payer Breakdown

The financial progression allows comparison of:

```text
Billed
   ↓
Allowed
   ↓
Paid
```

This page is designed to answer:

> What is happening across the claims portfolio at a glance?

---

# Page 2 — Denials Analysis

### Purpose

Identify denial patterns and potential drivers.

### Key Metrics

- Claim Lines
- Denied Claim Lines
- Denial Rate
- Denied Billed Amount
- Denied Allowed Amount

### Analysis

Denials are evaluated by:

- Denial Claim Lines by Reason
- Denial by Payers
- Denial by Provider Specialty
- Detailed Denial Claims

The project includes synthetic denial categories such as:

- CO-16 Missing Information
- CO-50 Non-Covered Service
- CO-97 Bundled Service
- PR-204 Not Covered

The page is designed to answer:

> Where are denials occurring, and what appears to be driving them?

---

# Page 3 — Payer & Provider Analysis

### Purpose

Evaluate reimbursement and operational performance across payers and providers.

### Financial Measures

- Total Billed
- Total Allowed
- Total Paid
- Allowed Rate
- Paid-to-Allowed Rate

### Example Calculation

```DAX
Allowed Rate =
DIVIDE(
    SUM('reporting vw_ClaimsAnalytics'[Allowed_Amount]),
    SUM('reporting vw_ClaimsAnalytics'[Billed_Amount]),
    0
)
```

### Payer Analysis

The report compares:

- Billed Amount by Payer
- Allowed Amount by Payer
- Payer Financial Performance
- Denial by Payers

### Provider Analysis

Provider performance can be analyzed by:

- Specialty
- Network Status
- Paid Amount

This page moves beyond record counts and begins evaluating differences in reimbursement and operational performance.

---

# Page 4 — Claims Operations

### Purpose

Analyze the claims lifecycle and processing efficiency.

The lifecycle is represented as:

```text
Service Date
     ↓
Received Date
     ↓
Adjudication Date
     ↓
Payment Date
```

### Operational KPIs

#### Average Service-to-Receipt Days

```DAX
Avg Service to Receipt Days =
AVERAGEX(
    FILTER(
        'reporting vw_ClaimsAnalytics',
        NOT ISBLANK('reporting vw_ClaimsAnalytics'[Service_Date]) &&
        NOT ISBLANK('reporting vw_ClaimsAnalytics'[Received_Date])
    ),
    DATEDIFF(
        'reporting vw_ClaimsAnalytics'[Service_Date],
        'reporting vw_ClaimsAnalytics'[Received_Date],
        DAY
    )
)
```

#### Average Adjudication Days

```DAX
Avg Adjudication Days =
AVERAGE(
    'reporting vw_ClaimsAnalytics'[Adjudication_Days]
)
```

#### Average Payment Days

```DAX
Avg Payment Days =
AVERAGEX(
    FILTER(
        'reporting vw_ClaimsAnalytics',
        NOT ISBLANK('reporting vw_ClaimsAnalytics'[Adjudication_Date]) &&
        NOT ISBLANK('reporting vw_ClaimsAnalytics'[Payment_Date])
    ),
    DATEDIFF(
        'reporting vw_ClaimsAnalytics'[Adjudication_Date],
        'reporting vw_ClaimsAnalytics'[Payment_Date],
        DAY
    )
)
```

#### Pending Claim Lines

```DAX
Pending Claim Lines =
CALCULATE(
    COUNTROWS('reporting vw_ClaimsAnalytics'),
    'reporting vw_ClaimsAnalytics'[Claim_Status] = "Pending"
)
```

### Operational Visuals

- Average Adjudication Days by Payer
- Lifecycle by Claim Status
- Claims by Service Date

This page is designed to answer:

> How efficiently are claims moving through adjudication and payment?

---

# Page 5 — Data Quality & Governance

### Purpose

Make the underlying validation process visible instead of presenting only a clean final dataset.

This page connects the Power BI report directly to the SQL data-quality framework.

### Core Measures

#### Total DQ Exceptions

```DAX
Total DQ Exceptions =
COUNTROWS('dq vw_Claims_Exceptions')
```

#### Affected Claim Lines

```DAX
Affected Claim Lines =
DISTINCTCOUNT(
    'dq vw_Claims_Exceptions'[Claim_Line_ID]
)
```

### Visuals

#### Data Quality Exceptions by Rule

Shows the volume of exceptions generated by each validation rule.

Examples:

```text
Duplicate Claim Line
Paid Amount > Allowed Amount
Missing Allowed Amount
Orphan Member
Orphan Provider
Orphan Payer
Denied With Payment
Received Before Service
Negative Billed Amount
Missing Diagnosis
```

#### Data Quality Exceptions by Severity

Summarizes exceptions into:

```text
High
Medium
```

This page is designed to answer:

> What failed validation, how serious is it, and how much of the claims population is affected?

---

# Core DAX Measures

Several reusable measures support the report.

## Claim Line Records

```DAX
Claim Line Records =
COUNTROWS(
    'reporting vw_ClaimsAnalytics'
)
```

---

## Unique Claim Line IDs

```DAX
Unique Claim Line IDs =
DISTINCTCOUNT(
    'reporting vw_ClaimsAnalytics'[Claim_Line_ID]
)
```

The project deliberately distinguishes physical records from unique claim-line identifiers because duplicate claim lines are part of the data-quality test scenarios.

---

## Total Billed

```DAX
Total Billed =
SUM(
    'reporting vw_ClaimsAnalytics'[Billed_Amount]
)
```

---

## Total Allowed

```DAX
Total Allowed =
SUM(
    'reporting vw_ClaimsAnalytics'[Allowed_Amount]
)
```

---

## Total Paid

```DAX
Total Paid =
SUM(
    'reporting vw_ClaimsAnalytics'[Paid_Amount]
)
```

---

## Denied Claim Lines

```DAX
Denied Claim Lines =
CALCULATE(
    COUNTROWS('reporting vw_ClaimsAnalytics'),
    'reporting vw_ClaimsAnalytics'[Claim_Status] = "Denied"
)
```

---

## Denial Rate

```DAX
Denial Rate =
DIVIDE(
    [Denied Claim Lines],
    [Claim Line Records],
    0
)
```

---

## Allowed Rate

```DAX
Allowed Rate =
DIVIDE(
    [Total Allowed],
    [Total Billed],
    0
)
```

---

## Paid-to-Allowed Rate

```DAX
Paid Allowed % =
DIVIDE(
    [Total Paid],
    [Total Allowed],
    0
)
```

---

# Validation and Reconciliation

An important part of the project was validating Power BI results against SQL rather than assuming a visual was correct because it rendered successfully.

For example, payer-level allowed rates were validated using:

```sql
SELECT
    Network_Status,
    SUM(Billed_Amount) AS Total_Billed,
    SUM(Allowed_Amount) AS Total_Allowed,
    CAST(
        SUM(Allowed_Amount) * 100.0 /
        NULLIF(SUM(Billed_Amount), 0)
        AS DECIMAL(10,2)
    ) AS Allowed_Rate
FROM reporting.vw_ClaimsAnalytics
GROUP BY Network_Status
ORDER BY Network_Status;
```

This reconciliation process helped identify Power BI issues involving:

- Incorrect filter context
- Measures referencing different tables
- Distinct counts versus physical row counts
- Incorrect visual types
- Percentage rounding
- Display-unit formatting
- Fields originating from disconnected or different reporting tables

A recurring validation question throughout development was:

> **Source? Date? Definition?**

A KPI is not considered trustworthy until its source, time context, grain, and business definition are understood.

---

# Key Analytical Concepts Demonstrated

This project demonstrates more than dashboard development.

## Data Grain

Understanding the difference between:

```text
Claim
Claim Line
Physical Record
Unique Claim-Line Identifier
```

---

## Referential Integrity

Validating foreign-key-like relationships across:

```text
Claims → Members
Claims → Providers
Claims → Payers
```

---

## Financial Validation

Evaluating relationships among:

```text
Billed Amount
Allowed Amount
Paid Amount
Patient Responsibility
```

---

## Temporal Validation

Evaluating lifecycle relationships among:

```text
Service Date
Received Date
Adjudication Date
Payment Date
```

---

## Exception Management

Making failed records visible rather than silently excluding them.

---

## Data Lineage

Following data from:

```text
Source
   ↓
SQL Tables
   ↓
Validation Rules
   ↓
Exception Layer
   ↓
Reporting View
   ↓
DAX
   ↓
Power BI Visual
```

---

## Filter Context

Ensuring dimensions such as payer, provider specialty, network status, denial reason, and claim status correctly filter analytical measures.

---

## Reconciliation

Comparing Power BI calculations against SQL query results before accepting the final KPI.

---

# SQL Project Structure

The SQL development files are organized in execution order.

```text
Healthcare_Claims_Analytics_SQL/
│
├── 00_README.txt
├── 01_Create_Database_and_Schemas.sql
├── 02_Create_Source_Tables.sql
├── 03_Source_Data_Validation.sql
│
├── 04_DQ01_Duplicate_Claim_Line.sql
├── 05_DQ02_Paid_Exceeds_Allowed.sql
├── 06_DQ03_Missing_Allowed_Amount.sql
├── 07_DQ04_Orphan_Member.sql
├── 08_DQ05_Orphan_Provider.sql
├── 09_DQ06_Orphan_Payer.sql
├── 10_DQ07_Denied_With_Payment.sql
├── 11_DQ08_Received_Before_Service.sql
├── 12_DQ09_Negative_Billed_Amount.sql
├── 13_DQ10_Missing_Diagnosis_Code.sql
│
├── 14_Create_DQ_Exception_Views.sql
├── 15_Create_Reporting_View.sql
└── 16_Validation_Checks.sql
```

This structure allows a reviewer to follow the development progression from source setup through validation and final reporting.

---

# Recommended Repository Structure

A complete GitHub repository can be organized as:

```text
healthcare-claims-analytics/
│
├── README.md
│
├── data/
│   ├── README.md
│   └── synthetic_healthcare_claims_analytics.xlsx
│
├── sql/
│   ├── 01_Create_Database_and_Schemas.sql
│   ├── 02_Create_Source_Tables.sql
│   ├── 03_Source_Data_Validation.sql
│   ├── 04_DQ01_Duplicate_Claim_Line.sql
│   ├── ...
│   ├── 14_Create_DQ_Exception_Views.sql
│   ├── 15_Create_Reporting_View.sql
│   └── 16_Validation_Checks.sql
│
├── powerbi/
│   └── Healthcare_Claims_Analytics.pbix
│
├── screenshots/
│   ├── 01_Executive_Overview.png
│   ├── 02_Denials_Analysis.png
│   ├── 03_Payer_Provider_Analysis.png
│   ├── 04_Claims_Operations.png
│   └── 05_Data_Quality.png
│
└── documentation/
    ├── data_dictionary.md
    ├── data_quality_rules.md
    └── project_architecture.md
```

---

# Development Approach

The project followed an iterative development process.

## Phase 1 — Understand the Data

- Define dataset grain
- Review source fields
- Identify reference datasets
- Validate source counts

## Phase 2 — Establish Data Quality Rules

- Identify potential failure conditions
- Write individual SQL validation queries
- Review returned exceptions
- Assign rule IDs and severity

## Phase 3 — Build the Exception Layer

- Consolidate DQ failures
- Preserve failed rule information
- Distinguish exceptions from affected claim lines
- Create DQ summary views

## Phase 4 — Build the Reporting Layer

- Join claims to reference data
- Add provider and payer attributes
- Add operational calculations
- Add DQ status
- Produce an analytics-ready SQL view

## Phase 5 — Build Business Measures

- Claim volume
- Financial measures
- Denial measures
- Reimbursement rates
- Lifecycle metrics
- DQ metrics

## Phase 6 — Build Power BI Report

- Executive reporting
- Denial analysis
- Payer/provider analysis
- Claims operations
- Data-quality reporting

## Phase 7 — Reconcile

- Compare Power BI results against SQL
- Investigate discrepancies
- Correct filter context
- Verify metric definitions
- Validate final outputs

---

# Key Lessons

## 1. The Dashboard Is the Last Mile

A polished visualization does not guarantee trustworthy analytics.

The quality of the dashboard depends on the quality and definition of the data feeding it.

---

## 2. Establish Grain Before Writing Measures

Determining whether a row represents a claim, claim line, transaction, or adjustment is fundamental to correct aggregation.

---

## 3. Do Not Hide Failed Records

A clean reporting dataset without an explanation of excluded records can create its own governance problem.

Exception visibility provides transparency into:

- What failed
- Why it failed
- How severe the issue is
- Which records are affected

---

## 4. Similar Numbers Are Not Necessarily the Same Metric

During development, distinctions such as:

```text
COUNTROWS()
```

versus:

```text
DISTINCTCOUNT()
```

proved important.

The correct calculation depends on the business question and data grain.

---

## 5. Validate Power BI Against SQL

When a visual appears suspicious, return to the source.

SQL reconciliation was used throughout the project to validate payer, denial, network, financial, and operational metrics.

---

## 6. Business Definitions Matter

Terms such as:

- Claim
- Claim line
- Denial
- Allowed amount
- Paid amount
- Adjudication time
- Exception
- Affected record

must be explicitly defined.

Technical correctness alone does not guarantee that two stakeholders are discussing the same KPI.

---

# What This Project Demonstrates

This project demonstrates practical experience applying:

### SQL

- Aggregations
- CASE logic
- GROUP BY
- HAVING
- LEFT JOIN
- Referential-integrity validation
- NULL handling
- Date calculations
- Financial validation
- UNION ALL
- SQL views
- Reporting-layer development

### Data Quality

- Uniqueness
- Completeness
- Referential integrity
- Financial consistency
- Temporal consistency
- Business-rule validation
- Exception management
- Severity classification

### Business Intelligence

- KPI development
- DAX
- Filter context
- Data reconciliation
- Dashboard design
- Operational analytics
- Financial analysis
- Trend analysis

### Healthcare Analytics Concepts

- Claim versus claim-line grain
- Denials
- Billed amounts
- Allowed amounts
- Paid amounts
- Payer analysis
- Provider specialty analysis
- Network analysis
- Adjudication
- Payment lag
- Claims lifecycle

### Governance

- Business definitions
- Data-quality rules
- Exception transparency
- Reporting consistency
- Data lineage
- Validation before consumption

---

# Potential Future Enhancements

This project intentionally uses a simplified synthetic claims model. Future iterations could expand the solution with:

- Claim adjustment and reversal transactions
- Claim versioning
- Header-versus-line adjudication
- More detailed denial categorization
- CARC/RARC analysis
- ICD diagnosis groupings
- CPT/HCPCS procedure groupings
- Member eligibility validation
- Provider network effective dates
- Payer contract modeling
- Expected reimbursement modeling
- First-pass resolution rate
- Clean claim rate
- Days in accounts receivable
- Resubmission analysis
- Appeal tracking
- Denial recovery analysis
- Claim aging
- Additional data-quality dimensions
- Historical DQ snapshots
- Rule ownership and stewardship
- Exception-resolution workflow
- Incremental refresh
- Microsoft Fabric implementation
- Automated SQL/Python validation testing

These enhancements would move the project closer to a production-style healthcare revenue-cycle and claims analytics architecture.

---

# Project Takeaway

The most important outcome of this project is not a single chart or KPI.

It is the end-to-end analytical process:

```text
Understand the grain
        ↓
Validate the source
        ↓
Identify exceptions
        ↓
Preserve transparency
        ↓
Build trusted reporting logic
        ↓
Define business measures
        ↓
Reconcile the results
        ↓
Visualize the insight
```

The project reflects an analytics principle that applies well beyond healthcare:

> **Before asking what the dashboard says, establish whether the underlying data deserves to be trusted.**

---

# Author

**Catherine McKillips**

Data & Business Intelligence Analyst

Focus areas:

- Data Analytics
- Business Intelligence
- SQL
- Power BI
- Data Quality
- Data Validation
- Reporting
- Data Governance
- Healthcare Analytics

---

## Disclaimer

This project was created for portfolio and educational purposes.

All healthcare claims data is synthetic. The project does not contain PHI, PII, or real patient information.

The business rules used in the project are intentionally simplified to demonstrate analytics, data-quality, and BI development concepts. They should not be interpreted as comprehensive production healthcare claims adjudication rules.
