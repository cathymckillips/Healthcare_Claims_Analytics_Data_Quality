USE HealthcareClaimsAnalytics;
GO
-- DQ10: Completeness
SELECT * FROM dbo.Claims
WHERE Diagnosis_Code IS NULL OR LTRIM(RTRIM(Diagnosis_Code))='';
