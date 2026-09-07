USE HealthcareClaimsAnalytics;
GO
CREATE OR ALTER VIEW dq.vw_Claims_Exceptions AS
SELECT Claim_Line_ID,Claim_ID,Member_ID,Provider_ID,Payer_ID,'DQ01' Rule_ID,'Duplicate Claim Line' Failed_Rule,'High' Severity
FROM dbo.Claims WHERE Claim_Line_ID IN (SELECT Claim_Line_ID FROM dbo.Claims GROUP BY Claim_Line_ID HAVING COUNT(*)>1)
UNION ALL
SELECT Claim_Line_ID,Claim_ID,Member_ID,Provider_ID,Payer_ID,'DQ02','Paid Amount Exceeds Allowed Amount','High'
FROM dbo.Claims WHERE Paid_Amount>Allowed_Amount
UNION ALL
SELECT Claim_Line_ID,Claim_ID,Member_ID,Provider_ID,Payer_ID,'DQ03','Missing Allowed Amount','Medium'
FROM dbo.Claims WHERE Allowed_Amount IS NULL AND Claim_Status IN ('Paid','Denied')
UNION ALL
SELECT c.Claim_Line_ID,c.Claim_ID,c.Member_ID,c.Provider_ID,c.Payer_ID,'DQ04','Orphan Member ID','High'
FROM dbo.Claims c LEFT JOIN dbo.Members m ON c.Member_ID=m.Member_ID WHERE m.Member_ID IS NULL
UNION ALL
SELECT c.Claim_Line_ID,c.Claim_ID,c.Member_ID,c.Provider_ID,c.Payer_ID,'DQ05','Orphan Provider ID','High'
FROM dbo.Claims c LEFT JOIN dbo.Providers p ON c.Provider_ID=p.Provider_ID WHERE p.Provider_ID IS NULL
UNION ALL
SELECT c.Claim_Line_ID,c.Claim_ID,c.Member_ID,c.Provider_ID,c.Payer_ID,'DQ06','Orphan Payer ID','High'
FROM dbo.Claims c LEFT JOIN dbo.Payers p ON c.Payer_ID=p.Payer_ID WHERE p.Payer_ID IS NULL
UNION ALL
SELECT Claim_Line_ID,Claim_ID,Member_ID,Provider_ID,Payer_ID,'DQ07','Denied Claim With Payment','High'
FROM dbo.Claims WHERE Claim_Status='Denied' AND Paid_Amount>0
UNION ALL
SELECT Claim_Line_ID,Claim_ID,Member_ID,Provider_ID,Payer_ID,'DQ08','Received Date Before Service Date','High'
FROM dbo.Claims WHERE Received_Date<Service_Date
UNION ALL
SELECT Claim_Line_ID,Claim_ID,Member_ID,Provider_ID,Payer_ID,'DQ09','Negative Billed Amount','High'
FROM dbo.Claims WHERE Billed_Amount<0
UNION ALL
SELECT Claim_Line_ID,Claim_ID,Member_ID,Provider_ID,Payer_ID,'DQ10','Missing Diagnosis Code','Medium'
FROM dbo.Claims WHERE Diagnosis_Code IS NULL OR LTRIM(RTRIM(Diagnosis_Code))='';
GO

CREATE OR ALTER VIEW dq.vw_DataQuality_Summary AS
SELECT Rule_ID,Failed_Rule,Severity,COUNT(*) Exception_Count
FROM dq.vw_Claims_Exceptions
GROUP BY Rule_ID,Failed_Rule,Severity;
GO

CREATE OR ALTER VIEW dq.vw_Claims_Quality_Status AS
SELECT c.Claim_Line_ID,c.Claim_ID,c.Member_ID,c.Provider_ID,c.Payer_ID,
 c.Claim_Status,c.Billed_Amount,c.Allowed_Amount,c.Paid_Amount,
 CASE WHEN e.Claim_Line_ID IS NULL THEN 'Pass' ELSE 'Exception' END Data_Quality_Status
FROM dbo.Claims c
LEFT JOIN (SELECT DISTINCT Claim_Line_ID FROM dq.vw_Claims_Exceptions) e
 ON c.Claim_Line_ID=e.Claim_Line_ID;
GO
