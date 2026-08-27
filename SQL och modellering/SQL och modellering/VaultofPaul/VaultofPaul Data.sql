USE Master;
GO

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'VaultofPaul') 
BEGIN
    ALTER DATABASE VaultofPaul SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE VaultofPaul;
END
GO

CREATE DATABASE VaultofPaul;
GO

USE VaultofPaul;
GO

-- Tabeller
CREATE TABLE Customer (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL CHECK (FirstName NOT LIKE '%Bajs%' AND FirstName NOT LIKE '%[0-9]%'),
    LastName NVARCHAR(50) NOT NULL CHECK (LastName NOT LIKE '%Korv%' AND LastName NOT LIKE '%[0-9]%'),
    Email NVARCHAR(100) NOT NULL UNIQUE CHECK (Email LIKE '%@%.%'),
    BirthDate DATE NOT NULL CHECK (DATEDIFF(YEAR, BirthDate, GETDATE()) >= 18),
    IsActive BIT NOT NULL DEFAULT 1
);

CREATE TABLE Account (
    AccountID INT IDENTITY(1,1) PRIMARY KEY,
    AccountNumber NVARCHAR(20) NOT NULL UNIQUE,
    Balance DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    AccountType NVARCHAR(20) NOT NULL CHECK (AccountType IN ('Savings', 'Checking', 'Credit', 'Loan')),
    IsActive BIT NOT NULL DEFAULT 1
);

CREATE TABLE Credit (
    CreditID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    AccountID INT NOT NULL,
    CreditLimit DECIMAL(10, 2) NOT NULL CHECK (CreditLimit > 0),
    InterestRate DECIMAL(5, 2) NOT NULL CHECK (InterestRate >= 0),
    StartDate DATE NOT NULL DEFAULT GETDATE(),
    CreditStatus NVARCHAR(20) NOT NULL CHECK (CreditStatus IN ('Active', 'Closed', 'Overdue')),
    UsedCredit DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),
    FOREIGN KEY (AccountID) REFERENCES Account(AccountID),
    CONSTRAINT CHK_CreditLimit CHECK (UsedCredit <= CreditLimit)
);

CREATE TABLE Card (
    CardID INT IDENTITY(1,1) PRIMARY KEY,
    CardNumber NVARCHAR(19) NOT NULL UNIQUE, 
    IssuedDate DATE NOT NULL DEFAULT GETDATE(),
    ExpireDate DATE NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CreditID INT NULL,
    FOREIGN KEY (CreditID) REFERENCES Credit(CreditID),
    CONSTRAINT CHK_ExpireDateAfterIssued CHECK (ExpireDate > IssuedDate)
);

CREATE TABLE Disposition (
    DispositionID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    AccountID INT NOT NULL,
    CardID INT NULL,
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),
    FOREIGN KEY (AccountID) REFERENCES Account(AccountID),
    FOREIGN KEY (CardID) REFERENCES Card(CardID),
    UNIQUE (AccountID, CardID)
);

CREATE TABLE Transactions (
    TransactionID INT IDENTITY(1,1) PRIMARY KEY,
    AccountID INT NOT NULL,
    CardID INT NULL,
    TransactionType NVARCHAR(20) NOT NULL 
    CHECK (TransactionType IN ('Deposit', 'Withdrawal', 'Payment', 'Purchase', 'Salary')),
    Amount DECIMAL(10, 2) NOT NULL CHECK (Amount > 0),
    TransactionDate DATETIME NOT NULL DEFAULT GETDATE(),
    Description NVARCHAR(100) NULL,
    FOREIGN KEY (AccountID) REFERENCES Account(AccountID),
    FOREIGN KEY (CardID) REFERENCES Card(CardID)
);

CREATE TABLE Loan (
    LoanID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    AccountID INT NOT NULL,
    LoanAmount DECIMAL(10, 2) NOT NULL CHECK (LoanAmount >= 0),
    InterestRate DECIMAL(5, 2) NOT NULL CHECK (InterestRate >= 0),
    StartDate DATE NOT NULL DEFAULT GETDATE(),
    LoanStatus NVARCHAR(20) NOT NULL CHECK (LoanStatus IN ('Active', 'Paid', 'Late', 'Cancelled')),
    PaymentFrequency NVARCHAR(20) NOT NULL CHECK (PaymentFrequency IN ('Monthly', 'Quarterly', 'Yearly')),
    RemainingBalance DECIMAL(10, 2) NOT NULL,
    LoanType NVARCHAR(20) NOT NULL DEFAULT 'Personal' 
    CHECK (LoanType IN ('Personal', 'Mortgage', 'CarLoan', 'StudentLoan')),
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),
    FOREIGN KEY (AccountID) REFERENCES Account(AccountID)
);

CREATE TABLE LoanPayment (
    LoanPaymentID INT IDENTITY(1,1) PRIMARY KEY,
    LoanID INT NOT NULL,
    LoanPaymentAmount DECIMAL(10, 2) NOT NULL CHECK (LoanPaymentAmount > 0),
    LoanPaymentDate DATETIME NOT NULL DEFAULT GETDATE(),
    LoanPaymentType NVARCHAR(20) NOT NULL CHECK (LoanPaymentType IN ('Principal', 'Interest', 'LateFee')),
    LoanPaymentDescription NVARCHAR(100) NULL,
    CONSTRAINT FK_LoanPayment_Loan FOREIGN KEY (LoanID) REFERENCES Loan(LoanID)
);

CREATE TABLE LoanSchedule (
    LoanScheduleID INT IDENTITY(1,1) PRIMARY KEY,
    LoanID INT NOT NULL,
    LoanPaymentNumber INT NOT NULL,
    LoanPaymentDate DATE NOT NULL, 
    LoanPaymentAmount DECIMAL(10, 2) NOT NULL, 
    PrincipalAmount DECIMAL(10, 2) NOT NULL, 
    InterestAmount DECIMAL(10, 2) NOT NULL, 
    RemainingBalance DECIMAL(10, 2) NOT NULL, 
    CONSTRAINT FK_LoanSchedule_Loan FOREIGN KEY (LoanID) REFERENCES Loan(LoanID)
);

CREATE TABLE SavingsAccount (
    SavingsID INT IDENTITY(1,1) PRIMARY KEY,
    AccountID INT NOT NULL,
    InterestRate DECIMAL(5, 2) NOT NULL CHECK (InterestRate >= 0),
    LastInterestDate DATE NOT NULL DEFAULT GETDATE(),
    Description NVARCHAR(50) NOT NULL DEFAULT 'Regular', 
    FOREIGN KEY (AccountID) REFERENCES Account(AccountID)
);

CREATE TABLE AuditLog (
    AuditLogID INT IDENTITY(1,1) PRIMARY KEY,
    TableName NVARCHAR(50),
    Action NVARCHAR(20) CHECK (Action IN ('Insert', 'Update', 'Delete')),
    RecordID INT,
    ActionDate DATETIME DEFAULT GETDATE(),
    Description NVARCHAR(255)
);

CREATE TABLE TransactionsLog (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    TransactionID INT NOT NULL,
    AccountID INT NOT NULL,
    TransactionType NVARCHAR(20) NOT NULL,
    Amount DECIMAL(10, 2) NOT NULL,
    TransactionDate DATETIME NOT NULL,
    Description NVARCHAR(100),
    LogDate DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (TransactionID) REFERENCES Transactions(TransactionID),
    FOREIGN KEY (AccountID) REFERENCES Account(AccountID)
);
GO

-- Stored Procedures
CREATE OR ALTER PROCEDURE RegisterCustomerAndAccount
    @FirstName NVARCHAR(50),
    @LastName NVARCHAR(50),
    @Email NVARCHAR(100),
    @BirthDate DATE,
    @InitialBalance DECIMAL(10, 2) = 0.00,
    @SavingsInterestRate DECIMAL(5, 2) = 1.00,
    @SavingsDescription NVARCHAR(50) = 'Regular',
    @CreditLimit DECIMAL(10, 2) = 1000.00,
    @CreditInterestRate DECIMAL(5, 2) = 5.00,
    @LoanAmount DECIMAL(10, 2) = NULL,
    @LoanInterestRate DECIMAL(5, 2) = 3.50,
    @PaymentFrequency NVARCHAR(20) = 'Monthly',
    @LoanType NVARCHAR(20) = 'Personal'
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO Customer (FirstName, LastName, Email, BirthDate, IsActive)
        VALUES (@FirstName, @LastName, @Email, @BirthDate, 1);
        DECLARE @CustomerID INT = SCOPE_IDENTITY();
        DECLARE @AccountNumber NVARCHAR(20), @AccountID INT, @CardID INT, @CardCount INT = 1, @CardNumber NVARCHAR(19);

        SET @AccountNumber = 'ACC' + RIGHT('00000000' + CAST(@CustomerID AS NVARCHAR(8)), 8) + 'S1';
        INSERT INTO Account (AccountNumber, Balance, AccountType, IsActive)
        VALUES (@AccountNumber, 0.00, 'Savings', 1);
        SET @AccountID = SCOPE_IDENTITY();
        INSERT INTO SavingsAccount (AccountID, InterestRate, Description)
        VALUES (@AccountID, @SavingsInterestRate, @SavingsDescription);
        INSERT INTO Disposition (CustomerID, AccountID, CardID)
        VALUES (@CustomerID, @AccountID, NULL);
        INSERT INTO AuditLog (TableName, Action, RecordID, Description)
        VALUES ('Account', 'Insert', @AccountID, 'New Savings account (' + @SavingsDescription + ') created for customer ID ' + CAST(@CustomerID AS NVARCHAR(10)));

        SET @AccountNumber = 'ACC' + RIGHT('00000000' + CAST(@CustomerID AS NVARCHAR(8)), 8) + 'C1';
        INSERT INTO Account (AccountNumber, Balance, AccountType, IsActive)
        VALUES (@AccountNumber, @InitialBalance, 'Checking', 1);
        SET @AccountID = SCOPE_IDENTITY();
        SET @CardNumber = '4000-' + RIGHT('0000' + CAST(@CustomerID AS NVARCHAR(4)), 4) + '-000' + CAST(@CardCount AS NVARCHAR(1)) + '-0001';
        INSERT INTO Card (CardNumber, ExpireDate, CreditID)
        VALUES (@CardNumber, DATEADD(YEAR, 3, GETDATE()), NULL);
        SET @CardID = SCOPE_IDENTITY();
        SET @CardCount = @CardCount + 1;
        INSERT INTO Disposition (CustomerID, AccountID, CardID)
        VALUES (@CustomerID, @AccountID, @CardID);
        INSERT INTO AuditLog (TableName, Action, RecordID, Description)
        VALUES 
            ('Account', 'Insert', @AccountID, 'New Checking account created for customer ID ' + CAST(@CustomerID AS NVARCHAR(10))),
            ('Card', 'Insert', @CardID, 'New card created for Checking account ID ' + CAST(@AccountID AS NVARCHAR(10)));

        SET @AccountNumber = 'ACC' + RIGHT('00000000' + CAST(@CustomerID AS NVARCHAR(8)), 8) + 'R1';
        INSERT INTO Account (AccountNumber, Balance, AccountType, IsActive)
        VALUES (@AccountNumber, 0.00, 'Credit', 1);
        SET @AccountID = SCOPE_IDENTITY();
        INSERT INTO Credit (CustomerID, AccountID, CreditLimit, InterestRate, CreditStatus)
        VALUES (@CustomerID, @AccountID, @CreditLimit, @CreditInterestRate, 'Active');
        SET @CardNumber = '5000-' + RIGHT('0000' + CAST(@CustomerID AS NVARCHAR(4)), 4) + '-000' + CAST(@CardCount AS NVARCHAR(1)) + '-0002';
        INSERT INTO Card (CardNumber, ExpireDate, CreditID)
        VALUES (@CardNumber, DATEADD(YEAR, 3, GETDATE()), SCOPE_IDENTITY());
        SET @CardID = SCOPE_IDENTITY();
        SET @CardCount = @CardCount + 1;
        INSERT INTO Disposition (CustomerID, AccountID, CardID)
        VALUES (@CustomerID, @AccountID, @CardID);
        INSERT INTO AuditLog (TableName, Action, RecordID, Description)
        VALUES 
            ('Account', 'Insert', @AccountID, 'New Credit account created for customer ID ' + CAST(@CustomerID AS NVARCHAR(10))),
            ('Card', 'Insert', @CardID, 'New card created for Credit account ID ' + CAST(@AccountID AS NVARCHAR(10)));

        IF @LoanAmount IS NOT NULL AND @LoanAmount > 0
        BEGIN
            SET @AccountNumber = 'ACC' + RIGHT('00000000' + CAST(@CustomerID AS NVARCHAR(8)), 8) + 'L1';
            INSERT INTO Account (AccountNumber, Balance, AccountType, IsActive)
            VALUES (@AccountNumber, @LoanAmount, 'Loan', 1);
            SET @AccountID = SCOPE_IDENTITY();
            INSERT INTO Loan (CustomerID, AccountID, LoanAmount, InterestRate, LoanStatus, PaymentFrequency, RemainingBalance, LoanType)
            VALUES (@CustomerID, @AccountID, @LoanAmount, @LoanInterestRate, 'Active', @PaymentFrequency, @LoanAmount, @LoanType);
            INSERT INTO Disposition (CustomerID, AccountID, CardID)
            VALUES (@CustomerID, @AccountID, NULL);
            INSERT INTO AuditLog (TableName, Action, RecordID, Description)
            VALUES ('Account', 'Insert', @AccountID, 'New ' + @LoanType + ' loan account created for customer ID ' + CAST(@CustomerID AS NVARCHAR(10)));
        END;

        INSERT INTO AuditLog (TableName, Action, RecordID, Description)
        VALUES ('Customer', 'Insert', @CustomerID, 'New customer registered: ' + @FirstName + ' ' + @LastName);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE DeactivateCustomer
    @CustomerID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM Customer WHERE CustomerID = @CustomerID)
            THROW 50006, 'Customer does not exist.', 1;

        IF EXISTS (SELECT 1 FROM Customer WHERE CustomerID = @CustomerID AND IsActive = 0)
            THROW 50025, 'Customer is already inactive.', 1;

        UPDATE Customer
        SET IsActive = 0
        WHERE CustomerID = @CustomerID;

        UPDATE Account
        SET IsActive = 0
        WHERE AccountID IN (
            SELECT AccountID FROM Disposition WHERE CustomerID = @CustomerID
            UNION
            SELECT AccountID FROM Loan WHERE CustomerID = @CustomerID
            UNION
            SELECT AccountID FROM SavingsAccount WHERE AccountID IN 
                (SELECT AccountID FROM Account WHERE AccountType = 'Savings')
        );

        INSERT INTO AuditLog (TableName, Action, RecordID, Description)
        VALUES ('Customer', 'Update', @CustomerID, 'Customer ID ' + CAST(@CustomerID AS NVARCHAR(10)) + ' set to inactive');

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE ActivateCustomer
    @CustomerID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM Customer WHERE CustomerID = @CustomerID)
            THROW 50006, 'Customer does not exist.', 1;

        IF EXISTS (SELECT 1 FROM Customer WHERE CustomerID = @CustomerID AND IsActive = 1)
            THROW 50026, 'Customer is already active.', 1;

        UPDATE Customer
        SET IsActive = 1
        WHERE CustomerID = @CustomerID;

        UPDATE Account
        SET IsActive = 1
        WHERE AccountID IN (
            SELECT AccountID FROM Disposition WHERE CustomerID = @CustomerID
            UNION
            SELECT AccountID FROM Loan WHERE CustomerID = @CustomerID
            UNION
            SELECT AccountID FROM SavingsAccount WHERE AccountID IN 
                (SELECT AccountID FROM Account WHERE AccountType = 'Savings')
        );

        INSERT INTO AuditLog (TableName, Action, RecordID, Description)
        VALUES ('Customer', 'Update', @CustomerID, 'Customer ID ' + CAST(@CustomerID AS NVARCHAR(10)) + ' set to active');

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE AddLoanToCustomer
    @CustomerID INT,
    @LoanAmount DECIMAL(10, 2),
    @InterestRate DECIMAL(5, 2) = 3.50,
    @PaymentFrequency NVARCHAR(20) = 'Monthly',
    @LoanType NVARCHAR(20) = 'Personal' 
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM Customer WHERE CustomerID = @CustomerID)
            THROW 50006, 'Customer does not exist.', 1;
        IF @LoanAmount <= 0
            THROW 50007, 'Loan amount must be greater than 0.', 1;
        IF @PaymentFrequency NOT IN ('Monthly', 'Quarterly', 'Yearly')
            THROW 50008, 'Invalid payment frequency. Must be Monthly, Quarterly, or Yearly.', 1;
        IF @LoanType NOT IN ('Personal', 'Mortgage', 'CarLoan', 'StudentLoan')
            THROW 50022, 'Invalid loan type. Must be Personal, Mortgage, CarLoan, or StudentLoan.', 1;

        DECLARE @AccountNumber NVARCHAR(20) = 'ACC' + RIGHT('00000000' + CAST(@CustomerID AS NVARCHAR(8)), 8) + 'L' + 
            CAST((SELECT COUNT(*) + 1 FROM Account WHERE AccountNumber LIKE 'ACC' + RIGHT('00000000' + 
            CAST(@CustomerID AS NVARCHAR(8)), 8) + 'L%') AS NVARCHAR(2));
        INSERT INTO Account (AccountNumber, Balance, AccountType)
        VALUES (@AccountNumber, @LoanAmount, 'Loan');
        DECLARE @AccountID INT = SCOPE_IDENTITY();

        INSERT INTO Loan (CustomerID, AccountID, LoanAmount, InterestRate, LoanStatus, 
                    PaymentFrequency, RemainingBalance, LoanType)
        VALUES (@CustomerID, @AccountID, @LoanAmount, @InterestRate, 'Active', 
                    @PaymentFrequency, @LoanAmount, @LoanType);
        DECLARE @LoanID INT = SCOPE_IDENTITY();

        DECLARE @InitialInterest DECIMAL(10, 2) = @LoanAmount * (@InterestRate / 100) * 
            CASE @PaymentFrequency WHEN 'Monthly' THEN 1.0 / 12.0 WHEN 'Quarterly' THEN 1.0 / 4.0 WHEN 'Yearly' THEN 1.0 END;
        INSERT INTO LoanPayment (LoanID, LoanPaymentAmount, LoanPaymentDate, LoanPaymentType, LoanPaymentDescription)
        VALUES (@LoanID, @InitialInterest, GETDATE(), 'Interest', 'Initial interest payment for ' + @LoanType + ' loan');
        INSERT INTO AuditLog (TableName, Action, RecordID, Description)
        VALUES ('LoanPayment', 'Insert', SCOPE_IDENTITY(), 
                'Initial interest payment of ' + CAST(@InitialInterest AS NVARCHAR(20)) + ' registered for ' + 
                    @LoanType + ' loan ID ' + CAST(@LoanID AS NVARCHAR(10)));

        INSERT INTO AuditLog (TableName, Action, RecordID, Description)
        VALUES ('Account', 'Insert', @AccountID, 'New ' + @LoanType + ' loan account created for customer ID ' + 
                CAST(@CustomerID AS NVARCHAR(10)));

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE RegisterLoanPayment
    @LoanID INT,
    @LoanPaymentAmount DECIMAL(10, 2),
    @LoanPaymentDate DATETIME = NULL,
    @LoanPaymentType NVARCHAR(20),
    @LoanPaymentDescription NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @LoanPaymentDate IS NULL SET @LoanPaymentDate = GETDATE();

        IF NOT EXISTS (SELECT 1 FROM Loan l 
                       JOIN Account a ON l.AccountID = a.AccountID 
                       WHERE l.LoanID = @LoanID AND a.IsActive = 1)
        BEGIN
            THROW 50001, 'Loan does not exist or is not active.', 1;
        END;

        IF @LoanPaymentAmount <= 0
        BEGIN
            THROW 50010, 'Loan payment amount must be greater than 0.', 1;
        END;

        IF @LoanPaymentType NOT IN ('Principal', 'Interest', 'LateFee')
        BEGIN
            THROW 50011, 'Invalid payment type. Must be Principal, Interest, or LateFee.', 1;
        END;

        INSERT INTO LoanPayment (LoanID, LoanPaymentAmount, LoanPaymentDate, LoanPaymentType, LoanPaymentDescription)
        VALUES (@LoanID, @LoanPaymentAmount, @LoanPaymentDate, @LoanPaymentType, @LoanPaymentDescription);

        UPDATE Loan
        SET RemainingBalance = RemainingBalance - @LoanPaymentAmount
        WHERE LoanID = @LoanID;

        IF (SELECT RemainingBalance FROM Loan WHERE LoanID = @LoanID) < 0
        BEGIN
            THROW 50002, 'Payment exceeds remaining loan balance.', 1;
        END;

        IF (SELECT RemainingBalance FROM Loan WHERE LoanID = @LoanID) = 0
        BEGIN
            UPDATE Loan
            SET LoanStatus = 'Paid'
            WHERE LoanID = @LoanID;
        END;

        INSERT INTO AuditLog (TableName, Action, RecordID, Description)
        VALUES ('LoanPayment', 'Insert', @LoanID, 'Loan payment of ' + CAST(@LoanPaymentAmount AS NVARCHAR(10)) + 
                ' registered for loan ID ' + CAST(@LoanID AS NVARCHAR(10)));

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE RegisterTransaction
    @CustomerID INT,
    @AccountID INT,
    @Amount DECIMAL(10, 2),
    @TransactionType NVARCHAR(20),
    @Description NVARCHAR(100) = NULL,
    @TransactionDate DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @TransactionDate IS NULL SET @TransactionDate = GETDATE();

        IF NOT EXISTS (SELECT 1 FROM Customer WHERE CustomerID = @CustomerID)
            THROW 50006, 'Customer does not exist.', 1;

        IF NOT EXISTS (SELECT 1 FROM Account WHERE AccountID = @AccountID AND IsActive = 1)
            THROW 50017, 'Account does not exist or is not active.', 1;

        IF @Amount <= 0
            THROW 50014, 'Amount must be greater than 0.', 1;

        IF @TransactionType NOT IN ('Deposit', 'Withdrawal', 'Salary', 'Payment')
            THROW 50015, 'Invalid transaction type. Must be Deposit, Withdrawal, Salary, or Payment.', 1;

        DECLARE @AccountCustomerID INT;
        SELECT @AccountCustomerID = COALESCE(
            (SELECT CustomerID FROM Disposition WHERE AccountID = @AccountID),
            (SELECT CustomerID FROM Loan WHERE AccountID = @AccountID),
            (SELECT CustomerID FROM Credit WHERE AccountID = @AccountID)
        );

        IF @AccountCustomerID IS NULL
            THROW 50020, 'Account is not associated with any customer.', 1;
        IF @AccountCustomerID != @CustomerID
            THROW 50021, 'Account does not belong to the specified customer.', 1;

        INSERT INTO Transactions (AccountID, CardID, TransactionType, Amount, TransactionDate, Description)
        VALUES (@AccountID, NULL, @TransactionType, @Amount, @TransactionDate, @Description);
        DECLARE @TransactionID INT = SCOPE_IDENTITY();

        UPDATE Account
        SET Balance = CASE 
                         WHEN @TransactionType IN ('Deposit', 'Salary', 'Payment') THEN Balance + @Amount
                         WHEN @TransactionType = 'Withdrawal' THEN Balance - @Amount
                         ELSE Balance 
                      END
        WHERE AccountID = @AccountID;

        IF EXISTS (SELECT 1 FROM Account WHERE AccountID = @AccountID AND Balance < 0 AND @TransactionType = 'Withdrawal')
            THROW 50027, 'Insufficient funds for withdrawal.', 1;

        INSERT INTO AuditLog (TableName, Action, RecordID, Description)
        VALUES ('Transactions', 'Insert', @AccountID, 
            CONCAT(CAST(@TransactionType AS NVARCHAR(20)), ' of ', CAST(@Amount AS NVARCHAR(20)),
            ' registered for account ID ', CAST(@AccountID AS NVARCHAR(10)), 
            ' by customer ID ', CAST(@CustomerID AS NVARCHAR(10))));

        INSERT INTO TransactionsLog (TransactionID, AccountID, TransactionType, Amount, TransactionDate, Description)
        VALUES (@TransactionID, @AccountID, @TransactionType, @Amount, @TransactionDate, @Description);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE PayLoanFromAccount
    @AccountID INT,
    @LoanID INT,
    @Amount DECIMAL(10, 2),
    @PaymentType NVARCHAR(20),
    @TransactionDate DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @TransactionDate IS NULL SET @TransactionDate = GETDATE();

        IF NOT EXISTS (SELECT 1 FROM Account WHERE AccountID = @AccountID AND IsActive = 1)
            THROW 50017, 'Account does not exist or is not active.', 1;

        DECLARE @LoanCustomerID INT;
        SELECT @LoanCustomerID = CustomerID FROM Loan WHERE LoanID = @LoanID;
        IF @LoanCustomerID IS NULL
            THROW 50009, 'Loan does not exist.', 1;

        IF @Amount <= 0
            THROW 50010, 'Amount must be greater than 0.', 1;

        IF @PaymentType NOT IN ('Principal', 'Interest', 'LateFee')
            THROW 50011, 'Invalid payment type. Must be Principal, Interest, or LateFee.', 1;

        IF EXISTS (SELECT 1 FROM Account WHERE AccountID = @AccountID AND AccountType = 'Loan')
            THROW 50018, 'Cannot use a Loan account to pay another loan.', 1;

        DECLARE @AccountCustomerID INT;
        SELECT @AccountCustomerID = COALESCE(
            (SELECT CustomerID FROM Disposition WHERE AccountID = @AccountID),
            (SELECT CustomerID FROM Loan WHERE AccountID = @AccountID),
            (SELECT CustomerID FROM Credit WHERE AccountID = @AccountID)
        );

        IF @AccountCustomerID IS NULL
            THROW 50020, 'Account is not associated with any customer.', 1;
        IF @AccountCustomerID != @LoanCustomerID
            THROW 50021, 'Account does not belong to the same customer as the loan.', 1;

        DECLARE @Description NVARCHAR(100) = CONCAT('Payment for loan ID ', @LoanID);
        EXEC RegisterTransaction 
            @CustomerID = @LoanCustomerID, 
            @AccountID = @AccountID,
            @Amount = @Amount,
            @TransactionType = 'Withdrawal',
            @Description = @Description,
            @TransactionDate = @TransactionDate;
        DECLARE @TransactionID INT = SCOPE_IDENTITY();

        DECLARE @LoanPaymentDescription NVARCHAR(100) = CONCAT('Payment from account ID ', 
                    CAST(@AccountID AS NVARCHAR(10)));

        EXEC RegisterLoanPayment 
            @LoanID = @LoanID,
            @LoanPaymentAmount = @Amount,
            @LoanPaymentDate = @TransactionDate,
            @LoanPaymentType = @PaymentType,
            @LoanPaymentDescription = @LoanPaymentDescription;

        INSERT INTO AuditLog (TableName, Action, RecordID, Description)
        VALUES ('LoanPaymentFromAccount', 'Insert', @LoanID, 
            CONCAT('Paid ', @Amount, ' (', COALESCE(@PaymentType, 'Unknown'), ') for loan ID ', 
                @LoanID, ' from account ID ', @AccountID));

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE AddSavingsAccount
    @CustomerID INT,
    @InitialBalance DECIMAL(10, 2),
    @InterestRate DECIMAL(5, 2) = 1.00,
    @Description NVARCHAR(50) = 'Regular'
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM Customer WHERE CustomerID = @CustomerID)
            THROW 50006, 'Customer does not exist.', 1;
        IF @InitialBalance < 0
            THROW 50016, 'Initial balance cannot be negative.', 1;

        DECLARE @AccountNumber NVARCHAR(20) = 'ACC' + RIGHT('00000000' + CAST(@CustomerID AS NVARCHAR(8)), 8) + 'S' + 
                CAST((SELECT COUNT(*) + 1 FROM Account WHERE AccountNumber LIKE 'ACC' + RIGHT('00000000' + 
                CAST(@CustomerID AS NVARCHAR(8)), 8) + 'S%') AS NVARCHAR(2));
        INSERT INTO Account (AccountNumber, Balance, AccountType, IsActive)
        VALUES (@AccountNumber, @InitialBalance, 'Savings', 1);
        DECLARE @AccountID INT = SCOPE_IDENTITY();

        INSERT INTO SavingsAccount (AccountID, InterestRate, Description)
        VALUES (@AccountID, @InterestRate, @Description);

        INSERT INTO Disposition (CustomerID, AccountID, CardID)
        VALUES (@CustomerID, @AccountID, NULL);

        INSERT INTO AuditLog (TableName, Action, RecordID, Description)
        VALUES ('Account', 'Insert', @AccountID, 'New Savings account (' + @Description + ') created for customer ID ' 
                + CAST(@CustomerID AS NVARCHAR(10)));

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE UpdateSavingsInterest
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE a
        SET a.Balance = a.Balance + (a.Balance * (sa.InterestRate / 100) * 
                     DATEDIFF(MONTH, sa.LastInterestDate, GETDATE()) / 12.0)
        FROM Account a
        JOIN SavingsAccount sa ON sa.AccountID = a.AccountID
        WHERE a.IsActive = 1
          AND DATEDIFF(MONTH, sa.LastInterestDate, GETDATE()) > 0;

        UPDATE sa
        SET sa.LastInterestDate = GETDATE()
        FROM SavingsAccount sa
        JOIN Account a ON sa.AccountID = a.AccountID
        WHERE a.IsActive = 1
          AND DATEDIFF(MONTH, sa.LastInterestDate, GETDATE()) > 0;

        INSERT INTO AuditLog (TableName, Action, RecordID, Description)
        SELECT 'SavingsAccount', 'Update', sa.AccountID, 
               'Interest updated for savings account ID ' + CAST(sa.AccountID AS NVARCHAR(10)) + 
               ' with rate ' + CAST(sa.InterestRate AS NVARCHAR(10)) + '%'
        FROM SavingsAccount sa
        JOIN Account a ON sa.AccountID = a.AccountID
        WHERE a.IsActive = 1
          AND DATEDIFF(MONTH, sa.LastInterestDate, GETDATE()) > 0;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- Triggers
CREATE OR ALTER TRIGGER UpdateLoanAccountBalance
ON LoanPayment
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        UPDATE a
        SET Balance = a.Balance - i.LoanPaymentAmount
        FROM Account a
        JOIN Loan l ON a.AccountID = l.AccountID
        JOIN inserted i ON l.LoanID = i.LoanID
        WHERE i.LoanPaymentType = 'Principal';

        INSERT INTO AuditLog (TableName, Action, RecordID, Description)
        SELECT 
            'Account', 
            'Update', 
            l.AccountID, 
            'Loan account balance reduced by ' + CAST(i.LoanPaymentAmount AS NVARCHAR(20)) + ' due to Principal payment'
        FROM Loan l
        JOIN inserted i ON l.LoanID = i.LoanID
        WHERE i.LoanPaymentType = 'Principal';

        IF EXISTS (
            SELECT 1 
            FROM Account a 
            JOIN Loan l ON a.AccountID = l.AccountID 
            JOIN inserted i ON l.LoanID = i.LoanID 
            WHERE a.Balance < 0 AND i.LoanPaymentType = 'Principal'
        )
        BEGIN
            THROW 50019, 'Loan account balance cannot be negative.', 1;
            ROLLBACK TRANSACTION;
        END;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER TRIGGER GenerateLoanSchedule
ON Loan
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @LoanID INT, @LoanAmount DECIMAL(10, 2), @InterestRate DECIMAL(5, 2), 
                @PaymentFrequency NVARCHAR(20);
        DECLARE @MonthlyPayment DECIMAL(10, 2), @MonthlyRate DECIMAL(10, 6), @NumberOfPayments INT;
        DECLARE @RemainingBalance DECIMAL(10, 2), @PaymentDate DATE, @PaymentNumber INT;
        DECLARE @InterestAmount DECIMAL(10, 2), @PrincipalAmount DECIMAL(10, 2);

        SELECT @LoanID = LoanID, 
               @LoanAmount = LoanAmount, 
               @InterestRate = InterestRate, 
               @PaymentFrequency = PaymentFrequency
        FROM inserted;

        IF @PaymentFrequency = 'Monthly'
        BEGIN
            SET @NumberOfPayments = 60;
            SET @MonthlyRate = @InterestRate / 100.0 / 12.0;
        END
        ELSE IF @PaymentFrequency = 'Quarterly'
        BEGIN
            SET @NumberOfPayments = 20;
            SET @MonthlyRate = @InterestRate / 100.0 / 4.0;
        END
        ELSE
        BEGIN
            SET @NumberOfPayments = 60;
            SET @MonthlyRate = @InterestRate / 100.0 / 12.0;
            SET @PaymentFrequency = 'Monthly';
        END;

        SET @MonthlyPayment = @LoanAmount * (@MonthlyRate * POWER(1 + @MonthlyRate, @NumberOfPayments)) / 
                              (POWER(1 + @MonthlyRate, @NumberOfPayments) - 1);

        SET @RemainingBalance = @LoanAmount;
        SET @PaymentDate = GETDATE();
        SET @PaymentNumber = 1;

        WHILE @PaymentNumber <= @NumberOfPayments
        BEGIN
            SET @InterestAmount = @RemainingBalance * @MonthlyRate;
            SET @PrincipalAmount = @MonthlyPayment - @InterestAmount;
            SET @RemainingBalance = @RemainingBalance - @PrincipalAmount;

            IF @PaymentFrequency = 'Monthly'
                SET @PaymentDate = DATEADD(MONTH, 1, @PaymentDate);
            ELSE IF @PaymentFrequency = 'Quarterly'
                SET @PaymentDate = DATEADD(MONTH, 3, @PaymentDate);

            INSERT INTO LoanSchedule (LoanID, LoanPaymentNumber, LoanPaymentDate, LoanPaymentAmount, PrincipalAmount, InterestAmount, RemainingBalance)
            VALUES (@LoanID, @PaymentNumber, @PaymentDate, @MonthlyPayment, @PrincipalAmount, @InterestAmount, @RemainingBalance);

            SET @PaymentNumber = @PaymentNumber + 1;
        END;

        INSERT INTO AuditLog (TableName, Action, RecordID, Description)
        VALUES ('LoanSchedule', 'Insert', @LoanID, 'Loan schedule generated for loan ID ' + CAST(@LoanID AS NVARCHAR(10)));
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- View
CREATE OR ALTER VIEW CustomerAccountOverview AS
SELECT DISTINCT
    c.CustomerID,
    c.FirstName + ' ' + c.LastName AS CustomerName,
    a.AccountID,
    a.AccountNumber,
    a.AccountType,
    COALESCE(a.Balance, 0.00) AS AccountBalance,
    CASE 
        WHEN a.AccountType = 'Credit' THEN COALESCE(cr.CreditLimit, 0.00) - COALESCE(cr.UsedCredit, 0.00)
        WHEN a.AccountType = 'Loan' THEN -COALESCE(l.RemainingBalance, 0.00)
        ELSE COALESCE(a.Balance, 0.00)
    END AS EffectiveBalance,
    COALESCE(cr.CreditLimit, 0.00) AS CreditLimit,
    COALESCE(cr.UsedCredit, 0.00) AS UsedCredit,
    COALESCE(l.LoanAmount, 0.00) AS LoanAmount,
    COALESCE(l.RemainingBalance, 0.00) AS RemainingBalance,
    COALESCE(l.LoanType, 'N/A') AS LoanType,
    COALESCE(sa.Description, 'N/A') AS SavingsDescription,
    COALESCE(ca.CardNumber, 'N/A') AS CardNumber, 
    COALESCE(
        (SELECT SUM(a2.Balance)
         FROM Account a2
         WHERE a2.AccountID IN (
             SELECT AccountID FROM Disposition WHERE CustomerID = c.CustomerID
             UNION
             SELECT AccountID FROM Loan WHERE CustomerID = c.CustomerID
             UNION
             SELECT AccountID FROM SavingsAccount WHERE AccountID = a2.AccountID
         )), 0.00) AS TotalAccountBalance,
    COALESCE(
        (SELECT SUM(CASE 
                        WHEN a2.AccountType = 'Credit' THEN COALESCE(cr2.CreditLimit, 0.00) - COALESCE(cr2.UsedCredit, 0.00) 
                        WHEN a2.AccountType = 'Loan' THEN -COALESCE(l2.RemainingBalance, 0.00) 
                        ELSE COALESCE(a2.Balance, 0.00) 
                    END)
         FROM Account a2
         LEFT JOIN Credit cr2 ON a2.AccountID = cr2.AccountID
         LEFT JOIN Loan l2 ON a2.AccountID = l2.AccountID
         WHERE a2.AccountID IN (
             SELECT AccountID FROM Disposition WHERE CustomerID = c.CustomerID
             UNION
             SELECT AccountID FROM Loan WHERE CustomerID = c.CustomerID
             UNION
             SELECT AccountID FROM SavingsAccount WHERE AccountID = a2.AccountID
         )), 0.00) AS TotalEffectiveBalance,
    COALESCE(
        (SELECT SUM(COALESCE(l2.RemainingBalance, 0.00) + COALESCE(cr2.UsedCredit, 0.00))
         FROM Account a2
         LEFT JOIN Loan l2 ON a2.AccountID = l2.AccountID
         LEFT JOIN Credit cr2 ON a2.AccountID = cr2.AccountID
         WHERE a2.AccountID IN (
             SELECT AccountID FROM Disposition WHERE CustomerID = c.CustomerID
             UNION
             SELECT AccountID FROM Loan WHERE CustomerID = c.CustomerID
             UNION
             SELECT AccountID FROM SavingsAccount WHERE AccountID = a2.AccountID
         )), 0.00) AS TotalDebt
FROM Customer c
JOIN Account a ON a.AccountID IN (
    SELECT AccountID FROM Disposition WHERE CustomerID = c.CustomerID
    UNION
    SELECT AccountID FROM Loan WHERE CustomerID = c.CustomerID
    UNION
    SELECT sa.AccountID 
    FROM SavingsAccount sa
    JOIN Disposition d ON sa.AccountID = d.AccountID
    WHERE d.CustomerID = c.CustomerID
)
LEFT JOIN Disposition d ON a.AccountID = d.AccountID AND d.CustomerID = c.CustomerID
LEFT JOIN Credit cr ON a.AccountID = cr.AccountID
LEFT JOIN Loan l ON a.AccountID = l.AccountID
LEFT JOIN SavingsAccount sa ON a.AccountID = sa.AccountID
LEFT JOIN Card ca ON d.CardID = ca.CardID 
WHERE c.IsActive = 1;
GO