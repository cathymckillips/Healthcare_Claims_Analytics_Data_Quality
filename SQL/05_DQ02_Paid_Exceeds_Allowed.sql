USE HealthcareClaimsAnalytics;
GO
-- DQ02: Financial consistency
SELECT * FROM dbo.Claims WHERE Paid_Amount > Allowed_Amount;
SELECT COUNT(*) AS DQ02_Exception_Count FROM dbo.Claims WHERE Paid_Amount > Allowed_Amount;
