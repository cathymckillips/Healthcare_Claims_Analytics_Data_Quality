USE HealthcareClaimsAnalytics;
GO
-- DQ06: Payer referential integrity
SELECT c.* FROM dbo.Claims c
LEFT JOIN dbo.Payers p ON c.Payer_ID=p.Payer_ID
WHERE p.Payer_ID IS NULL;
