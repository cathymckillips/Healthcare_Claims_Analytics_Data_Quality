USE HealthcareClaimsAnalytics;
GO
-- DQ05: Provider referential integrity
SELECT c.* FROM dbo.Claims c
LEFT JOIN dbo.Providers p ON c.Provider_ID=p.Provider_ID
WHERE p.Provider_ID IS NULL;
