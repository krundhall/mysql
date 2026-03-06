-- Kevin Grundhall kegr25 PAGPT25h

-- 1.
CREATE TABLE IF NOT EXISTS Guest(
	guestID varchar(255) primary key,
    Fname varchar(255),
    Lname varchar(255),
    Age INT,
    Phone varchar(255),
    Email varchar(255),
    Country varchar(255)
    );

CREATE TABLE IF NOT EXISTS Room(
	roomID varchar(255) PRIMARY KEY,
    roomType varchar(255),
    pricePerNight INT,
    floorNum INT,
    availableSlots INT
);

CREATE TABLE IF NOT EXISTS Booking(
	bookingID INT AUTO_INCREMENT PRIMARY KEY,
    roomID varchar(255),
    guestID varchar(255),
    checkIn date,
    numOfNights INT,
    checkOut date,
    FOREIGN KEY (roomID) references Room(roomID),
    FOREIGN KEY (guestID) references Guest(guestID));

INSERT INTO Guest (guestID, Fname, Lname, Age, Phone, Email, Country) VALUES
('G001', 'Karl', 'Persson', 33, '070-111', 'karl@mail.com', 'Sweden'),
('G002', 'Nina', 'Koch', 29, '070-222', 'nina@mail.com', 'Germany'),
('G003', 'Tom', 'Walsh', 41, '070-333', 'tom@mail.com', 'Ireland'),
('G004', 'Sara', 'Ali', 27, '070-444', 'sara@mail.com', 'Sweden'),
('G005', 'Leo', 'Marin', 35, '070-555', 'leo@mail.com', 'Spain');

INSERT INTO Room (roomID, roomType, pricePerNight, floorNum, availableSlots) VALUES
('R01', 'Single', 800, 1, 3),
('R02', 'Double', 1200, 2, 3),
('R03', 'Suite', 2500, 4, 2),
('R04', 'Single', 800, 1, 3),
('R05', 'Double', 1200, 3, 3);

INSERT INTO Booking (bookingID, roomID, guestID, checkIn, numOfNights, checkOut) VALUES
(1, 'R01', 'G001', '2024-03-01', 3, '2024-03-04'),
(2, 'R02', 'G002', '2024-03-05', 2, '2024-03-07'),
(3, 'R03', 'G003', '2024-04-10', 5, '2024-04-15'),
(4, 'R01', 'G004', '2024-05-01', 7, NULL),
(5, 'R02', 'G001', '2024-05-03', 4, NULL),
(6, 'R03', 'G002', '2024-05-10', 2, NULL),
(7, 'R04', 'G003', '2024-05-12', 3, NULL),
(8, 'R05', 'G005', '2024-04-20', 6, '2024-04-26'),
(9, 'R01', 'G002', '2024-06-01', 2, NULL),
(10, 'R05', 'G004', '2024-06-05', 3, NULL);


-- 2.
SELECT g.guestID, g.Fname, g.Lname, count(b.bookingID) as numOfBookings
FROM guest g
LEFT JOIN booking b ON g.guestID = b.guestID
GROUP BY g.guestID, g.Fname, g.Lname
HAVING COUNT(b.bookingID) = 0;


-- 3.
SELECT r.roomID, r.roomType, ROUND(AVG(b.numOfNights), 2) as AverageNights
FROM room r
JOIN booking b ON r.roomID = b.roomID
WHERE b.checkOut IS NOT NULL
GROUP BY r.roomID, r.roomType
ORDER BY AverageNights


-- 4.
CREATE VIEW CurrentGuests AS
SELECT b.bookingID, g.Fname, g.Lname,
	   r.roomID, r.roomType, DATE_ADD(b.checkIn, INTERVAL b.numOfNights DAY) AS ExpectedCheckOut
FROM booking b
JOIN guest g ON b.guestID = g.guestID
JOIN room r ON b.roomID = r.roomID
WHERE b.checkOut IS NULL


-- 5.
DELIMITER $$
CREATE TRIGGER T_CHECKOUT
AFTER UPDATE ON Booking FOR EACH ROW
BEGIN
	IF OLD.checkOut IS NULL and NEW.checkout IS NOT NULL THEN
		UPDATE Room
        SET availableSlots = availableSlots + 1
        WHERE roomID = NEW.roomID;
	END IF;
END$$
DELIMITER ;


-- 6.
DELIMITER $$
CREATE PROCEDURE MakeBooking (
	IN p_roomID VARCHAR(255),
    IN p_guestID VARCHAR(255),
    IN p_checkIn DATE,
    IN p_numOfNights INT)
BEGIN
	-- Declare a variable
	DECLARE freeSlots INT;

    -- Check the availableSlots column in room
    SELECT availableSlots INTO freeSlots
    FROM room
    WHERE roomID = p_roomID;

    -- Make IF statement with populated variable
    IF freeSlots > 0 THEN
		-- Insert new booking
		INSERT INTO Booking (roomID, guestID, checkIn, numOfNights)
		VALUES (p_roomID, p_guestID, p_checkIn, p_numOfNights);

        UPDATE Room
        SET availableSlots = availableSlots - 1
        WHERE roomID = p_roomID;

        SELECT 'Row inserted' AS Message;
	ELSE
		SELECT 'Row NOT inserted! No slots available.' AS Message;
	END IF;
END$$
DELIMITER ;


-- 7.
SELECT g.guestID, CONCAT(Fname, ' ', Lname) AS name_, b.bookingID, b.roomID
FROM guest g
LEFT JOIN booking b ON g.guestID = b.guestID
ORDER BY b.bookingID DESC


-- 8.
SELECT
	CONCAT(Fname, ' ', Lname) AS guestName,
    r.roomType,
    DATE_ADD(b.checkIn, INTERVAL b.numOfNights DAY) AS ExpectedCheckOut
FROM guest g
INNER JOIN booking b ON g.guestID = b.guestID
INNER JOIN room r ON r.roomID = b.roomID
WHERE b.checkOut IS NULL
ORDER BY ExpectedCheckOut DESC


-- 9.
DELIMITER $$
CREATE FUNCTION GetOverstayFee(p_bookingID INT)
RETURNS INT
DETERMINISTIC
BEGIN
	DECLARE actualNights INT;
    DECLARE plannedNights INT;

		SELECT DATEDIFF(checkOut, checkIn), numOfNights
		INTO actualNights, plannedNights
		FROM booking
		WHERE p_bookingID = bookingID;

    IF actualNights is NULL THEN
		RETURN 0;
	END IF;

    IF actualNights > plannedNights THEN
		RETURN (actualNights - plannedNights) * 200;
	ELSE
		RETURN 0;
	END IF;

END$$
DELIMITER ;

SELECT b.bookingID, g.Fname, g.Lname,
    DATEDIFF(b.checkOut, b.checkIn) - b.numOfNights AS extraNights,
    GetOverstayFee(b.bookingID) AS totalFee
FROM Booking b
JOIN Guest g ON b.guestID = g.guestID
WHERE GetOverstayFee(b.bookingID) > 0;


-- 10.
DELIMITER $$
CREATE FUNCTION GetBookingCount(p_roomID VARCHAR(255))
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE total INT;
    SELECT COUNT(*) INTO total
    FROM Booking
    WHERE roomID = p_roomID;
    RETURN total;
END$$
DELIMITER ;

SELECT r.roomID, r.roomType, GetBookingCount(r.roomID) AS numOfBookings
FROM Room r
ORDER BY numOfBookings DESC;