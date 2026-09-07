USE HealthcareClaimsAnalytics;
GO
-- DQ07: Cross-field business logic
SELECT * FROM dbo.Claims WHERE Claim_Status='Denied' AND Paid_Amount>0;
