-- Kevin Grundhall kegr25 pagpt25h

-- 1

-- 2
--  2. Write an SQL statement that shows info about students who have not borrowed any books.
--     Table should have the following columns: stNum | Fname | Lname | numOfLeases.

SELECT s.stNum, s.Fname, s.Lname, COUNT(bl.leaseNumber) as numOfLeases
FROM Student s
LEFT JOIN BookLease bl ON s.stNum = bl.stNum
GROUP BY s.stNum, s.Fname, s.Lname
HAVING numOfLeases = 0
-- Tänk på att eftersom vi har dataaggretion (count), så måste vi använda HAVING istället för WHERE.


-- 3
--  3. Write an SQL statement that shows each Book and its average lease time (the actual days, not the planned ones), only count leases that are completed (dateReturned is available).
--     The result table should show the following columns: the ISBN, Title, and the average rental days as “AverageBorrowTime”.
SELECT b.ISBN, b.Title, AVG(DATEDIFF(bl.dateReturned, bl.startDate)) as AverageBorrowTime
FROM Book b
JOIN BookLease bl ON b.isbn = bl.isbn
WHERE bl.dateReturned IS NOT NULL
GROUP BY b.isbn, b.Title
-- Ingen dataaggregation, så WHERE (och före group!)


-- 4. Create a view that shows which Books are currently rented (dateReturned is null),
--    with the columns ISBN, Title, Fname, Lname, and expected return date (e.g., startDate plus leaseInDays) as “ExpectedDate”.
CREATE VIEW view1 AS
SELECT b.ISBN, b.Title, s.Fname, s.Lname, DATE_ADD(bl.startDate, INTERVAL bl.leaseInDays DAY) AS ExpectedDate
FROM Book b
JOIN BookLease bl ON b.ISBN = bl.ISBN
JOIN Student s ON s.stNum = bl.stNum
HAVING bl.dateReturned IS NULL
-- Använd bara group by när vi aggregerar data (count, avg, sum)
-- bl.dateReturned filtrerar individuella rader, därav inte HAVING, utan WHERE

-- 5. Create a trigger on the BookLease table which, when a lease is returned (when null is changed to date in returnDate),
-- increases the respective Book's number of copies by 1.
DELIMITER $$
CREATE TRIGGER trigger1
AFTER UPDATE
ON BookLease
FOR EACH ROW
BEGIN
	if (OLD.dateReturned IS NULL AND NEW.dateReturned IS NOT NULL) THEN
		UPDATE Book
		SET numOfCopies = numOfCopies + 1
        WHERE ISBN = NEW.ISBN;
	END IF;
END$$
DELIMITER ;
-- Kom ihåg DELIMITER

--  6. Create a procedure that handles a lease of a book. Checks must be made so that the book’s number of copies is not equal to zero.
-- If no copy is available of the book (numOfCopies = 0) the lease must not go through (aborted).'
-- The procedure must check if the book is still available and do the following actions:
DELIMITER $$
CREATE PROCEDURE procedure1 (
	IN p_leaseNumber INT,
    IN p_ISBN VARCHAR(255),
    IN p_stNum VARCHAR(255),
    IN p_startDate DATE,
    IN p_leaseInDays INT,
    IN p_dateReturned DATE
    )
BEGIN
	DECLARE copies INT;

    SELECT numOfCopies INTO copies
    FROM Book
    WHERE ISBN = p_ISBN;

    IF copies > 0 THEN
		INSERT INTO BookLease(leaseNumber, ISBN, stNum, startDate, leaseInDays, dateReturned)
        VALUES (p_leaseNumber, p_ISBN, p_stNum, p_startDate, p_leaseInDays, p_dateReturned);

        UPDATE Book
        SET numOfCopies = numOfCopies - 1
        WHERE ISBN = p_ISBN;
        SELECT 'Row Inserted' AS message;
	ELSE
		SELECT 'Row NOT Inserted! No copies available.' AS message;
	END IF;
END$$
DELIMITER ;

-- 7 Write an SQL statement that shows all students, each lease the student has made, and which books they have borrowed.
--   If a student has not made any lease, s/he must still appear in the results. The result table should show the following columns:
--   stNum | combine FName and LName as name_ | leaseNumber | ISBN. Display leaseNumber in descending order.
SELECT s.stNum, CONCAT(s.Fname, ' ', s.Lname) AS name_, bl.leaseNumber, b.ISBN
FROM Student s
LEFT JOIN BookLease bl ON s.stNum = bl.stNum
LEFT JOIN Book b ON b.ISBN = bl.ISBN
ORDER BY bl.leaseNumber DESC
-- Dubbel leftjoin för att bevara alla NULL

-- 8
-- Write an SQL statement that displays the students who are still borrowing a book. The result table should show the following columns:
-- studentName (concatenate with a space: Fname and Lname), Title and ExpectedReturnDate.
SELECT CONCAT(s.Fname, ' ', s.Lname) AS studentName, b.Title, DATE_ADD(bl.startDate, INTERVAL bl.leaseInDays DAY) AS ExpectedReturnDate
FROM Student s
JOIN BookLease bl ON s.stNum = bl.stNum
JOIN Book b ON b.ISBN = bl.ISBN
WHERE bl.dateReturned IS NULL

--   9. Let’s say that the library imposes a fine of 12.5 SEK for each day a book is overdue.
--      Write a SQL statement that shows each rented book, the student’s name, number of overdue days, and the overdue amount.
--      The result table should show the following columns: the leaseNumber, ISBN, Fname, Lname, numOfOverdueDays, and totalAmount
--      (OBS! Only show the students who have overdue amount). Use a function that accepts an input (i.e., leaseNumber) and returns numOfOverdueDays.
DELIMITER $$
CREATE FUNCTION overdueFees(p_leaseNumber INT) RETURNS INT
DETERMINISTIC
BEGIN
	DECLARE overdue_days INT;
    DECLARE v_startDate DATE;
    DECLARE v_leaseInDays INT;

    SELECT startDate, leaseInDays INTO v_startDate, v_leaseInDays
    FROM BookLease
    WHERE leaseNumber = p_leaseNumber;

    SET overdue_days = DATEDIFF(CURRENT_DATE, DATE_ADD(v_startDate, INTERVAL v_leaseInDays DAY));

    RETURN overdue_days;
END$$
DELIMITER ;


SELECT
bl.leaseNumber,
b.ISBN,
s.Fname,
s.LName,
overdueFees(bl.leaseNumber) as numOfOverdueDays,
overdueFees(bl.leaseNumber) * 12.5 as totalAmount

FROM Student s
JOIN BookLease bl ON s.stNum = bl.stNum
JOIN Book b ON b.ISBN = bl.ISBN
WHERE overdueFees(bl.leaseNumber) > 0
-- WHERE because we're not using COUNT, MIN, MAX, AVG, SUM

10.
-- Create a function that accepts as an input the book ISBN and outputs the number of times this book has been borrowed (from table BookLease).
-- Plug this function into a SELECT statement to display the books in descending order by numOfTimes,
-- if a book has never been borrowed (i.e, H-0082-M), it still must be shown.
-- The table should have the following columns: ISBN | Title | numOfTimes
DELIMITER $$
CREATE FUNCTION amountBorrowed (p_ISBN VARCHAR(255)) RETURNS INT
DETERMINISTIC
BEGIN
	DECLARE count INT;

    SELECT COUNT(leaseNumber) INTO count
    FROM BookLease
    WHERE ISBN = p_ISBN;

    return count;
END$$
DELIMITER ;


SELECT b.ISBN, b.Title, amountBorrowed(b.ISBN) AS numOfTimes
FROM Book b
ORDER BY numOfTimes DESC
-- Tänk på att den slutgiltiga SELECT delen här inte behövde joinas med BookLease då funktionen tar han om den delen.
