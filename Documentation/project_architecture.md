# Healthcare Claims Analytics — Project Architecture

## Overview

This document describes the technical architecture of the Healthcare Claims Analytics portfolio project.

The solution demonstrates an end-to-end analytics workflow from synthetic source data through SQL validation, data-quality exception management, reporting views, DAX measures, and Power BI visualization.

The primary design principle is:

> **Power BI should consume analytics-ready data rather than contain every transformation and validation rule itself.**

---

# Architecture Overview

```text
┌───────────────────────────────────────┐
│       SYNTHETIC SOURCE DATA           │
│                                       │
│ Claims                                │
│ Members                               │
│ Providers                             │
│ Payers                                │
└───────────────────┬───────────────────┘
                    │
                    ▼
┌───────────────────────────────────────┐
│          SQL SERVER SOURCE            │
│                                       │
│ dbo.Claims                            │
│ dbo.Members                           │
│ dbo.Providers                         │
│ dbo.Payers                            │
└───────────────────┬───────────────────┘
                    │
                    ▼
┌───────────────────────────────────────┐
│        SOURCE VALIDATION              │
│                                       │
│ Row counts                            │
│ Grain validation                      │
│ Identifier review                     │
│ Financial review                      │
│ Date review                           │
└───────────────────┬───────────────────┘
                    │
                    ▼
┌───────────────────────────────────────┐
│       DATA QUALITY FRAMEWORK          │
│                                       │
│ DQ01 Duplicate Claim Line             │
│ DQ02 Paid > Allowed                   │
│ DQ03 Missing Allowed Amount           │
│ DQ04 Orphan Member                    │
│ DQ05 Orphan Provider                  │
│ DQ06 Orphan Payer                     │
│ DQ07 Denied With Payment              │
│ DQ08 Received Before Service          │
│ DQ09 Negative Billed Amount           │
│ DQ10 Missing Diagnosis                │
└───────────────────┬───────────────────┘
                    │
                    ▼
┌───────────────────────────────────────┐
│          EXCEPTION LAYER              │
│                                       │
│ dq.vw_Claims_Exceptions               │
│ dq.vw_DataQuality_Summary             │
│ dq.vw_Claims_Quality_Status           │
└───────────────────┬───────────────────┘
                    │
                    ▼
┌───────────────────────────────────────┐
│          REPORTING LAYER              │
│                                       │
│ reporting.vw_ClaimsAnalytics          │
│                                       │
│ Claims + Members + Providers + Payers │
│ + DQ Status + Derived Metrics         │
└───────────────────┬───────────────────┘
                    │
                    ▼
┌───────────────────────────────────────┐
│             POWER BI                  │
│                                       │
│ DAX Measures                          │
│ KPI Cards                             │
│ Operational Analytics                │
│ Financial Analytics                  │
│ Denial Analytics                      │
│ Data Quality Reporting                │
└───────────────────────────────────────┘
```

---

# Layer 1 — Synthetic Source Data

The project begins with four synthetic datasets:

```text
Claims
Members
Providers
Payers
```

The source data intentionally contains data-quality exceptions.

This allows the solution to demonstrate both:

1. Business analytics
2. Data-quality/governance analytics

No real healthcare information is used.

---

# Layer 2 — SQL Server Source Tables

The datasets are loaded into SQL Server.

```text
dbo.Claims
dbo.Members
dbo.Providers
dbo.Payers
```

## Source Counts

```text
Claims       306 claim-line records
Members       80 records
Providers     12 records
Payers         3 records
```

These counts establish the baseline used for later reconciliation.

---

# Layer 3 — Source Validation

Before transformation, the source data is validated.

Validation includes:

- Record counts
- Claim-versus-claim-line grain
- Duplicate identifiers
- NULL values
- Financial relationships
- Reference-data relationships
- Date sequencing

The primary grain is established as:

> **One row = one claim line**

This decision drives downstream measures and prevents accidental mixing of claim counts and claim-line counts.

---

# Layer 4 — Data Quality Framework

The data-quality layer contains ten independent SQL validation rules.

```text
DQ01 → Uniqueness
DQ02 → Financial consistency
DQ03 → Completeness
DQ04 → Referential integrity
DQ05 → Referential integrity
DQ06 → Referential integrity
DQ07 → Business-rule consistency
DQ08 → Temporal consistency
DQ09 → Financial validity
DQ10 → Completeness
```

Each rule identifies records requiring investigation.

The rules are deliberately evaluated from the actual source fields rather than relying on a preexisting issue flag.

---

# Layer 5 — Exception Management

The individual DQ rule results are consolidated into:

```text
dq.vw_Claims_Exceptions
```

The exception layer records:

```text
Claim Line ID
Claim ID
Member ID
Provider ID
Payer ID
Rule ID
Failed Rule
Severity
```

This architecture allows a claim line to fail more than one rule.

For example:

```text
Claim Line
   |
   +---- DQ02
   |
   +---- DQ10
```

This is intentionally preserved as two exceptions rather than collapsing the record into a generic "bad data" flag.

---

# Data Quality Summary Layer

The project also creates:

```text
dq.vw_DataQuality_Summary
```

This provides aggregated counts by:

- Rule
- Description
- Severity

It supports dashboard-level data-quality reporting.

---

# Claim Quality Status

The view:

```text
dq.vw_Claims_Quality_Status
```

provides a simplified classification:

```text
Pass
Exception
```

This allows the reporting layer to retain awareness of data quality without embedding all DQ logic directly into the claims view.

---

# Layer 6 — Reporting Layer

The primary analytics-ready SQL object is:

```text
reporting.vw_ClaimsAnalytics
```

The reporting view combines:

```text
dbo.Claims
     |
     +---- dbo.Members
     |
     +---- dbo.Providers
     |
     +---- dbo.Payers
     |
     +---- dq.vw_Claims_Quality_Status
```

The result is a denormalized analytical view suitable for Power BI.

---

# Reporting View Enrichment

The reporting layer adds descriptive attributes including:

### Member

- Age Band
- Gender
- State
- Plan Type

### Provider

- Provider Name
- Specialty
- Provider State
- Network Status

### Payer

- Payer Name
- Payer Type

### Data Quality

- Data Quality Status

---

# Derived SQL Metrics

Several calculations are performed upstream in SQL.

## Adjudication Days

```sql
DATEDIFF(
    DAY,
    Received_Date,
    Adjudication_Date
)
```

Represents:

```text
Claim Receipt → Adjudication
```

---

## Billed-to-Allowed Variance

```sql
Billed_Amount - Allowed_Amount
```

Represents the difference between submitted charges and the payer-allowed amount.

---

## Allowed-to-Paid Variance

```sql
Allowed_Amount - Paid_Amount
```

Supports reimbursement analysis.

---

# Layer 7 — Power BI Semantic and Measure Layer

Power BI consumes the reporting and DQ views.

DAX is primarily used for business measures that should respond dynamically to report filter context.

Examples include:

```text
Claim Line Records
Total Billed
Total Allowed
Total Paid
Denied Claim Lines
Denial Rate
Allowed Rate
Paid-to-Allowed Rate
Average Adjudication Days
Average Payment Days
Pending Claim Lines
Total DQ Exceptions
Affected Claim Lines
```

---

# Why Some Logic Is in SQL and Some Is in DAX

The project deliberately separates responsibilities.

## SQL

Used for:

- Source validation
- Joins
- Referential-integrity checks
- Data-quality rules
- Exception generation
- Reporting-view creation
- Row-level derived fields
- Reusable integration logic

## DAX

Used for:

- Dynamic aggregation
- Ratios
- Percentages
- Filter-aware KPIs
- Dashboard calculations
- Interactive analytical measures

This creates a cleaner separation between:

```text
Data preparation
```

and:

```text
Business analysis
```

---

# Power BI Report Architecture

The report contains five analytical pages.

```text
1. Claims Executive Overview
          |
          v
2. Denials Analysis
          |
          v
3. Payer & Provider Analysis
          |
          v
4. Claims Operations
          |
          v
5. Data Quality & Governance
```

Navigation buttons provide movement between pages.

---

# Page 1 — Claims Executive Overview

## Purpose

Provide a high-level view of the claims portfolio.

## Primary Questions

- How many claim-line records exist?
- How much was billed?
- How much was allowed?
- How much was paid?
- What is the denial rate?
- How long does adjudication take?

## Core Visuals

- KPI cards
- Claim status
- Financial funnel
- Claims over time
- Payer breakdown

---

# Page 2 — Denials Analysis

## Purpose

Identify denial patterns.

## Primary Questions

- How many claim lines are denied?
- What is the denial rate?
- What are the leading denial reasons?
- Which payers experience more denials?
- Are certain provider specialties associated with higher denial rates?

---

# Page 3 — Payer & Provider Analysis

## Purpose

Compare financial and operational performance across business dimensions.

## Primary Questions

- How do billed and allowed amounts differ by payer?
- How much has been paid?
- Which specialties account for more paid dollars?
- Does network status affect allowed rates?
- How do denial rates differ?

---

# Page 4 — Claims Operations

## Purpose

Analyze the operational claims lifecycle.

```text
Service
   ↓
Receipt
   ↓
Adjudication
   ↓
Payment
```

## Core KPIs

- Average Service-to-Receipt Days
- Average Adjudication Days
- Average Payment Days
- Pending Claim Lines

## Primary Questions

- How quickly are claims submitted?
- How long does adjudication take?
- How long does payment take after adjudication?
- Which payers take longer?
- How does operational performance change over time?

---

# Page 5 — Data Quality & Governance

## Purpose

Make the validation framework visible to report consumers.

## Primary Questions

- How many DQ exceptions exist?
- How many claim lines are affected?
- Which rules fail most frequently?
- What is the severity distribution?
- Which records require further investigation?

This page connects the dashboard directly to the underlying data-quality process.

---

# Validation Architecture

Power BI outputs are reconciled against SQL throughout development.

The process is:

```text
Power BI Result
       |
       v
Does it look reasonable?
       |
       +---- No ----> Validate in SQL
       |                  |
       |                  v
       |            Compare Results
       |                  |
       |                  v
       |        Investigate Filter Context
       |                  |
       |                  v
       |             Correct Logic
       |
       +---- Yes ----> Still validate critical KPIs
```

This is especially important for:

- Distinct counts
- Row counts
- Payer filtering
- Provider filtering
- Denial counts
- Financial totals
- Percentages
- Network-status comparisons

---

# Filter Context

One important Power BI development lesson from the project was ensuring that dimensions and measures operate against compatible tables.

For example:

```text
Payer_Name
```

must correctly filter:

```text
Total Billed
Total Allowed
Total Paid
Denied Claim Lines
```

When a dimension fails to filter a measure, Power BI may repeat the grand total for every category.

SQL reconciliation was used to identify and correct these issues.

---

# Data Flow Summary

```text
SYNTHETIC DATA
      |
      v
SQL SOURCE TABLES
      |
      v
SOURCE VALIDATION
      |
      v
DQ01 - DQ10
      |
      v
EXCEPTION MANAGEMENT
      |
      v
REPORTING VIEW
      |
      v
POWER BI MODEL
      |
      v
DAX MEASURES
      |
      v
BUSINESS VISUALS
      |
      v
VALIDATION AGAINST SQL
      |
      v
TRUSTED ANALYTICAL OUTPUT
```

---

# Design Principles

## 1. Validate Before Visualizing

Power BI is not treated as the starting point.

---

## 2. Preserve Source Transparency

Data-quality failures are exposed rather than silently removed.

---

## 3. Establish Grain Early

The claim-line grain is explicitly defined before creating KPIs.

---

## 4. Separate Layers

Source, DQ, reporting, and presentation responsibilities are separated.

---

## 5. Reconcile Critical Metrics

Important Power BI calculations are compared against SQL.

---

## 6. Use Business-Meaningful Definitions

Metrics are named according to what they actually measure.

For example:

```text
Billed-to-Allowed Variance
```

is preferred over automatically calling the difference:

```text
Lost Revenue
```

because the latter would imply a business conclusion not established by the data.

---

# Production Considerations

This portfolio architecture is intentionally lightweight.

A production implementation could introduce:

```text
Raw / Landing Layer
        ↓
Staging Layer
        ↓
Standardized Layer
        ↓
Governed / Curated Layer
        ↓
Semantic Model
        ↓
Reporting
```

Additional capabilities could include:

- Incremental ingestion
- Data orchestration
- Historical snapshots
- Automated data-quality testing
- Rule metadata
- Data stewardship
- Exception ownership
- Resolution status
- Audit history
- Slowly changing dimensions
- Claim transaction/version logic
- Row-level security
- Deployment pipelines
- Automated reconciliation
- Microsoft Fabric lakehouse/warehouse architecture

---

# Project Scope

This architecture demonstrates concepts applicable to:

- Healthcare claims analytics
- Revenue-cycle analytics
- Business intelligence
- Data quality
- Reporting
- Data governance
- Data validation
- Operational analytics

It is not intended to replicate a complete production payer, provider, clearinghouse, or claims-adjudication platform.

---

# Privacy and Security

All source data is synthetic.

The repository contains:

- No PHI
- No PII
- No real patient records
- No real claims
- No real healthcare transactions

This makes the project suitable for public portfolio demonstration.

---

# Final Architecture Principle

The project can be summarized as:

> **Source → Validate → Govern → Report → Reconcile → Analyze**

The Power BI dashboard is the visible end product, but the SQL validation, data-quality framework, exception management, reporting architecture, and reconciliation process are what establish confidence in the metrics displayed.