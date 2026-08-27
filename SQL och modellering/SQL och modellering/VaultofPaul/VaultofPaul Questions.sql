USE VaultofPaul
go




--EXEC RegisterCustomerAndAccount 
--    @FirstName = 'Bajs', 
--    @LastName = 'Korv', 
--    @Email = 'Bajs@Korv.se', 
--    @BirthDate = '1337-07-24'; 


-- Inaktiverar/aktiverar customerID(Paul)
EXEC DeactivateCustomer 
    @CustomerID = 1;
EXEC ActivateCustomer 
    @CustomerID = 1;

-- Frågor-- Frågor-- Frågor

--Vilka kunder har det högsta totala saldot på sina konton?

SELECT 
    c.CustomerID,
    c.FirstName + ' ' + c.LastName AS CustomerName,
    SUM(a.Balance) AS TotalBalance
FROM Customer c
JOIN Disposition d ON c.CustomerID = d.CustomerID
JOIN Account a ON d.AccountID = a.AccountID
GROUP BY c.CustomerID, c.FirstName, c.LastName
ORDER BY TotalBalance DESC;

--Vilka konton har flest transaktioner, och vad är det genomsnittliga transaktionsbeloppet?
SELECT 
    a.AccountID,
    a.AccountType,
    COUNT(t.TransactionID) AS TransactionCount,
    AVG(t.Amount) AS AvgTransactionAmount
FROM Account a
JOIN Transactions t ON a.AccountID = t.AccountID
GROUP BY a.AccountID, a.AccountType
ORDER BY TransactionCount DESC;

--Hur ser låneschemat ut för ett specifikt lånkonto?
SELECT 
	ls.*,
    l.LoanID    
FROM Loan l
JOIN LoanSchedule ls ON l.LoanID = ls.LoanID
WHERE l.LoanID = 2

--Total ränta betalad per lån
SELECT 
    l.LoanID,
    l.LoanType,
    c.FirstName + ' ' + c.LastName AS CustomerName,
    SUM(lp.LoanPaymentAmount) AS TotalInterestPaid
FROM Loan l
JOIN Customer c ON l.CustomerID = c.CustomerID
JOIN LoanPayment lp ON l.LoanID = lp.LoanID
WHERE lp.LoanPaymentType = 'Interest'
GROUP BY l.LoanID, l.LoanType, c.FirstName, c.LastName
ORDER BY TotalInterestPaid DESC;

--Sparande med högsta ränta
SELECT 
    a.AccountNumber,
    sa.InterestRate,
    a.Balance,
    c.FirstName + ' ' + c.LastName AS CustomerName
FROM SavingsAccount sa
JOIN Account a ON sa.AccountID = a.AccountID
JOIN Disposition d ON a.AccountID = d.AccountID
JOIN Customer c ON d.CustomerID = c.CustomerID
WHERE a.IsActive = 1
ORDER BY sa.InterestRate DESC, a.Balance DESC;

--Senaste veckans auditlog (frågan kom efter)
SELECT 
    TableName,
    Action,
    RecordID,
    ActionDate,
    Description
FROM AuditLog
WHERE ActionDate >= DATEADD(WEEK, -1, GETDATE())
ORDER BY ActionDate DESC;