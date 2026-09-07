USE HealthcareClaimsAnalytics;
GO
-- DQ09: Financial validity
SELECT * FROM dbo.Claims WHERE Billed_Amount < 0;
