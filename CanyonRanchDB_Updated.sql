-- =============================================================
-- Canyon Ranch 2026 — SQL Server Full Schema
-- Microsoft SQL Server / SSMS
-- =============================================================

CREATE DATABASE CanyonRanchDB;
GO

USE CanyonRanchDB;
GO

-- =============================================================
-- SCHEMAS
-- =============================================================
CREATE SCHEMA booking;
GO
CREATE SCHEMA property;
GO
CREATE SCHEMA service;
GO
CREATE SCHEMA billing;
GO
CREATE SCHEMA package;
GO
CREATE SCHEMA staff;
GO
CREATE SCHEMA activity;
GO
CREATE SCHEMA products;
GO

-- =============================================================
-- TABLES
-- =============================================================

-- ---------------------------------------------------------------
-- 1. STAFF (no dependencies)
-- ---------------------------------------------------------------
CREATE TABLE staff.STAFF (
  StaffID          NCHAR(7)     NOT NULL,
  FirstName        NVARCHAR(25) NOT NULL,
  LastName         NVARCHAR(25) NOT NULL,
  HireDate         DATE         NOT NULL,
  EmploymentStatus NVARCHAR(25) NOT NULL,
  Role             NVARCHAR(25) NOT NULL,
  PRIMARY KEY (StaffID)
);

-- ---------------------------------------------------------------
-- 2. PGCOORDINATOR (depends on: STAFF)
-- ---------------------------------------------------------------
-- ON DELETE NO ACTION / ON UPDATE CASCADE:
--   A coordinator row is tied to a staff record. If a staff member
--   is deleted, we block it (NO ACTION) to preserve coordinator
--   assignment history. If a StaffID is corrected, cascade keeps
--   the coordinator record in sync automatically.
-- ---------------------------------------------------------------
CREATE TABLE staff.PGCOORDINATOR (
  StaffID NCHAR(7) NOT NULL,
  PRIMARY KEY (StaffID),
  FOREIGN KEY (StaffID) REFERENCES staff.STAFF(StaffID)
    ON DELETE NO ACTION
    ON UPDATE CASCADE
);


-- ---------------------------------------------------------------
-- 3. GUEST (no dependencies)
-- ---------------------------------------------------------------
CREATE TABLE booking.GUEST (
  GuestID       NCHAR(7)     NOT NULL,
  FirstName     NVARCHAR(25) NOT NULL,
  LastName      NVARCHAR(25) NOT NULL,
  DateOfBirth   DATE         NOT NULL,
  Gender        NVARCHAR(10) NOT NULL,
  Email         NVARCHAR(25) NOT NULL,
  Street        NVARCHAR(25) NOT NULL,
  City          NVARCHAR(25) NOT NULL,
  State         NVARCHAR(25) NOT NULL,
  ZipCode       NCHAR(20)    NOT NULL,
  No_Of_Visits  INT          NOT NULL,
  IsFirstTime   BIT          NOT NULL DEFAULT 0,
  PRIMARY KEY (GuestID)
);


-- ---------------------------------------------------------------
-- 4. GUEST_PHONENO (depends on: GUEST)
-- ---------------------------------------------------------------
-- ON DELETE CASCADE / ON UPDATE CASCADE:
--   Phone numbers have no meaning without their guest. If a guest
--   is deleted, their phone numbers should be removed automatically
--   (CASCADE). ID corrections cascade through as well.
-- ---------------------------------------------------------------
CREATE TABLE booking.GUEST_PHONENO (
  PhoneNo NCHAR(20) NOT NULL,
  GuestID NCHAR(7)  NOT NULL,
  PRIMARY KEY (PhoneNo, GuestID),
  FOREIGN KEY (GuestID) REFERENCES booking.GUEST(GuestID)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);


-- ---------------------------------------------------------------
-- 5. RESERVATION (depends on: PGCOORDINATOR and GUEST)
-- ---------------------------------------------------------------
-- ON DELETE NO ACTION / ON UPDATE CASCADE:
--   A reservation must always have a Guest and an assigned coordinator.
--   Deleting a coordinator and Guest should be blocked (NO ACTION) while
--   active reservations exist. StaffID and GuestID updates cascade through.
-- ---------------------------------------------------------------
CREATE TABLE booking.RESERVATION (
  ReservationID   NCHAR(7)     NOT NULL,
  ArrivalDate     DATE         NOT NULL,
  DepartureDate   DATE         NOT NULL,
  NoOfGuest       INT          NOT NULL CHECK (NoOfGuest > 0),
  PackageSelected NVARCHAR(25),
  PropertyType    NVARCHAR(25),
  RoomType        NVARCHAR(25),
  StaffID         NCHAR(7)     NOT NULL,
  GuestID       NCHAR(7)       NOT NULL,
  PRIMARY KEY (ReservationID),
  FOREIGN KEY (GuestID) REFERENCES booking.Guest(GuestID)
    ON DELETE NO ACTION
    ON UPDATE CASCADE,
  FOREIGN KEY (StaffID) REFERENCES staff.PGCOORDINATOR(StaffID)
    ON DELETE NO ACTION
    ON UPDATE CASCADE
);


-- ---------------------------------------------------------------
-- 6. CENTMEMBERSHIP (depends on: GUEST)
-- ---------------------------------------------------------------
-- ON DELETE NO ACTION / ON UPDATE CASCADE:
--   Membership records have financial and discount history value.
--   Deleting a guest while membership records exist is blocked
--   (NO ACTION) to preserve audit trails. ID updates cascade.
-- ---------------------------------------------------------------
CREATE TABLE booking.CENTMEMBERSHIP (
  MembershipID    NCHAR(7)     NOT NULL,
  GuestID         NCHAR(7)     NOT NULL,
  MembershipSDate DATE         NOT NULL,
  MembershipEDate DATE         NOT NULL,
  DiscountRate    DECIMAL(5,2) NOT NULL,
  RoomDiscount    DECIMAL(5,2) NOT NULL,
  ServiceDiscount DECIMAL(5,2) NOT NULL,
  MinStayExempt   INT          NOT NULL,
  PRIMARY KEY (MembershipID, GuestID),
  FOREIGN KEY (GuestID) REFERENCES booking.GUEST(GuestID)
    ON DELETE NO ACTION
    ON UPDATE CASCADE
);

-- ---------------------------------------------------------------
-- 7. PROPERTY (no dependencies)
-- ---------------------------------------------------------------
CREATE TABLE property.PROPERTY (
  PropertyID   NCHAR(7)     NOT NULL,
  PropertyName NVARCHAR(25) NOT NULL,
  Location     NVARCHAR(25) NOT NULL,
  PropertyType NVARCHAR(25) NOT NULL,
  PRIMARY KEY (PropertyID)
);

-- ---------------------------------------------------------------
-- 8. ROOM (depends on: PROPERTY)
-- ---------------------------------------------------------------
-- ON DELETE NO ACTION / ON UPDATE CASCADE:
--   Rooms cannot exist without a property. Deleting a property
--   that still has rooms is blocked (NO ACTION). PropertyID
--   corrections cascade to all room records.
-- ---------------------------------------------------------------
CREATE TABLE property.ROOM (
  RoomID     NCHAR(7)      NOT NULL,
  RoomNo     NVARCHAR(25)  NOT NULL,
  RoomType   NVARCHAR(25)  NOT NULL,
  Capacity   INT           NOT NULL,
  BaseRate   DECIMAL(10,2) NOT NULL,
  PropertyID NCHAR(7)      NOT NULL,
  PRIMARY KEY (RoomID),
  FOREIGN KEY (PropertyID) REFERENCES property.PROPERTY(PropertyID)
    ON DELETE NO ACTION
    ON UPDATE CASCADE
);

-- ---------------------------------------------------------------
-- 9. DEPARTMENT (depends on: PROPERTY)
-- ---------------------------------------------------------------
-- ON DELETE NO ACTION / ON UPDATE CASCADE:
--   Departments are operationally tied to a property. Deleting a
--   property with active departments is blocked (NO ACTION).
--   PropertyID updates cascade through.
-- ---------------------------------------------------------------
CREATE TABLE property.DEPARTMENT (
  DepartmentID NCHAR(7)      NOT NULL,
  DeptBudget   DECIMAL(15,2),
  DirFirstName NVARCHAR(25),
  DirLastName  NVARCHAR(25),
  PropertyID   NCHAR(7)      NOT NULL,
  PRIMARY KEY (DepartmentID),
  FOREIGN KEY (PropertyID) REFERENCES property.PROPERTY(PropertyID)
    ON DELETE NO ACTION
    ON UPDATE CASCADE
);

-- ---------------------------------------------------------------
-- 10. PACKAGE (no dependencies)
-- ---------------------------------------------------------------
CREATE TABLE package.PACKAGE (
  PackageID   NCHAR(7)     NOT NULL,
  PackageName NVARCHAR(25) NOT NULL,
  Season      NVARCHAR(25),
  RoomType    NVARCHAR(25),
  NoOfNights  INT,
  PartySize   INT,
  PRIMARY KEY (PackageID)
);

-- ---------------------------------------------------------------
-- 11. SERVICEVOUCHER (depends on: PACKAGE)
-- ---------------------------------------------------------------
-- ON DELETE CASCADE / ON UPDATE CASCADE:
--   Vouchers are part of a package definition. If a package is
--   retired and deleted, its vouchers have no standalone value
--   and should be removed (CASCADE).
-- ---------------------------------------------------------------
CREATE TABLE package.SERVICEVOUCHER (
  VoucherType           NCHAR(7)     NOT NULL,
  PackageID             NCHAR(7)     NOT NULL,
  DollarAllowance       DECIMAL(10,2),
  ServiceCountAllowance INT,
  PRIMARY KEY (VoucherType, PackageID),
  FOREIGN KEY (PackageID) REFERENCES package.PACKAGE(PackageID)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

-- ---------------------------------------------------------------
-- 12. STAY (depends on: GUEST, PROPERTY, PACKAGE, PGCOORDINATOR)
-- ---------------------------------------------------------------
-- ON DELETE NO ACTION / ON UPDATE CASCADE (GuestID, PropertyID, StaffID):
-- ON DELETE NO ACTION / ON UPDATE CASCADE (GuestID, PropertyID, StaffID):
--   A stay is a core business transaction — deleting a guest,
--   property, or coordinator while stay records exist is blocked
--   (NO ACTION) to preserve operational and billing history.
-- ON DELETE SET NULL / ON UPDATE CASCADE (PackageID):
--   Package is optional on a stay. If a package is removed from
--   the system, the stay record is retained but PackageID is
--   cleared (SET NULL) rather than losing the stay history.
-- ---------------------------------------------------------------
CREATE TABLE booking.STAY (
  StayID        NCHAR(7) NOT NULL,
  ArrivalDate   DATE     NOT NULL,
  DepartureDate DATE     NOT NULL,
  PartySize     INT      NOT NULL,
  GuestID       NCHAR(7) NOT NULL,
  PropertyID    NCHAR(7) NOT NULL,
  PackageID     NCHAR(7),
  StaffID       NCHAR(7) NOT NULL,
  PRIMARY KEY (StayID),
  FOREIGN KEY (GuestID)    REFERENCES booking.GUEST(GuestID)
    ON DELETE NO ACTION
    ON UPDATE CASCADE,
  FOREIGN KEY (PropertyID) REFERENCES property.PROPERTY(PropertyID)
    ON DELETE NO ACTION
    ON UPDATE CASCADE,
  FOREIGN KEY (PackageID)  REFERENCES package.PACKAGE(PackageID)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  FOREIGN KEY (StaffID)    REFERENCES staff.PGCOORDINATOR(StaffID)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION    -- NO ACTION avoids cascade cycle via PGCOORDINATOR -> STAFF
);

-- ---------------------------------------------------------------
-- 13. SERVICECATEGORY (no dependencies)
-- ---------------------------------------------------------------
CREATE TABLE service.SERVICECATEGORY (
  CategoryID   NCHAR(7)     NOT NULL,
  CategoryName NVARCHAR(25) NOT NULL,
  PRIMARY KEY (CategoryID)
);

-- ---------------------------------------------------------------
-- 14. SERVICECATEGORY_SUBCATEGORY (depends on: SERVICECATEGORY)
-- ---------------------------------------------------------------
-- ON DELETE CASCADE / ON UPDATE CASCADE:
--   Subcategories are child values of a category. Removing a
--   category removes its subcategory entries as well (CASCADE).
-- ---------------------------------------------------------------
CREATE TABLE service.SERVICECATEGORY_SUBCATEGORY (
  CategoryID  NCHAR(7) NOT NULL,
  SubCategory NVARCHAR(25) NOT NULL,
  PRIMARY KEY (CategoryID, SubCategory),
  FOREIGN KEY (CategoryID) REFERENCES service.SERVICECATEGORY(CategoryID)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

-- ---------------------------------------------------------------
-- 15. SERVICE (depends on: SERVICECATEGORY)
-- ---------------------------------------------------------------
-- ON DELETE NO ACTION / ON UPDATE CASCADE:
--   Services are linked to categories for classification. Deleting
--   a category that still has services is blocked (NO ACTION) to
--   avoid orphaned service records.
-- ---------------------------------------------------------------
CREATE TABLE service.SERVICE (
  ServiceID       NCHAR(7)      NOT NULL,
  ServiceName     NVARCHAR(25)  NOT NULL,
  Description     NVARCHAR(MAX),
  DurationMinutes INT           NOT NULL,
  StandardPrice   DECIMAL(10,2) NOT NULL,
  IsComplimentary BIT           NOT NULL DEFAULT 0,
  CategoryID      NCHAR(7)      NOT NULL,
  PRIMARY KEY (ServiceID),
  FOREIGN KEY (CategoryID) REFERENCES service.SERVICECATEGORY(CategoryID)
    ON DELETE NO ACTION
    ON UPDATE CASCADE
);


-- ---------------------------------------------------------------
-- 16. DELIVERS (depends on: STAFF, SERVICE)
-- ---------------------------------------------------------------
-- ON DELETE CASCADE / ON UPDATE CASCADE (both FKs):
--   A qualification record has no meaning without both the staff
--   member and the service it references. If either is removed,
--   the qualification record is removed too (CASCADE).
-- ---------------------------------------------------------------
CREATE TABLE service.DELIVERS (
  StaffID   NCHAR(7) NOT NULL,
  ServiceID NCHAR(7) NOT NULL,
  PRIMARY KEY (StaffID, ServiceID),
  FOREIGN KEY (StaffID)   REFERENCES staff.STAFF(StaffID)
    ON DELETE NO ACTION
    ON UPDATE CASCADE,
  FOREIGN KEY (ServiceID) REFERENCES service.SERVICE(ServiceID)
    ON DELETE NO ACTION
    ON UPDATE CASCADE
);


-- ---------------------------------------------------------------
-- 17. SERVICEAPPOINTMENT (depends on: STAY, SERVICE, STAFF)
-- ---------------------------------------------------------------
-- ON DELETE NO ACTION / ON UPDATE CASCADE (all FKs):
--   Appointment records are billing and medical history. Deleting
--   a stay, service, or staff member while appointments exist is
--   blocked (NO ACTION). All ID corrections cascade through.
-- ---------------------------------------------------------------
CREATE TABLE service.SERVICEAPPOINTMENT (
  AppointmentID INT NOT NULL IDENTITY(1,1),
  StayID            NCHAR(7)     NOT NULL,
  ServiceID         NCHAR(7)     NOT NULL,
  StaffID           NCHAR(7)     NOT NULL,
  ScheduledDateTime DATETIME     NOT NULL,
  Status            NVARCHAR(25),
  MedicalAlertFlag  BIT          NOT NULL DEFAULT 0,
  PRIMARY KEY (AppointmentID),
  FOREIGN KEY (StayID)    REFERENCES booking.STAY(StayID)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  FOREIGN KEY (ServiceID) REFERENCES service.SERVICE(ServiceID)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  FOREIGN KEY (StaffID)   REFERENCES staff.STAFF(StaffID)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
);

-- ---------------------------------------------------------------
-- 18. PRODUCTS (no dependencies)
-- ---------------------------------------------------------------
CREATE TABLE products.PRODUCTS (
  ProductID   NCHAR(7)      NOT NULL,
  ProductName NVARCHAR(25)  NOT NULL,
  Category    NVARCHAR(25),
  UnitPrice   DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (ProductID)
);

-- ---------------------------------------------------------------
-- 19. ACTIVITY (depends on: PROPERTY)
-- ---------------------------------------------------------------
-- ON DELETE NO ACTION / ON UPDATE CASCADE:
--   Activities are hosted within a property. Deleting a property record while
--   activity records exist is blocked (NO ACTION) to preserve the
--   guest's activity history. PropertyID updates cascade.
-- ---------------------------------------------------------------
CREATE TABLE activity.ACTIVITY (
  ActivityID        NCHAR(7)     NOT NULL,
  Title             NVARCHAR(25) NOT NULL,
  ScheduledDateTime DATETIME     NOT NULL,
  MaxCapacity       INT          NOT NULL,
  Location          NVARCHAR(25),
  Instructor        NVARCHAR(25),
  PropertyID            NCHAR(7)     NOT NULL,
  PRIMARY KEY (ActivityID),
  FOREIGN KEY (PropertyID) REFERENCES property.Property(PropertyID)
    ON DELETE NO ACTION
    ON UPDATE CASCADE
);

-- ---------------------------------------------------------------
-- 20. ACTIVITYATTENDANCE (depends on: ACTIVITY,GUEST)
-- ---------------------------------------------------------------
-- ON DELETE CASCADE / ON UPDATE CASCADE (ActivityID):
--   Attendance records belong entirely to an activity. If the
--   activity is deleted, all attendance records for it are
--   removed automatically (CASCADE).
-- ON DELETE NO ACTION / ON UPDATE NO ACTION (GuestID):
--   A guest record must not be deleted while attendance records
--   reference it — block deletion (NO ACTION) to preserve the
--   guest's activity history.
-- ---------------------------------------------------------------
CREATE TABLE activity.ACTIVITYATTENDANCE (
  ActivityID       NCHAR(7)     NOT NULL,
  GuestID          NCHAR(7)     NOT NULL,
  AttendanceStatus NVARCHAR(25),
  CheckInTime      DATETIME,
  CheckOutTime     DATETIME,
  PRIMARY KEY (ActivityID, GuestID),
  FOREIGN KEY (ActivityID) REFERENCES activity.ACTIVITY(ActivityID)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  FOREIGN KEY (GuestID) REFERENCES booking.GUEST(GuestID)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
);


-- ---------------------------------------------------------------
-- 21. GUESTFOLIO (depends on: STAY, PRODUCTS)
-- ---------------------------------------------------------------
-- ON DELETE NO ACTION / ON UPDATE CASCADE (StayID):
--   Folio records are financial transactions tied to a stay.
--   Deleting a stay with folio entries is blocked (NO ACTION).
-- ON DELETE SET NULL / ON UPDATE CASCADE (ProductID):
--   ProductID is optional. If a product is removed from the
--   catalogue, the folio charge record is kept but the product
--   reference is cleared (SET NULL).
-- ---------------------------------------------------------------
CREATE TABLE billing.GUESTFOLIO (
  FolioID         NCHAR(7)      NOT NULL,
  Amount          DECIMAL(10,2) NOT NULL,
  TransactionDate DATE          NOT NULL,
  PaymentMethod   NVARCHAR(25),
  TransactionType NVARCHAR(25),
  StayID          NCHAR(7)      NOT NULL,
  ProductID       NCHAR(7),
  PRIMARY KEY (FolioID),
  FOREIGN KEY (StayID)    REFERENCES booking.STAY(StayID)
    ON DELETE NO ACTION
    ON UPDATE CASCADE,
  FOREIGN KEY (ProductID) REFERENCES products.PRODUCTS(ProductID)
    ON DELETE SET NULL
    ON UPDATE CASCADE
);

-- ---------------------------------------------------------------
-- 22. TRANSACTION (depends on: GUEST)
-- ---------------------------------------------------------------
-- ON DELETE NO ACTION / ON UPDATE CASCADE:
--   Transaction records are financial history for a guest.
--   Deleting a guest with transaction history is blocked
--   (NO ACTION). GuestID updates cascade.
-- ---------------------------------------------------------------
CREATE TABLE billing.[TRANSACTION] (
  TransactionID     NCHAR(7)     NOT NULL,
  TransactionStatus NVARCHAR(25),
  GuestID           NCHAR(7)     NOT NULL,
  PRIMARY KEY (TransactionID),
  FOREIGN KEY (GuestID) REFERENCES booking.GUEST(GuestID)
    ON DELETE NO ACTION
    ON UPDATE CASCADE
);

-- ---------------------------------------------------------------
-- 23. PAYS (depends on: TRANSACTION, GUESTFOLIO)
-- ---------------------------------------------------------------
-- ON DELETE NO ACTION / ON UPDATE CASCADE (both FKs):
--   Payment linkage records must not be silently removed. Deleting
--   a transaction or folio while a PAYS record exists is blocked
--   (NO ACTION). ID corrections cascade.
-- ---------------------------------------------------------------
CREATE TABLE billing.PAYS (
  TransactionID NCHAR(7) NOT NULL,
  FolioID       NCHAR(7) NOT NULL,
  PRIMARY KEY (TransactionID, FolioID),
  FOREIGN KEY (TransactionID) REFERENCES billing.[TRANSACTION](TransactionID)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  FOREIGN KEY (FolioID) REFERENCES billing.GUESTFOLIO(FolioID)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
);

-- ---------------------------------------------------------------
-- 24. QUESTIONNAIRE (Regular entity — standalone with own PK)
-- ---------------------------------------------------------------
CREATE TABLE booking.QUESTIONNAIRE (
  QuestionnaireID  NCHAR(7) NOT NULL,
  AnyRecentSurgery BIT      NOT NULL DEFAULT 0,
  IsPregnant       BIT      NOT NULL DEFAULT 0,
  PRIMARY KEY (QuestionnaireID)
);

-- ---------------------------------------------------------------
-- 25. HEALTHDATA (Associative entity — links QUESTIONNAIRE to RESERVATION)
-- ---------------------------------------------------------------
-- ON DELETE NO ACTION / ON UPDATE CASCADE (both FKs):
--   Health data is a medical record that must not be silently
--   deleted. Removing a questionnaire or reservation while health
--   data exists is blocked (NO ACTION). ID updates cascade.
-- ---------------------------------------------------------------
CREATE TABLE booking.HEALTHDATA (
  QuestionnaireID NCHAR(7) NOT NULL,
  ReservationID   NCHAR(7) NOT NULL,
  PRIMARY KEY (QuestionnaireID, ReservationID),
  FOREIGN KEY (QuestionnaireID) REFERENCES booking.QUESTIONNAIRE(QuestionnaireID)
    ON DELETE NO ACTION
    ON UPDATE CASCADE,
  FOREIGN KEY (ReservationID) REFERENCES booking.RESERVATION(ReservationID)
    ON DELETE NO ACTION
    ON UPDATE CASCADE
);

-- ---------------------------------------------------------------
-- 26. PREFERENCE (depends on: RESERVATION)
-- ---------------------------------------------------------------
-- ON DELETE CASCADE / ON UPDATE CASCADE:
--   Preferences are personal settings attached to a reservation.
--   If a reservation is removed, its preferences are removed too
--   (CASCADE) as they have no meaning without it.
-- ---------------------------------------------------------------
CREATE TABLE booking.PREFERENCE (
  ReservationID   NCHAR(7)     NOT NULL,
  MassagePressure NVARCHAR(25),
  TherapistGender NVARCHAR(25),
  TimeOfDay       NVARCHAR(25),
  PRIMARY KEY (ReservationID),
  FOREIGN KEY (ReservationID) REFERENCES booking.RESERVATION(ReservationID)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

-- =============================================================
-- NON-CLUSTERED INDEXES
-- =============================================================

-- Index on SERVICEAPPOINTMENT.ScheduledDateTime
-- Justification: The most common operational query is "what appointments
-- are scheduled today / this week?" Coordinators and therapists filter
-- appointments by date/time constantly. A non-clustered index on
-- ScheduledDateTime dramatically speeds up these range scans without
-- affecting the clustered primary key on AppointmentID.
CREATE NONCLUSTERED INDEX IX_ServiceAppointment_ScheduledDateTime
  ON service.SERVICEAPPOINTMENT (ScheduledDateTime);
GO

-- Index on STAY.GuestID
-- Justification: Guest lookup is the entry point for nearly every
-- front-desk operation — "find all stays for this guest." GuestID
-- appears as a FK filter in STAY, GUESTFOLIO, and TRANSACTION queries.
-- Indexing it on STAY avoids full table scans when retrieving a
-- guest's stay history.
CREATE NONCLUSTERED INDEX IX_Stay_GuestID
  ON booking.STAY (GuestID);
GO

-- Index on GUESTFOLIO.StayID
-- Justification: Billing queries routinely aggregate or list all
-- charges for a given stay (e.g. to produce a checkout invoice).
-- StayID is the primary FK filter on GUESTFOLIO and without an index
-- every invoice generation performs a full folio table scan.
CREATE NONCLUSTERED INDEX IX_GuestFolio_StayID
  ON billing.GUESTFOLIO (StayID);
GO

-- =============================================================
-- VIEW 1 (Operational): vw_GuestStayDetail
-- =============================================================
-- Business value:
--   Program coordinators need a single, readable summary of a guest's
--   current or most recent stay without writing multi-table joins.
--   This view surfaces guest identity, stay dates and property,
--   every service appointment with its status and medical alert flag,
--   and the guest's service preferences — all in one place. It enables
--   coordinators to quickly review a guest's schedule, flag medical
--   alerts before appointments, and check preference notes without
--   navigating multiple screens or tables.
-- Joins: booking.GUEST, booking.STAY, service.SERVICEAPPOINTMENT,
--        service.SERVICE, booking.RESERVATION, booking.PREFERENCE
-- =============================================================
CREATE VIEW booking.vw_GuestStayDetail AS
SELECT
  g.GuestID,
  g.FirstName                              AS GuestFirstName,
  g.LastName                               AS GuestLastName,
  g.Email,
  s.StayID,
  s.ArrivalDate,
  s.DepartureDate,
  s.PartySize,
  prop.PropertyName,
  sa.AppointmentID,
  sa.ScheduledDateTime                     AS AppointmentDateTime,
  svc.ServiceName,
  sa.Status                                AS AppointmentStatus,
  sa.MedicalAlertFlag,
  pref.MassagePressure,
  pref.TherapistGender,
  pref.TimeOfDay
    FROM booking.GUEST                     AS g
    INNER JOIN booking.STAY                AS s    ON g.GuestID       = s.GuestID
    INNER JOIN property.PROPERTY           AS prop ON s.PropertyID    = prop.PropertyID
    INNER JOIN service.SERVICEAPPOINTMENT  AS sa   ON s.StayID          = sa.StayID
    INNER JOIN service.SERVICE             AS svc  ON sa.ServiceID    = svc.ServiceID
    INNER JOIN booking.RESERVATION         AS r    ON r.GuestID       = g.GuestID
    LEFT JOIN booking.PREFERENCE           AS pref ON r.ReservationID = pref.ReservationID;
GO
 
-- Sample query — retrieve full detail for a specific guest's most recent stay:
-- SELECT *
-- FROM booking.vw_GuestStayDetail
-- WHERE GuestID = N'G000001'
-- ORDER BY ArrivalDate DESC;
 
-- =============================================================
-- VIEW 2 (Analytical): vw_ServiceUtilizationByHour
-- =============================================================
-- Business value:
--   Management needs to understand when demand for services peaks
--   across each property so they can optimise staff scheduling,
--   room allocation, and promotional offers. This view aggregates
--   appointment counts by service category, property, and hour of
--   day, making it easy to identify high-demand windows (e.g.
--   "Massage bookings spike at 10am at Tucson") and quiet periods
--   where capacity could be filled with promotions or discounts.
-- Aggregate: COUNT on AppointmentID grouped by category, property,
--            and extracted hour of ScheduledDateTime.
-- =============================================================
CREATE VIEW service.vw_ServiceUtilizationByHour AS
SELECT
  sc.CategoryName,
  prop.PropertyName,
  DATEPART(HOUR, sa.ScheduledDateTime)     AS HourOfDay,
  COUNT(sa.AppointmentID)                  AS AppointmentCount
    FROM service.SERVICEAPPOINTMENT  AS sa
    INNER JOIN booking.STAY                AS s    ON sa.StayID     = s.StayID
    INNER JOIN property.PROPERTY           AS prop ON s.PropertyID  = prop.PropertyID
    INNER JOIN service.SERVICE             AS svc  ON sa.ServiceID  = svc.ServiceID
    INNER JOIN service.SERVICECATEGORY     AS sc   ON svc.CategoryID = sc.CategoryID
GROUP BY
  sc.CategoryName,
  prop.PropertyName,
  DATEPART(HOUR, sa.ScheduledDateTime);
GO
 
-- Sample query — find peak hours for each category at each property,
-- ordered to surface the busiest slots first:
-- SELECT *
-- FROM service.vw_ServiceUtilizationByHour
-- ORDER BY PropertyName, CategoryName, AppointmentCount DESC;