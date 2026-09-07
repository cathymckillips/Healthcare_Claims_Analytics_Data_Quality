USE HealthcareClaimsAnalytics;
GO
SELECT COUNT(*) AS Claims FROM dbo.Claims;
SELECT COUNT(*) AS Members FROM dbo.Members;
SELECT COUNT(*) AS Providers FROM dbo.Providers;
SELECT COUNT(*) AS Payers FROM dbo.Payers;
-- Expected: 306 / 80 / 12 / 3
SELECT Claim_ID, COUNT(*) AS ClaimLineCount
FROM dbo.Claims GROUP BY Claim_ID HAVING COUNT(*) > 1
ORDER BY ClaimLineCount DESC;
