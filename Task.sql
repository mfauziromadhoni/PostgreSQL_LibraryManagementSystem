-- Library Management System

--Project Task

-- Task 1. Create a New Book Record ('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')
SELECT * FROM books
INSERT INTO books(isbn, book_title, category, rental_price, status, author, publisher)
VALUES
('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');

-- Task 2: Update an Existing Member's Address
SELECT * FROM members
UPDATE members
SET member_address = '123 Main St'
WHERE member_id = 'C101';

-- Task 3: Delete a Record from the Issued Status Table
-- Objective: Delete the record with issued_id = 'IS121' from the issued_status 
SELECT * FROM issued_status

DELETE FROM issued_status
WHERE issued_id = 'IS121';

-- Task 4: Retrieve All Books Issued by a Specific Employee
-- Objective: Select all books issued by the employee with emp_id = 'E101'.
SELECT * FROM issued_status
WHERE issued_emp_id = 'E101';

-- Task 5: List Members Who Have Issued More Than One Book
-- Objective: Use GROUP BY to find members who have issued more than one book.
SELECT * FROM issued_status
SELECT 
		issued_emp_id,
		COUNT(issued_id) AS total_book_issued
FROM issued_status
GROUP BY 1
HAVING COUNT(issued_id) > 1;

--CTAS
-- Task 6: Create Summary Tables**: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt
CREATE TABLE books_cnts
AS
SELECT 
	b.isbn,
	b.book_title,
	COUNT(issued_id) AS numb_issued
FROM books AS b
JOIN
issued_status AS ist
ON ist.issued_book_isbn = b.isbn
GROUP BY 1,2;

SELECT * FROM books_cnts

-- Task 7. **Retrieve All Books in a Specific Category
SELECT * FROM books
WHERE category = 'Classic';

-- Task 8: Find Total Rental Income by Category
SELECT 
	category,
	SUM(rental_price) AS sum_rent_price,
	COUNT(*)
FROM books
GROUP BY 1;

-- Task 9. List Members Who Registered in the Last 180 Days
SELECT * FROM members
WHERE reg_date >= CURRENT_DATE - INTERVAL '100 days';

INSERT INTO members(member_id,member_name,member_address,reg_date)
VALUES
('C120','Nashwa Zahira','123 Main St','2025-06-01'),
('C121','Reva Mikayla','145 Main St','2025-06-10');


-- Task 10: List Employees with Their Branch Manager's Name and their branch details
SELECT
	e1.*,
	b.manager_id,
	e2.emp_name AS manager
FROM employees AS e1
JOIN
branch AS b
ON b.branch_id = e1.branch_id
JOIN
employees AS e2
ON b.manager_id = e2.emp_id

-- Task 11. Create a Table of Books with Rental Price Above a Certain Threshold (>7 USD)
CREATE TABLE books_rent_price_thrlshld
AS
SELECT * FROM books
WHERE rental_price > 7

SELECT * FROM books_rent_price_thrlshld


-- Task 12: Retrieve the List of Books Not Yet Returned
SELECT * FROM issued_status
SELECT * FROM return_status

SELECT 
	DISTINCT ist.issued_book_name
FROM issued_status AS ist
LEFT JOIN
return_status AS rs
ON ist.issued_id = rs.issued_id
WHERE rs.return_id IS NULL

/*Task 13: Identify Members with Overdue Books
Write a query to identify members who have overdue books (assume a 30-day return period). Display the member's name, book title, issue date, and days overdue.
*/
-- issued_status==members==books==return_status
--return books which is return
-- overdue >30 days

SELECT 
	ist.issued_member_id,
	m.member_name,
	b.book_title,
	ist.issued_date,
	rs.return_date,
	CURRENT_DATE - ist.issued_date AS overdues
FROM issued_status AS ist
JOIN
members AS m
ON m.member_id = ist.issued_member_id
JOIN 
books AS b
ON b.isbn = ist.issued_book_isbn
LEFT JOIN
return_status AS rs
ON rs.issued_id = ist.issued_id
WHERE 
	rs.return_date IS NULL
	AND 
	(CURRENT_DATE - ist.issued_date) >30
ORDER BY 1


/*Task 14: Update Book Status on Return
Write a query to update the status of books in the books table to "available" when they are returned (based on entries in the return_status table).*/

--Update Return of Books Manually
SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-553-29698-2';

SELECT * FROM books;

UPDATE books
SET status = 'no'
WHERE isbn = '978-0-553-29698-2';

SELECT * FROM return_status
WHERE issued_id = 'IS137'

INSERT INTO return_status(return_id,issued_id,return_date)
VALUES
('RS123','IS137',CURRENT_DATE)
SELECT * FROM return_status
WHERE issued_id = 'IS137'

/* Manually insert
UPDATE books
SET status = 'YES'
WHERE isbn = '978-0-553-29698-2';*/

--Update Return of books Automaticaly
CREATE OR REPLACE PROCEDURE add_return_records(p_return_id VARCHAR(10), p_issued_id VARCHAR(10))
LANGUAGE plpgsql
AS $$

DECLARE
	v_isbn VARCHAR(50);
	v_book_name VARCHAR(80);

BEGIN
	--main program
	--Inserting returns based on users input
	INSERT INTO return_status(return_id,issued_id,return_date)
	VALUES
	(p_return_id,p_issued_id,CURRENT_DATE);

	SELECT 
		issued_book_isbn,
		issued_book_name
		INTO
		v_isbn,
		v_book_name
	FROM issued_status
	WHERE issued_id = p_issued_id;

	UPDATE books
	SET status = 'yes'
	WHERE isbn = v_isbn;

	RAISE NOTICE 'Thanks for return the book : %', v_book_name;
	
END;
$$

--Testing
-- isbn = '978-0-307-58837-1'
-- issued_id = 'IS135'

-- Calling Function/Procedure
CALL add_return_records ('RS140','IS135')

--Checking Status
SELECT * FROM return_status
WHERE return_id = 'RS140';

SELECT * FROM books
WHERE isbn = '978-0-307-58837-1';


/*Task 15: Branch Performance Report
Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.*/

CREATE TABLE branch_report
AS
SELECT 
	b.branch_id,
	b.manager_id,
	COUNT(ist.issued_id) AS number_of_book_issued,
	COUNT(rs.return_id) AS number_book_return,
	SUM(bk.rental_price) AS total_revenue
FROM issued_status as ist
JOIN 
employees as e
ON e.emp_id = ist.issued_emp_id
JOIN
branch as b
ON e.branch_id = b.branch_id
LEFT JOIN
return_status as rs
ON rs.issued_id = ist.issued_id
JOIN 
books as bk
ON ist.issued_book_isbn = bk.isbn
GROUP BY 1,2;

SELECT * FROM branch_report;


/*Task 16: CTAS: Create a Table of Active Members
Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members 
who have issued at least one book in the last 2 year.*/

CREATE TABLE active_member
AS
SELECT * FROM members
WHERE member_id IN (
					SELECT
						DISTINCT issued_member_id
					FROM issued_status
					WHERE issued_date >= CURRENT_DATE - INTERVAL '2 year'
					);

SELECT * FROM active_member;


/*Task 17: Find Employees with the Most Book Issues Processed
Write a query to find the top 3 employees who have processed the most book issues. 
Display the employee name, number of books processed, and their branch.*/

SELECT 
	e.emp_name,
	b.*,
	COUNT(ist.issued_id) AS no_issued_book
FROM issued_status AS ist
JOIN
employees AS e
ON e.emp_id = ist.issued_emp_id
JOIN
branch AS b
ON b.branch_id = e.branch_id
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 3;

/*Task 19: Stored Procedure Objective: Create a stored procedure to manage the status of books in a library system. 
Description: Write a stored procedure that updates the status of a book in the library based on its issuance. 
The procedure should function as follows: The stored procedure should take the book_id as an input parameter. 
The procedure should first check if the book is available (status = 'yes'). 
If the book is available, it should be issued, and the status in the books table should be updated to 'no'. 
If the book is not available (status = 'no'), 
the procedure should return an error message indicating that the book is currently not available.*/

SELECT * FROM issued_status;

CREATE OR REPLACE PROCEDURE issue_book(p_issued_id VARCHAR(10), p_issued_member_id VARCHAR(10), p_issued_book_isbn VARCHAR(20), 
p_issued_emp_id VARCHAR(10))
LANGUAGE plpgsql
AS $$

DECLARE
	--declaration
	v_status VARCHAR(10);
BEGIN
	--main program
		--checking if book is available 'yes'
		SELECT
			status
			INTO
			v_status
		FROM books
		WHERE isbn = p_issued_book_isbn;

		IF v_status = 'yes' THEN

			INSERT INTO issued_status(issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id)
			VALUES
			(p_issued_id, p_issued_member_id, CURRENT_DATE, p_issued_book_isbn, p_issued_emp_id);

			UPDATE books
			SET status = 'no'
			WHERE isbn = p_issued_book_isbn;

			RAISE NOTICE 'Book records have been successfully (book isbn) : %',p_issued_book_isbn;

		ELSE

			RAISE NOTICE 'Sorry that book you have requested is not available (book isbn) : %',p_issued_book_isbn;

		END IF;

END;
$$

--Testing

SELECT * FROM books;
--isbn = '978-0-330-25864-8' status (yes)
--isbn = '978-0-375-41398-8' status (no)

SELECT * FROM issued_status;

--Calling Function

CALL issue_book('IS141', 'C108', '978-0-330-25864-8', 'E104'); --(ex: status is 'yes')

CALL issue_book('IS142', 'C108', '978-0-375-41398-8', 'E104'); --(ex: status is 'no')

--Checking of status (if started with 'yes')
SELECT * FROM books
WHERE isbn = '978-0-330-25864-8';
