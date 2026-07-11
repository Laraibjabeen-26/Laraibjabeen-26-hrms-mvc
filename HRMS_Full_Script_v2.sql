
-- HRMS (Human Resource Management System) Database - VERSION 2
-- Updated per manager's feedback:
--   1. New lookup tables: AllowanceTypes, DeductionTypes
--   2. SalaryAllowances / SalaryDeductions now key off EmployeeID
--      (NOT PayrollID) so allowances/deductions can be entered
--      BEFORE a payroll run exists.
--   3. PayrollID is no longer chosen/typed anywhere up front.
--      It is generated automatically, AFTER the system has:
--         Step 1: read the employee's Basic Salary
--         Step 2: totalled the employee's allowances
--         Step 3: totalled the employee's deductions
--      ...only then does INSERT INTO Payroll create the PayrollID,
--      via usp_GeneratePayroll (see stored procedure section).

CREATE DATABASE HRMS;
GO
USE HRms;
GO

-- 1. Departments 
CREATE TABLE Departments (
    DepartmentID INT IDENTITY(1,1) PRIMARY KEY,
    DepartmentName VARCHAR(100) NOT NULL,
    Location VARCHAR(100) NULL
);
GO

-- 2. Designations 
CREATE TABLE Designations (
    DesignationID INT IDENTITY(1,1) PRIMARY KEY,
    DesignationName VARCHAR(100) NOT NULL,
    DepartmentID INT NOT NULL,
    CONSTRAINT FK_Designations_Departments
        FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID)
);
GO

-- 3. Employees -----------------------------------------------
CREATE TABLE Employees (
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Gender CHAR(1) NOT NULL,
    DateOfBirth DATE NOT NULL,
    DateOfJoining DATE NOT NULL,
    DepartmentID INT NOT NULL,
    DesignationID INT NOT NULL,
    Email VARCHAR(100) NOT NULL,
    Phone VARCHAR(20) NULL,
    BasicSalary DECIMAL(10,2) NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_Employees_Departments
        FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID),
    CONSTRAINT FK_Employees_Designations
        FOREIGN KEY (DesignationID) REFERENCES Designations(DesignationID)
);
GO

-- 4. Attendance ------------------------------------------------
CREATE TABLE Attendance (
    AttendanceID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT NOT NULL,
    AttendanceDate DATE NOT NULL,
    Status VARCHAR(10) NOT NULL,   -- Present, Absent, Leave, HalfDay
    InTime TIME NULL,
    OutTime TIME NULL,
    CONSTRAINT FK_Attendance_Employees
        FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID)
);
GO

-- 5. LeaveTypes --------------------------------------------------
CREATE TABLE LeaveTypes (
    LeaveTypeID INT IDENTITY(1,1) PRIMARY KEY,
    LeaveTypeName VARCHAR(50) NOT NULL,
    MaxDaysAllowed INT NOT NULL
);
GO

-- 6. LeaveApplications ----------------------------------------
CREATE TABLE LeaveApplications (
    LeaveApplicationID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT NOT NULL,
    LeaveTypeID INT NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    TotalDays INT NOT NULL,
    Reason VARCHAR(200) NULL,
    Status VARCHAR(20) NOT NULL DEFAULT 'Pending',  -- Pending, Approved, Rejected
    AppliedDate DATE NOT NULL,
    CONSTRAINT FK_LeaveApplications_Employees
        FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID),
    CONSTRAINT FK_LeaveApplications_LeaveTypes
        FOREIGN KEY (LeaveTypeID) REFERENCES LeaveTypes(LeaveTypeID)
);
GO

-- 7. Payroll -------------------------------------------------------
-- NOTE: PayrollID is IDENTITY and is only ever created by
-- usp_GeneratePayroll, AFTER salary + allowances + deductions
-- have already been checked/combined. Nothing else inserts here.
CREATE TABLE Payroll (
    PayrollID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT NOT NULL,
    PayMonth INT NOT NULL,
    PayYear INT NOT NULL,
    BasicSalary DECIMAL(10,2) NOT NULL,
    GrossSalary DECIMAL(10,2) NOT NULL,
    TotalDeductions DECIMAL(10,2) NOT NULL,
    NetSalary DECIMAL(10,2) NOT NULL,
    PaymentDate DATE NULL,
    CONSTRAINT FK_Payroll_Employees
        FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID),
    CONSTRAINT UQ_Payroll_EmployeeMonth UNIQUE (EmployeeID, PayMonth, PayYear)
);
GO

-- 8. AllowanceTypes  (NEW - lookup table, feeds the Employee Form dropdown via GET) ----
CREATE TABLE AllowanceTypes (
    AllowanceTypeID INT IDENTITY(1,1) PRIMARY KEY,
    AllowanceTypeName VARCHAR(50) NOT NULL UNIQUE
);
GO

-- 9. DeductionTypes  (NEW - lookup table, feeds the Employee Form dropdown via GET) ----
CREATE TABLE DeductionTypes (
    DeductionTypeID INT IDENTITY(1,1) PRIMARY KEY,
    DeductionTypeName VARCHAR(50) NOT NULL UNIQUE
);
GO

-- 10. SalaryAllowances (CHANGED) --------------------------------
-- Now tied to EmployeeID + AllowanceTypeID + Month/Year, so an
-- allowance can be entered for an employee BEFORE any payroll
-- run exists. PayrollID is filled in LATER, once payroll for that
-- employee/month is generated (nullable until then).
CREATE TABLE SalaryAllowances (
    AllowanceID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT NOT NULL,
    AllowanceTypeID INT NOT NULL,
    PayMonth INT NOT NULL,
    PayYear INT NOT NULL,
    Amount DECIMAL(10,2) NOT NULL,
    PayrollID INT NULL,
    CONSTRAINT FK_SalaryAllowances_Employees
        FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID),
    CONSTRAINT FK_SalaryAllowances_AllowanceTypes
        FOREIGN KEY (AllowanceTypeID) REFERENCES AllowanceTypes(AllowanceTypeID),
    CONSTRAINT FK_SalaryAllowances_Payroll
        FOREIGN KEY (PayrollID) REFERENCES Payroll(PayrollID)
);
GO

-- 11. SalaryDeductions (CHANGED) --------------------------------
-- Same idea as SalaryAllowances: keyed off EmployeeID, not PayrollID.
CREATE TABLE SalaryDeductions (
    DeductionID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT NOT NULL,
    DeductionTypeID INT NOT NULL,
    PayMonth INT NOT NULL,
    PayYear INT NOT NULL,
    Amount DECIMAL(10,2) NOT NULL,
    PayrollID INT NULL,
    CONSTRAINT FK_SalaryDeductions_Employees
        FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID),
    CONSTRAINT FK_SalaryDeductions_DeductionTypes
        FOREIGN KEY (DeductionTypeID) REFERENCES DeductionTypes(DeductionTypeID),
    CONSTRAINT FK_SalaryDeductions_Payroll
        FOREIGN KEY (PayrollID) REFERENCES Payroll(PayrollID)
);
GO

-- 12. Users -----------------------------------------------------
CREATE TABLE Users (
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT NOT NULL,
    Username VARCHAR(50) NOT NULL UNIQUE,
    PasswordHash VARCHAR(200) NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedDate DATE NOT NULL,
    CONSTRAINT FK_Users_Employees
        FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID)
);
GO

-- 13. Roles -----------------------------------------------------
CREATE TABLE Roles (
    RoleID INT IDENTITY(1,1) PRIMARY KEY,
    RoleName VARCHAR(50) NOT NULL
);
GO

-- 14. UserRoles (many-to-many between Users and Roles) --------
CREATE TABLE UserRoles (
    UserID INT NOT NULL,
    RoleID INT NOT NULL,
    PRIMARY KEY (UserID, RoleID),
    CONSTRAINT FK_UserRoles_Users
        FOREIGN KEY (UserID) REFERENCES Users(UserID),
    CONSTRAINT FK_UserRoles_Roles
        FOREIGN KEY (RoleID) REFERENCES Roles(RoleID)
);
GO

-- INSERTING SAMPLE DATA

-- INSERTING SAMPLE DATA


-- Departments (6 rows)
INSERT INTO Departments (DepartmentName, Location) VALUES
('Human Resources', 'Lahore'),
('Information Technology', 'Karachi'),
('Finance', 'Islamabad'),
('Sales & Marketing', 'Rawalpindi'),
('Operations', 'Faisalabad'),
('Customer Support', 'Multan');
GO

-- Designations (12 rows)
INSERT INTO Designations (DesignationName, DepartmentID) VALUES
('HR Manager', 1),
('HR Executive', 1),
('Software Engineer', 2),
('Senior Software Engineer', 2),
('IT Support Officer', 2),
('Accountant', 3),
('Finance Manager', 3),
('Sales Executive', 4),
('Marketing Manager', 4),
('Operations Manager', 5),
('Warehouse Supervisor', 5),
('Customer Support Officer', 6);
GO

-- Employees (40 rows)
INSERT INTO Employees (FirstName, LastName, Gender, DateOfBirth, DateOfJoining, DepartmentID, DesignationID, Email, Phone, BasicSalary, IsActive) VALUES
('Ahmed', 'Butt', 'M', '1993-04-08', '2019-10-13', 6, 12, 'ahmed.butt1@company.com', '03862458591', 90000, 1),
('Ali', 'Siddiqui', 'M', '1985-02-07', '2020-04-21', 5, 10, 'ali.siddiqui2@company.com', '03714335942', 110000, 1),
('Bilal', 'Yousaf', 'F', '1992-08-19', '2020-07-23', 1, 1, 'bilal.yousaf3@company.com', '03898090293', 60000, 1),
('Sara', 'Aslam', 'M', '1991-06-04', '2019-07-09', 4, 8, 'sara.aslam4@company.com', '03456770619', 90000, 1),
('Ayesha', 'Aslam', 'M', '1999-09-04', '2024-06-15', 4, 8, 'ayesha.aslam5@company.com', '03705918715', 130000, 1),
('Hamza', 'Shah', 'F', '1991-12-03', '2019-04-04', 6, 12, 'hamza.shah6@company.com', '03985855124', 45000, 1),
('Usman', 'Farooq', 'M', '1997-05-15', '2022-07-25', 3, 6, 'usman.farooq7@company.com', '03476960453', 50000, 1),
('Fatima', 'Aslam', 'M', '1990-09-24', '2020-05-16', 2, 4, 'fatima.aslam8@company.com', '03485528972', 110000, 1),
('Zainab', 'Yousaf', 'M', '1995-01-08', '2023-08-11', 1, 2, 'zainab.yousaf9@company.com', '03515491946', 45000, 1),
('Omar', 'Iqbal', 'F', '1991-11-16', '2021-03-21', 6, 12, 'omar.iqbal10@company.com', '03185443951', 50000, 1),
('Hassan', 'Farooq', 'F', '1998-10-13', '2021-01-11', 2, 3, 'hassan.farooq11@company.com', '03659279821', 45000, 1),
('Sana', 'Malik', 'M', '1989-11-06', '2023-06-11', 6, 12, 'sana.malik12@company.com', '03762065818', 75000, 1),
('Nida', 'Qureshi', 'F', '1993-09-28', '2024-04-14', 1, 1, 'nida.qureshi13@company.com', '03875476583', 130000, 1),
('Kashif', 'Hussain', 'M', '1994-07-06', '2021-07-18', 1, 2, 'kashif.hussain14@company.com', '03643997281', 90000, 1),
('Rabia', 'Butt', 'F', '1991-03-12', '2023-04-11', 2, 5, 'rabia.butt15@company.com', '03999897858', 45000, 1),
('Tariq', 'Shah', 'F', '2000-01-04', '2024-03-17', 3, 7, 'tariq.shah16@company.com', '03301971823', 50000, 1),
('Imran', 'Mirza', 'M', '1987-12-16', '2023-07-30', 1, 1, 'imran.mirza17@company.com', '03168973915', 90000, 1),
('Mahnoor', 'Raza', 'F', '1998-04-18', '2023-03-27', 6, 12, 'mahnoor.raza18@company.com', '03916229731', 75000, 1),
('Faisal', 'Abbasi', 'F', '1999-02-08', '2020-04-05', 1, 2, 'faisal.abbasi19@company.com', '03024860684', 90000, 1),
('Iqra', 'Farooq', 'M', '1987-12-21', '2019-05-01', 2, 3, 'iqra.farooq20@company.com', '03046543670', 45000, 1),
('Adeel', 'Akhtar', 'M', '1993-11-16', '2020-03-14', 5, 10, 'adeel.akhtar21@company.com', '03928930103', 50000, 1),
('Sadia', 'Rehman', 'F', '1991-02-04', '2022-09-11', 4, 9, 'sadia.rehman22@company.com', '03547897151', 75000, 1),
('Waqas', 'Malik', 'M', '1986-07-24', '2020-11-25', 1, 1, 'waqas.malik23@company.com', '03244191175', 90000, 1),
('Amna', 'Baig', 'M', '1998-03-09', '2021-08-05', 2, 3, 'amna.baig24@company.com', '03562642635', 45000, 1),
('Salman', 'Yousaf', 'M', '1987-04-06', '2021-04-12', 4, 9, 'salman.yousaf25@company.com', '03277728339', 45000, 1),
('Mariam', 'Raza', 'F', '1985-07-09', '2024-03-12', 4, 9, 'mariam.raza26@company.com', '03549164991', 50000, 1),
('Junaid', 'Iqbal', 'F', '1991-01-19', '2023-02-15', 5, 10, 'junaid.iqbal27@company.com', '03956261415', 45000, 1),
('Hina', 'Malik', 'F', '1990-01-17', '2019-06-14', 2, 3, 'hina.malik28@company.com', '03762140194', 110000, 1),
('Danish', 'Farooq', 'F', '1988-10-08', '2022-03-31', 5, 10, 'danish.farooq29@company.com', '03792375453', 75000, 1),
('Sobia', 'Mirza', 'F', '1993-04-22', '2023-01-06', 3, 6, 'sobia.mirza30@company.com', '03337640184', 50000, 1),
('Asad', 'Javed', 'F', '1995-02-01', '2021-07-27', 5, 10, 'asad.javed31@company.com', '03094576135', 90000, 1),
('Farah', 'Aslam', 'M', '1996-02-08', '2021-01-26', 3, 6, 'farah.aslam32@company.com', '03566075395', 90000, 1),
('Yasir', 'Akhtar', 'M', '1994-11-04', '2024-04-06', 2, 4, 'yasir.akhtar33@company.com', '03142795765', 110000, 1),
('Nadia', 'Yousaf', 'M', '1993-05-20', '2020-03-07', 6, 12, 'nadia.yousaf34@company.com', '03265428914', 90000, 1),
('Zeeshan', 'Rehman', 'F', '1986-02-21', '2021-05-17', 3, 6, 'zeeshan.rehman35@company.com', '03006596150', 130000, 1),
('Komal', 'Chaudhry', 'F', '1990-12-15', '2022-02-03', 6, 12, 'komal.chaudhry36@company.com', '03711162230', 45000, 1),
('Shahzad', 'Sheikh', 'M', '1986-06-19', '2022-02-05', 2, 4, 'shahzad.sheikh37@company.com', '03161701771', 60000, 1),
('Rida', 'Abbasi', 'M', '1996-04-22', '2020-05-26', 6, 12, 'rida.abbasi38@company.com', '03457817881', 90000, 1),
('Naveed', 'Chaudhry', 'M', '1990-03-14', '2019-02-20', 2, 5, 'naveed.chaudhry39@company.com', '03427907400', 130000, 1),
('Bushra', 'Farooq', 'F', '1990-12-04', '2021-02-22', 1, 2, 'bushra.farooq40@company.com', '03284348276', 130000, 1);
GO

-- Attendance (40 employees x 30 days = 1200 rows)
INSERT INTO Attendance (EmployeeID, AttendanceDate, Status, InTime, OutTime) VALUES
(1, '2026-06-01', 'Leave', NULL, NULL),
(1, '2026-06-02', 'Present', '09:01:00', '17:01:00'),
(1, '2026-06-03', 'Present', '09:01:00', '17:03:00'),
(1, '2026-06-04', 'Present', '09:00:00', '17:02:00'),
(1, '2026-06-05', 'Present', '09:04:00', '17:03:00'),
(1, '2026-06-06', 'Present', '09:04:00', '17:02:00'),
(1, '2026-06-07', 'Leave', NULL, NULL),
(1, '2026-06-08', 'Present', '09:02:00', '17:01:00'),
(1, '2026-06-09', 'Present', '09:02:00', '17:00:00'),
(1, '2026-06-10', 'Present', '09:03:00', '17:02:00'),
(1, '2026-06-11', 'Present', '09:02:00', '17:03:00'),
(1, '2026-06-12', 'Present', '09:04:00', '17:00:00'),
(1, '2026-06-13', 'Present', '09:04:00', '17:01:00'),
(1, '2026-06-14', 'Present', '09:05:00', '17:03:00'),
(1, '2026-06-15', 'Present', '09:04:00', '17:05:00'),
(1, '2026-06-16', 'Present', '09:05:00', '17:05:00'),
(1, '2026-06-17', 'Present', '09:02:00', '17:03:00'),
(1, '2026-06-18', 'Present', '09:05:00', '17:02:00'),
(1, '2026-06-19', 'Present', '09:05:00', '17:00:00'),
(1, '2026-06-20', 'Present', '09:02:00', '17:04:00'),
(1, '2026-06-21', 'Present', '09:03:00', '17:02:00'),
(1, '2026-06-22', 'Present', '09:02:00', '17:04:00'),
(1, '2026-06-23', 'Present', '09:03:00', '17:05:00'),
(1, '2026-06-24', 'Leave', NULL, NULL),
(1, '2026-06-25', 'Present', '09:01:00', '17:04:00'),
(1, '2026-06-26', 'Present', '09:03:00', '17:04:00'),
(1, '2026-06-27', 'Present', '09:02:00', '17:02:00'),
(1, '2026-06-28', 'Present', '09:04:00', '17:04:00'),
(1, '2026-06-29', 'Present', '09:03:00', '17:03:00'),
(1, '2026-06-30', 'Present', '09:01:00', '17:04:00'),
(2, '2026-06-01', 'Present', '09:05:00', '17:01:00'),
(2, '2026-06-02', 'Present', '09:02:00', '17:04:00'),
(2, '2026-06-03', 'Present', '09:04:00', '17:02:00'),
(2, '2026-06-04', 'Present', '09:01:00', '17:05:00'),
(2, '2026-06-05', 'Present', '09:01:00', '17:01:00'),
(2, '2026-06-06', 'Present', '09:01:00', '17:03:00'),
(2, '2026-06-07', 'Present', '09:00:00', '17:03:00'),
(2, '2026-06-08', 'Present', '09:05:00', '17:04:00'),
(2, '2026-06-09', 'Present', '09:05:00', '17:03:00'),
(2, '2026-06-10', 'Present', '09:01:00', '17:01:00'),
(2, '2026-06-11', 'Present', '09:00:00', '17:00:00'),
(2, '2026-06-12', 'Present', '09:01:00', '17:01:00'),
(2, '2026-06-13', 'Present', '09:05:00', '17:04:00'),
(2, '2026-06-14', 'Present', '09:04:00', '17:01:00'),
(2, '2026-06-15', 'Leave', NULL, NULL),
(2, '2026-06-16', 'Present', '09:01:00', '17:03:00'),
(2, '2026-06-17', 'Present', '09:04:00', '17:04:00'),
(2, '2026-06-18', 'Present', '09:03:00', '17:04:00'),
(2, '2026-06-19', 'Present', '09:04:00', '17:03:00'),
(2, '2026-06-20', 'Present', '09:04:00', '17:03:00'),
(2, '2026-06-21', 'Absent', NULL, NULL),
(2, '2026-06-22', 'Present', '09:03:00', '17:03:00'),
(2, '2026-06-23', 'Present', '09:01:00', '17:05:00'),
(2, '2026-06-24', 'Present', '09:04:00', '17:03:00'),
(2, '2026-06-25', 'Present', '09:02:00', '17:03:00'),
(2, '2026-06-26', 'Present', '09:02:00', '17:01:00'),
(2, '2026-06-27', 'Present', '09:02:00', '17:04:00'),
(2, '2026-06-28', 'Present', '09:01:00', '17:01:00'),
(2, '2026-06-29', 'Present', '09:01:00', '17:05:00'),
(2, '2026-06-30', 'Present', '09:03:00', '17:03:00'),
(3, '2026-06-01', 'Present', '09:03:00', '17:03:00'),
(3, '2026-06-02', 'Present', '09:03:00', '17:03:00'),
(3, '2026-06-03', 'Leave', NULL, NULL),
(3, '2026-06-04', 'Present', '09:05:00', '17:00:00'),
(3, '2026-06-05', 'Absent', NULL, NULL),
(3, '2026-06-06', 'Present', '09:03:00', '17:03:00'),
(3, '2026-06-07', 'Present', '09:02:00', '17:02:00'),
(3, '2026-06-08', 'Present', '09:03:00', '17:04:00'),
(3, '2026-06-09', 'Present', '09:04:00', '17:04:00'),
(3, '2026-06-10', 'Absent', NULL, NULL),
(3, '2026-06-11', 'Present', '09:02:00', '17:03:00'),
(3, '2026-06-12', 'Present', '09:03:00', '17:02:00'),
(3, '2026-06-13', 'Present', '09:03:00', '17:05:00'),
(3, '2026-06-14', 'Present', '09:03:00', '17:01:00'),
(3, '2026-06-15', 'HalfDay', '09:00:00', '13:00:00'),
(3, '2026-06-16', 'Present', '09:03:00', '17:04:00'),
(3, '2026-06-17', 'Present', '09:00:00', '17:00:00'),
(3, '2026-06-18', 'Present', '09:01:00', '17:03:00'),
(3, '2026-06-19', 'Present', '09:02:00', '17:03:00'),
(3, '2026-06-20', 'Present', '09:03:00', '17:02:00'),
(3, '2026-06-21', 'Present', '09:03:00', '17:02:00'),
(3, '2026-06-22', 'Present', '09:03:00', '17:02:00'),
(3, '2026-06-23', 'Present', '09:03:00', '17:00:00'),
(3, '2026-06-24', 'Present', '09:00:00', '17:02:00'),
(3, '2026-06-25', 'Present', '09:00:00', '17:05:00'),
(3, '2026-06-26', 'Present', '09:00:00', '17:01:00'),
(3, '2026-06-27', 'Present', '09:00:00', '17:04:00'),
(3, '2026-06-28', 'Present', '09:01:00', '17:03:00'),
(3, '2026-06-29', 'Present', '09:04:00', '17:01:00'),
(3, '2026-06-30', 'Present', '09:02:00', '17:02:00'),
(4, '2026-06-01', 'Present', '09:04:00', '17:05:00'),
(4, '2026-06-02', 'Present', '09:01:00', '17:02:00'),
(4, '2026-06-03', 'Present', '09:00:00', '17:02:00'),
(4, '2026-06-04', 'Present', '09:03:00', '17:03:00'),
(4, '2026-06-05', 'Leave', NULL, NULL),
(4, '2026-06-06', 'Present', '09:04:00', '17:05:00'),
(4, '2026-06-07', 'Present', '09:01:00', '17:00:00'),
(4, '2026-06-08', 'Present', '09:02:00', '17:05:00'),
(4, '2026-06-09', 'Present', '09:00:00', '17:04:00'),
(4, '2026-06-10', 'Present', '09:02:00', '17:04:00'),
(4, '2026-06-11', 'Present', '09:02:00', '17:00:00'),
(4, '2026-06-12', 'Present', '09:02:00', '17:00:00'),
(4, '2026-06-13', 'Present', '09:03:00', '17:00:00'),
(4, '2026-06-14', 'Present', '09:02:00', '17:05:00'),
(4, '2026-06-15', 'Absent', NULL, NULL),
(4, '2026-06-16', 'Present', '09:01:00', '17:03:00'),
(4, '2026-06-17', 'Present', '09:04:00', '17:05:00'),
(4, '2026-06-18', 'Present', '09:04:00', '17:03:00'),
(4, '2026-06-19', 'Present', '09:05:00', '17:04:00'),
(4, '2026-06-20', 'Present', '09:01:00', '17:00:00'),
(4, '2026-06-21', 'Present', '09:03:00', '17:01:00'),
(4, '2026-06-22', 'Present', '09:04:00', '17:04:00'),
(4, '2026-06-23', 'Present', '09:02:00', '17:00:00'),
(4, '2026-06-24', 'Present', '09:02:00', '17:01:00'),
(4, '2026-06-25', 'Present', '09:02:00', '17:02:00'),
(4, '2026-06-26', 'Present', '09:04:00', '17:05:00'),
(4, '2026-06-27', 'Absent', NULL, NULL),
(4, '2026-06-28', 'Present', '09:04:00', '17:01:00'),
(4, '2026-06-29', 'Present', '09:05:00', '17:03:00'),
(4, '2026-06-30', 'Present', '09:01:00', '17:05:00'),
(5, '2026-06-01', 'Present', '09:05:00', '17:03:00'),
(5, '2026-06-02', 'Present', '09:00:00', '17:00:00'),
(5, '2026-06-03', 'Present', '09:03:00', '17:05:00'),
(5, '2026-06-04', 'Present', '09:05:00', '17:04:00'),
(5, '2026-06-05', 'Present', '09:04:00', '17:04:00'),
(5, '2026-06-06', 'Present', '09:05:00', '17:04:00'),
(5, '2026-06-07', 'Present', '09:05:00', '17:03:00'),
(5, '2026-06-08', 'Present', '09:02:00', '17:01:00'),
(5, '2026-06-09', 'Present', '09:01:00', '17:02:00'),
(5, '2026-06-10', 'Present', '09:04:00', '17:05:00'),
(5, '2026-06-11', 'Present', '09:01:00', '17:05:00'),
(5, '2026-06-12', 'Present', '09:05:00', '17:04:00'),
(5, '2026-06-13', 'HalfDay', '09:00:00', '13:00:00'),
(5, '2026-06-14', 'Present', '09:02:00', '17:00:00'),
(5, '2026-06-15', 'Present', '09:02:00', '17:01:00'),
(5, '2026-06-16', 'Present', '09:02:00', '17:00:00'),
(5, '2026-06-17', 'Present', '09:01:00', '17:02:00'),
(5, '2026-06-18', 'Present', '09:00:00', '17:04:00'),
(5, '2026-06-19', 'Present', '09:01:00', '17:05:00'),
(5, '2026-06-20', 'Absent', NULL, NULL),
(5, '2026-06-21', 'Present', '09:00:00', '17:04:00'),
(5, '2026-06-22', 'Present', '09:03:00', '17:03:00'),
(5, '2026-06-23', 'Present', '09:00:00', '17:02:00'),
(5, '2026-06-24', 'Leave', NULL, NULL),
(5, '2026-06-25', 'Present', '09:00:00', '17:03:00'),
(5, '2026-06-26', 'Present', '09:04:00', '17:05:00'),
(5, '2026-06-27', 'Present', '09:01:00', '17:01:00'),
(5, '2026-06-28', 'Present', '09:02:00', '17:00:00'),
(5, '2026-06-29', 'HalfDay', '09:00:00', '13:00:00'),
(5, '2026-06-30', 'Present', '09:03:00', '17:04:00'),
(6, '2026-06-01', 'Present', '09:04:00', '17:01:00'),
(6, '2026-06-02', 'Present', '09:03:00', '17:03:00'),
(6, '2026-06-03', 'Leave', NULL, NULL),
(6, '2026-06-04', 'Present', '09:04:00', '17:03:00'),
(6, '2026-06-05', 'Present', '09:04:00', '17:00:00'),
(6, '2026-06-06', 'Present', '09:05:00', '17:00:00'),
(6, '2026-06-07', 'Leave', NULL, NULL),
(6, '2026-06-08', 'Present', '09:01:00', '17:02:00'),
(6, '2026-06-09', 'Present', '09:01:00', '17:01:00'),
(6, '2026-06-10', 'Present', '09:00:00', '17:01:00'),
(6, '2026-06-11', 'Present', '09:03:00', '17:05:00'),
(6, '2026-06-12', 'Present', '09:02:00', '17:00:00'),
(6, '2026-06-13', 'Present', '09:05:00', '17:02:00'),
(6, '2026-06-14', 'Present', '09:03:00', '17:00:00'),
(6, '2026-06-15', 'Present', '09:02:00', '17:05:00'),
(6, '2026-06-16', 'Present', '09:01:00', '17:03:00'),
(6, '2026-06-17', 'Present', '09:01:00', '17:05:00'),
(6, '2026-06-18', 'Present', '09:02:00', '17:01:00'),
(6, '2026-06-19', 'Present', '09:01:00', '17:02:00'),
(6, '2026-06-20', 'Present', '09:04:00', '17:02:00'),
(6, '2026-06-21', 'Present', '09:03:00', '17:05:00'),
(6, '2026-06-22', 'Present', '09:03:00', '17:02:00'),
(6, '2026-06-23', 'Present', '09:03:00', '17:03:00'),
(6, '2026-06-24', 'Present', '09:00:00', '17:03:00'),
(6, '2026-06-25', 'Present', '09:04:00', '17:02:00'),
(6, '2026-06-26', 'Present', '09:01:00', '17:05:00'),
(6, '2026-06-27', 'Present', '09:04:00', '17:04:00'),
(6, '2026-06-28', 'HalfDay', '09:00:00', '13:00:00'),
(6, '2026-06-29', 'HalfDay', '09:00:00', '13:00:00'),
(6, '2026-06-30', 'Present', '09:02:00', '17:04:00'),
(7, '2026-06-01', 'Present', '09:01:00', '17:03:00'),
(7, '2026-06-02', 'Present', '09:03:00', '17:02:00'),
(7, '2026-06-03', 'Present', '09:04:00', '17:03:00'),
(7, '2026-06-04', 'Present', '09:03:00', '17:00:00'),
(7, '2026-06-05', 'Present', '09:03:00', '17:02:00'),
(7, '2026-06-06', 'Present', '09:00:00', '17:01:00'),
(7, '2026-06-07', 'Present', '09:05:00', '17:03:00'),
(7, '2026-06-08', 'Present', '09:03:00', '17:04:00'),
(7, '2026-06-09', 'Present', '09:00:00', '17:02:00'),
(7, '2026-06-10', 'Present', '09:00:00', '17:03:00'),
(7, '2026-06-11', 'Absent', NULL, NULL),
(7, '2026-06-12', 'Present', '09:00:00', '17:05:00'),
(7, '2026-06-13', 'Absent', NULL, NULL),
(7, '2026-06-14', 'Present', '09:00:00', '17:01:00'),
(7, '2026-06-15', 'Present', '09:04:00', '17:03:00'),
(7, '2026-06-16', 'Present', '09:00:00', '17:01:00'),
(7, '2026-06-17', 'Present', '09:01:00', '17:02:00'),
(7, '2026-06-18', 'Present', '09:05:00', '17:03:00'),
(7, '2026-06-19', 'Present', '09:05:00', '17:04:00'),
(7, '2026-06-20', 'Present', '09:05:00', '17:01:00'),
(7, '2026-06-21', 'Present', '09:00:00', '17:04:00'),
(7, '2026-06-22', 'Present', '09:01:00', '17:00:00'),
(7, '2026-06-23', 'Present', '09:00:00', '17:05:00'),
(7, '2026-06-24', 'Present', '09:03:00', '17:05:00'),
(7, '2026-06-25', 'Present', '09:05:00', '17:02:00'),
(7, '2026-06-26', 'Present', '09:03:00', '17:03:00'),
(7, '2026-06-27', 'Present', '09:04:00', '17:01:00'),
(7, '2026-06-28', 'Present', '09:04:00', '17:04:00'),
(7, '2026-06-29', 'Present', '09:01:00', '17:00:00'),
(7, '2026-06-30', 'Present', '09:03:00', '17:02:00'),
(8, '2026-06-01', 'Leave', NULL, NULL),
(8, '2026-06-02', 'Present', '09:00:00', '17:02:00'),
(8, '2026-06-03', 'Present', '09:04:00', '17:04:00'),
(8, '2026-06-04', 'HalfDay', '09:00:00', '13:00:00'),
(8, '2026-06-05', 'Present', '09:01:00', '17:03:00'),
(8, '2026-06-06', 'Present', '09:02:00', '17:02:00'),
(8, '2026-06-07', 'Present', '09:04:00', '17:03:00'),
(8, '2026-06-08', 'Present', '09:02:00', '17:01:00'),
(8, '2026-06-09', 'HalfDay', '09:00:00', '13:00:00'),
(8, '2026-06-10', 'Present', '09:03:00', '17:01:00'),
(8, '2026-06-11', 'Absent', NULL, NULL),
(8, '2026-06-12', 'Present', '09:02:00', '17:05:00'),
(8, '2026-06-13', 'Present', '09:03:00', '17:03:00'),
(8, '2026-06-14', 'HalfDay', '09:00:00', '13:00:00'),
(8, '2026-06-15', 'Present', '09:05:00', '17:01:00'),
(8, '2026-06-16', 'Present', '09:00:00', '17:01:00'),
(8, '2026-06-17', 'Present', '09:04:00', '17:02:00'),
(8, '2026-06-18', 'Absent', NULL, NULL),
(8, '2026-06-19', 'Absent', NULL, NULL),
(8, '2026-06-20', 'Present', '09:04:00', '17:03:00'),
(8, '2026-06-21', 'Present', '09:01:00', '17:03:00'),
(8, '2026-06-22', 'Absent', NULL, NULL),
(8, '2026-06-23', 'HalfDay', '09:00:00', '13:00:00'),
(8, '2026-06-24', 'Present', '09:02:00', '17:02:00'),
(8, '2026-06-25', 'Present', '09:03:00', '17:05:00'),
(8, '2026-06-26', 'Present', '09:02:00', '17:05:00'),
(8, '2026-06-27', 'Absent', NULL, NULL),
(8, '2026-06-28', 'Present', '09:02:00', '17:05:00'),
(8, '2026-06-29', 'Present', '09:03:00', '17:04:00'),
(8, '2026-06-30', 'Present', '09:00:00', '17:01:00'),
(9, '2026-06-01', 'Present', '09:02:00', '17:01:00'),
(9, '2026-06-02', 'Present', '09:03:00', '17:00:00'),
(9, '2026-06-03', 'Present', '09:05:00', '17:00:00'),
(9, '2026-06-04', 'Present', '09:05:00', '17:02:00'),
(9, '2026-06-05', 'Leave', NULL, NULL),
(9, '2026-06-06', 'Present', '09:00:00', '17:02:00'),
(9, '2026-06-07', 'Present', '09:03:00', '17:01:00'),
(9, '2026-06-08', 'Present', '09:03:00', '17:04:00'),
(9, '2026-06-09', 'Present', '09:01:00', '17:01:00'),
(9, '2026-06-10', 'Present', '09:04:00', '17:03:00'),
(9, '2026-06-11', 'Present', '09:01:00', '17:03:00'),
(9, '2026-06-12', 'Leave', NULL, NULL),
(9, '2026-06-13', 'Present', '09:03:00', '17:05:00'),
(9, '2026-06-14', 'Present', '09:02:00', '17:05:00'),
(9, '2026-06-15', 'Present', '09:03:00', '17:02:00'),
(9, '2026-06-16', 'Present', '09:01:00', '17:00:00'),
(9, '2026-06-17', 'Present', '09:02:00', '17:04:00'),
(9, '2026-06-18', 'Present', '09:03:00', '17:05:00'),
(9, '2026-06-19', 'Present', '09:02:00', '17:01:00'),
(9, '2026-06-20', 'HalfDay', '09:00:00', '13:00:00'),
(9, '2026-06-21', 'Absent', NULL, NULL),
(9, '2026-06-22', 'Present', '09:03:00', '17:04:00'),
(9, '2026-06-23', 'Present', '09:02:00', '17:05:00'),
(9, '2026-06-24', 'Present', '09:05:00', '17:03:00'),
(9, '2026-06-25', 'Present', '09:04:00', '17:05:00'),
(9, '2026-06-26', 'Present', '09:00:00', '17:04:00'),
(9, '2026-06-27', 'Present', '09:02:00', '17:01:00'),
(9, '2026-06-28', 'Present', '09:02:00', '17:01:00'),
(9, '2026-06-29', 'Present', '09:04:00', '17:02:00'),
(9, '2026-06-30', 'Present', '09:05:00', '17:05:00'),
(10, '2026-06-01', 'Present', '09:01:00', '17:05:00'),
(10, '2026-06-02', 'Present', '09:05:00', '17:05:00'),
(10, '2026-06-03', 'Present', '09:03:00', '17:00:00'),
(10, '2026-06-04', 'Present', '09:05:00', '17:01:00'),
(10, '2026-06-05', 'Present', '09:02:00', '17:02:00'),
(10, '2026-06-06', 'Present', '09:01:00', '17:01:00'),
(10, '2026-06-07', 'Present', '09:04:00', '17:02:00'),
(10, '2026-06-08', 'Present', '09:02:00', '17:01:00'),
(10, '2026-06-09', 'Present', '09:03:00', '17:02:00'),
(10, '2026-06-10', 'Present', '09:02:00', '17:00:00'),
(10, '2026-06-11', 'Present', '09:00:00', '17:01:00'),
(10, '2026-06-12', 'Present', '09:01:00', '17:05:00'),
(10, '2026-06-13', 'Present', '09:03:00', '17:04:00'),
(10, '2026-06-14', 'Present', '09:03:00', '17:00:00'),
(10, '2026-06-15', 'Present', '09:00:00', '17:03:00'),
(10, '2026-06-16', 'Present', '09:05:00', '17:05:00'),
(10, '2026-06-17', 'Present', '09:03:00', '17:05:00'),
(10, '2026-06-18', 'Leave', NULL, NULL),
(10, '2026-06-19', 'Present', '09:01:00', '17:03:00'),
(10, '2026-06-20', 'Present', '09:04:00', '17:02:00'),
(10, '2026-06-21', 'Leave', NULL, NULL),
(10, '2026-06-22', 'Present', '09:00:00', '17:05:00'),
(10, '2026-06-23', 'Present', '09:05:00', '17:02:00'),
(10, '2026-06-24', 'Present', '09:00:00', '17:01:00'),
(10, '2026-06-25', 'Present', '09:00:00', '17:02:00'),
(10, '2026-06-26', 'HalfDay', '09:00:00', '13:00:00'),
(10, '2026-06-27', 'Present', '09:01:00', '17:04:00'),
(10, '2026-06-28', 'Present', '09:03:00', '17:02:00'),
(10, '2026-06-29', 'Present', '09:05:00', '17:05:00'),
(10, '2026-06-30', 'Leave', NULL, NULL),
(11, '2026-06-01', 'Present', '09:05:00', '17:05:00'),
(11, '2026-06-02', 'Present', '09:03:00', '17:05:00'),
(11, '2026-06-03', 'Present', '09:03:00', '17:04:00'),
(11, '2026-06-04', 'Present', '09:02:00', '17:00:00'),
(11, '2026-06-05', 'Present', '09:01:00', '17:03:00'),
(11, '2026-06-06', 'Present', '09:01:00', '17:02:00'),
(11, '2026-06-07', 'Present', '09:05:00', '17:02:00'),
(11, '2026-06-08', 'Present', '09:05:00', '17:02:00'),
(11, '2026-06-09', 'Present', '09:02:00', '17:01:00'),
(11, '2026-06-10', 'HalfDay', '09:00:00', '13:00:00'),
(11, '2026-06-11', 'Leave', NULL, NULL),
(11, '2026-06-12', 'Present', '09:00:00', '17:05:00'),
(11, '2026-06-13', 'Present', '09:05:00', '17:04:00'),
(11, '2026-06-14', 'HalfDay', '09:00:00', '13:00:00'),
(11, '2026-06-15', 'Present', '09:02:00', '17:01:00'),
(11, '2026-06-16', 'HalfDay', '09:00:00', '13:00:00'),
(11, '2026-06-17', 'Present', '09:01:00', '17:00:00'),
(11, '2026-06-18', 'Present', '09:04:00', '17:01:00'),
(11, '2026-06-19', 'Present', '09:01:00', '17:02:00'),
(11, '2026-06-20', 'Present', '09:04:00', '17:00:00'),
(11, '2026-06-21', 'Present', '09:01:00', '17:01:00'),
(11, '2026-06-22', 'Present', '09:01:00', '17:00:00'),
(11, '2026-06-23', 'Present', '09:00:00', '17:01:00'),
(11, '2026-06-24', 'Present', '09:01:00', '17:04:00'),
(11, '2026-06-25', 'Present', '09:01:00', '17:02:00'),
(11, '2026-06-26', 'Present', '09:05:00', '17:03:00'),
(11, '2026-06-27', 'Present', '09:05:00', '17:00:00'),
(11, '2026-06-28', 'Present', '09:02:00', '17:04:00'),
(11, '2026-06-29', 'Present', '09:03:00', '17:04:00'),
(11, '2026-06-30', 'Present', '09:04:00', '17:00:00'),
(12, '2026-06-01', 'Present', '09:05:00', '17:04:00'),
(12, '2026-06-02', 'Present', '09:05:00', '17:00:00'),
(12, '2026-06-03', 'Present', '09:03:00', '17:03:00'),
(12, '2026-06-04', 'Present', '09:00:00', '17:03:00'),
(12, '2026-06-05', 'Present', '09:03:00', '17:00:00'),
(12, '2026-06-06', 'Absent', NULL, NULL),
(12, '2026-06-07', 'Present', '09:01:00', '17:00:00'),
(12, '2026-06-08', 'Present', '09:04:00', '17:05:00'),
(12, '2026-06-09', 'Present', '09:05:00', '17:02:00'),
(12, '2026-06-10', 'Present', '09:04:00', '17:04:00'),
(12, '2026-06-11', 'Present', '09:04:00', '17:04:00'),
(12, '2026-06-12', 'Present', '09:05:00', '17:00:00'),
(12, '2026-06-13', 'Absent', NULL, NULL),
(12, '2026-06-14', 'Present', '09:04:00', '17:05:00'),
(12, '2026-06-15', 'Absent', NULL, NULL),
(12, '2026-06-16', 'Present', '09:01:00', '17:03:00'),
(12, '2026-06-17', 'Present', '09:03:00', '17:03:00'),
(12, '2026-06-18', 'Present', '09:00:00', '17:02:00'),
(12, '2026-06-19', 'Present', '09:05:00', '17:02:00'),
(12, '2026-06-20', 'Present', '09:01:00', '17:05:00'),
(12, '2026-06-21', 'Leave', NULL, NULL),
(12, '2026-06-22', 'Present', '09:00:00', '17:00:00'),
(12, '2026-06-23', 'Present', '09:05:00', '17:05:00'),
(12, '2026-06-24', 'Present', '09:01:00', '17:04:00'),
(12, '2026-06-25', 'Present', '09:04:00', '17:04:00'),
(12, '2026-06-26', 'Present', '09:00:00', '17:03:00'),
(12, '2026-06-27', 'Present', '09:05:00', '17:03:00'),
(12, '2026-06-28', 'Absent', NULL, NULL),
(12, '2026-06-29', 'Present', '09:02:00', '17:04:00'),
(12, '2026-06-30', 'Present', '09:00:00', '17:04:00'),
(13, '2026-06-01', 'Present', '09:01:00', '17:05:00'),
(13, '2026-06-02', 'Present', '09:00:00', '17:02:00'),
(13, '2026-06-03', 'Present', '09:02:00', '17:00:00'),
(13, '2026-06-04', 'Present', '09:04:00', '17:01:00'),
(13, '2026-06-05', 'Present', '09:04:00', '17:04:00'),
(13, '2026-06-06', 'Present', '09:05:00', '17:04:00'),
(13, '2026-06-07', 'Present', '09:05:00', '17:05:00'),
(13, '2026-06-08', 'Present', '09:01:00', '17:02:00'),
(13, '2026-06-09', 'Present', '09:02:00', '17:02:00'),
(13, '2026-06-10', 'Present', '09:01:00', '17:01:00'),
(13, '2026-06-11', 'Present', '09:03:00', '17:00:00'),
(13, '2026-06-12', 'Present', '09:05:00', '17:00:00'),
(13, '2026-06-13', 'Present', '09:04:00', '17:01:00'),
(13, '2026-06-14', 'Present', '09:03:00', '17:02:00'),
(13, '2026-06-15', 'Present', '09:02:00', '17:05:00'),
(13, '2026-06-16', 'Present', '09:04:00', '17:04:00'),
(13, '2026-06-17', 'Present', '09:00:00', '17:01:00'),
(13, '2026-06-18', 'Present', '09:04:00', '17:00:00'),
(13, '2026-06-19', 'Present', '09:02:00', '17:03:00'),
(13, '2026-06-20', 'Present', '09:03:00', '17:04:00'),
(13, '2026-06-21', 'Present', '09:02:00', '17:01:00'),
(13, '2026-06-22', 'Present', '09:00:00', '17:02:00'),
(13, '2026-06-23', 'Present', '09:02:00', '17:05:00'),
(13, '2026-06-24', 'Present', '09:03:00', '17:04:00'),
(13, '2026-06-25', 'Present', '09:00:00', '17:01:00'),
(13, '2026-06-26', 'Present', '09:04:00', '17:00:00'),
(13, '2026-06-27', 'Present', '09:02:00', '17:01:00'),
(13, '2026-06-28', 'Present', '09:02:00', '17:02:00'),
(13, '2026-06-29', 'Present', '09:00:00', '17:03:00'),
(13, '2026-06-30', 'Present', '09:01:00', '17:01:00'),
(14, '2026-06-01', 'Present', '09:05:00', '17:01:00'),
(14, '2026-06-02', 'Present', '09:05:00', '17:02:00'),
(14, '2026-06-03', 'Present', '09:05:00', '17:00:00'),
(14, '2026-06-04', 'Present', '09:03:00', '17:00:00'),
(14, '2026-06-05', 'Absent', NULL, NULL),
(14, '2026-06-06', 'Present', '09:04:00', '17:03:00'),
(14, '2026-06-07', 'Present', '09:03:00', '17:02:00'),
(14, '2026-06-08', 'Present', '09:00:00', '17:02:00'),
(14, '2026-06-09', 'Present', '09:04:00', '17:03:00'),
(14, '2026-06-10', 'Present', '09:02:00', '17:00:00'),
(14, '2026-06-11', 'Present', '09:00:00', '17:01:00'),
(14, '2026-06-12', 'Present', '09:03:00', '17:04:00'),
(14, '2026-06-13', 'Present', '09:02:00', '17:05:00'),
(14, '2026-06-14', 'Present', '09:02:00', '17:01:00'),
(14, '2026-06-15', 'Present', '09:05:00', '17:00:00'),
(14, '2026-06-16', 'Present', '09:01:00', '17:02:00'),
(14, '2026-06-17', 'Present', '09:05:00', '17:01:00'),
(14, '2026-06-18', 'Present', '09:01:00', '17:02:00'),
(14, '2026-06-19', 'Present', '09:04:00', '17:01:00'),
(14, '2026-06-20', 'Present', '09:05:00', '17:00:00'),
(14, '2026-06-21', 'Present', '09:05:00', '17:03:00'),
(14, '2026-06-22', 'Present', '09:04:00', '17:04:00'),
(14, '2026-06-23', 'Present', '09:04:00', '17:05:00'),
(14, '2026-06-24', 'Present', '09:04:00', '17:02:00'),
(14, '2026-06-25', 'Absent', NULL, NULL),
(14, '2026-06-26', 'Present', '09:01:00', '17:03:00'),
(14, '2026-06-27', 'Present', '09:03:00', '17:05:00'),
(14, '2026-06-28', 'Present', '09:02:00', '17:04:00'),
(14, '2026-06-29', 'Present', '09:04:00', '17:00:00'),
(14, '2026-06-30', 'Present', '09:03:00', '17:00:00'),
(15, '2026-06-01', 'Present', '09:02:00', '17:00:00'),
(15, '2026-06-02', 'Present', '09:00:00', '17:04:00'),
(15, '2026-06-03', 'Present', '09:03:00', '17:03:00'),
(15, '2026-06-04', 'Present', '09:05:00', '17:00:00'),
(15, '2026-06-05', 'Present', '09:04:00', '17:05:00'),
(15, '2026-06-06', 'Present', '09:04:00', '17:03:00'),
(15, '2026-06-07', 'Present', '09:00:00', '17:03:00'),
(15, '2026-06-08', 'Present', '09:02:00', '17:05:00'),
(15, '2026-06-09', 'Present', '09:05:00', '17:01:00'),
(15, '2026-06-10', 'Present', '09:05:00', '17:03:00'),
(15, '2026-06-11', 'HalfDay', '09:00:00', '13:00:00'),
(15, '2026-06-12', 'Present', '09:04:00', '17:01:00'),
(15, '2026-06-13', 'Present', '09:02:00', '17:03:00'),
(15, '2026-06-14', 'Present', '09:02:00', '17:05:00'),
(15, '2026-06-15', 'Present', '09:05:00', '17:05:00'),
(15, '2026-06-16', 'Present', '09:02:00', '17:00:00'),
(15, '2026-06-17', 'Present', '09:03:00', '17:02:00'),
(15, '2026-06-18', 'Present', '09:05:00', '17:04:00'),
(15, '2026-06-19', 'Absent', NULL, NULL),
(15, '2026-06-20', 'Present', '09:04:00', '17:05:00'),
(15, '2026-06-21', 'Present', '09:02:00', '17:02:00'),
(15, '2026-06-22', 'HalfDay', '09:00:00', '13:00:00'),
(15, '2026-06-23', 'Present', '09:03:00', '17:01:00'),
(15, '2026-06-24', 'Present', '09:00:00', '17:02:00'),
(15, '2026-06-25', 'Present', '09:05:00', '17:02:00'),
(15, '2026-06-26', 'Present', '09:05:00', '17:05:00'),
(15, '2026-06-27', 'Present', '09:05:00', '17:05:00'),
(15, '2026-06-28', 'Leave', NULL, NULL),
(15, '2026-06-29', 'Present', '09:05:00', '17:03:00'),
(15, '2026-06-30', 'Present', '09:00:00', '17:02:00'),
(16, '2026-06-01', 'Present', '09:01:00', '17:02:00'),
(16, '2026-06-02', 'Leave', NULL, NULL),
(16, '2026-06-03', 'Present', '09:01:00', '17:01:00'),
(16, '2026-06-04', 'Present', '09:02:00', '17:00:00'),
(16, '2026-06-05', 'Present', '09:04:00', '17:05:00'),
(16, '2026-06-06', 'Absent', NULL, NULL),
(16, '2026-06-07', 'Present', '09:02:00', '17:04:00'),
(16, '2026-06-08', 'Present', '09:03:00', '17:01:00'),
(16, '2026-06-09', 'Present', '09:05:00', '17:04:00'),
(16, '2026-06-10', 'Present', '09:01:00', '17:05:00'),
(16, '2026-06-11', 'Present', '09:03:00', '17:02:00'),
(16, '2026-06-12', 'Present', '09:01:00', '17:03:00'),
(16, '2026-06-13', 'Present', '09:05:00', '17:03:00'),
(16, '2026-06-14', 'Present', '09:01:00', '17:02:00'),
(16, '2026-06-15', 'HalfDay', '09:00:00', '13:00:00'),
(16, '2026-06-16', 'Present', '09:01:00', '17:02:00'),
(16, '2026-06-17', 'Present', '09:04:00', '17:03:00'),
(16, '2026-06-18', 'Present', '09:02:00', '17:03:00'),
(16, '2026-06-19', 'Present', '09:03:00', '17:01:00'),
(16, '2026-06-20', 'Present', '09:04:00', '17:01:00'),
(16, '2026-06-21', 'Absent', NULL, NULL),
(16, '2026-06-22', 'Present', '09:03:00', '17:02:00'),
(16, '2026-06-23', 'Present', '09:00:00', '17:05:00'),
(16, '2026-06-24', 'Present', '09:00:00', '17:02:00'),
(16, '2026-06-25', 'Present', '09:01:00', '17:02:00'),
(16, '2026-06-26', 'Present', '09:04:00', '17:01:00'),
(16, '2026-06-27', 'Present', '09:00:00', '17:01:00'),
(16, '2026-06-28', 'Present', '09:02:00', '17:00:00'),
(16, '2026-06-29', 'Present', '09:03:00', '17:04:00'),
(16, '2026-06-30', 'Present', '09:03:00', '17:00:00'),
(17, '2026-06-01', 'Present', '09:00:00', '17:02:00'),
(17, '2026-06-02', 'Leave', NULL, NULL),
(17, '2026-06-03', 'Present', '09:05:00', '17:02:00'),
(17, '2026-06-04', 'Present', '09:01:00', '17:00:00'),
(17, '2026-06-05', 'Present', '09:03:00', '17:05:00'),
(17, '2026-06-06', 'Present', '09:05:00', '17:03:00'),
(17, '2026-06-07', 'Present', '09:00:00', '17:00:00'),
(17, '2026-06-08', 'Present', '09:01:00', '17:01:00'),
(17, '2026-06-09', 'Present', '09:05:00', '17:04:00'),
(17, '2026-06-10', 'Present', '09:00:00', '17:02:00'),
(17, '2026-06-11', 'Present', '09:00:00', '17:00:00'),
(17, '2026-06-12', 'Present', '09:05:00', '17:04:00'),
(17, '2026-06-13', 'Present', '09:00:00', '17:03:00'),
(17, '2026-06-14', 'Present', '09:00:00', '17:05:00'),
(17, '2026-06-15', 'Present', '09:01:00', '17:05:00'),
(17, '2026-06-16', 'Present', '09:03:00', '17:00:00'),
(17, '2026-06-17', 'Present', '09:01:00', '17:04:00'),
(17, '2026-06-18', 'Present', '09:05:00', '17:05:00'),
(17, '2026-06-19', 'Present', '09:02:00', '17:00:00'),
(17, '2026-06-20', 'HalfDay', '09:00:00', '13:00:00'),
(17, '2026-06-21', 'Present', '09:04:00', '17:04:00'),
(17, '2026-06-22', 'Present', '09:03:00', '17:00:00'),
(17, '2026-06-23', 'Present', '09:02:00', '17:02:00'),
(17, '2026-06-24', 'Present', '09:02:00', '17:00:00'),
(17, '2026-06-25', 'Present', '09:05:00', '17:05:00'),
(17, '2026-06-26', 'Present', '09:04:00', '17:05:00'),
(17, '2026-06-27', 'Present', '09:01:00', '17:00:00'),
(17, '2026-06-28', 'Present', '09:02:00', '17:05:00'),
(17, '2026-06-29', 'Present', '09:05:00', '17:03:00'),
(17, '2026-06-30', 'HalfDay', '09:00:00', '13:00:00'),
(18, '2026-06-01', 'Present', '09:01:00', '17:01:00'),
(18, '2026-06-02', 'Present', '09:03:00', '17:00:00'),
(18, '2026-06-03', 'Present', '09:00:00', '17:01:00'),
(18, '2026-06-04', 'Absent', NULL, NULL),
(18, '2026-06-05', 'Present', '09:02:00', '17:04:00'),
(18, '2026-06-06', 'Present', '09:04:00', '17:03:00'),
(18, '2026-06-07', 'Present', '09:05:00', '17:01:00'),
(18, '2026-06-08', 'Present', '09:00:00', '17:05:00'),
(18, '2026-06-09', 'Present', '09:00:00', '17:02:00'),
(18, '2026-06-10', 'Present', '09:03:00', '17:05:00'),
(18, '2026-06-11', 'Present', '09:03:00', '17:02:00'),
(18, '2026-06-12', 'HalfDay', '09:00:00', '13:00:00'),
(18, '2026-06-13', 'Present', '09:03:00', '17:02:00'),
(18, '2026-06-14', 'Leave', NULL, NULL),
(18, '2026-06-15', 'Present', '09:00:00', '17:05:00'),
(18, '2026-06-16', 'Present', '09:03:00', '17:04:00'),
(18, '2026-06-17', 'HalfDay', '09:00:00', '13:00:00'),
(18, '2026-06-18', 'Present', '09:02:00', '17:02:00'),
(18, '2026-06-19', 'Present', '09:02:00', '17:05:00'),
(18, '2026-06-20', 'Present', '09:03:00', '17:04:00'),
(18, '2026-06-21', 'Present', '09:01:00', '17:05:00'),
(18, '2026-06-22', 'Present', '09:03:00', '17:00:00'),
(18, '2026-06-23', 'Present', '09:02:00', '17:04:00'),
(18, '2026-06-24', 'HalfDay', '09:00:00', '13:00:00'),
(18, '2026-06-25', 'Present', '09:00:00', '17:00:00'),
(18, '2026-06-26', 'Present', '09:03:00', '17:02:00'),
(18, '2026-06-27', 'Present', '09:05:00', '17:05:00'),
(18, '2026-06-28', 'Present', '09:00:00', '17:01:00'),
(18, '2026-06-29', 'Present', '09:05:00', '17:03:00'),
(18, '2026-06-30', 'Present', '09:00:00', '17:01:00'),
(19, '2026-06-01', 'Present', '09:02:00', '17:02:00'),
(19, '2026-06-02', 'Present', '09:04:00', '17:00:00'),
(19, '2026-06-03', 'Present', '09:05:00', '17:03:00'),
(19, '2026-06-04', 'Leave', NULL, NULL),
(19, '2026-06-05', 'Present', '09:00:00', '17:04:00'),
(19, '2026-06-06', 'Present', '09:02:00', '17:03:00'),
(19, '2026-06-07', 'Present', '09:02:00', '17:01:00'),
(19, '2026-06-08', 'HalfDay', '09:00:00', '13:00:00'),
(19, '2026-06-09', 'Present', '09:01:00', '17:03:00'),
(19, '2026-06-10', 'Present', '09:04:00', '17:00:00'),
(19, '2026-06-11', 'Present', '09:02:00', '17:05:00'),
(19, '2026-06-12', 'Present', '09:04:00', '17:02:00'),
(19, '2026-06-13', 'Present', '09:03:00', '17:01:00'),
(19, '2026-06-14', 'Present', '09:00:00', '17:03:00'),
(19, '2026-06-15', 'Present', '09:05:00', '17:03:00'),
(19, '2026-06-16', 'HalfDay', '09:00:00', '13:00:00'),
(19, '2026-06-17', 'Present', '09:02:00', '17:05:00'),
(19, '2026-06-18', 'Present', '09:00:00', '17:04:00'),
(19, '2026-06-19', 'Present', '09:02:00', '17:01:00'),
(19, '2026-06-20', 'Present', '09:05:00', '17:05:00'),
(19, '2026-06-21', 'Present', '09:02:00', '17:04:00'),
(19, '2026-06-22', 'Present', '09:01:00', '17:01:00'),
(19, '2026-06-23', 'Present', '09:03:00', '17:00:00'),
(19, '2026-06-24', 'Present', '09:04:00', '17:02:00'),
(19, '2026-06-25', 'Present', '09:04:00', '17:01:00'),
(19, '2026-06-26', 'Present', '09:00:00', '17:00:00'),
(19, '2026-06-27', 'Present', '09:05:00', '17:05:00'),
(19, '2026-06-28', 'Present', '09:03:00', '17:03:00'),
(19, '2026-06-29', 'Present', '09:00:00', '17:01:00'),
(19, '2026-06-30', 'HalfDay', '09:00:00', '13:00:00'),
(20, '2026-06-01', 'Present', '09:03:00', '17:03:00'),
(20, '2026-06-02', 'Present', '09:02:00', '17:01:00'),
(20, '2026-06-03', 'Absent', NULL, NULL),
(20, '2026-06-04', 'Present', '09:05:00', '17:04:00'),
(20, '2026-06-05', 'Present', '09:01:00', '17:03:00'),
(20, '2026-06-06', 'Present', '09:00:00', '17:00:00'),
(20, '2026-06-07', 'Present', '09:02:00', '17:01:00'),
(20, '2026-06-08', 'Present', '09:05:00', '17:01:00'),
(20, '2026-06-09', 'Present', '09:04:00', '17:02:00'),
(20, '2026-06-10', 'Present', '09:02:00', '17:01:00'),
(20, '2026-06-11', 'Present', '09:04:00', '17:02:00'),
(20, '2026-06-12', 'Present', '09:02:00', '17:04:00'),
(20, '2026-06-13', 'Present', '09:04:00', '17:05:00'),
(20, '2026-06-14', 'Present', '09:04:00', '17:01:00'),
(20, '2026-06-15', 'Present', '09:04:00', '17:05:00'),
(20, '2026-06-16', 'Leave', NULL, NULL),
(20, '2026-06-17', 'Present', '09:04:00', '17:00:00'),
(20, '2026-06-18', 'Present', '09:00:00', '17:00:00'),
(20, '2026-06-19', 'Present', '09:05:00', '17:04:00'),
(20, '2026-06-20', 'Present', '09:01:00', '17:04:00'),
(20, '2026-06-21', 'Present', '09:05:00', '17:00:00'),
(20, '2026-06-22', 'Present', '09:05:00', '17:04:00'),
(20, '2026-06-23', 'Present', '09:02:00', '17:03:00'),
(20, '2026-06-24', 'Present', '09:05:00', '17:03:00'),
(20, '2026-06-25', 'Present', '09:00:00', '17:05:00'),
(20, '2026-06-26', 'Present', '09:03:00', '17:03:00'),
(20, '2026-06-27', 'Present', '09:01:00', '17:02:00'),
(20, '2026-06-28', 'Present', '09:02:00', '17:05:00'),
(20, '2026-06-29', 'Present', '09:02:00', '17:03:00'),
(20, '2026-06-30', 'Present', '09:02:00', '17:04:00'),
(21, '2026-06-01', 'Present', '09:02:00', '17:01:00'),
(21, '2026-06-02', 'Present', '09:02:00', '17:03:00'),
(21, '2026-06-03', 'Present', '09:00:00', '17:00:00'),
(21, '2026-06-04', 'Present', '09:03:00', '17:04:00'),
(21, '2026-06-05', 'Present', '09:01:00', '17:02:00'),
(21, '2026-06-06', 'Leave', NULL, NULL),
(21, '2026-06-07', 'Present', '09:01:00', '17:01:00'),
(21, '2026-06-08', 'Present', '09:04:00', '17:03:00'),
(21, '2026-06-09', 'Present', '09:02:00', '17:03:00'),
(21, '2026-06-10', 'Present', '09:03:00', '17:04:00'),
(21, '2026-06-11', 'Present', '09:01:00', '17:01:00'),
(21, '2026-06-12', 'Present', '09:00:00', '17:00:00'),
(21, '2026-06-13', 'Present', '09:04:00', '17:05:00'),
(21, '2026-06-14', 'Present', '09:02:00', '17:04:00'),
(21, '2026-06-15', 'Present', '09:00:00', '17:03:00'),
(21, '2026-06-16', 'Present', '09:02:00', '17:05:00'),
(21, '2026-06-17', 'Present', '09:03:00', '17:02:00'),
(21, '2026-06-18', 'Present', '09:00:00', '17:04:00'),
(21, '2026-06-19', 'Present', '09:02:00', '17:04:00'),
(21, '2026-06-20', 'Present', '09:03:00', '17:04:00'),
(21, '2026-06-21', 'Present', '09:04:00', '17:02:00'),
(21, '2026-06-22', 'Present', '09:04:00', '17:05:00'),
(21, '2026-06-23', 'Present', '09:01:00', '17:00:00'),
(21, '2026-06-24', 'Present', '09:02:00', '17:04:00'),
(21, '2026-06-25', 'Leave', NULL, NULL),
(21, '2026-06-26', 'Present', '09:01:00', '17:04:00'),
(21, '2026-06-27', 'Present', '09:04:00', '17:00:00'),
(21, '2026-06-28', 'Present', '09:01:00', '17:05:00'),
(21, '2026-06-29', 'Present', '09:03:00', '17:04:00'),
(21, '2026-06-30', 'Present', '09:04:00', '17:04:00'),
(22, '2026-06-01', 'Present', '09:04:00', '17:02:00'),
(22, '2026-06-02', 'Present', '09:04:00', '17:05:00'),
(22, '2026-06-03', 'Present', '09:04:00', '17:02:00'),
(22, '2026-06-04', 'Present', '09:04:00', '17:04:00'),
(22, '2026-06-05', 'Present', '09:04:00', '17:02:00'),
(22, '2026-06-06', 'Present', '09:00:00', '17:02:00'),
(22, '2026-06-07', 'Present', '09:00:00', '17:03:00'),
(22, '2026-06-08', 'Present', '09:05:00', '17:05:00'),
(22, '2026-06-09', 'Present', '09:04:00', '17:03:00'),
(22, '2026-06-10', 'Present', '09:05:00', '17:04:00'),
(22, '2026-06-11', 'Present', '09:05:00', '17:00:00'),
(22, '2026-06-12', 'Present', '09:01:00', '17:04:00'),
(22, '2026-06-13', 'Present', '09:04:00', '17:03:00'),
(22, '2026-06-14', 'Present', '09:05:00', '17:01:00'),
(22, '2026-06-15', 'Present', '09:05:00', '17:00:00'),
(22, '2026-06-16', 'Present', '09:03:00', '17:02:00'),
(22, '2026-06-17', 'Present', '09:03:00', '17:05:00'),
(22, '2026-06-18', 'Present', '09:04:00', '17:04:00'),
(22, '2026-06-19', 'Leave', NULL, NULL),
(22, '2026-06-20', 'Absent', NULL, NULL),
(22, '2026-06-21', 'Present', '09:00:00', '17:05:00'),
(22, '2026-06-22', 'Present', '09:01:00', '17:04:00'),
(22, '2026-06-23', 'Present', '09:05:00', '17:03:00'),
(22, '2026-06-24', 'Present', '09:02:00', '17:01:00'),
(22, '2026-06-25', 'Present', '09:04:00', '17:02:00'),
(22, '2026-06-26', 'Present', '09:05:00', '17:05:00'),
(22, '2026-06-27', 'Present', '09:05:00', '17:02:00'),
(22, '2026-06-28', 'Present', '09:01:00', '17:01:00'),
(22, '2026-06-29', 'Present', '09:02:00', '17:01:00'),
(22, '2026-06-30', 'Leave', NULL, NULL),
(23, '2026-06-01', 'HalfDay', '09:00:00', '13:00:00'),
(23, '2026-06-02', 'Present', '09:05:00', '17:01:00'),
(23, '2026-06-03', 'Present', '09:03:00', '17:02:00'),
(23, '2026-06-04', 'Present', '09:04:00', '17:05:00'),
(23, '2026-06-05', 'Present', '09:00:00', '17:04:00'),
(23, '2026-06-06', 'Present', '09:03:00', '17:03:00'),
(23, '2026-06-07', 'Present', '09:01:00', '17:02:00'),
(23, '2026-06-08', 'Present', '09:05:00', '17:00:00'),
(23, '2026-06-09', 'Present', '09:03:00', '17:05:00'),
(23, '2026-06-10', 'Present', '09:03:00', '17:01:00'),
(23, '2026-06-11', 'Present', '09:04:00', '17:02:00'),
(23, '2026-06-12', 'Leave', NULL, NULL),
(23, '2026-06-13', 'Present', '09:01:00', '17:00:00'),
(23, '2026-06-14', 'Present', '09:04:00', '17:01:00'),
(23, '2026-06-15', 'Present', '09:05:00', '17:04:00'),
(23, '2026-06-16', 'Present', '09:01:00', '17:00:00'),
(23, '2026-06-17', 'Present', '09:02:00', '17:05:00'),
(23, '2026-06-18', 'Present', '09:05:00', '17:01:00'),
(23, '2026-06-19', 'Present', '09:04:00', '17:01:00'),
(23, '2026-06-20', 'Present', '09:03:00', '17:03:00'),
(23, '2026-06-21', 'Present', '09:02:00', '17:02:00'),
(23, '2026-06-22', 'Present', '09:00:00', '17:00:00'),
(23, '2026-06-23', 'Present', '09:01:00', '17:04:00'),
(23, '2026-06-24', 'Present', '09:00:00', '17:01:00'),
(23, '2026-06-25', 'Present', '09:01:00', '17:00:00'),
(23, '2026-06-26', 'HalfDay', '09:00:00', '13:00:00'),
(23, '2026-06-27', 'Present', '09:03:00', '17:01:00'),
(23, '2026-06-28', 'Leave', NULL, NULL),
(23, '2026-06-29', 'HalfDay', '09:00:00', '13:00:00'),
(23, '2026-06-30', 'Leave', NULL, NULL),
(24, '2026-06-01', 'Absent', NULL, NULL),
(24, '2026-06-02', 'Present', '09:04:00', '17:04:00'),
(24, '2026-06-03', 'Present', '09:02:00', '17:02:00'),
(24, '2026-06-04', 'Present', '09:05:00', '17:04:00'),
(24, '2026-06-05', 'Present', '09:01:00', '17:04:00'),
(24, '2026-06-06', 'Present', '09:01:00', '17:00:00'),
(24, '2026-06-07', 'Present', '09:05:00', '17:03:00'),
(24, '2026-06-08', 'Present', '09:05:00', '17:01:00'),
(24, '2026-06-09', 'Present', '09:02:00', '17:02:00'),
(24, '2026-06-10', 'Present', '09:01:00', '17:01:00'),
(24, '2026-06-11', 'Present', '09:05:00', '17:03:00'),
(24, '2026-06-12', 'Present', '09:04:00', '17:02:00'),
(24, '2026-06-13', 'Present', '09:05:00', '17:00:00'),
(24, '2026-06-14', 'Present', '09:01:00', '17:03:00'),
(24, '2026-06-15', 'Present', '09:01:00', '17:00:00'),
(24, '2026-06-16', 'Present', '09:01:00', '17:03:00'),
(24, '2026-06-17', 'Present', '09:02:00', '17:02:00'),
(24, '2026-06-18', 'Present', '09:04:00', '17:00:00'),
(24, '2026-06-19', 'Present', '09:02:00', '17:05:00'),
(24, '2026-06-20', 'Present', '09:05:00', '17:00:00'),
(24, '2026-06-21', 'Present', '09:01:00', '17:03:00'),
(24, '2026-06-22', 'Present', '09:05:00', '17:02:00'),
(24, '2026-06-23', 'Present', '09:05:00', '17:02:00'),
(24, '2026-06-24', 'Present', '09:01:00', '17:01:00'),
(24, '2026-06-25', 'HalfDay', '09:00:00', '13:00:00'),
(24, '2026-06-26', 'Present', '09:03:00', '17:05:00'),
(24, '2026-06-27', 'HalfDay', '09:00:00', '13:00:00'),
(24, '2026-06-28', 'Present', '09:05:00', '17:04:00'),
(24, '2026-06-29', 'Leave', NULL, NULL),
(24, '2026-06-30', 'Present', '09:05:00', '17:01:00'),
(25, '2026-06-01', 'Present', '09:05:00', '17:04:00'),
(25, '2026-06-02', 'Absent', NULL, NULL),
(25, '2026-06-03', 'Present', '09:03:00', '17:04:00'),
(25, '2026-06-04', 'Present', '09:00:00', '17:04:00'),
(25, '2026-06-05', 'Present', '09:04:00', '17:04:00'),
(25, '2026-06-06', 'Present', '09:04:00', '17:01:00'),
(25, '2026-06-07', 'Present', '09:04:00', '17:03:00'),
(25, '2026-06-08', 'Present', '09:01:00', '17:05:00'),
(25, '2026-06-09', 'Present', '09:00:00', '17:04:00'),
(25, '2026-06-10', 'Present', '09:00:00', '17:03:00'),
(25, '2026-06-11', 'Present', '09:03:00', '17:03:00'),
(25, '2026-06-12', 'Present', '09:04:00', '17:03:00'),
(25, '2026-06-13', 'Present', '09:02:00', '17:05:00'),
(25, '2026-06-14', 'Present', '09:02:00', '17:00:00'),
(25, '2026-06-15', 'Present', '09:04:00', '17:00:00'),
(25, '2026-06-16', 'Present', '09:02:00', '17:05:00'),
(25, '2026-06-17', 'Present', '09:00:00', '17:00:00'),
(25, '2026-06-18', 'HalfDay', '09:00:00', '13:00:00'),
(25, '2026-06-19', 'Present', '09:02:00', '17:03:00'),
(25, '2026-06-20', 'Present', '09:01:00', '17:05:00'),
(25, '2026-06-21', 'HalfDay', '09:00:00', '13:00:00'),
(25, '2026-06-22', 'Present', '09:03:00', '17:02:00'),
(25, '2026-06-23', 'HalfDay', '09:00:00', '13:00:00'),
(25, '2026-06-24', 'Present', '09:03:00', '17:03:00'),
(25, '2026-06-25', 'Present', '09:05:00', '17:04:00'),
(25, '2026-06-26', 'Present', '09:02:00', '17:00:00'),
(25, '2026-06-27', 'Present', '09:04:00', '17:03:00'),
(25, '2026-06-28', 'Present', '09:05:00', '17:01:00'),
(25, '2026-06-29', 'Present', '09:00:00', '17:02:00'),
(25, '2026-06-30', 'Present', '09:05:00', '17:04:00'),
(26, '2026-06-01', 'Present', '09:03:00', '17:01:00'),
(26, '2026-06-02', 'Present', '09:02:00', '17:01:00'),
(26, '2026-06-03', 'Present', '09:05:00', '17:00:00'),
(26, '2026-06-04', 'Present', '09:05:00', '17:03:00'),
(26, '2026-06-05', 'Present', '09:00:00', '17:01:00'),
(26, '2026-06-06', 'Present', '09:00:00', '17:04:00'),
(26, '2026-06-07', 'Present', '09:04:00', '17:05:00'),
(26, '2026-06-08', 'Present', '09:00:00', '17:01:00'),
(26, '2026-06-09', 'Present', '09:03:00', '17:03:00'),
(26, '2026-06-10', 'Present', '09:01:00', '17:00:00'),
(26, '2026-06-11', 'Present', '09:02:00', '17:01:00'),
(26, '2026-06-12', 'Present', '09:05:00', '17:04:00'),
(26, '2026-06-13', 'Present', '09:04:00', '17:05:00'),
(26, '2026-06-14', 'Present', '09:01:00', '17:02:00'),
(26, '2026-06-15', 'Absent', NULL, NULL),
(26, '2026-06-16', 'HalfDay', '09:00:00', '13:00:00'),
(26, '2026-06-17', 'Present', '09:03:00', '17:02:00'),
(26, '2026-06-18', 'Present', '09:04:00', '17:04:00'),
(26, '2026-06-19', 'Absent', NULL, NULL),
(26, '2026-06-20', 'Leave', NULL, NULL),
(26, '2026-06-21', 'Present', '09:03:00', '17:04:00'),
(26, '2026-06-22', 'Present', '09:02:00', '17:05:00'),
(26, '2026-06-23', 'Present', '09:04:00', '17:02:00'),
(26, '2026-06-24', 'Present', '09:03:00', '17:01:00'),
(26, '2026-06-25', 'Present', '09:01:00', '17:04:00'),
(26, '2026-06-26', 'Present', '09:01:00', '17:02:00'),
(26, '2026-06-27', 'Absent', NULL, NULL),
(26, '2026-06-28', 'Present', '09:03:00', '17:00:00'),
(26, '2026-06-29', 'Present', '09:03:00', '17:04:00'),
(26, '2026-06-30', 'Present', '09:03:00', '17:01:00'),
(27, '2026-06-01', 'Present', '09:02:00', '17:05:00'),
(27, '2026-06-02', 'Present', '09:03:00', '17:02:00'),
(27, '2026-06-03', 'Present', '09:05:00', '17:01:00'),
(27, '2026-06-04', 'Present', '09:03:00', '17:05:00'),
(27, '2026-06-05', 'Present', '09:00:00', '17:00:00'),
(27, '2026-06-06', 'Present', '09:04:00', '17:05:00'),
(27, '2026-06-07', 'Present', '09:01:00', '17:03:00'),
(27, '2026-06-08', 'Present', '09:02:00', '17:02:00'),
(27, '2026-06-09', 'HalfDay', '09:00:00', '13:00:00'),
(27, '2026-06-10', 'Present', '09:01:00', '17:05:00'),
(27, '2026-06-11', 'Present', '09:03:00', '17:01:00'),
(27, '2026-06-12', 'Present', '09:05:00', '17:01:00'),
(27, '2026-06-13', 'Present', '09:01:00', '17:04:00'),
(27, '2026-06-14', 'Present', '09:02:00', '17:03:00'),
(27, '2026-06-15', 'Present', '09:05:00', '17:02:00'),
(27, '2026-06-16', 'Present', '09:02:00', '17:04:00'),
(27, '2026-06-17', 'Absent', NULL, NULL),
(27, '2026-06-18', 'Present', '09:05:00', '17:03:00'),
(27, '2026-06-19', 'Present', '09:02:00', '17:01:00'),
(27, '2026-06-20', 'Present', '09:03:00', '17:00:00'),
(27, '2026-06-21', 'Present', '09:01:00', '17:05:00'),
(27, '2026-06-22', 'Present', '09:02:00', '17:04:00'),
(27, '2026-06-23', 'Leave', NULL, NULL),
(27, '2026-06-24', 'Present', '09:03:00', '17:02:00'),
(27, '2026-06-25', 'Present', '09:02:00', '17:01:00'),
(27, '2026-06-26', 'Present', '09:01:00', '17:03:00'),
(27, '2026-06-27', 'Present', '09:05:00', '17:02:00'),
(27, '2026-06-28', 'Present', '09:03:00', '17:05:00'),
(27, '2026-06-29', 'Present', '09:03:00', '17:03:00'),
(27, '2026-06-30', 'Present', '09:02:00', '17:01:00'),
(28, '2026-06-01', 'Present', '09:04:00', '17:03:00'),
(28, '2026-06-02', 'Present', '09:04:00', '17:05:00'),
(28, '2026-06-03', 'HalfDay', '09:00:00', '13:00:00'),
(28, '2026-06-04', 'Present', '09:00:00', '17:05:00'),
(28, '2026-06-05', 'Present', '09:00:00', '17:03:00'),
(28, '2026-06-06', 'Present', '09:05:00', '17:01:00'),
(28, '2026-06-07', 'Present', '09:01:00', '17:00:00'),
(28, '2026-06-08', 'Present', '09:03:00', '17:02:00'),
(28, '2026-06-09', 'Present', '09:05:00', '17:05:00'),
(28, '2026-06-10', 'Leave', NULL, NULL),
(28, '2026-06-11', 'Leave', NULL, NULL),
(28, '2026-06-12', 'Present', '09:00:00', '17:00:00'),
(28, '2026-06-13', 'Present', '09:03:00', '17:00:00'),
(28, '2026-06-14', 'Present', '09:05:00', '17:02:00'),
(28, '2026-06-15', 'Present', '09:02:00', '17:00:00'),
(28, '2026-06-16', 'Present', '09:05:00', '17:05:00'),
(28, '2026-06-17', 'Present', '09:01:00', '17:00:00'),
(28, '2026-06-18', 'Leave', NULL, NULL),
(28, '2026-06-19', 'Present', '09:01:00', '17:01:00'),
(28, '2026-06-20', 'Present', '09:02:00', '17:02:00'),
(28, '2026-06-21', 'Present', '09:03:00', '17:00:00'),
(28, '2026-06-22', 'Present', '09:03:00', '17:03:00'),
(28, '2026-06-23', 'Present', '09:05:00', '17:01:00'),
(28, '2026-06-24', 'Present', '09:00:00', '17:05:00'),
(28, '2026-06-25', 'HalfDay', '09:00:00', '13:00:00'),
(28, '2026-06-26', 'Present', '09:00:00', '17:00:00'),
(28, '2026-06-27', 'Present', '09:03:00', '17:04:00'),
(28, '2026-06-28', 'Present', '09:05:00', '17:00:00'),
(28, '2026-06-29', 'Present', '09:00:00', '17:03:00'),
(28, '2026-06-30', 'Present', '09:05:00', '17:02:00'),
(29, '2026-06-01', 'Present', '09:00:00', '17:04:00'),
(29, '2026-06-02', 'Leave', NULL, NULL),
(29, '2026-06-03', 'Present', '09:05:00', '17:04:00'),
(29, '2026-06-04', 'Present', '09:00:00', '17:00:00'),
(29, '2026-06-05', 'Present', '09:02:00', '17:04:00'),
(29, '2026-06-06', 'Present', '09:00:00', '17:01:00'),
(29, '2026-06-07', 'Leave', NULL, NULL),
(29, '2026-06-08', 'Present', '09:01:00', '17:04:00'),
(29, '2026-06-09', 'Present', '09:05:00', '17:03:00'),
(29, '2026-06-10', 'Leave', NULL, NULL),
(29, '2026-06-11', 'Present', '09:04:00', '17:01:00'),
(29, '2026-06-12', 'Present', '09:03:00', '17:05:00'),
(29, '2026-06-13', 'Absent', NULL, NULL),
(29, '2026-06-14', 'Present', '09:05:00', '17:01:00'),
(29, '2026-06-15', 'Present', '09:05:00', '17:05:00'),
(29, '2026-06-16', 'Present', '09:05:00', '17:02:00'),
(29, '2026-06-17', 'Present', '09:03:00', '17:01:00'),
(29, '2026-06-18', 'Present', '09:02:00', '17:04:00'),
(29, '2026-06-19', 'Present', '09:04:00', '17:03:00'),
(29, '2026-06-20', 'HalfDay', '09:00:00', '13:00:00'),
(29, '2026-06-21', 'Present', '09:05:00', '17:02:00'),
(29, '2026-06-22', 'Present', '09:03:00', '17:03:00'),
(29, '2026-06-23', 'Present', '09:04:00', '17:03:00'),
(29, '2026-06-24', 'Present', '09:05:00', '17:04:00'),
(29, '2026-06-25', 'Present', '09:00:00', '17:04:00'),
(29, '2026-06-26', 'Present', '09:01:00', '17:05:00'),
(29, '2026-06-27', 'Present', '09:02:00', '17:01:00'),
(29, '2026-06-28', 'Present', '09:05:00', '17:01:00'),
(29, '2026-06-29', 'Present', '09:02:00', '17:02:00'),
(29, '2026-06-30', 'Present', '09:00:00', '17:02:00'),
(30, '2026-06-01', 'Present', '09:02:00', '17:00:00'),
(30, '2026-06-02', 'Present', '09:01:00', '17:03:00'),
(30, '2026-06-03', 'Present', '09:04:00', '17:04:00'),
(30, '2026-06-04', 'Present', '09:00:00', '17:00:00'),
(30, '2026-06-05', 'Present', '09:00:00', '17:04:00'),
(30, '2026-06-06', 'Present', '09:02:00', '17:03:00'),
(30, '2026-06-07', 'Present', '09:03:00', '17:03:00'),
(30, '2026-06-08', 'Present', '09:05:00', '17:04:00'),
(30, '2026-06-09', 'Leave', NULL, NULL),
(30, '2026-06-10', 'HalfDay', '09:00:00', '13:00:00'),
(30, '2026-06-11', 'Present', '09:01:00', '17:05:00'),
(30, '2026-06-12', 'Present', '09:01:00', '17:02:00'),
(30, '2026-06-13', 'Present', '09:03:00', '17:01:00'),
(30, '2026-06-14', 'Present', '09:03:00', '17:02:00'),
(30, '2026-06-15', 'Present', '09:03:00', '17:00:00'),
(30, '2026-06-16', 'Present', '09:01:00', '17:05:00'),
(30, '2026-06-17', 'Present', '09:04:00', '17:04:00'),
(30, '2026-06-18', 'Present', '09:00:00', '17:01:00'),
(30, '2026-06-19', 'Present', '09:03:00', '17:02:00'),
(30, '2026-06-20', 'Present', '09:03:00', '17:02:00'),
(30, '2026-06-21', 'Present', '09:03:00', '17:05:00'),
(30, '2026-06-22', 'HalfDay', '09:00:00', '13:00:00'),
(30, '2026-06-23', 'Present', '09:02:00', '17:04:00'),
(30, '2026-06-24', 'Leave', NULL, NULL),
(30, '2026-06-25', 'Present', '09:02:00', '17:01:00'),
(30, '2026-06-26', 'HalfDay', '09:00:00', '13:00:00'),
(30, '2026-06-27', 'HalfDay', '09:00:00', '13:00:00'),
(30, '2026-06-28', 'Present', '09:05:00', '17:05:00'),
(30, '2026-06-29', 'Present', '09:04:00', '17:01:00'),
(30, '2026-06-30', 'Present', '09:02:00', '17:03:00'),
(31, '2026-06-01', 'Present', '09:04:00', '17:01:00'),
(31, '2026-06-02', 'Present', '09:04:00', '17:01:00'),
(31, '2026-06-03', 'Present', '09:04:00', '17:00:00'),
(31, '2026-06-04', 'HalfDay', '09:00:00', '13:00:00'),
(31, '2026-06-05', 'Present', '09:05:00', '17:01:00'),
(31, '2026-06-06', 'Present', '09:02:00', '17:05:00'),
(31, '2026-06-07', 'Present', '09:03:00', '17:05:00'),
(31, '2026-06-08', 'Present', '09:05:00', '17:02:00'),
(31, '2026-06-09', 'Present', '09:05:00', '17:01:00'),
(31, '2026-06-10', 'Present', '09:03:00', '17:00:00'),
(31, '2026-06-11', 'Present', '09:04:00', '17:03:00'),
(31, '2026-06-12', 'Present', '09:04:00', '17:04:00'),
(31, '2026-06-13', 'Leave', NULL, NULL),
(31, '2026-06-14', 'Absent', NULL, NULL),
(31, '2026-06-15', 'Present', '09:00:00', '17:02:00'),
(31, '2026-06-16', 'Present', '09:04:00', '17:04:00'),
(31, '2026-06-17', 'Present', '09:00:00', '17:00:00'),
(31, '2026-06-18', 'Present', '09:05:00', '17:05:00'),
(31, '2026-06-19', 'Present', '09:05:00', '17:04:00'),
(31, '2026-06-20', 'Present', '09:05:00', '17:05:00'),
(31, '2026-06-21', 'Present', '09:02:00', '17:03:00'),
(31, '2026-06-22', 'Present', '09:00:00', '17:02:00'),
(31, '2026-06-23', 'Present', '09:05:00', '17:04:00'),
(31, '2026-06-24', 'Present', '09:05:00', '17:04:00'),
(31, '2026-06-25', 'Present', '09:02:00', '17:03:00'),
(31, '2026-06-26', 'Present', '09:05:00', '17:04:00'),
(31, '2026-06-27', 'Present', '09:01:00', '17:02:00'),
(31, '2026-06-28', 'HalfDay', '09:00:00', '13:00:00'),
(31, '2026-06-29', 'Present', '09:02:00', '17:03:00'),
(31, '2026-06-30', 'Leave', NULL, NULL),
(32, '2026-06-01', 'Present', '09:05:00', '17:01:00'),
(32, '2026-06-02', 'Present', '09:02:00', '17:03:00'),
(32, '2026-06-03', 'Present', '09:04:00', '17:03:00'),
(32, '2026-06-04', 'Present', '09:00:00', '17:03:00'),
(32, '2026-06-05', 'Present', '09:03:00', '17:02:00'),
(32, '2026-06-06', 'Present', '09:00:00', '17:05:00'),
(32, '2026-06-07', 'Present', '09:02:00', '17:05:00'),
(32, '2026-06-08', 'Present', '09:01:00', '17:05:00'),
(32, '2026-06-09', 'Present', '09:01:00', '17:04:00'),
(32, '2026-06-10', 'Present', '09:04:00', '17:03:00'),
(32, '2026-06-11', 'HalfDay', '09:00:00', '13:00:00'),
(32, '2026-06-12', 'Present', '09:03:00', '17:05:00'),
(32, '2026-06-13', 'Present', '09:05:00', '17:05:00'),
(32, '2026-06-14', 'Present', '09:00:00', '17:05:00'),
(32, '2026-06-15', 'Present', '09:01:00', '17:03:00'),
(32, '2026-06-16', 'Present', '09:03:00', '17:00:00'),
(32, '2026-06-17', 'Present', '09:01:00', '17:02:00'),
(32, '2026-06-18', 'Present', '09:00:00', '17:04:00'),
(32, '2026-06-19', 'Present', '09:04:00', '17:01:00'),
(32, '2026-06-20', 'Present', '09:01:00', '17:03:00'),
(32, '2026-06-21', 'Present', '09:05:00', '17:03:00'),
(32, '2026-06-22', 'Present', '09:05:00', '17:02:00'),
(32, '2026-06-23', 'Present', '09:04:00', '17:03:00'),
(32, '2026-06-24', 'Present', '09:02:00', '17:02:00'),
(32, '2026-06-25', 'Present', '09:04:00', '17:01:00'),
(32, '2026-06-26', 'Present', '09:05:00', '17:02:00'),
(32, '2026-06-27', 'Leave', NULL, NULL),
(32, '2026-06-28', 'Present', '09:05:00', '17:01:00'),
(32, '2026-06-29', 'Present', '09:01:00', '17:02:00'),
(32, '2026-06-30', 'Present', '09:02:00', '17:05:00'),
(33, '2026-06-01', 'Present', '09:03:00', '17:03:00'),
(33, '2026-06-02', 'Present', '09:04:00', '17:03:00'),
(33, '2026-06-03', 'Present', '09:03:00', '17:05:00'),
(33, '2026-06-04', 'Present', '09:05:00', '17:01:00'),
(33, '2026-06-05', 'Present', '09:03:00', '17:02:00'),
(33, '2026-06-06', 'Present', '09:02:00', '17:03:00'),
(33, '2026-06-07', 'Present', '09:02:00', '17:00:00'),
(33, '2026-06-08', 'Present', '09:01:00', '17:03:00'),
(33, '2026-06-09', 'HalfDay', '09:00:00', '13:00:00'),
(33, '2026-06-10', 'Present', '09:03:00', '17:03:00'),
(33, '2026-06-11', 'Present', '09:03:00', '17:05:00'),
(33, '2026-06-12', 'Present', '09:03:00', '17:01:00'),
(33, '2026-06-13', 'Present', '09:00:00', '17:01:00'),
(33, '2026-06-14', 'Present', '09:02:00', '17:01:00'),
(33, '2026-06-15', 'Present', '09:01:00', '17:03:00'),
(33, '2026-06-16', 'Present', '09:03:00', '17:04:00'),
(33, '2026-06-17', 'Present', '09:04:00', '17:00:00'),
(33, '2026-06-18', 'Present', '09:04:00', '17:02:00'),
(33, '2026-06-19', 'Present', '09:00:00', '17:05:00'),
(33, '2026-06-20', 'Present', '09:01:00', '17:03:00'),
(33, '2026-06-21', 'Present', '09:05:00', '17:01:00'),
(33, '2026-06-22', 'Present', '09:00:00', '17:03:00'),
(33, '2026-06-23', 'Present', '09:00:00', '17:03:00'),
(33, '2026-06-24', 'Absent', NULL, NULL),
(33, '2026-06-25', 'Present', '09:01:00', '17:01:00'),
(33, '2026-06-26', 'Present', '09:04:00', '17:05:00'),
(33, '2026-06-27', 'Present', '09:05:00', '17:04:00'),
(33, '2026-06-28', 'Present', '09:01:00', '17:04:00'),
(33, '2026-06-29', 'Present', '09:01:00', '17:01:00'),
(33, '2026-06-30', 'Present', '09:04:00', '17:02:00'),
(34, '2026-06-01', 'Present', '09:04:00', '17:04:00'),
(34, '2026-06-02', 'Present', '09:05:00', '17:02:00'),
(34, '2026-06-03', 'Present', '09:02:00', '17:04:00'),
(34, '2026-06-04', 'HalfDay', '09:00:00', '13:00:00'),
(34, '2026-06-05', 'Present', '09:00:00', '17:01:00'),
(34, '2026-06-06', 'HalfDay', '09:00:00', '13:00:00'),
(34, '2026-06-07', 'Present', '09:00:00', '17:02:00'),
(34, '2026-06-08', 'Absent', NULL, NULL),
(34, '2026-06-09', 'Present', '09:01:00', '17:01:00'),
(34, '2026-06-10', 'Present', '09:02:00', '17:01:00'),
(34, '2026-06-11', 'Present', '09:05:00', '17:03:00'),
(34, '2026-06-12', 'Present', '09:04:00', '17:05:00'),
(34, '2026-06-13', 'Present', '09:03:00', '17:03:00'),
(34, '2026-06-14', 'Present', '09:05:00', '17:00:00'),
(34, '2026-06-15', 'Present', '09:05:00', '17:02:00'),
(34, '2026-06-16', 'Present', '09:02:00', '17:03:00'),
(34, '2026-06-17', 'HalfDay', '09:00:00', '13:00:00'),
(34, '2026-06-18', 'Present', '09:00:00', '17:05:00'),
(34, '2026-06-19', 'Present', '09:03:00', '17:05:00'),
(34, '2026-06-20', 'Present', '09:02:00', '17:00:00'),
(34, '2026-06-21', 'Present', '09:03:00', '17:01:00'),
(34, '2026-06-22', 'HalfDay', '09:00:00', '13:00:00'),
(34, '2026-06-23', 'Present', '09:03:00', '17:02:00'),
(34, '2026-06-24', 'Present', '09:02:00', '17:02:00'),
(34, '2026-06-25', 'Present', '09:01:00', '17:04:00'),
(34, '2026-06-26', 'Absent', NULL, NULL),
(34, '2026-06-27', 'Present', '09:05:00', '17:00:00'),
(34, '2026-06-28', 'Present', '09:05:00', '17:03:00'),
(34, '2026-06-29', 'Present', '09:01:00', '17:03:00'),
(34, '2026-06-30', 'Present', '09:03:00', '17:01:00'),
(35, '2026-06-01', 'HalfDay', '09:00:00', '13:00:00'),
(35, '2026-06-02', 'Leave', NULL, NULL),
(35, '2026-06-03', 'Absent', NULL, NULL),
(35, '2026-06-04', 'Present', '09:02:00', '17:00:00'),
(35, '2026-06-05', 'Present', '09:02:00', '17:00:00'),
(35, '2026-06-06', 'Present', '09:05:00', '17:01:00'),
(35, '2026-06-07', 'Present', '09:05:00', '17:02:00'),
(35, '2026-06-08', 'Present', '09:01:00', '17:03:00'),
(35, '2026-06-09', 'Present', '09:05:00', '17:00:00'),
(35, '2026-06-10', 'Present', '09:03:00', '17:00:00'),
(35, '2026-06-11', 'Present', '09:01:00', '17:04:00'),
(35, '2026-06-12', 'Present', '09:00:00', '17:00:00'),
(35, '2026-06-13', 'Present', '09:00:00', '17:03:00'),
(35, '2026-06-14', 'Present', '09:03:00', '17:00:00'),
(35, '2026-06-15', 'Present', '09:00:00', '17:05:00'),
(35, '2026-06-16', 'Present', '09:00:00', '17:02:00'),
(35, '2026-06-17', 'Present', '09:02:00', '17:01:00'),
(35, '2026-06-18', 'Present', '09:01:00', '17:05:00'),
(35, '2026-06-19', 'HalfDay', '09:00:00', '13:00:00'),
(35, '2026-06-20', 'Present', '09:04:00', '17:04:00'),
(35, '2026-06-21', 'Present', '09:05:00', '17:01:00'),
(35, '2026-06-22', 'Present', '09:05:00', '17:01:00'),
(35, '2026-06-23', 'Present', '09:01:00', '17:03:00'),
(35, '2026-06-24', 'Present', '09:03:00', '17:01:00'),
(35, '2026-06-25', 'Present', '09:00:00', '17:01:00'),
(35, '2026-06-26', 'Present', '09:04:00', '17:05:00'),
(35, '2026-06-27', 'Present', '09:03:00', '17:02:00'),
(35, '2026-06-28', 'Present', '09:01:00', '17:02:00'),
(35, '2026-06-29', 'Present', '09:01:00', '17:04:00'),
(35, '2026-06-30', 'Present', '09:05:00', '17:04:00'),
(36, '2026-06-01', 'Present', '09:05:00', '17:00:00'),
(36, '2026-06-02', 'Present', '09:05:00', '17:02:00'),
(36, '2026-06-03', 'Present', '09:04:00', '17:04:00'),
(36, '2026-06-04', 'Present', '09:03:00', '17:02:00'),
(36, '2026-06-05', 'Present', '09:01:00', '17:03:00'),
(36, '2026-06-06', 'Present', '09:01:00', '17:03:00'),
(36, '2026-06-07', 'Present', '09:00:00', '17:04:00'),
(36, '2026-06-08', 'Absent', NULL, NULL),
(36, '2026-06-09', 'Present', '09:02:00', '17:02:00'),
(36, '2026-06-10', 'Present', '09:04:00', '17:03:00'),
(36, '2026-06-11', 'Present', '09:05:00', '17:01:00'),
(36, '2026-06-12', 'Present', '09:00:00', '17:00:00'),
(36, '2026-06-13', 'Present', '09:00:00', '17:02:00'),
(36, '2026-06-14', 'Present', '09:00:00', '17:03:00'),
(36, '2026-06-15', 'Present', '09:05:00', '17:05:00'),
(36, '2026-06-16', 'Present', '09:03:00', '17:03:00'),
(36, '2026-06-17', 'Present', '09:00:00', '17:05:00'),
(36, '2026-06-18', 'Present', '09:04:00', '17:01:00'),
(36, '2026-06-19', 'Present', '09:02:00', '17:00:00'),
(36, '2026-06-20', 'Present', '09:01:00', '17:01:00'),
(36, '2026-06-21', 'Present', '09:03:00', '17:04:00'),
(36, '2026-06-22', 'Present', '09:05:00', '17:05:00'),
(36, '2026-06-23', 'Present', '09:02:00', '17:05:00'),
(36, '2026-06-24', 'Present', '09:01:00', '17:00:00'),
(36, '2026-06-25', 'Present', '09:03:00', '17:00:00'),
(36, '2026-06-26', 'Present', '09:04:00', '17:00:00'),
(36, '2026-06-27', 'Present', '09:05:00', '17:05:00'),
(36, '2026-06-28', 'Present', '09:00:00', '17:00:00'),
(36, '2026-06-29', 'Present', '09:05:00', '17:00:00'),
(36, '2026-06-30', 'Present', '09:02:00', '17:04:00'),
(37, '2026-06-01', 'Present', '09:05:00', '17:02:00'),
(37, '2026-06-02', 'Present', '09:01:00', '17:05:00'),
(37, '2026-06-03', 'Present', '09:02:00', '17:05:00'),
(37, '2026-06-04', 'Absent', NULL, NULL),
(37, '2026-06-05', 'Present', '09:00:00', '17:02:00'),
(37, '2026-06-06', 'Present', '09:02:00', '17:04:00'),
(37, '2026-06-07', 'Present', '09:05:00', '17:04:00'),
(37, '2026-06-08', 'Present', '09:03:00', '17:03:00'),
(37, '2026-06-09', 'Present', '09:00:00', '17:03:00'),
(37, '2026-06-10', 'Absent', NULL, NULL),
(37, '2026-06-11', 'Present', '09:01:00', '17:02:00'),
(37, '2026-06-12', 'Present', '09:04:00', '17:05:00'),
(37, '2026-06-13', 'Present', '09:01:00', '17:05:00'),
(37, '2026-06-14', 'Present', '09:00:00', '17:00:00'),
(37, '2026-06-15', 'Present', '09:03:00', '17:02:00'),
(37, '2026-06-16', 'Present', '09:01:00', '17:01:00'),
(37, '2026-06-17', 'Leave', NULL, NULL),
(37, '2026-06-18', 'Absent', NULL, NULL),
(37, '2026-06-19', 'Present', '09:05:00', '17:05:00'),
(37, '2026-06-20', 'Present', '09:01:00', '17:02:00'),
(37, '2026-06-21', 'Present', '09:05:00', '17:02:00'),
(37, '2026-06-22', 'Present', '09:00:00', '17:04:00'),
(37, '2026-06-23', 'Present', '09:04:00', '17:05:00'),
(37, '2026-06-24', 'Leave', NULL, NULL),
(37, '2026-06-25', 'Present', '09:04:00', '17:00:00'),
(37, '2026-06-26', 'HalfDay', '09:00:00', '13:00:00'),
(37, '2026-06-27', 'Present', '09:03:00', '17:02:00'),
(37, '2026-06-28', 'Present', '09:02:00', '17:02:00'),
(37, '2026-06-29', 'Present', '09:03:00', '17:00:00'),
(37, '2026-06-30', 'Present', '09:02:00', '17:04:00'),
(38, '2026-06-01', 'Present', '09:05:00', '17:04:00'),
(38, '2026-06-02', 'Present', '09:02:00', '17:04:00'),
(38, '2026-06-03', 'HalfDay', '09:00:00', '13:00:00'),
(38, '2026-06-04', 'HalfDay', '09:00:00', '13:00:00'),
(38, '2026-06-05', 'Present', '09:05:00', '17:04:00'),
(38, '2026-06-06', 'Present', '09:01:00', '17:01:00'),
(38, '2026-06-07', 'Present', '09:03:00', '17:00:00'),
(38, '2026-06-08', 'Present', '09:02:00', '17:05:00'),
(38, '2026-06-09', 'Present', '09:00:00', '17:02:00'),
(38, '2026-06-10', 'Present', '09:05:00', '17:03:00'),
(38, '2026-06-11', 'Present', '09:05:00', '17:02:00'),
(38, '2026-06-12', 'Present', '09:04:00', '17:01:00'),
(38, '2026-06-13', 'Present', '09:00:00', '17:01:00'),
(38, '2026-06-14', 'Present', '09:00:00', '17:00:00'),
(38, '2026-06-15', 'Leave', NULL, NULL),
(38, '2026-06-16', 'Absent', NULL, NULL),
(38, '2026-06-17', 'Present', '09:05:00', '17:02:00'),
(38, '2026-06-18', 'Present', '09:05:00', '17:00:00'),
(38, '2026-06-19', 'Present', '09:04:00', '17:01:00'),
(38, '2026-06-20', 'Present', '09:03:00', '17:00:00'),
(38, '2026-06-21', 'Present', '09:00:00', '17:03:00'),
(38, '2026-06-22', 'Present', '09:01:00', '17:01:00'),
(38, '2026-06-23', 'Present', '09:02:00', '17:03:00'),
(38, '2026-06-24', 'Present', '09:05:00', '17:02:00'),
(38, '2026-06-25', 'Present', '09:02:00', '17:01:00'),
(38, '2026-06-26', 'Present', '09:01:00', '17:01:00'),
(38, '2026-06-27', 'Present', '09:04:00', '17:00:00'),
(38, '2026-06-28', 'Present', '09:01:00', '17:03:00'),
(38, '2026-06-29', 'Present', '09:03:00', '17:00:00'),
(38, '2026-06-30', 'Present', '09:01:00', '17:03:00'),
(39, '2026-06-01', 'Present', '09:02:00', '17:00:00'),
(39, '2026-06-02', 'Present', '09:05:00', '17:02:00'),
(39, '2026-06-03', 'Present', '09:05:00', '17:04:00'),
(39, '2026-06-04', 'Present', '09:02:00', '17:01:00'),
(39, '2026-06-05', 'Present', '09:01:00', '17:02:00'),
(39, '2026-06-06', 'Present', '09:00:00', '17:05:00'),
(39, '2026-06-07', 'Present', '09:01:00', '17:00:00'),
(39, '2026-06-08', 'HalfDay', '09:00:00', '13:00:00'),
(39, '2026-06-09', 'Absent', NULL, NULL),
(39, '2026-06-10', 'Present', '09:04:00', '17:01:00'),
(39, '2026-06-11', 'Present', '09:00:00', '17:01:00'),
(39, '2026-06-12', 'Present', '09:00:00', '17:01:00'),
(39, '2026-06-13', 'Present', '09:03:00', '17:02:00'),
(39, '2026-06-14', 'Present', '09:05:00', '17:00:00'),
(39, '2026-06-15', 'Present', '09:02:00', '17:00:00'),
(39, '2026-06-16', 'Present', '09:00:00', '17:01:00'),
(39, '2026-06-17', 'Leave', NULL, NULL),
(39, '2026-06-18', 'Present', '09:01:00', '17:00:00'),
(39, '2026-06-19', 'Leave', NULL, NULL),
(39, '2026-06-20', 'Present', '09:02:00', '17:00:00'),
(39, '2026-06-21', 'Present', '09:03:00', '17:00:00'),
(39, '2026-06-22', 'Present', '09:04:00', '17:03:00'),
(39, '2026-06-23', 'Present', '09:03:00', '17:03:00'),
(39, '2026-06-24', 'Present', '09:05:00', '17:03:00'),
(39, '2026-06-25', 'Present', '09:01:00', '17:01:00'),
(39, '2026-06-26', 'Present', '09:03:00', '17:01:00'),
(39, '2026-06-27', 'Present', '09:04:00', '17:04:00'),
(39, '2026-06-28', 'Present', '09:02:00', '17:03:00'),
(39, '2026-06-29', 'Present', '09:04:00', '17:03:00'),
(39, '2026-06-30', 'Present', '09:02:00', '17:03:00'),
(40, '2026-06-01', 'Present', '09:01:00', '17:05:00'),
(40, '2026-06-02', 'Absent', NULL, NULL),
(40, '2026-06-03', 'Present', '09:05:00', '17:04:00'),
(40, '2026-06-04', 'Present', '09:03:00', '17:05:00'),
(40, '2026-06-05', 'Present', '09:04:00', '17:03:00'),
(40, '2026-06-06', 'Present', '09:04:00', '17:04:00'),
(40, '2026-06-07', 'Present', '09:02:00', '17:01:00'),
(40, '2026-06-08', 'Present', '09:04:00', '17:01:00'),
(40, '2026-06-09', 'Present', '09:02:00', '17:00:00'),
(40, '2026-06-10', 'Present', '09:03:00', '17:04:00'),
(40, '2026-06-11', 'Present', '09:04:00', '17:01:00'),
(40, '2026-06-12', 'HalfDay', '09:00:00', '13:00:00'),
(40, '2026-06-13', 'Present', '09:05:00', '17:01:00'),
(40, '2026-06-14', 'Present', '09:05:00', '17:00:00'),
(40, '2026-06-15', 'Present', '09:01:00', '17:04:00'),
(40, '2026-06-16', 'Present', '09:03:00', '17:02:00'),
(40, '2026-06-17', 'Leave', NULL, NULL),
(40, '2026-06-18', 'HalfDay', '09:00:00', '13:00:00'),
(40, '2026-06-19', 'Present', '09:01:00', '17:04:00'),
(40, '2026-06-20', 'Present', '09:05:00', '17:05:00'),
(40, '2026-06-21', 'Present', '09:04:00', '17:00:00'),
(40, '2026-06-22', 'Present', '09:02:00', '17:04:00'),
(40, '2026-06-23', 'Present', '09:04:00', '17:01:00'),
(40, '2026-06-24', 'Present', '09:03:00', '17:04:00'),
(40, '2026-06-25', 'Present', '09:03:00', '17:00:00'),
(40, '2026-06-26', 'Present', '09:01:00', '17:04:00'),
(40, '2026-06-27', 'Present', '09:04:00', '17:03:00'),
(40, '2026-06-28', 'Present', '09:04:00', '17:01:00'),
(40, '2026-06-29', 'Present', '09:02:00', '17:05:00'),
(40, '2026-06-30', 'Present', '09:02:00', '17:00:00');
GO

-- LeaveTypes (5 rows)
INSERT INTO LeaveTypes (LeaveTypeName, MaxDaysAllowed) VALUES
('Annual Leave', 14),
('Sick Leave', 10),
('Casual Leave', 8),
('Maternity Leave', 90),
('Unpaid Leave', 30);
GO

-- LeaveApplications (60 rows)
INSERT INTO LeaveApplications (EmployeeID, LeaveTypeID, StartDate, EndDate, TotalDays, Reason, Status, AppliedDate) VALUES
(2, 2, '2026-05-05', '2026-05-05', 1, 'Emergency at home', 'Approved', '2026-05-02'),
(5, 3, '2026-06-13', '2026-06-17', 5, 'Fever', 'Approved', '2026-06-10'),
(9, 2, '2026-06-14', '2026-06-17', 4, 'Rest', 'Approved', '2026-06-09'),
(40, 3, '2026-02-19', '2026-02-20', 2, 'Medical checkup', 'Approved', '2026-02-16'),
(9, 2, '2026-06-01', '2026-06-05', 5, 'Medical checkup', 'Rejected', '2026-05-27'),
(3, 2, '2026-05-11', '2026-05-15', 5, 'Family function', 'Approved', '2026-05-10'),
(32, 2, '2026-03-03', '2026-03-04', 2, 'Personal work', 'Rejected', '2026-03-01'),
(6, 3, '2026-04-01', '2026-04-03', 3, 'Family function', 'Approved', '2026-03-31'),
(23, 3, '2026-01-01', '2026-01-01', 1, 'Medical checkup', 'Approved', '2025-12-28'),
(11, 4, '2026-04-13', '2026-04-15', 3, 'Travel', 'Approved', '2026-04-09'),
(37, 2, '2026-02-15', '2026-02-15', 1, 'Emergency at home', 'Rejected', '2026-02-12'),
(2, 3, '2026-03-04', '2026-03-04', 1, 'Personal work', 'Pending', '2026-02-28'),
(11, 1, '2026-05-03', '2026-05-05', 3, 'Travel', 'Rejected', '2026-04-29'),
(2, 4, '2026-06-06', '2026-06-10', 5, 'Medical checkup', 'Pending', '2026-06-05'),
(22, 2, '2026-02-14', '2026-02-18', 5, 'Rest', 'Rejected', '2026-02-09'),
(17, 3, '2026-03-08', '2026-03-08', 1, 'Fever', 'Approved', '2026-03-03'),
(32, 2, '2026-01-12', '2026-01-12', 1, 'Medical checkup', 'Pending', '2026-01-07'),
(31, 2, '2026-01-01', '2026-01-02', 2, 'Family function', 'Approved', '2025-12-31'),
(31, 1, '2026-03-13', '2026-03-16', 4, 'Medical checkup', 'Rejected', '2026-03-10'),
(6, 5, '2026-04-06', '2026-04-08', 3, 'Medical checkup', 'Approved', '2026-04-02'),
(3, 3, '2026-04-15', '2026-04-17', 3, 'Family function', 'Rejected', '2026-04-10'),
(4, 2, '2026-06-04', '2026-06-04', 1, 'Rest', 'Approved', '2026-05-30'),
(27, 5, '2026-02-18', '2026-02-18', 1, 'Emergency at home', 'Approved', '2026-02-13'),
(27, 5, '2026-06-16', '2026-06-20', 5, 'Family function', 'Approved', '2026-06-15'),
(26, 1, '2026-05-19', '2026-05-23', 5, 'Emergency at home', 'Approved', '2026-05-14'),
(10, 1, '2026-04-06', '2026-04-07', 2, 'Family function', 'Rejected', '2026-04-04'),
(3, 4, '2026-01-14', '2026-01-15', 2, 'Emergency at home', 'Approved', '2026-01-09'),
(17, 3, '2026-06-03', '2026-06-03', 1, 'Medical checkup', 'Approved', '2026-05-29'),
(21, 3, '2026-05-15', '2026-05-15', 1, 'Emergency at home', 'Approved', '2026-05-10'),
(34, 4, '2026-01-14', '2026-01-15', 2, 'Family function', 'Approved', '2026-01-09'),
(7, 1, '2026-05-04', '2026-05-06', 3, 'Emergency at home', 'Approved', '2026-05-01'),
(27, 3, '2026-04-16', '2026-04-20', 5, 'Travel', 'Approved', '2026-04-14'),
(18, 4, '2026-02-20', '2026-02-24', 5, 'Rest', 'Approved', '2026-02-19'),
(26, 3, '2026-06-08', '2026-06-08', 1, 'Rest', 'Approved', '2026-06-05'),
(24, 1, '2026-03-10', '2026-03-12', 3, 'Personal work', 'Rejected', '2026-03-09'),
(15, 2, '2026-03-15', '2026-03-17', 3, 'Personal work', 'Approved', '2026-03-10'),
(6, 2, '2026-04-07', '2026-04-10', 4, 'Rest', 'Approved', '2026-04-02'),
(24, 1, '2026-05-06', '2026-05-06', 1, 'Personal work', 'Approved', '2026-05-02'),
(9, 5, '2026-05-01', '2026-05-02', 2, 'Family function', 'Rejected', '2026-04-29'),
(4, 2, '2026-01-15', '2026-01-15', 1, 'Personal work', 'Approved', '2026-01-12'),
(24, 4, '2026-05-13', '2026-05-13', 1, 'Rest', 'Pending', '2026-05-10'),
(32, 5, '2026-04-06', '2026-04-09', 4, 'Travel', 'Approved', '2026-04-03'),
(11, 3, '2026-06-03', '2026-06-05', 3, 'Fever', 'Approved', '2026-06-01'),
(37, 2, '2026-02-08', '2026-02-09', 2, 'Personal work', 'Approved', '2026-02-03'),
(2, 1, '2026-04-05', '2026-04-06', 2, 'Travel', 'Rejected', '2026-04-03'),
(17, 5, '2026-03-09', '2026-03-12', 4, 'Medical checkup', 'Rejected', '2026-03-05'),
(17, 2, '2026-04-10', '2026-04-14', 5, 'Emergency at home', 'Approved', '2026-04-05'),
(7, 1, '2026-05-12', '2026-05-16', 5, 'Rest', 'Approved', '2026-05-09'),
(20, 1, '2026-04-03', '2026-04-05', 3, 'Personal work', 'Approved', '2026-03-31'),
(17, 3, '2026-02-05', '2026-02-09', 5, 'Emergency at home', 'Approved', '2026-02-04'),
(39, 4, '2026-06-11', '2026-06-12', 2, 'Rest', 'Pending', '2026-06-07'),
(19, 3, '2026-04-13', '2026-04-16', 4, 'Rest', 'Pending', '2026-04-08'),
(13, 3, '2026-06-08', '2026-06-12', 5, 'Rest', 'Approved', '2026-06-05'),
(33, 3, '2026-02-18', '2026-02-19', 2, 'Personal work', 'Pending', '2026-02-16'),
(17, 5, '2026-02-11', '2026-02-11', 1, 'Family function', 'Approved', '2026-02-08'),
(27, 3, '2026-03-09', '2026-03-13', 5, 'Personal work', 'Approved', '2026-03-08'),
(31, 1, '2026-06-19', '2026-06-23', 5, 'Travel', 'Pending', '2026-06-17'),
(33, 1, '2026-06-13', '2026-06-17', 5, 'Personal work', 'Approved', '2026-06-11'),
(9, 2, '2026-03-14', '2026-03-18', 5, 'Medical checkup', 'Pending', '2026-03-12'),
(6, 4, '2026-03-06', '2026-03-08', 3, 'Rest', 'Pending', '2026-03-02');
GO



-- AllowanceTypes (2 rows) -- feeds the Employee Form "Allowance Type" dropdown via GET /api/allowancetypes
INSERT INTO AllowanceTypes (AllowanceTypeName) VALUES
('Fuel Allowance'),
('Mobile Allowance');
GO

-- DeductionTypes (2 rows) -- feeds the Employee Form "Deduction Type" dropdown via GET /api/deductiontypes
INSERT INTO DeductionTypes (DeductionTypeName) VALUES
('EOBI'),
('Advance Payment');
GO

-- SalaryAllowances (40 employees x 3 months x 2 allowance types = 240 rows)
-- EmployeeID, AllowanceTypeID (1=Fuel Allowance, 2=Mobile Allowance), PayMonth, PayYear, Amount
INSERT INTO SalaryAllowances (EmployeeID, AllowanceTypeID, PayMonth, PayYear, Amount) VALUES
(1, 1, 4, 2026, 8000.00),
(1, 2, 4, 2026, 2500.00),
(1, 1, 5, 2026, 8000.00),
(1, 2, 5, 2026, 2500.00),
(1, 1, 6, 2026, 8000.00),
(1, 2, 6, 2026, 2500.00),
(2, 1, 4, 2026, 8000.00),
(2, 2, 4, 2026, 2500.00),
(2, 1, 5, 2026, 8000.00),
(2, 2, 5, 2026, 2500.00),
(2, 1, 6, 2026, 8000.00),
(2, 2, 6, 2026, 2500.00),
(3, 1, 4, 2026, 8000.00),
(3, 2, 4, 2026, 2500.00),
(3, 1, 5, 2026, 8000.00),
(3, 2, 5, 2026, 2500.00),
(3, 1, 6, 2026, 8000.00),
(3, 2, 6, 2026, 2500.00),
(4, 1, 4, 2026, 8000.00),
(4, 2, 4, 2026, 2500.00),
(4, 1, 5, 2026, 8000.00),
(4, 2, 5, 2026, 2500.00),
(4, 1, 6, 2026, 8000.00),
(4, 2, 6, 2026, 2500.00),
(5, 1, 4, 2026, 8000.00),
(5, 2, 4, 2026, 2500.00),
(5, 1, 5, 2026, 8000.00),
(5, 2, 5, 2026, 2500.00),
(5, 1, 6, 2026, 8000.00),
(5, 2, 6, 2026, 2500.00),
(6, 1, 4, 2026, 8000.00),
(6, 2, 4, 2026, 2500.00),
(6, 1, 5, 2026, 8000.00),
(6, 2, 5, 2026, 2500.00),
(6, 1, 6, 2026, 8000.00),
(6, 2, 6, 2026, 2500.00),
(7, 1, 4, 2026, 8000.00),
(7, 2, 4, 2026, 2500.00),
(7, 1, 5, 2026, 8000.00),
(7, 2, 5, 2026, 2500.00),
(7, 1, 6, 2026, 8000.00),
(7, 2, 6, 2026, 2500.00),
(8, 1, 4, 2026, 8000.00),
(8, 2, 4, 2026, 2500.00),
(8, 1, 5, 2026, 8000.00),
(8, 2, 5, 2026, 2500.00),
(8, 1, 6, 2026, 8000.00),
(8, 2, 6, 2026, 2500.00),
(9, 1, 4, 2026, 8000.00),
(9, 2, 4, 2026, 2500.00),
(9, 1, 5, 2026, 8000.00),
(9, 2, 5, 2026, 2500.00),
(9, 1, 6, 2026, 8000.00),
(9, 2, 6, 2026, 2500.00),
(10, 1, 4, 2026, 8000.00),
(10, 2, 4, 2026, 2500.00),
(10, 1, 5, 2026, 8000.00),
(10, 2, 5, 2026, 2500.00),
(10, 1, 6, 2026, 8000.00),
(10, 2, 6, 2026, 2500.00),
(11, 1, 4, 2026, 8000.00),
(11, 2, 4, 2026, 2500.00),
(11, 1, 5, 2026, 8000.00),
(11, 2, 5, 2026, 2500.00),
(11, 1, 6, 2026, 8000.00),
(11, 2, 6, 2026, 2500.00),
(12, 1, 4, 2026, 8000.00),
(12, 2, 4, 2026, 2500.00),
(12, 1, 5, 2026, 8000.00),
(12, 2, 5, 2026, 2500.00),
(12, 1, 6, 2026, 8000.00),
(12, 2, 6, 2026, 2500.00),
(13, 1, 4, 2026, 8000.00),
(13, 2, 4, 2026, 2500.00),
(13, 1, 5, 2026, 8000.00),
(13, 2, 5, 2026, 2500.00),
(13, 1, 6, 2026, 8000.00),
(13, 2, 6, 2026, 2500.00),
(14, 1, 4, 2026, 8000.00),
(14, 2, 4, 2026, 2500.00),
(14, 1, 5, 2026, 8000.00),
(14, 2, 5, 2026, 2500.00),
(14, 1, 6, 2026, 8000.00),
(14, 2, 6, 2026, 2500.00),
(15, 1, 4, 2026, 8000.00),
(15, 2, 4, 2026, 2500.00),
(15, 1, 5, 2026, 8000.00),
(15, 2, 5, 2026, 2500.00),
(15, 1, 6, 2026, 8000.00),
(15, 2, 6, 2026, 2500.00),
(16, 1, 4, 2026, 8000.00),
(16, 2, 4, 2026, 2500.00),
(16, 1, 5, 2026, 8000.00),
(16, 2, 5, 2026, 2500.00),
(16, 1, 6, 2026, 8000.00),
(16, 2, 6, 2026, 2500.00),
(17, 1, 4, 2026, 8000.00),
(17, 2, 4, 2026, 2500.00),
(17, 1, 5, 2026, 8000.00),
(17, 2, 5, 2026, 2500.00),
(17, 1, 6, 2026, 8000.00),
(17, 2, 6, 2026, 2500.00),
(18, 1, 4, 2026, 8000.00),
(18, 2, 4, 2026, 2500.00),
(18, 1, 5, 2026, 8000.00),
(18, 2, 5, 2026, 2500.00),
(18, 1, 6, 2026, 8000.00),
(18, 2, 6, 2026, 2500.00),
(19, 1, 4, 2026, 8000.00),
(19, 2, 4, 2026, 2500.00),
(19, 1, 5, 2026, 8000.00),
(19, 2, 5, 2026, 2500.00),
(19, 1, 6, 2026, 8000.00),
(19, 2, 6, 2026, 2500.00),
(20, 1, 4, 2026, 8000.00),
(20, 2, 4, 2026, 2500.00),
(20, 1, 5, 2026, 8000.00),
(20, 2, 5, 2026, 2500.00),
(20, 1, 6, 2026, 8000.00),
(20, 2, 6, 2026, 2500.00),
(21, 1, 4, 2026, 8000.00),
(21, 2, 4, 2026, 2500.00),
(21, 1, 5, 2026, 8000.00),
(21, 2, 5, 2026, 2500.00),
(21, 1, 6, 2026, 8000.00),
(21, 2, 6, 2026, 2500.00),
(22, 1, 4, 2026, 8000.00),
(22, 2, 4, 2026, 2500.00),
(22, 1, 5, 2026, 8000.00),
(22, 2, 5, 2026, 2500.00),
(22, 1, 6, 2026, 8000.00),
(22, 2, 6, 2026, 2500.00),
(23, 1, 4, 2026, 8000.00),
(23, 2, 4, 2026, 2500.00),
(23, 1, 5, 2026, 8000.00),
(23, 2, 5, 2026, 2500.00),
(23, 1, 6, 2026, 8000.00),
(23, 2, 6, 2026, 2500.00),
(24, 1, 4, 2026, 8000.00),
(24, 2, 4, 2026, 2500.00),
(24, 1, 5, 2026, 8000.00),
(24, 2, 5, 2026, 2500.00),
(24, 1, 6, 2026, 8000.00),
(24, 2, 6, 2026, 2500.00),
(25, 1, 4, 2026, 8000.00),
(25, 2, 4, 2026, 2500.00),
(25, 1, 5, 2026, 8000.00),
(25, 2, 5, 2026, 2500.00),
(25, 1, 6, 2026, 8000.00),
(25, 2, 6, 2026, 2500.00),
(26, 1, 4, 2026, 8000.00),
(26, 2, 4, 2026, 2500.00),
(26, 1, 5, 2026, 8000.00),
(26, 2, 5, 2026, 2500.00),
(26, 1, 6, 2026, 8000.00),
(26, 2, 6, 2026, 2500.00),
(27, 1, 4, 2026, 8000.00),
(27, 2, 4, 2026, 2500.00),
(27, 1, 5, 2026, 8000.00),
(27, 2, 5, 2026, 2500.00),
(27, 1, 6, 2026, 8000.00),
(27, 2, 6, 2026, 2500.00),
(28, 1, 4, 2026, 8000.00),
(28, 2, 4, 2026, 2500.00),
(28, 1, 5, 2026, 8000.00),
(28, 2, 5, 2026, 2500.00),
(28, 1, 6, 2026, 8000.00),
(28, 2, 6, 2026, 2500.00),
(29, 1, 4, 2026, 8000.00),
(29, 2, 4, 2026, 2500.00),
(29, 1, 5, 2026, 8000.00),
(29, 2, 5, 2026, 2500.00),
(29, 1, 6, 2026, 8000.00),
(29, 2, 6, 2026, 2500.00),
(30, 1, 4, 2026, 8000.00),
(30, 2, 4, 2026, 2500.00),
(30, 1, 5, 2026, 8000.00),
(30, 2, 5, 2026, 2500.00),
(30, 1, 6, 2026, 8000.00),
(30, 2, 6, 2026, 2500.00),
(31, 1, 4, 2026, 8000.00),
(31, 2, 4, 2026, 2500.00),
(31, 1, 5, 2026, 8000.00),
(31, 2, 5, 2026, 2500.00),
(31, 1, 6, 2026, 8000.00),
(31, 2, 6, 2026, 2500.00),
(32, 1, 4, 2026, 8000.00),
(32, 2, 4, 2026, 2500.00),
(32, 1, 5, 2026, 8000.00),
(32, 2, 5, 2026, 2500.00),
(32, 1, 6, 2026, 8000.00),
(32, 2, 6, 2026, 2500.00),
(33, 1, 4, 2026, 8000.00),
(33, 2, 4, 2026, 2500.00),
(33, 1, 5, 2026, 8000.00),
(33, 2, 5, 2026, 2500.00),
(33, 1, 6, 2026, 8000.00),
(33, 2, 6, 2026, 2500.00),
(34, 1, 4, 2026, 8000.00),
(34, 2, 4, 2026, 2500.00),
(34, 1, 5, 2026, 8000.00),
(34, 2, 5, 2026, 2500.00),
(34, 1, 6, 2026, 8000.00),
(34, 2, 6, 2026, 2500.00),
(35, 1, 4, 2026, 8000.00),
(35, 2, 4, 2026, 2500.00),
(35, 1, 5, 2026, 8000.00),
(35, 2, 5, 2026, 2500.00),
(35, 1, 6, 2026, 8000.00),
(35, 2, 6, 2026, 2500.00),
(36, 1, 4, 2026, 8000.00),
(36, 2, 4, 2026, 2500.00),
(36, 1, 5, 2026, 8000.00),
(36, 2, 5, 2026, 2500.00),
(36, 1, 6, 2026, 8000.00),
(36, 2, 6, 2026, 2500.00),
(37, 1, 4, 2026, 8000.00),
(37, 2, 4, 2026, 2500.00),
(37, 1, 5, 2026, 8000.00),
(37, 2, 5, 2026, 2500.00),
(37, 1, 6, 2026, 8000.00),
(37, 2, 6, 2026, 2500.00),
(38, 1, 4, 2026, 8000.00),
(38, 2, 4, 2026, 2500.00),
(38, 1, 5, 2026, 8000.00),
(38, 2, 5, 2026, 2500.00),
(38, 1, 6, 2026, 8000.00),
(38, 2, 6, 2026, 2500.00),
(39, 1, 4, 2026, 8000.00),
(39, 2, 4, 2026, 2500.00),
(39, 1, 5, 2026, 8000.00),
(39, 2, 5, 2026, 2500.00),
(39, 1, 6, 2026, 8000.00),
(39, 2, 6, 2026, 2500.00),
(40, 1, 4, 2026, 8000.00),
(40, 2, 4, 2026, 2500.00),
(40, 1, 5, 2026, 8000.00),
(40, 2, 5, 2026, 2500.00),
(40, 1, 6, 2026, 8000.00),
(40, 2, 6, 2026, 2500.00);
GO

-- SalaryDeductions (120 EOBI rows, every employee every month, + 4 Advance Payment rows for employees who took an advance)
-- EmployeeID, DeductionTypeID (1=EOBI, 2=Advance Payment), PayMonth, PayYear, Amount
INSERT INTO SalaryDeductions (EmployeeID, DeductionTypeID, PayMonth, PayYear, Amount) VALUES
(1, 1, 4, 2026, 1000.00),
(1, 1, 5, 2026, 1000.00),
(1, 1, 6, 2026, 1000.00),
(2, 1, 4, 2026, 1000.00),
(2, 1, 5, 2026, 1000.00),
(2, 1, 6, 2026, 1000.00),
(3, 1, 4, 2026, 1000.00),
(3, 1, 5, 2026, 1000.00),
(3, 1, 6, 2026, 1000.00),
(4, 1, 4, 2026, 1000.00),
(4, 1, 5, 2026, 1000.00),
(4, 1, 6, 2026, 1000.00),
(5, 1, 4, 2026, 1000.00),
(5, 1, 5, 2026, 1000.00),
(5, 1, 6, 2026, 1000.00),
(6, 1, 4, 2026, 1000.00),
(6, 1, 5, 2026, 1000.00),
(6, 1, 6, 2026, 1000.00),
(7, 1, 4, 2026, 1000.00),
(7, 1, 5, 2026, 1000.00),
(7, 1, 6, 2026, 1000.00),
(8, 1, 4, 2026, 1000.00),
(8, 1, 5, 2026, 1000.00),
(8, 1, 6, 2026, 1000.00),
(9, 1, 4, 2026, 1000.00),
(9, 1, 5, 2026, 1000.00),
(9, 1, 6, 2026, 1000.00),
(10, 1, 4, 2026, 1000.00),
(10, 1, 5, 2026, 1000.00),
(10, 1, 6, 2026, 1000.00),
(11, 1, 4, 2026, 1000.00),
(11, 1, 5, 2026, 1000.00),
(11, 1, 6, 2026, 1000.00),
(12, 1, 4, 2026, 1000.00),
(12, 1, 5, 2026, 1000.00),
(12, 1, 6, 2026, 1000.00),
(13, 1, 4, 2026, 1000.00),
(13, 1, 5, 2026, 1000.00),
(13, 1, 6, 2026, 1000.00),
(14, 1, 4, 2026, 1000.00),
(14, 1, 5, 2026, 1000.00),
(14, 1, 6, 2026, 1000.00),
(15, 1, 4, 2026, 1000.00),
(15, 1, 5, 2026, 1000.00),
(15, 1, 6, 2026, 1000.00),
(16, 1, 4, 2026, 1000.00),
(16, 1, 5, 2026, 1000.00),
(16, 1, 6, 2026, 1000.00),
(17, 1, 4, 2026, 1000.00),
(17, 1, 5, 2026, 1000.00),
(17, 1, 6, 2026, 1000.00),
(18, 1, 4, 2026, 1000.00),
(18, 1, 5, 2026, 1000.00),
(18, 1, 6, 2026, 1000.00),
(19, 1, 4, 2026, 1000.00),
(19, 1, 5, 2026, 1000.00),
(19, 1, 6, 2026, 1000.00),
(20, 1, 4, 2026, 1000.00),
(20, 1, 5, 2026, 1000.00),
(20, 1, 6, 2026, 1000.00),
(21, 1, 4, 2026, 1000.00),
(21, 1, 5, 2026, 1000.00),
(21, 1, 6, 2026, 1000.00),
(22, 1, 4, 2026, 1000.00),
(22, 1, 5, 2026, 1000.00),
(22, 1, 6, 2026, 1000.00),
(23, 1, 4, 2026, 1000.00),
(23, 1, 5, 2026, 1000.00),
(23, 1, 6, 2026, 1000.00),
(24, 1, 4, 2026, 1000.00),
(24, 1, 5, 2026, 1000.00),
(24, 1, 6, 2026, 1000.00),
(25, 1, 4, 2026, 1000.00),
(25, 1, 5, 2026, 1000.00),
(25, 1, 6, 2026, 1000.00),
(26, 1, 4, 2026, 1000.00),
(26, 1, 5, 2026, 1000.00),
(26, 1, 6, 2026, 1000.00),
(27, 1, 4, 2026, 1000.00),
(27, 1, 5, 2026, 1000.00),
(27, 1, 6, 2026, 1000.00),
(28, 1, 4, 2026, 1000.00),
(28, 1, 5, 2026, 1000.00),
(28, 1, 6, 2026, 1000.00),
(29, 1, 4, 2026, 1000.00),
(29, 1, 5, 2026, 1000.00),
(29, 1, 6, 2026, 1000.00),
(30, 1, 4, 2026, 1000.00),
(30, 1, 5, 2026, 1000.00),
(30, 1, 6, 2026, 1000.00),
(31, 1, 4, 2026, 1000.00),
(31, 1, 5, 2026, 1000.00),
(31, 1, 6, 2026, 1000.00),
(32, 1, 4, 2026, 1000.00),
(32, 1, 5, 2026, 1000.00),
(32, 1, 6, 2026, 1000.00),
(33, 1, 4, 2026, 1000.00),
(33, 1, 5, 2026, 1000.00),
(33, 1, 6, 2026, 1000.00),
(34, 1, 4, 2026, 1000.00),
(34, 1, 5, 2026, 1000.00),
(34, 1, 6, 2026, 1000.00),
(35, 1, 4, 2026, 1000.00),
(35, 1, 5, 2026, 1000.00),
(35, 1, 6, 2026, 1000.00),
(36, 1, 4, 2026, 1000.00),
(36, 1, 5, 2026, 1000.00),
(36, 1, 6, 2026, 1000.00),
(37, 1, 4, 2026, 1000.00),
(37, 1, 5, 2026, 1000.00),
(37, 1, 6, 2026, 1000.00),
(38, 1, 4, 2026, 1000.00),
(38, 1, 5, 2026, 1000.00),
(38, 1, 6, 2026, 1000.00),
(39, 1, 4, 2026, 1000.00),
(39, 1, 5, 2026, 1000.00),
(39, 1, 6, 2026, 1000.00),
(40, 1, 4, 2026, 1000.00),
(40, 1, 5, 2026, 1000.00),
(40, 1, 6, 2026, 1000.00),
(5, 2, 6, 2026, 20000.00),
(12, 2, 6, 2026, 15000.00),
(20, 2, 6, 2026, 10000.00),
(33, 2, 6, 2026, 25000.00);
GO


-- ================================================================
-- usp_GeneratePayroll
-- This is the ONLY place a PayrollID is ever created.
-- Order of operations (matches manager's requirement):
--   Step 1: read the employee's Basic Salary
--   Step 2: total up that employee's allowances for the month
--   Step 3: total up that employee's deductions for the month
--   Step 4: only now, INSERT INTO Payroll -> PayrollID is generated
--   Step 5: stamp that new PayrollID back onto the allowance/
--           deduction rows it was built from, for traceability
-- ================================================================
CREATE PROCEDURE usp_GeneratePayroll
    @EmployeeID INT,
    @Month INT,
    @Year INT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 FROM Payroll
        WHERE EmployeeID = @EmployeeID AND PayMonth = @Month AND PayYear = @Year
    )
    BEGIN
        PRINT 'Payroll already exists for this employee/month - not regenerated.';
        RETURN;
    END

    DECLARE @Basic DECIMAL(10,2);
    DECLARE @AllowanceTotal DECIMAL(10,2);
    DECLARE @DeductionTotal DECIMAL(10,2);
    DECLARE @Gross DECIMAL(10,2);
    DECLARE @Net DECIMAL(10,2);
    DECLARE @NewPayrollID INT;

    -- Step 1: check salary
    SELECT @Basic = BasicSalary FROM Employees WHERE EmployeeID = @EmployeeID;

    -- Step 2: combine allowances for this employee/month
    SELECT @AllowanceTotal = ISNULL(SUM(Amount), 0)
    FROM SalaryAllowances
    WHERE EmployeeID = @EmployeeID AND PayMonth = @Month AND PayYear = @Year;

    -- Step 3: combine deductions for this employee/month
    SELECT @DeductionTotal = ISNULL(SUM(Amount), 0)
    FROM SalaryDeductions
    WHERE EmployeeID = @EmployeeID AND PayMonth = @Month AND PayYear = @Year;

    SET @Gross = @Basic + @AllowanceTotal;
    SET @Net   = @Gross - @DeductionTotal;

    -- Step 4: NOW the PayrollID is generated (identity column)
    INSERT INTO Payroll (EmployeeID, PayMonth, PayYear, BasicSalary, GrossSalary, TotalDeductions, NetSalary, PaymentDate)
    VALUES (@EmployeeID, @Month, @Year, @Basic, @Gross, @DeductionTotal, @Net, NULL);

    SET @NewPayrollID = SCOPE_IDENTITY();

    -- Step 5: link the allowance/deduction rows back to the payroll that was generated from them
    UPDATE SalaryAllowances
    SET PayrollID = @NewPayrollID
    WHERE EmployeeID = @EmployeeID AND PayMonth = @Month AND PayYear = @Year AND PayrollID IS NULL;

    UPDATE SalaryDeductions
    SET PayrollID = @NewPayrollID
    WHERE EmployeeID = @EmployeeID AND PayMonth = @Month AND PayYear = @Year AND PayrollID IS NULL;

    SELECT @NewPayrollID AS GeneratedPayrollID;
END
GO

-- ================================================================
-- usp_GeneratePayrollForMonth
-- Batch version: runs usp_GeneratePayroll for every active employee
-- for the given month/year. Used at month-end.
-- ================================================================
CREATE PROCEDURE usp_GeneratePayrollForMonth
    @Month INT,
    @Year INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @EmployeeID INT;

    DECLARE emp_cursor CURSOR FOR
        SELECT EmployeeID FROM Employees WHERE IsActive = 1;

    OPEN emp_cursor;
    FETCH NEXT FROM emp_cursor INTO @EmployeeID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC usp_GeneratePayroll @EmployeeID = @EmployeeID, @Month = @Month, @Year = @Year;
        FETCH NEXT FROM emp_cursor INTO @EmployeeID;
    END

    CLOSE emp_cursor;
    DEALLOCATE emp_cursor;
END
GO

-- Generate payroll for all 40 employees for Apr, May, Jun 2026
-- (this is what actually creates all 120 PayrollID values - notice
--  no PayrollID is ever typed in or inserted by hand anywhere above)
EXEC usp_GeneratePayrollForMonth @Month = 4, @Year = 2026;
GO
EXEC usp_GeneratePayrollForMonth @Month = 5, @Year = 2026;
GO
EXEC usp_GeneratePayrollForMonth @Month = 6, @Year = 2026;
GO

-- Users (40 rows, one login per employee)
INSERT INTO Users (EmployeeID, Username, PasswordHash, IsActive, CreatedDate) VALUES
(1, 'ahmed.butt1', 'HASH_0001XYZ', 1, '2019-10-13'),
(2, 'ali.siddiqui2', 'HASH_0002XYZ', 1, '2020-04-21'),
(3, 'bilal.yousaf3', 'HASH_0003XYZ', 1, '2020-07-23'),
(4, 'sara.aslam4', 'HASH_0004XYZ', 1, '2019-07-09'),
(5, 'ayesha.aslam5', 'HASH_0005XYZ', 1, '2024-06-15'),
(6, 'hamza.shah6', 'HASH_0006XYZ', 1, '2019-04-04'),
(7, 'usman.farooq7', 'HASH_0007XYZ', 1, '2022-07-25'),
(8, 'fatima.aslam8', 'HASH_0008XYZ', 1, '2020-05-16'),
(9, 'zainab.yousaf9', 'HASH_0009XYZ', 1, '2023-08-11'),
(10, 'omar.iqbal10', 'HASH_0010XYZ', 1, '2021-03-21'),
(11, 'hassan.farooq11', 'HASH_0011XYZ', 1, '2021-01-11'),
(12, 'sana.malik12', 'HASH_0012XYZ', 1, '2023-06-11'),
(13, 'nida.qureshi13', 'HASH_0013XYZ', 1, '2024-04-14'),
(14, 'kashif.hussain14', 'HASH_0014XYZ', 1, '2021-07-18'),
(15, 'rabia.butt15', 'HASH_0015XYZ', 1, '2023-04-11'),
(16, 'tariq.shah16', 'HASH_0016XYZ', 1, '2024-03-17'),
(17, 'imran.mirza17', 'HASH_0017XYZ', 1, '2023-07-30'),
(18, 'mahnoor.raza18', 'HASH_0018XYZ', 1, '2023-03-27'),
(19, 'faisal.abbasi19', 'HASH_0019XYZ', 1, '2020-04-05'),
(20, 'iqra.farooq20', 'HASH_0020XYZ', 1, '2019-05-01'),
(21, 'adeel.akhtar21', 'HASH_0021XYZ', 1, '2020-03-14'),
(22, 'sadia.rehman22', 'HASH_0022XYZ', 1, '2022-09-11'),
(23, 'waqas.malik23', 'HASH_0023XYZ', 1, '2020-11-25'),
(24, 'amna.baig24', 'HASH_0024XYZ', 1, '2021-08-05'),
(25, 'salman.yousaf25', 'HASH_0025XYZ', 1, '2021-04-12'),
(26, 'mariam.raza26', 'HASH_0026XYZ', 1, '2024-03-12'),
(27, 'junaid.iqbal27', 'HASH_0027XYZ', 1, '2023-02-15'),
(28, 'hina.malik28', 'HASH_0028XYZ', 1, '2019-06-14'),
(29, 'danish.farooq29', 'HASH_0029XYZ', 1, '2022-03-31'),
(30, 'sobia.mirza30', 'HASH_0030XYZ', 1, '2023-01-06'),
(31, 'asad.javed31', 'HASH_0031XYZ', 1, '2021-07-27'),
(32, 'farah.aslam32', 'HASH_0032XYZ', 1, '2021-01-26'),
(33, 'yasir.akhtar33', 'HASH_0033XYZ', 1, '2024-04-06'),
(34, 'nadia.yousaf34', 'HASH_0034XYZ', 1, '2020-03-07'),
(35, 'zeeshan.rehman35', 'HASH_0035XYZ', 1, '2021-05-17'),
(36, 'komal.chaudhry36', 'HASH_0036XYZ', 1, '2022-02-03'),
(37, 'shahzad.sheikh37', 'HASH_0037XYZ', 1, '2022-02-05'),
(38, 'rida.abbasi38', 'HASH_0038XYZ', 1, '2020-05-26'),
(39, 'naveed.chaudhry39', 'HASH_0039XYZ', 1, '2019-02-20'),
(40, 'bushra.farooq40', 'HASH_0040XYZ', 1, '2021-02-22');
GO

-- Roles (4 rows)
INSERT INTO Roles (RoleName) VALUES
('Admin'),
('HR'),
('Manager'),
('Employee');
GO

-- UserRoles (40 base rows + a few extra manager/admin/HR assignments)
INSERT INTO UserRoles (UserID, RoleID) VALUES
(1, 4),
(2, 4),
(3, 4),
(4, 4),
(5, 4),
(6, 4),
(7, 4),
(8, 4),
(9, 4),
(10, 4),
(11, 4),
(12, 4),
(13, 4),
(14, 4),
(15, 4),
(16, 4),
(17, 4),
(18, 4),
(19, 4),
(20, 4),
(21, 4),
(22, 4),
(23, 4),
(24, 4),
(25, 4),
(26, 4),
(27, 4),
(28, 4),
(29, 4),
(30, 4),
(31, 4),
(32, 4),
(33, 4),
(34, 4),
(35, 4),
(36, 4),
(37, 4),
(38, 4),
(39, 4),
(40, 4),
(1, 3),
(2, 3),
(3, 3),
(4, 3),
(5, 3),
(1, 1),
(2, 2),
(3, 2);
GO


-- ================================================================
-- HRMS Practice Queries (v2 - updated for the new Allowance/Deduction/Payroll design)
-- ================================================================

USE HRMS;
GO

-- Q1: List all departments
SELECT * FROM Departments;
GO

-- Q2: List only active employees
SELECT EmployeeID, FirstName, LastName, BasicSalary
FROM Employees
WHERE IsActive = 1;
GO

-- Q3: List employees sorted by salary (highest first)
SELECT FirstName, LastName, BasicSalary
FROM Employees
ORDER BY BasicSalary DESC;
GO

-- Q4: Full employee details with Department and Designation names (JOIN)
SELECT
    e.EmployeeID,
    e.FirstName + ' ' + e.LastName AS FullName,
    d.DepartmentName,
    ds.DesignationName,
    e.BasicSalary
FROM Employees e
INNER JOIN Departments d  ON e.DepartmentID  = d.DepartmentID
INNER JOIN Designations ds ON e.DesignationID = ds.DesignationID;
GO

-- Q5: Count of employees in each department
SELECT
    d.DepartmentName,
    COUNT(e.EmployeeID) AS TotalEmployees
FROM Departments d
LEFT JOIN Employees e ON d.DepartmentID = e.DepartmentID
GROUP BY d.DepartmentName;
GO

-- Q6: Average salary per department
SELECT
    d.DepartmentName,
    AVG(e.BasicSalary) AS AverageSalary
FROM Departments d
INNER JOIN Employees e ON d.DepartmentID = e.DepartmentID
GROUP BY d.DepartmentName;
GO

-- Q7: Employees who joined after 1 Jan 2023
SELECT FirstName, LastName, DateOfJoining
FROM Employees
WHERE DateOfJoining > '2023-01-01';
GO

-- Q8: Attendance summary - how many days each employee was Present
SELECT
    e.FirstName + ' ' + e.LastName AS FullName,
    COUNT(a.AttendanceID) AS DaysPresent
FROM Employees e
INNER JOIN Attendance a ON e.EmployeeID = a.EmployeeID
WHERE a.Status = 'Present'
GROUP BY e.FirstName, e.LastName
ORDER BY DaysPresent DESC;
GO

-- Q9: Employees who were Absent more than 2 times (HAVING)
SELECT
    e.FirstName + ' ' + e.LastName AS FullName,
    COUNT(a.AttendanceID) AS DaysAbsent
FROM Employees e
INNER JOIN Attendance a ON e.EmployeeID = a.EmployeeID
WHERE a.Status = 'Absent'
GROUP BY e.FirstName, e.LastName
HAVING COUNT(a.AttendanceID) > 2;
GO

-- Q10: Leave applications with employee name and leave type name
SELECT
    e.FirstName + ' ' + e.LastName AS FullName,
    lt.LeaveTypeName,
    la.StartDate,
    la.EndDate,
    la.TotalDays,
    la.Status
FROM LeaveApplications la
INNER JOIN Employees e   ON la.EmployeeID  = e.EmployeeID
INNER JOIN LeaveTypes lt ON la.LeaveTypeID = lt.LeaveTypeID
WHERE la.Status = 'Approved';
GO

-- Q11: Total leave days taken by each employee (only Approved leaves)
SELECT
    e.FirstName + ' ' + e.LastName AS FullName,
    SUM(la.TotalDays) AS TotalLeaveDaysTaken
FROM Employees e
INNER JOIN LeaveApplications la ON e.EmployeeID = la.EmployeeID
WHERE la.Status = 'Approved'
GROUP BY e.FirstName, e.LastName
ORDER BY TotalLeaveDaysTaken DESC;
GO

-- Q12: Payroll report (Net Salary) for June 2026
SELECT
    e.FirstName + ' ' + e.LastName AS FullName,
    p.PayMonth,
    p.PayYear,
    p.GrossSalary,
    p.TotalDeductions,
    p.NetSalary
FROM Payroll p
INNER JOIN Employees e ON p.EmployeeID = e.EmployeeID
WHERE p.PayMonth = 6 AND p.PayYear = 2026
ORDER BY p.NetSalary DESC;
GO

-- Q13: Full salary slip (Basic + Allowances - Deductions) for one employee, one month
-- Allowance/Deduction type NAMES now come from the new lookup tables.
SELECT
    e.FirstName + ' ' + e.LastName AS FullName,
    p.PayMonth,
    p.PayYear,
    p.BasicSalary,
    at.AllowanceTypeName,
    sa.Amount AS AllowanceAmount,
    dt.DeductionTypeName,
    sd.Amount AS DeductionAmount,
    p.NetSalary
FROM Payroll p
INNER JOIN Employees e            ON p.EmployeeID = e.EmployeeID
LEFT JOIN SalaryAllowances sa      ON p.PayrollID = sa.PayrollID
LEFT JOIN AllowanceTypes at        ON sa.AllowanceTypeID = at.AllowanceTypeID
LEFT JOIN SalaryDeductions sd      ON p.PayrollID = sd.PayrollID
LEFT JOIN DeductionTypes dt        ON sd.DeductionTypeID = dt.DeductionTypeID
WHERE e.EmployeeID = 1 AND p.PayMonth = 6 AND p.PayYear = 2026;
GO

-- Q14: Top 5 highest paid employees
SELECT TOP 5
    FirstName + ' ' + LastName AS FullName,
    BasicSalary
FROM Employees
ORDER BY BasicSalary DESC;
GO

-- Q15: All login users with their assigned roles
SELECT
    u.Username,
    e.FirstName + ' ' + e.LastName AS FullName,
    r.RoleName
FROM Users u
INNER JOIN Employees e ON u.EmployeeID = e.EmployeeID
INNER JOIN UserRoles ur ON u.UserID = ur.UserID
INNER JOIN Roles r ON ur.RoleID = r.RoleID
ORDER BY u.Username;
GO

-- Q16: Employees who have NEVER applied for leave (LEFT JOIN + IS NULL)
SELECT
    e.FirstName + ' ' + e.LastName AS FullName
FROM Employees e
LEFT JOIN LeaveApplications la ON e.EmployeeID = la.EmployeeID
WHERE la.LeaveApplicationID IS NULL;
GO

-- Q17: UPDATE example - give a 10% raise to the IT department (DepartmentID = 2)
UPDATE Employees
SET BasicSalary = BasicSalary * 1.10
WHERE DepartmentID = 2;
GO

-- Q18: DELETE example - remove a single Rejected leave application by its ID
-- (Always use a WHERE clause with an exact ID when deleting!)
DELETE FROM LeaveApplications
WHERE LeaveApplicationID = 60 AND Status = 'Rejected';
GO

-- Q19: CREATE VIEW - a reusable "virtual table" of full employee details
CREATE VIEW vw_EmployeeFullDetails AS
SELECT
    e.EmployeeID,
    e.FirstName + ' ' + e.LastName AS FullName,
    d.DepartmentName,
    ds.DesignationName,
    e.BasicSalary,
    e.DateOfJoining
FROM Employees e
INNER JOIN Departments d   ON e.DepartmentID  = d.DepartmentID
INNER JOIN Designations ds ON e.DesignationID = ds.DesignationID;
GO

-- Use the view like a normal table:
SELECT * FROM vw_EmployeeFullDetails WHERE DepartmentName = 'Information Technology';
GO

-- Q20: STORED PROCEDURE - reusable payroll lookup by month/year
CREATE PROCEDURE usp_GetPayrollByMonth
    @Month INT,
    @Year INT
AS
BEGIN
    SELECT
        e.FirstName + ' ' + e.LastName AS FullName,
        p.GrossSalary,
        p.TotalDeductions,
        p.NetSalary
    FROM Payroll p
    INNER JOIN Employees e ON p.EmployeeID = e.EmployeeID
    WHERE p.PayMonth = @Month AND p.PayYear = @Year
    ORDER BY p.NetSalary DESC;
END
GO

-- Run the stored procedure:
EXEC usp_GetPayrollByMonth @Month = 5, @Year = 2026;
GO

-- ---------------- NEW QUERIES for the updated design ----------------

-- Q21: List the two allowance types (feeds the Employee Form dropdown)
SELECT * FROM AllowanceTypes;
GO

-- Q22: List the two deduction types (feeds the Employee Form dropdown)
SELECT * FROM DeductionTypes;
GO

-- Q23: All allowances + deductions entered for one employee, for one month,
-- BEFORE payroll has necessarily been generated (shows EmployeeID-based design)
SELECT e.FirstName + ' ' + e.LastName AS FullName,
       at.AllowanceTypeName, sa.Amount, sa.PayMonth, sa.PayYear, sa.PayrollID
FROM SalaryAllowances sa
INNER JOIN Employees e ON sa.EmployeeID = e.EmployeeID
INNER JOIN AllowanceTypes at ON sa.AllowanceTypeID = at.AllowanceTypeID
WHERE sa.EmployeeID = 5 AND sa.PayMonth = 6 AND sa.PayYear = 2026;
GO

-- Q24: Generate payroll for ONE employee for a month (this is what creates the PayrollID)
-- EXEC usp_GeneratePayroll @EmployeeID = 5, @Month = 6, @Year = 2026;

-- Q25: Generate payroll for ALL employees for a month in one go
-- EXEC usp_GeneratePayrollForMonth @Month = 6, @Year = 2026;

-- Q26: Employees who took an Advance Payment deduction (per-employee, optional deduction)
SELECT e.FirstName + ' ' + e.LastName AS FullName, sd.Amount, sd.PayMonth, sd.PayYear
FROM SalaryDeductions sd
INNER JOIN Employees e ON sd.EmployeeID = e.EmployeeID
INNER JOIN DeductionTypes dt ON sd.DeductionTypeID = dt.DeductionTypeID
WHERE dt.DeductionTypeName = 'Advance Payment';
GO

select * from employees ;
GO
select * from AllowanceTypes;
go
select * from DeductionTypes;
go
select * from salaryallowances ;
go
select * from SalaryDeductions;
go
select * from Payroll;
go
select * from Departments;
go
select * from designations;
go
select * from roles;
go

USE HRMS;
GO

SELECT COUNT(*) FROM Employees;

SELECT @@SERVERNAME;

SELECT DB_NAME() AS CurrentDatabase;

USE HRMS;
GO

SELECT COUNT(*) AS EmployeeCount FROM Employees;

SELECT COUNT(*) AS PayrollCount FROM Payroll;

SELECT COUNT(*) AS AllowanceCount FROM SalaryAllowances;

SELECT COUNT(*) AS DeductionCount FROM SalaryDeductions;

SELECT DISTINCT PayMonth, PayYear
FROM Payroll
ORDER BY PayYear, PayMonth;

SELECT
    PayrollID,
    EmployeeID,
    PayMonth,
    PayYear,
    NetSalary
FROM Payroll
WHERE EmployeeID = 8
ORDER BY PayYear, PayMonth;

SELECT * FROM Users;
SELECT * FROM Employees;