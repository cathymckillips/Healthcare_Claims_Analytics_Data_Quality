USE HealthcareClaimsAnalytics;
GO
SELECT * FROM dq.vw_DataQuality_Summary ORDER BY Rule_ID;
SELECT COUNT(*) Total_Exceptions FROM dq.vw_Claims_Exceptions;
SELECT COUNT(DISTINCT Claim_Line_ID) Claim_Lines_With_Exceptions FROM dq.vw_Claims_Exceptions;
SELECT Data_Quality_Status,COUNT(*) Claim_Line_Count
FROM dq.vw_Claims_Quality_Status GROUP BY Data_Quality_Status;
SELECT COUNT(*) Reporting_Row_Count FROM reporting.vw_ClaimsAnalytics;
SELECT TOP 20 * FROM reporting.vw_ClaimsAnalytics;
