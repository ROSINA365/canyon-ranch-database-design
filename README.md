
# Canyon Ranch: Relational Database and Data Warehouse Design

End-to-end database project for **Canyon Ranch**, a luxury wellness resort with five properties and more than 500 spa, health and hospitality services. We designed and built a normalized SQL Server database, wrote advanced analytical queries, designed a star-schema data warehouse, and assessed data privacy risks under HIPAA, CCPA and GDPR.

**Course:** DSCI 723 – Data Management and Warehousing, University of South Dakota (Spring 2026)
**Tools:** Microsoft SQL Server · SSMS · T-SQL · ERDPlus

## Business problem

Canyon Ranch ran on disconnected systems: a legacy lodging system, a standalone guest application, paper-based activity tracking and no integrated point-of-sale system. Staff could not see a full guest profile, analyze service use, or make data-driven decisions. Our goal was one integrated database that supports daily operations and management reporting.

## What we built

### 1. Conceptual design (ER model)

- ER diagram in ERDPlus covering guests, stays, properties, rooms, staff, services, packages, activities, products, billing and health data.
- **STAY** is the central entity. It links reservations, service bookings, charges and activities.
- Weak entities (membership, service vouchers) and associative entities (service appointments, activity attendance, payments) handle dependent and many-to-many relationships.

### 2. Relational schema and normalization

- Mapped the ER model to **26 tables** across 8 schemas: booking, property, service, billing, package, staff, activity and products.
- Listed functional dependencies and normalized each table to **Third Normal Form (3NF)**.
- Mapped multivalued attributes (guest phone numbers, service subcategories) to their own tables.

### 3. Physical implementation in SQL Server

- Primary keys, foreign keys and CHECK constraints.
- A documented **ON DELETE / ON UPDATE** rule for every foreign key. For example, deleting a guest with stay history is blocked to protect billing records, while phone numbers are removed with the guest.
- **3 non-clustered indexes** on the most common lookups: appointments by date, stays by guest and charges by stay.
- Realistic sample data for every table, loaded in the correct dependency order.

### 4. Advanced SQL queries

| # | Technique | Business question |
|---|---|---|
| 1 | Multi-table JOIN (6 tables) | Full appointment schedule: guest, property, service and staff |
| 2 | Aggregate + GROUP BY / HAVING | Which services bring in the most revenue? |
| 3 | CTE + RANK | Ranking guests by total spending |
| 4 | Window functions (RANK, LAG) | Which repeat guests spent 20% more on a later visit? |
| 5 | Correlated subquery | Which guest booked the most appointments with each staff member? |
| 6 | Stored procedure | `usp_BookServiceAppointment`: books an appointment after checking that the stay exists, belongs to the guest, falls within the stay dates and does not double-book the staff member |

### 5. Views

- **`vw_GuestStayDetail` (operational):** one screen per guest showing stay dates, property, every appointment, medical alert flags and service preferences, so coordinators don't have to write joins.
- **`vw_ServiceUtilizationByHour` (analytical):** appointment counts by service category, property and hour of day, to plan staff schedules and spot quiet periods for promotions.

### 6. Data warehouse (star schema)

- **Fact table:** `fact_ServiceAppointment`, with one row per service appointment.
- **Dimensions:** Date, Guest, Service, Property, Staff and Package. They use integer surrogate keys and keep the original business keys so records can be traced back.
- **Slowly Changing Dimension Type 2** on Guest (StartDate, EndDate, IsCurrent), so changes to guest details keep their history.
- Warehouse queries:
  - **ROLLUP:** revenue by category, property and year.
  - **GROUPING SETS:** appointment counts at four levels.
  - **3-month rolling average:** flags peak months.
  - **Revenue per guest by visit frequency tier:** supports loyalty decisions.

### 7. Data privacy and ethics

- Classified every table into four sensitivity tiers: Public, Internal, Confidential and Restricted/PHI.
- Analyzed five privacy risk scenarios, such as insider access to health data and re-identifying guests by combining data. Each has a recommended fix: role-based access, row-level security, encryption, audit triggers and a data retention policy.
- Assessed obligations under **HIPAA, CCPA/CPRA and GDPR**.

## How to run

1. Open SQL Server Management Studio (SSMS).
2. Run `sql/01_schema_and_sample_data.sql`. It creates the database, schemas, tables, indexes, views and sample data.
3. Run the queries in `sql/02_advanced_queries.sql`.

`sql/03_revised_schema.sql` is our later, corrected design. GUEST now links to RESERVATION in the right direction, a DELIVERS table records which staff can perform which service, and appointment IDs are auto-numbered.

## Team

Group 5: Sanjay Kumar Singh, Abigail Torome, Swetha Lnu, Isaac Wainaina and **Sharon Rosina Wamalwa**
Supervised by Dr. Bartlomiej Hanus

**My role:**

- Team coordinator: ran meetings, kept the task tracker, and compiled and checked the final report against the rubric.
- Merged the team's sub-diagrams into the final integrated ER diagram and audited every relationship for correct cardinality and participation.
- Created and tested the database backup (.bak) and confirmed it restored cleanly in SSMS.
- Cross-reviewed the CREATE TABLE scripts and SQL queries for correctness.

This is an academic case study. All data is fictional sample data.
