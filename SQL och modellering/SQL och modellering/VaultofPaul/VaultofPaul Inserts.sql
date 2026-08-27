USE VaultofPaul

--BuisniessCase, är att bara använda store procedures. 
--Transaction sköter existerande konton Deposit/Withdrawal och handling/utag, kanske borde ha ett annat
-- namn för det. Men Men

-- KUNDER
EXEC RegisterCustomerAndAccount 
    @FirstName = 'Paul', 
    @LastName = 'Sandegård', 
    @Email = 'PaulSan@pmail.se', 
    @BirthDate = '1990-09-28', 
    @InitialBalance = 20000.00;

EXEC RegisterCustomerAndAccount 
    @FirstName = 'Data', 
    @LastName = 'Nisse', 
    @Email = 'DataNissen@data.com', 
    @BirthDate = '1985-06-15', 
    @InitialBalance = 5000.00, 
    @LoanAmount = 15000.00, 
    @LoanType = 'CarLoan';

EXEC RegisterCustomerAndAccount 
    @FirstName = 'Gamla', 
    @LastName = 'Bettan', 
    @Email = 'Gamlabettan@jordgubbsland.nu', 
    @BirthDate = '1950-12-01', 
    @InitialBalance = 10.00;

EXEC RegisterCustomerAndAccount 
    @FirstName = 'Anna', 
    @LastName = 'Andersson', 
    @Email = 'anna@domain.com', 
    @BirthDate = '1995-03-22', 
    @InitialBalance = 1000.00, 
    @SavingsInterestRate = 1.50, 
    @SavingsDescription = 'Pensionsspar', 
    @CreditLimit = 5000.00, 
    @CreditInterestRate = 4.00, 
    @LoanAmount = 10000.00, 
    @LoanInterestRate = 3.00, 
    @PaymentFrequency = 'Monthly', 
    @LoanType = 'CarLoan';

EXEC RegisterCustomerAndAccount 
    @FirstName = 'Kung', 
    @LastName = 'Klantig', 
    @Email = 'Klanter@Kung.com', 
    @BirthDate = '1992-05-10', 
    @InitialBalance = 20000.00;

EXEC RegisterCustomerAndAccount 
    @FirstName = 'Bob', 
    @LastName = 'Berg', 
    @Email = 'bob@domain.com', 
    @BirthDate = '1985-06-15', 
    @InitialBalance = 5000.00, 
    @LoanAmount = 15000.00, 
    @LoanType = 'CarLoan';

EXEC RegisterCustomerAndAccount 
    @FirstName = 'Clara', 
    @LastName = 'Carlsson', 
    @Email = 'clara@domain.com', 
    @BirthDate = '1998-12-01', 
    @InitialBalance = 10000.00;

EXEC RegisterCustomerAndAccount 
    @FirstName = 'David', 
    @LastName = 'Dahl', 
    @Email = 'david@domain.com', 
    @BirthDate = '1990-03-22', 
    @InitialBalance = 10000.00;

EXEC RegisterCustomerAndAccount 
    @FirstName = 'Emma', 
    @LastName = 'Eriksson', 
    @Email = 'emma@domain.com', 
    @BirthDate = '1995-07-30', 
    @InitialBalance = 3000.00, 
    @LoanAmount = 5000.00, 
    @LoanType = 'Personal';

EXEC RegisterCustomerAndAccount 
    @FirstName = 'David', 
    @LastName = 'Hasselhoff', 
    @Email = 'DavidHassehoff@email.com', 
    @BirthDate = '1952-05-17', 
    @InitialBalance = 200000.00;

-- Savings "Lägger till ett konto"

-- . Lägg till ett extra sparkonto för Gamla Bettan
EXEC AddSavingsAccount 
    @CustomerID = 3, 
    @InitialBalance = 1000.00, 
    @InterestRate = 2.00, 
    @Description = 'Vacation Fund';

-- . Lägg till ett extra sparkonto för Alice
EXEC AddSavingsAccount 
    @CustomerID = 4, 
    @InitialBalance = 5000.00, 
    @InterestRate = 1.50, 
    @Description = 'Emergency Fund';

EXEC AddSavingsAccount 
    @CustomerID = 3, 
    @InitialBalance = 1000.00, 
    @InterestRate = 2.00, 
    @Description = 'Vacation Fund';

-- Lån

EXEC AddLoanToCustomer 
    @CustomerID = 5,
    @LoanAmount = 10000.00,
    @InterestRate = 4.25,
    @PaymentFrequency = 'Monthly',
    @LoanType = 'Personal';

-- Exempel 2: Bolån med standardränta (3.50%)
EXEC AddLoanToCustomer 
    @CustomerID = 2,
    @LoanAmount = 250000.00,
    @PaymentFrequency = 'Monthly',
    @LoanType = 'Mortgage';

-- Exempel 3: Billån med kvartalsbetalningar
EXEC AddLoanToCustomer 
    @CustomerID = 3,
    @LoanAmount = 35000.00,
    @InterestRate = 5.75,
    @PaymentFrequency = 'Quarterly',
    @LoanType = 'CarLoan';

EXEC AddLoanToCustomer 
    @CustomerID = 4,
    @LoanAmount = 20000.00,
    @InterestRate = 2.80,
    @PaymentFrequency = 'Yearly',
    @LoanType = 'StudentLoan';

-- Betala lån

EXEC RegisterLoanPayment 
    @LoanID = 1,
    @LoanPaymentAmount = 500.00,
    @LoanPaymentType = 'Interest',
    @LoanPaymentDescription = 'Monthly interest payment';

EXEC RegisterLoanPayment 
    @LoanID = 2,
    @LoanPaymentAmount = 1500.00,
    @LoanPaymentType = 'Principal';

EXEC PayLoanFromAccount 
    @AccountID = 5,
    @LoanID = 1,
    @Amount = 1000.00,
    @PaymentType = 'Principal';

-- betala lån med andra konton

-- Exempel 3: Betalning av förseningsavgift
EXEC PayLoanFromAccount 
    @AccountID = 5,
    @LoanID = 1,
    @Amount = 25.00,
    @PaymentType = 'LateFee',
    @TransactionDate = '2025-03-15';

-- Exempel 4: Mindre betalning av kapital
EXEC PayLoanFromAccount 
    @AccountID = 12,
    @LoanID = 2,
    @Amount = 500.00,
    @PaymentType = 'Principal';

-- Transactioner
-- . Gör transaktioner för Paul
-- Insättning på sparkontot (AccountID 1)

EXEC RegisterTransaction 
    @CustomerID = 1, 
    @AccountID = 1, 
    @Amount = 3000.00, 
    @TransactionType = 'Deposit', 
    @Description = 'Savings deposit';

-- Uttag från checkingkontot (AccountID 2)
EXEC RegisterTransaction 
    @CustomerID = 1, 
    @AccountID = 2, 
    @Amount = 500.00, 
    @TransactionType = 'Withdrawal', 
    @Description = 'Grocery shopping';

--  Gör transaktioner för Data Nisse
EXEC RegisterTransaction 
    @CustomerID = 2, 
    @AccountID = 4, 
    @Amount = 2000.00, 
    @TransactionType = 'Deposit', 
    @Description = 'Savings deposit';

--  Gör transaktioner för Gamla Bettan
EXEC RegisterTransaction 
    @CustomerID = 3, 
    @AccountID = 8, 
    @Amount = 200.00, 
    @TransactionType = 'Deposit', 
    @Description = 'Vacation savings';

SELECT * FROM CustomerAccountOverview 
EXEC RegisterTransaction 
    @CustomerID = 5, 
    @AccountID = 16, 
    @Amount = 1000.00, 
    @TransactionType = 'Withdrawal', 
    @Description = 'Car repair';

-- Insättning på extra sparkontot (AccountID 16)
EXEC RegisterTransaction 
    @CustomerID = 4, 
    @AccountID = 11, 
    @Amount = 1000.00, 
    @TransactionType = 'Deposit', 
    @Description = 'Emergency fund deposit';

--  Gör transaktioner för BOB
-- Insättning på checkingkontot (AccountID 17)
EXEC RegisterTransaction 
    @CustomerID = 5, 
    @AccountID = 17, 
    @Amount = 1000.00, 
    @TransactionType = 'Deposit', 
    @Description = 'Salary deposit';

EXEC AddSavingsAccount 
    @CustomerID = 3, 
    @InitialBalance = 1000.00, 
    @InterestRate = 2.00, 
    @Description = 'Vacation Fund';

--  Gör några transaktioner för Paul
-- Insättning på sparkontot (AccountID 1)
EXEC RegisterTransaction 
    @CustomerID = 1, 
    @AccountID = 1, 
    @Amount = 3000.00, 
    @TransactionType = 'Deposit', 
    @Description = 'Savings deposit';

-- Uttag från checkingkontot (AccountID 2)
EXEC RegisterTransaction 
    @CustomerID = 1, 
    @AccountID = 2, 
    @Amount = 500.00, 
    @TransactionType = 'Withdrawal', 
    @Description = 'Grocery shopping';

--  Gör en insättning för DataNisse på hans sparkonto (AccountID 4)
EXEC RegisterTransaction 
    @CustomerID = 2, 
    @AccountID = 4, 
    @Amount = 2000.00, 
    @TransactionType = 'Deposit', 
    @Description = 'Savings deposit';

EXEC AddLoanToCustomer 
    @CustomerID = 2, 
    @LoanAmount = 20000.00, 
    @InterestRate = 2.50, 
    @PaymentFrequency = 'Yearly', 
    @LoanType = 'Mortgage';


-- Kolla resultatet
SELECT * FROM CustomerAccountOverview 
--where customerID = 1
SELECT * FROM AuditLog 

Select * from TransactionsLog

EXEC DeactivateCustomer 
    @CustomerID = 1;
EXEC ActivateCustomer 
    @CustomerID = 1;