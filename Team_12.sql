-- بسم الله الرحمن الرحيم

/*   /\_/\
*   (= ._.)
*   / >  \>
*/

-- 2.1 a):
create database University_HR_ManagementSystem_Team_No_12;
go
use University_HR_ManagementSystem_Team_No_12
go

-- 2.1 b) helper function: CREATE IT BEFORE CREATING TABLES!
create or alter function getsalary(@employee_id int)
returns decimal(10,2)
as 
begin

declare @base_salary decimal(10,2) = (
				select top 1 r.base_salary 
				from Employee e inner join Employee_Role er on (e.employee_ID=er.emp_ID) 
				inner join Role r on (r.role_name=er.role_name)
				where e.employee_ID=@employee_id
				order by r.rank asc
				);

declare @YOE int = (
				select top 1 years_of_experience 
				from Employee 
				where @employee_id=employee_ID
				);

declare @YOE_perc decimal(4,2) = (
				select top 1 r.percentage_YOE 
				from Employee e inner join Employee_Role er on (e.employee_ID=er.emp_ID) 
				inner join Role r on (r.role_name=er.role_name)
				where e.employee_ID=@employee_id
				order by r.rank asc
				);

return @base_salary + (@YOE_perc/100) * @YOE * @base_salary;

end
go

-- 2.1 b):
create or alter proc createAllTables as	
begin

	create table Department(
		name varchar(50) primary key, 
		building_location varchar(50)
	);

	create table Employee(
		employee_ID int primary key identity(1,1), 
		first_name varchar(50), last_name varchar (50), 
		email varchar(50), 
		password varchar (50), 
		address varchar (50), 
		gender char(1), 
		official_day_off varchar(50),
		years_of_experience int, 
		national_ID char (16), 
		employment_status varchar(50),
		type_of_contract varchar (50), 
		emergency_contact_name varchar (50),
		emergency_contact_phone char (11), 
		annual_balance int, accidental_balance int, 
		salary as (dbo.getsalary(employee_ID)),
		hire_date date, 
		last_working_date date, 
		dept_name varchar (50), 
		constraint Emp_deptFK foreign key (dept_name) references Department(name),
		CHECK (annual_balance>=0),
		CHECK (accidental_balance>=0),
		CHECK (type_of_contract IN ('full_time', 'part_time')),
		CHECK (employment_status IN ('active', 'onleave', 'notice_period','resigned')),
		CHECK (hire_date<=last_working_date),
		CHECK (gender in ('M', 'F'))
	);

	create table Employee_Phone (
		emp_ID int, 
		phone_num char(11),
		primary key(emp_ID, phone_num),
		constraint Phone_empFK foreign key (emp_ID) references Employee(employee_ID)
	);


	create table Role (
		role_name varchar(50) primary key, 
		title varchar(50), 
		description varchar(50), 
		rank int,
		base_salary decimal (10,2), 
		percentage_YOE decimal (4,2), 
		percentage_overtime decimal(4,2), 
		annual_balance int, 
		accidental_balance int
	);

	create table Employee_Role(
		emp_ID int foreign key references Employee(employee_ID), 
		role_name varchar(50) foreign key references Role(role_name),
		primary key(emp_ID, role_name)
	);

	create table Role_existsIn_Department(
		department_name varchar(50) foreign key references Department(name), 
		Role_name varchar(50) foreign key references Role(role_name),
		primary key(department_name, Role_name)
	);

	create table Leave(
		request_ID int primary key identity(1,1),
		date_of_request date,
		start_date date,
		end_date date,
		num_days as (DATEDIFF(day, start_date, end_date)+1),
		final_approval_status varchar(50) DEFAULT 'pending',
		CHECK (final_approval_status IN ('pending', 'approved', 'rejected')),
		CHECK (end_date>=start_date)
	);

	create table Annual_Leave(
		request_ID int primary key,
		emp_ID int,
		replacement_emp int,
		constraint Ann_empFK foreign key (emp_ID) references Employee (employee_ID),
		constraint Ann_leaveFK foreign key (request_ID) references Leave (request_ID),
		constraint Ann_repEmpFK foreign key (replacement_emp) references Employee (employee_ID)
	);

	create table Accidental_Leave(
		request_ID int primary key,
		emp_ID int,
		constraint Acc_empFK foreign key (emp_ID) references Employee (employee_ID),
		constraint Acc_leaveFK foreign key (request_ID) references Leave (request_ID)
	);

	create table Medical_Leave(
		request_ID int primary key,
		insurance_status bit,
		disability_details VARCHAR(50),
		type VARCHAR(50),
		Emp_ID int,
		constraint Med_empFK foreign key (Emp_ID) references Employee (employee_ID),
		constraint Med_leaveFK foreign key (request_ID) references Leave (request_ID),
		CHECK (type IN ('sick', 'maternity'))
	);

	create table Unpaid_Leave(
		request_ID int primary key,
		Emp_ID int,
		constraint Unp_empFK foreign key (Emp_ID) references Employee (employee_ID),
		constraint Unp_leaveFK foreign key (request_ID) references Leave (request_ID)
	);

	create table Compensation_Leave(
		request_ID int primary key,
		reason varchar(50),
		date_of_original_workday date,
		emp_ID int,
		replacement_emp int,
		constraint Com_empFK foreign key (emp_ID) references Employee (employee_ID),
		constraint Com_repEmpFK foreign key (replacement_emp) references Employee (employee_ID),
		constraint Com_leaveFK foreign key (request_ID) references Leave (request_ID)
	);

	create table Document (
		document_ID int primary key identity(1,1),
		type varchar(50),
		description varchar(50),
		file_name varchar(50),
		creation_date date,
		expiry_date date,
		status varchar(50),
		emp_ID int,
		medical_ID int,
		unpaid_ID int,
		constraint Doc_empFK foreign key (emp_ID) references Employee(employee_ID),
		constraint Doc_medicalFK foreign key (medical_ID) references Medical_Leave(request_ID),
		constraint Doc_unpaidFK foreign key (unpaid_ID) references Unpaid_Leave(request_ID),
		CHECK (status IN ('valid', 'expired')),
		CHECK (expiry_date>=creation_date)
	);

	create table Payroll (
		ID int primary key identity(1,1),
		payment_date date,
		final_salary_amount decimal(10,1),
		from_date date,
		to_date date,
		comments varchar(150),
		bonus_amount decimal(10,2),
		deductions_amount decimal(10,2),	
		emp_ID int, 
		constraint Pay_empFK foreign key (emp_ID) references Employee(employee_ID),
		CHECK(to_date>=from_date)
	);

	create table Attendance (
		attendance_ID int primary key identity(1,1),
		date date, 
		check_in_time time, 
		check_out_time time, 
		total_duration as CAST( DATEADD( SECOND, DATEDIFF (SECOND,check_in_time,check_out_time) ,0) AS TIME), 
		status varchar(50) DEFAULT 'absent', 
		emp_ID int,
		constraint Att_empFK foreign key (emp_ID) references Employee(employee_ID),
		CHECK (status IN ('absent', 'attended')),
		CHECK (check_out_time>=check_in_time)
	);

	create table Deduction (
		deduction_ID int identity(1,1), 
		emp_ID int, 
		date date,
		amount decimal(10, 2),
		type varchar(50), 
		status varchar(50) DEFAULT 'pending',
		unpaid_ID int, 
		attendance_ID int, 
		Primary key (deduction_ID, emp_ID),
		constraint Ded_empFK foreign key (emp_ID) references Employee(employee_ID), 
		constraint Ded_unpaidFK foreign key (unpaid_ID) references Unpaid_Leave(request_ID),
		constraint Ded_attendanceFK foreign key (attendance_ID) references Attendance(attendance_ID),
		CHECK (type IN ('unpaid', 'missing_hours', 'missing_days')),
		CHECK (status IN ('pending', 'finalized'))
	);

	create table Performance (
		performance_ID int primary key identity(1,1),
		rating int, 
		comments varchar(50), 
		semester char(3), 
		emp_ID int, 
		constraint Per_empFK foreign key (emp_ID) references Employee(employee_ID),
		CHECK (rating >= 1 AND rating <= 5)
	);

	create table Employee_Replace_Employee (
		Table_ID int primary key IDENTITY(1,1),
		Emp1_ID int, 
		Emp2_ID int, 
		from_date date, 
		to_date date,
		foreign key (Emp1_ID) references Employee(employee_ID), 
		foreign key (Emp2_ID) references Employee(employee_ID),
		CHECK (to_date>=from_date)
	);

	create table Employee_Approve_Leave (
		Emp1_ID int, 
		Leave_ID int, 
		status varchar(50) DEFAULT 'pending', 
		primary key (Emp1_ID, Leave_ID),
		foreign key (Emp1_ID) references Employee(employee_ID), 
		foreign key (Leave_ID) references Leave(request_ID),
		CHECK (status IN ('pending', 'approved', 'rejected'))
	);
end;
go

-- 2.1 c):
-- delete the tables in a revere topological order
create or alter procedure dropAllTables as 
begin
	drop table Employee_Approve_Leave;
	drop table Employee_Replace_Employee;
	drop table Performance;
	drop table Deduction;
	drop table Attendance;	
	drop table Payroll;
	drop table Document;
	drop table Compensation_Leave;
	drop table Unpaid_Leave;
	drop table Medical_Leave;
	drop table Accidental_Leave;
	drop table Annual_Leave;
	drop table Leave;
	drop table Role_existsIn_Department;
	drop table Employee_Role;
	drop table Role;
	drop table Employee_Phone;
	drop table Employee;
	drop table Department;
end;
go

-- 2.1 d):										
create or alter proc dropAllProceduresFunctionsViews as		
begin
	-- all functions
	drop function HRLoginValidation, Bonus_amount, EmployeeLoginValidation, MyPerformance,
	MyAttendance, Last_month_payroll, Deductions_Attendance, Is_On_Leave, Status_leaves

	-- 2.1
	drop proc createAllTables, dropAllTables, clearAllTables
	
	-- 2.2
	drop view allEmployeeProfiles, NoEmployeeDept, allPerformance, allRejectedMedicals, allEmployeeAttendance
	
	-- 2.3
	drop proc Update_Status_Doc, Remove_Deductions, Update_Employment_Status, Create_Holiday, Add_Holiday, 
	Initiate_Attendance, Update_Attendance, Remove_Holiday, Remove_DayOff, remove_approved_leaves, Replace_employee

	-- 2.4
	drop proc HR_approval_on_annual, HR_approval_on_accidental, HR_approval_an_acc, HR_approval_unpaid, 
	HR_approval_comp, Deduction_hours, Deduction_days, Deduction_unpaid, Add_Payroll

	-- 2.5
	drop proc Submit_annual, Upperboard_approve_annual, Submit_accidental,
	Submit_medical, Submit_unpaid, Upperboard_approve_unpaids, Submit_compensation, Dean_andHR_Evaluation

end;
go

-- 2.1 e):
create or alter procedure clearAllTables as 
begin
	delete from Employee_Approve_Leave;
	delete from Employee_Replace_Employee;
	delete from Performance;
	delete from Deduction;
	delete from Attendance;	
	delete from Payroll;
	delete from Document;
	delete from Compensation_Leave;
	delete from Unpaid_Leave;
	delete from Medical_Leave;
	delete from Accidental_Leave;
	delete from Annual_Leave;
	delete from Leave;
	delete from Role_existsIn_Department;
	delete from Employee_Role;
	delete from Role;
	delete from Employee_Phone;
	delete from Employee;
	delete from Department;
end;
go

-- 2.2 a):
Create or alter View allEmployeeProfiles As 
    Select 
        employee_ID , first_name , last_name, gender , email, address, years_of_experience, 
            official_day_off, type_of_contract, employment_status, annual_balance, accidental_balance
    From Employee;
Go 

-- 2.2 b):
Create or alter View NoEmployeeDept As 
    Select dept_name, count(employee_ID) as NoOfEmployees
    from Employee
    where dept_name is not null
    group by dept_name;
Go

-- 2.2 c):
Create or alter View allPerformance As 
    Select * 
    From Performance
    Where semester LIKE 'W%';
Go

-- 2.2 d):
Create or alter View allRejectedMedicals As
    Select
        ml.request_ID, ml.Emp_ID AS employee_ID, ml.insurance_status, ml.disability_details, ml.type,
            l.date_of_request, l.start_date, l.end_date, l.num_days, l.final_approval_status
    From Medical_Leave ml INNER JOIN Leave l 
    On ml.request_ID = l.request_ID
    Where l.final_approval_status = 'rejected';
Go

-- 2.2 e): 
Create or alter View allEmployeeAttendance As
    Select 
        attendance_ID, emp_ID, date, check_in_time, check_out_time, total_duration, status
    From Attendance
    Where date = CAST(DATEADD(day, -1, GETDATE()) AS DATE);
Go


-- 2.3 a):
CREATE OR ALTER PROC Update_Status_Doc
AS
    UPDATE Document
    SET status = 'expired'
    WHERE expiry_date < CAST(GETDATE() AS DATE);
GO

-- 2.3 b):
CREATE OR ALTER PROC Remove_Deductions
AS
    DELETE FROM Deduction
    WHERE EXISTS (SELECT 1 FROM Employee WHERE Employee.employee_ID = Deduction.emp_id AND Employee.employment_status = 'resigned')
GO

/*
    Comment from Ahmad Hesham Fathy, 61-6552, T16, 
    "hot comment enenena 3amleen assumption en el on leave hayeb2a active"

	for more information -> contact ahmed.abdelmajid@student.guc.edu.eg
*/
--2.3 c):
CREATE OR ALTER PROC Update_Employment_Status 
    @Employee_ID int
AS
BEGIN
    DECLARE @Is_On_Leave BIT = dbo.Is_On_Leave(@Employee_ID, CAST(GETDATE() AS DATE), CAST(GETDATE() AS DATE));
    declare @prev varchar(50) = (select employment_status from Employee where employee_ID=@Employee_ID)

    if @prev = 'resigned'
    return

    IF (@Is_On_Leave=1)
    BEGIN
        UPDATE Employee
        SET employment_status = 'onleave'
        WHERE employee_ID = @Employee_ID;
        return
    END

    if (@prev = 'onleave')
    BEGIN
        UPDATE Employee
        SET employment_status = 'active'
        WHERE employee_ID = @Employee_ID;
        return
    END

 
END;
GO

-- 2.3 d):
CREATE OR ALTER PROC Create_Holiday
AS
    CREATE TABLE Holiday(
	    holiday_id INT PRIMARY KEY IDENTITY(1,1),
	    name VARCHAR(50),
	    from_date DATE,
	    to_date DATE,
	    CHECK (from_date <= to_date)
    );
GO

-- 2.3 e):
CREATE OR ALTER PROC Add_Holiday
    @holiday_name VARCHAR(50),
    @from_date DATE,
    @to_date DATE
AS
    INSERT INTO Holiday (name, from_date, to_date)
    VALUES(@holiday_name, @from_date, @to_date)
GO

-- 2.3 f):
CREATE OR ALTER PROCEDURE Initiate_Attendance 
AS 
    INSERT INTO Attendance(emp_ID, date) 
    SELECT E.employee_ID, CAST(GETDATE() AS DATE) 
    FROM Employee E 
    WHERE NOT EXISTS ( 
        SELECT 1 
        FROM Attendance A 
        WHERE A.emp_ID = E.employee_ID 
          AND A.date = CAST(GETDATE() AS DATE) 
    ); 
GO

--2.3 g):
CREATE OR ALTER PROCEDURE Update_Attendance
    @employee_id INT,
    @check_in_time TIME,
    @check_out_time TIME
AS
    UPDATE Attendance 
    SET check_in_time = @check_in_time,
        check_out_time = @check_out_time,
        status = CASE WHEN (@check_in_time IS NOT NULL) AND (@check_out_time IS NOT NULL) THEN 'attended' ELSE 'absent' END
    WHERE emp_ID = @employee_id AND date = CAST(GETDATE() AS DATE);
GO

-- 2.3 h):
CREATE OR ALTER PROC Remove_Holiday
AS
    DELETE FROM Attendance
    WHERE EXISTS (
        SELECT 1
	    FROM Holiday
        WHERE Attendance.date Between Holiday.from_date AND Holiday.to_Date
    );
GO

-- 2.3 i):
CREATE OR ALTER PROCEDURE Remove_DayOff
    @Employee_ID INT
AS
BEGIN
    DECLARE @DayOff VARCHAR(50);

    SELECT @DayOff = official_day_off
    FROM Employee
    WHERE employee_ID = @Employee_ID;

    DELETE FROM Attendance
    WHERE emp_ID = @Employee_ID
      AND status = 'absent'
      AND DATENAME(WEEKDAY, date) = @DayOff
      AND MONTH(date) = MONTH(GETDATE())
      AND YEAR(date) = YEAR(GETDATE());
END;
GO

-- 2.3 j): 
CREATE OR ALTER PROCEDURE remove_approved_leaves
    @employee_id INT
AS
BEGIN
    DELETE FROM Attendance
    WHERE emp_ID = @employee_id
      AND EXISTS (
          SELECT 1
          FROM Leave L
          WHERE L.final_approval_status = 'approved'
           AND Attendance.date BETWEEN L.start_date AND L.end_date
            AND L.request_ID IN (
                SELECT request_ID FROM Annual_Leave WHERE emp_ID = @employee_id
                UNION
                SELECT request_ID FROM Accidental_Leave WHERE emp_ID = @employee_id
                UNION
                SELECT request_ID FROM Medical_Leave WHERE Emp_ID = @employee_id
                UNION
                SELECT request_ID FROM Unpaid_Leave WHERE Emp_ID = @employee_id
                UNION
                SELECT request_ID FROM Compensation_Leave WHERE emp_ID = @employee_id
            )
      );
END;
GO

--2.3 k): 
--Note: Employee 2 replaces employee 1 
CREATE OR ALTER PROCEDURE Replace_employee
    @Emp1_ID INT,    
    @Emp2_ID INT,     
    @from_date DATE,
    @to_date DATE
AS
BEGIN
    INSERT INTO Employee_Replace_Employee (Emp1_ID, Emp2_ID, from_date, to_date)
    VALUES (@Emp1_ID, @Emp2_ID, @from_date, @to_date);
END;
GO

