

Project Summary: VaultofPaul Bank Database


This project involved designing and building a realistic banking database in SQL Server. The final system includes customers, different types of accounts (Savings, Checking, Credit, Loan), cards, transactions, loan payments, and audit logging.
Development Process
I started by creating an ERD and identifying the main entities. Early on, I decided not to include tables for employees, branches, or customer service, because they would add unnecessary complexity for the scope of this school project.
I also explored several more advanced ideas that I later removed to keep the project manageable:

Child accounts (ages 15–18) linked to parents with spending limits
Investment accounts (stocks, funds, bonds)
A separate CustomerInformation table with address, salary, etc.

After a group project and a pause, I decided to start over with a cleaner design. This was a good decision — the original version had grown to 22 tables with redundant and broken parts.
Key Design Decisions

Kept CustomerID directly in the Credit and Loan tables for simplicity and reliability, while still using a Disposition table to show who can access which accounts and cards.
Created a powerful stored procedure RegisterCustomerAndAccount that sets up a full customer with multiple accounts and cards in one go.
Added triggers for automatic balance updates, interest calculations, and generating loan repayment schedules.
Focused on data integrity with constraints, foreign keys, and proper error handling.

Challenges & Lessons Learned
The biggest challenge was managing complexity. One idea often led to another, and the project grew quickly. I learned that it’s important to prioritize and sometimes cut features, even if they are interesting.
Working with the main registration procedure taught me a lot about debugging, transaction handling, and keeping procedures well-organized. I also realized how valuable it is to document design choices and the reasons behind them.
Overall, I’m satisfied with the final result. The database is solid, realistic enough for a school project, and has a clear structure that can be extended in the future.
