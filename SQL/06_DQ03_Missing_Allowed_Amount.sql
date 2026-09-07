USE HealthcareClaimsAnalytics;
GO
-- DQ03: Completeness for adjudicated claims
SELECT * FROM dbo.Claims
WHERE Allowed_Amount IS NULL AND Claim_Status IN ('Paid','Denied');
