USE HealthcareClaimsAnalytics;
GO
-- Skip this file if your four dbo source tables already exist.
CREATE TABLE dbo.Claims (
 Claim_ID VARCHAR(20), Claim_Line_ID VARCHAR(30), Member_ID VARCHAR(20),
 Provider_ID VARCHAR(20), Payer_ID VARCHAR(20), Service_Date DATE,
 Received_Date DATE, Adjudication_Date DATE, Payment_Date DATE,
 Claim_Status VARCHAR(20), Place_of_Service VARCHAR(50),
 Diagnosis_Code VARCHAR(20), Procedure_Code VARCHAR(20),
 Billed_Amount DECIMAL(12,2), Allowed_Amount DECIMAL(12,2),
 Paid_Amount DECIMAL(12,2), Patient_Responsibility DECIMAL(12,2),
 Denial_Reason VARCHAR(100), Data_Quality_Status VARCHAR(20), Issue_Type VARCHAR(100)
);
CREATE TABLE dbo.Members (
 Member_ID VARCHAR(20), Age_Band VARCHAR(20), Gender VARCHAR(10), State VARCHAR(10),
 Plan_Type VARCHAR(50), Effective_Date DATE, Termination_Date DATE
);
CREATE TABLE dbo.Providers (
 Provider_ID VARCHAR(20), Provider_Name VARCHAR(100), Specialty VARCHAR(50),
 State VARCHAR(10), Network_Status VARCHAR(30)
);
CREATE TABLE dbo.Payers (
 Payer_ID VARCHAR(20), Payer_Name VARCHAR(100), Payer_Type VARCHAR(50)
);
GO
