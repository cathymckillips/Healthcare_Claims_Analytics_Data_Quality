USE HealthcareClaimsAnalytics;
GO
-- DQ01: Uniqueness
SELECT Claim_Line_ID, COUNT(*) AS DuplicateCount
FROM dbo.Claims GROUP BY Claim_Line_ID HAVING COUNT(*) > 1;
