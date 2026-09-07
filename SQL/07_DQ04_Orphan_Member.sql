USE HealthcareClaimsAnalytics;
GO
-- DQ04: Member referential integrity
SELECT c.* FROM dbo.Claims c
LEFT JOIN dbo.Members m ON c.Member_ID=m.Member_ID
WHERE m.Member_ID IS NULL;
