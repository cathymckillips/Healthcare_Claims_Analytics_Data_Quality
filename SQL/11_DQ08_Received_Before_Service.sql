USE HealthcareClaimsAnalytics;
GO
-- DQ08: Chronological consistency
SELECT * FROM dbo.Claims WHERE Received_Date < Service_Date;
