use CanyonRanchDB1

--------------------------------------------
-- Query 1: Multi-Table JOIN
--------------------------------------------


SELECT 
    g.GuestID,
    g.FirstName + ' ' + g.LastName AS GuestName,
    p.PropertyName,
    s.ServiceName,
    stf.FirstName + ' ' + stf.LastName AS StaffName,
    sa.ScheduledDateTime
FROM booking.GUEST g
JOIN booking.STAY st ON g.GuestID = st.GuestID
JOIN property.PROPERTY p ON st.PropertyID = p.PropertyID
JOIN service.SERVICEAPPOINTMENT sa ON st.StayID = sa.StayID
JOIN service.SERVICE s ON sa.ServiceID = s.ServiceID
JOIN staff.STAFF stf ON sa.StaffID = stf.StaffID
ORDER BY sa.ScheduledDateTime;



--------------------------------------------
-- Query 2: Aggregate + GROUP BY + HAVING
--------------------------------------------

SELECT 
    s.ServiceName,
    COUNT(sa.AppointmentID) AS TotalAppointments,
    SUM(s.StandardPrice) AS TotalRevenue
FROM service.SERVICE s
JOIN service.SERVICEAPPOINTMENT sa 
    ON s.ServiceID = sa.ServiceID
GROUP BY s.ServiceName
HAVING SUM(s.StandardPrice) > 100
ORDER BY TotalRevenue DESC;


--------------------------------------------
-- Query 3: CTE + Ranking
--------------------------------------------

WITH GuestSpending AS (
    SELECT 
        g.GuestID,
        g.FirstName + ' ' + g.LastName AS GuestName,
        SUM(f.Amount) AS TotalSpent
    FROM booking.GUEST g
    JOIN booking.STAY st ON g.GuestID = st.GuestID
    JOIN billing.GUESTFOLIO f ON st.StayID = f.StayID
    GROUP BY g.GuestID, g.FirstName, g.LastName
)
SELECT 
    GuestID,
    GuestName,
    TotalSpent,
    RANK() OVER (ORDER BY TotalSpent DESC) AS SpendingRank
FROM GuestSpending;



--------------------------------------------
-- Query 4: Window Function
-- Rank guests by total spend per stay
-- and find guests who spent 20% more
-- on a later visit
--------------------------------------------
--------------------------------------------
-- Part 1
--------------------------------------------
WITH GuestSpend AS (
    SELECT 
        s.PropertyID,
        s.StayID,
        s.GuestID,
        g.FirstName,
        g.LastName,
        s.ArrivalDate,
        SUM(se.StandardPrice) AS TotalSpend
    FROM booking.STAY s
    JOIN booking.GUEST g
        ON s.GuestID = g.GuestID
    JOIN service.SERVICEAPPOINTMENT sa
        ON s.StayID = sa.StayID
    JOIN service.SERVICE se
        ON sa.ServiceID = se.ServiceID
    GROUP BY 
        s.PropertyID,
        s.StayID,
        s.GuestID,
        g.FirstName,
        g.LastName,
        s.ArrivalDate
)

SELECT
    PropertyID,
    StayID,
    GuestID,
    FirstName,
    LastName,
    ArrivalDate,
    TotalSpend,

    RANK() OVER (
        PARTITION BY PropertyID
        ORDER BY TotalSpend DESC
    ) AS SpendRank,

    LAG(TotalSpend) OVER (
        PARTITION BY GuestID,propertyID
        ORDER BY ArrivalDate
    ) AS PreviousSpend
FROM GuestSpend;


--Temporary comments
-----database has no records of previous spend of any user, so need to add some repeat customers
--   to show the purrent and previous spent

--------------------------------------------
-- Part 2
-- Query to find whether any customer spend has increased by 20%
--------------------------------------------

WITH GuestSpend AS (
    SELECT 
        s.PropertyID,
        s.StayID,
        s.GuestID,
        g.FirstName,
        g.LastName,
        s.ArrivalDate,
        SUM(se.StandardPrice) AS TotalSpend
    FROM booking.STAY s
    JOIN booking.GUEST g
        ON s.GuestID = g.GuestID
    JOIN service.SERVICEAPPOINTMENT sa
        ON s.StayID = sa.StayID
    JOIN service.SERVICE se
        ON sa.ServiceID = se.ServiceID
    GROUP BY 
        s.PropertyID,
        s.StayID,
        s.GuestID,
        g.FirstName,
        g.LastName,
        s.ArrivalDate
),
SpendCompare AS (
    SELECT
        *,
        LAG(TotalSpend) OVER (
            PARTITION BY GuestID
            ORDER BY ArrivalDate
        ) AS PreviousSpend
    FROM GuestSpend
)
SELECT *
FROM SpendCompare
WHERE PreviousSpend IS NOT NULL
  AND TotalSpend > PreviousSpend * 1.20;

--Temporary comments
--as no repeat customers are entered in database, therefore, no results are shown
-- insert few repeat customers



--------------------------------------------
-- Query 5: Correlated Subquery
-- Find the guest who booked the most
-- appointments with each staff member
--------------------------------------------

SELECT *
FROM (
    SELECT
        st.StaffID,
        st.FirstName AS StaffFirstName,
        st.LastName AS StaffLastName,
        g.GuestID,
        g.FirstName AS GuestFirstName,
        g.LastName AS GuestLastName,
        COUNT(*) AS TotalAppointments
    FROM service.SERVICEAPPOINTMENT sa
    JOIN staff.STAFF st
        ON sa.StaffID = st.StaffID
    JOIN booking.STAY s
        ON sa.StayID = s.StayID
    JOIN booking.GUEST g
        ON s.GuestID = g.GuestID
    GROUP BY
        st.StaffID,
        st.FirstName,
        st.LastName,
        g.GuestID,
        g.FirstName,
        g.LastName
) AS Main
WHERE TotalAppointments = (
    SELECT MAX(AppCount)
    FROM (
        SELECT 
            COUNT(*) AS AppCount
        FROM service.SERVICEAPPOINTMENT sa2
        JOIN booking.STAY s2
            ON sa2.StayID = s2.StayID
        WHERE sa2.StaffID = Main.StaffID
        GROUP BY s2.GuestID
    ) AS Sub
)
ORDER BY StaffID;


--------------------------------------------
-- Query 6: Stored Procedure
-- Name: usp_BookServiceAppointment
--------------------------------------------

CREATE OR ALTER PROCEDURE service.usp_BookServiceAppointment --both is defined at once for errorless performance on multiple device while testing
    @GuestID NCHAR(7),
    @ServiceID NCHAR(7),
    @StaffID NCHAR(7),
    @AppointmentDateTime DATETIME,
    @StayID NCHAR(7)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StayGuestID NCHAR(7),
            @ArrivalDate DATE,
            @DepartureDate DATE,
            @NewAppointmentID NCHAR(7);

    ---------------------------------------------------
    -- 1. Check if Stay exists
    ---------------------------------------------------
    SELECT 
        @StayGuestID = GuestID,
        @ArrivalDate = ArrivalDate,
        @DepartureDate = DepartureDate
    FROM booking.STAY
    WHERE StayID = @StayID;

    IF @StayGuestID IS NULL
    BEGIN
        RAISERROR('StayID does not exist.', 16, 1);
        RETURN;
    END

    ---------------------------------------------------
    -- 2. Check if Stay belongs to Guest
    ---------------------------------------------------
    IF @StayGuestID <> @GuestID
    BEGIN
        RAISERROR('This stay does not belong to the guest.', 16, 1);
        RETURN;
    END

    ---------------------------------------------------
    -- 3. Check if appointment is within stay dates
    ---------------------------------------------------
    IF @AppointmentDateTime < CAST(@ArrivalDate AS DATETIME)
       OR @AppointmentDateTime >= DATEADD(DAY, 1, CAST(@DepartureDate AS DATETIME))
    BEGIN
        RAISERROR('Appointment is outside the stay dates.', 16, 1);
        RETURN;
    END

    ---------------------------------------------------
    -- 4. Check if staff is already booked
    ---------------------------------------------------
    IF EXISTS (
        SELECT 1
        FROM service.SERVICEAPPOINTMENT
        WHERE StaffID = @StaffID
          AND ScheduledDateTime = @AppointmentDateTime
    )
    BEGIN
        RAISERROR('Staff member is already booked at this time.', 16, 1);
        RETURN;
    END

    ---------------------------------------------------
    -- 5. Generate AppointmentID
    ---------------------------------------------------
    SELECT @NewAppointmentID =
        'SA' + RIGHT('000' + CAST(COUNT(*) + 1 AS VARCHAR), 3)
    FROM service.SERVICEAPPOINTMENT;

    ---------------------------------------------------
    -- 6. Insert appointment
    ---------------------------------------------------
    INSERT INTO service.SERVICEAPPOINTMENT (
        AppointmentID,
        StayID,
        ServiceID,
        StaffID,
        ScheduledDateTime,
        Status,
        MedicalAlertFlag
    )
    VALUES (
        @NewAppointmentID,
        @StayID,
        @ServiceID,
        @StaffID,
        @AppointmentDateTime,
        'Scheduled',
        0
    );

    PRINT 'Appointment booked successfully. ID: ' + @NewAppointmentID;
END;
GO

---------------------------------------------------
-- Steps to Book an Appointment
-- Checking the staff details
---------------------------------------------------
select * from staff.STAFF


---------------------------------------------------
-- Checking the services details
---------------------------------------------------
select * from service.SERVICE

---------------------------------------------------
-- Checking the guestID and StayID
---------------------------------------------------
SELECT StayID, GuestID, ArrivalDate, DepartureDate
FROM booking.STAY;

---------------------------------------------------
-- Checking the roomid
---------------------------------------------------
select * from property.ROOM

---------------------------------------------------
-- Booking an appointment
---------------------------------------------------
EXEC service.usp_BookServiceAppointment
    @GuestID = 'G001',
    @ServiceID = 'SVC001',
    @StaffID = 'S002',
    @AppointmentDateTime = '2026-05-03 11:10:00',
    @StayID = 'ST001';

---------------------------------------------------
-- Confirming the booked appointment 
---------------------------------------------------
SELECT *
FROM service.SERVICEAPPOINTMENT;