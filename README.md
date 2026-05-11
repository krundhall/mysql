# MySQL Cheatsheet
- https://quickref.me/mysql.html
- https://www.mysqltutorial.org/mysql-cheat-sheet/
- https://devhints.io/mysql


# SQL Cheatsheet - Key Concepts

## WHERE vs HAVING
- **WHERE**: Filters individual rows BEFORE grouping (use for regular columns)
```sql
  WHERE dateReturned IS NOT NULL
  WHERE age > 18
```
- **HAVING**: Filters groups AFTER aggregation (use with COUNT, AVG, SUM, etc.)
```sql
  HAVING COUNT(*) > 5
  HAVING AVG(price) < 100
```

## SQL Query Order
```sql
SELECT ...
FROM ...
JOIN ...
WHERE ...        -- filters rows BEFORE grouping
GROUP BY ...     -- groups the filtered rows
HAVING ...       -- filters groups AFTER aggregation
ORDER BY ...
```

## JOIN Types
- **INNER JOIN (or just JOIN)**: Only matching rows from both tables
- **LEFT JOIN**: ALL rows from left table + matching from right (NULLs if no match)
- **Rule**: If you need "show all X even if no Y", use LEFT JOIN

## Aggregate Functions (require GROUP BY)
- `COUNT(column)` - counts non-NULL values
- `AVG(column)` - average
- `SUM(column)` - total
- When using aggregates, non-aggregated columns must be in GROUP BY

## Date Functions
- `CURRENT_DATE` or `CURDATE()` - today's date
- `DATEDIFF(date1, date2)` - difference in days
- `DATE_ADD(date, INTERVAL n DAY/MONTH/YEAR)` - add time to date
```sql
  DATE_ADD(startDate, INTERVAL 10 DAY)
```

## String Functions
- `CONCAT(str1, ' ', str2)` - combine strings
```sql
  CONCAT(Fname, ' ', Lname) AS fullName
```

## NULL Handling
- Use `IS NULL` or `IS NOT NULL` (NOT == NULL)
```sql
  WHERE dateReturned IS NULL
  WHERE dateReturned IS NOT NULL
```

---

## CREATE TABLE
```sql
CREATE TABLE TableName (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255),
    age INT,
    FOREIGN KEY (other_id) REFERENCES OtherTable(id)
);
```

## CREATE VIEW
```sql
CREATE VIEW viewName AS
SELECT ...
FROM ...
WHERE ...;
```

---

## TRIGGER Syntax
```sql
DELIMITER $$
CREATE TRIGGER triggerName
AFTER UPDATE ON TableName
FOR EACH ROW
BEGIN
    IF (OLD.column IS NULL AND NEW.column IS NOT NULL) THEN
        UPDATE OtherTable
        SET count = count + 1
        WHERE id = NEW.id;
    END IF;
END$$
DELIMITER ;
```
- **OLD.column** = value BEFORE update
- **NEW.column** = value AFTER update
- Use `IF ... THEN ... ELSE ... END IF;`

---

## PROCEDURE Syntax
```sql
DELIMITER $$
CREATE PROCEDURE procName(
    IN p_param1 INT,
    IN p_param2 VARCHAR(255)
)
BEGIN
    DECLARE var_name INT;

    SELECT column INTO var_name
    FROM Table
    WHERE condition;

    IF var_name > 0 THEN
        INSERT INTO ...;
        UPDATE ...;
        SELECT 'Success message' AS message;
    ELSE
        SELECT 'Error message' AS message;
    END IF;
END$$
DELIMITER ;
```
- Call with: `CALL procName(value1, value2);`

---

## FUNCTION Syntax
```sql
DELIMITER $$
CREATE FUNCTION funcName(p_param INT) RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE result INT;

    SELECT COUNT(*) INTO result
    FROM Table
    WHERE column = p_param;

    RETURN result;
END$$
DELIMITER ;
```
- Use in SELECT: `SELECT funcName(column) AS alias FROM ...`
- Functions work on individual rows (NOT aggregate)
- Can use in WHERE clause: `WHERE funcName(id) > 0`

---

## Common Patterns

### Students with no leases (LEFT JOIN + COUNT = 0)
```sql
SELECT s.id, s.name, COUNT(l.id) AS numLeases
FROM Student s
LEFT JOIN Lease l ON s.id = l.student_id
GROUP BY s.id, s.name
HAVING COUNT(l.id) = 0;
```

### Average with completed records only
```sql
SELECT id, AVG(DATEDIFF(endDate, startDate)) AS avgDays
FROM Table
WHERE endDate IS NOT NULL
GROUP BY id;
```

### Currently active records
```sql
WHERE dateReturned IS NULL
```

### Expected return date
```sql
DATE_ADD(startDate, INTERVAL days DAY) AS expectedDate
```

---

## Quick Troubleshooting
- **"Unknown column in HAVING"** → Move condition to WHERE
- **Duplicate rows** → Check if you need GROUP BY or remove unnecessary JOIN
- **Can't group by column** → Add it to GROUP BY or use aggregate function
- **Date arithmetic wrong** → Use DATE_ADD with INTERVAL, not plain addition
- **Function not found** → Make sure DELIMITER is set and function created before using

---

## Comparison Operators
- `=` equals
- `!=` or `<>` not equals
- `>` greater than
- `<` less than
- `>=` greater than or equal
- `<=` less than or equal
- `IS NULL` / `IS NOT NULL` for NULL checks

## Logical Operators
- `AND` - both conditions must be true
- `OR` - at least one condition must be true
- `NOT` - negates a condition

---

## Variable Assignment in Procedures/Functions
```sql
DECLARE var_name datatype;           -- declare
SELECT column INTO var_name FROM ... -- assign from query
SET var_name = value;                -- direct assignment
```

## SELECT INTO (for single row results)
```sql
SELECT col1, col2 INTO var1, var2
FROM Table
WHERE condition;
```

---

## Key Reminders
- **Always end statements with semicolon (;)** except when using DELIMITER
- **Use DELIMITER when creating triggers/procedures/functions** to avoid premature execution
- **Column aliases** use `AS` keyword: `SELECT column AS alias`
- **Table aliases** don't need `AS`: `FROM Student s`
- **Prefix parameters** with `p_` to distinguish from column names (convention)
- **User-defined functions ≠ aggregate functions** - can be used in WHERE clause
