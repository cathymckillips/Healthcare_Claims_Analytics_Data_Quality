IF DB_ID('HealthcareClaimsAnalytics') IS NULL
    CREATE DATABASE HealthcareClaimsAnalytics;
GO
USE HealthcareClaimsAnalytics;
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name='dq') EXEC('CREATE SCHEMA dq');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name='reporting') EXEC('CREATE SCHEMA reporting');
GO
