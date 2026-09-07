USE HealthcareClaimsAnalytics;
GO
CREATE OR ALTER VIEW reporting.vw_ClaimsAnalytics AS
SELECT c.Claim_ID,c.Claim_Line_ID,c.Member_ID,m.Age_Band,m.Gender,m.State Member_State,m.Plan_Type,
 c.Provider_ID,p.Provider_Name,p.Specialty,p.State Provider_State,p.Network_Status,
 c.Payer_ID,py.Payer_Name,py.Payer_Type,c.Service_Date,c.Received_Date,c.Adjudication_Date,c.Payment_Date,
 c.Claim_Status,c.Place_of_Service,c.Diagnosis_Code,c.Procedure_Code,
 c.Billed_Amount,c.Allowed_Amount,c.Paid_Amount,c.Patient_Responsibility,c.Denial_Reason,
 qs.Data_Quality_Status,
 DATEDIFF(DAY,c.Received_Date,c.Adjudication_Date) Adjudication_Days,
 c.Billed_Amount-c.Allowed_Amount Billed_to_Allowed_Variance,
 c.Allowed_Amount-c.Paid_Amount Allowed_to_Paid_Variance
FROM dbo.Claims c
LEFT JOIN dbo.Members m ON c.Member_ID=m.Member_ID
LEFT JOIN dbo.Providers p ON c.Provider_ID=p.Provider_ID
LEFT JOIN dbo.Payers py ON c.Payer_ID=py.Payer_ID
LEFT JOIN dq.vw_Claims_Quality_Status qs ON c.Claim_Line_ID=qs.Claim_Line_ID;
GO
