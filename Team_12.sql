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

-- to be removed
exec createAllTables
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

-- 2.4 a)
create or alter function HRLoginValidation(@employee_id int, @password varchar(50)) 
returns bit as 
begin	
	if exists (
		select * from Employee where 
		employee_ID = @employee_id and password=@password and dept_name like 'HR%'
	)
	return 1;
	return 0;
end;
go

-- helper for 2.4 b)
create or alter proc HR_approval_on_annual 
@request_ID int, @HR_ID int
as
begin

-- if the request does not exist in the annual table
if not exists(
	select * from Annual_Leave where request_ID=@request_ID
) return

-- employee is not supposed to approve the request
-- either invalid request or invalid employee
if not exists(
	select * from Employee_Approve_Leave where Emp1_ID=@HR_ID and Leave_ID=@request_ID
) return


-- if the request has been previously rejected
if exists(
	select * from Employee_Approve_Leave e where e.Leave_ID=@request_ID and e.status='rejected'
)
return


-- check if leave is already approved (prevents double deduction)
declare @current_status varchar(50) = (
    select top 1 final_approval_status from Leave where request_ID = @request_ID
);
if (@current_status = 'approved')
    return -- already processed, don't deduct balance again


-- useful variables
declare @num_days int = (select top 1 l.num_days from Leave l where l.request_ID = @request_ID);
declare @employee_id int = (
	select top 1 a.emp_ID from Annual_Leave a
	where a.request_ID = @request_ID
);
declare @balance int = (
	select top 1 annual_balance from Employee e
	where e.employee_ID = @employee_id
);
declare @start_date date = (select top 1 l.start_date from Leave l where l.request_ID=@request_ID);
declare @end_date date = (select top 1 l.end_date from Leave l where l.request_ID=@request_ID);
declare @replacement_emp int = (select top 1 replacement_emp from Annual_Leave where request_id=@request_ID)

declare @final_status varchar(50) = 'approved'

-- cannot approve a request that has started
if (@start_date <= cast(getdate() as date))
set @final_status = 'rejected'; 


-- if insufficient leave balance
if (@balance is null or @balance<@num_days) 
set @final_status = 'rejected'; 


-- check if employee already has overlapping approved leaves using Is_On_Leave function
if exists (select * from Leave l inner join Annual_Leave a on (l.request_ID=a.request_ID)
	where l.final_approval_status='approved' and l.start_date<=cast(@end_date as date) and l.end_date>=cast(@start_date as date))
set @final_status = 'rejected'; 

update Leave 
set final_approval_status = @final_status			
where request_ID = @request_ID

update Employee_Approve_Leave
set status = @final_status
where Leave_ID=@request_ID and Emp1_ID=@HR_ID

if @final_status = 'approved'
begin
	-- deduct balance 
	update Employee
	set annual_balance = annual_balance - @num_days
	where employee_ID=@employee_id

	-- use Replace_employee procedure 
	exec Replace_employee @employee_id, @replacement_emp, @start_date, @end_date
end

end
go

-- helper for 2.4 b)
create or alter proc HR_approval_on_accidental
@request_ID int, @HR_ID int
as
begin

-- if the request does not exist in the accidental table
if not exists(
	select * from Accidental_Leave where request_ID=@request_ID
) return

-- employee is not supposed to approve the request
-- either invalid request or invalid employee
if not exists(
	select * from Employee_Approve_Leave where Emp1_ID=@HR_ID and Leave_ID=@request_ID
) return


-- if the request has been previously rejected
if exists(
	select * from Employee_Approve_Leave e where e.Leave_ID=@request_ID and e.status='rejected'
)
return

-- check if leave is already approved (prevents double deduction)
declare @current_status varchar(50) = (
    select top 1 final_approval_status from Leave where request_ID = @request_ID
);
if (@current_status = 'approved')
    return; -- already processed, don't deduct balance again

-- check if submitted within 48 hours (from date_of_request to start_date)
declare @date_of_request date = (select top 1 date_of_request from Leave where request_ID=@request_ID);
declare @start_date date = (select top 1 start_date from Leave where request_ID=@request_ID);
declare @employee_id int = (
	select top 1 a.emp_ID from Accidental_Leave a
	where a.request_ID = @request_ID
);
declare @balance int = (
	select top 1 accidental_balance from Employee e
	where e.employee_ID = @employee_id
);
declare @end_date date = (select end_date from Leave where request_ID=@request_ID);


declare @final_status varchar(50) = 'approved';

if (@start_date <= cast(getdate() as date))
set @final_status = 'rejected'

if (DATEDIFF(hour, @date_of_request, @start_date) > 48)
set @final_status = 'rejected'


-- request or employee does not exist in the table
if (@balance is null) 
set @final_status = 'rejected'

if (@balance<1) 
set @final_status = 'rejected'


-- check if employee already has overlapping approved leaves using Is_On_Leave function
if exists (select * from Leave l inner join Accidental_Leave a on (l.request_ID=a.request_ID) where l.request_ID=@request_ID and
	 l.final_approval_status='approved' and l.start_date<=cast(@end_date as date) and l.end_date>=cast(@start_date as date))
set @final_status = 'rejected'; -- employee already has overlapping leave

update Leave 
set final_approval_status = @final_status
where request_ID = @request_ID

update Employee_Approve_Leave
set status = @final_status
where Leave_ID=@request_ID and Emp1_ID=@HR_ID

if @final_status = 'approved'
begin
	update Employee
	set accidental_balance = accidental_balance - 1
	where employee_ID=@employee_id
end

end
go

-- 2.4 b)
create or alter proc HR_approval_an_acc 
@request_ID int, @HR_ID int
as 
begin

if exists(
	select * from Leave where request_ID=@request_ID and final_approval_status='rejected'
) return

exec HR_approval_on_annual @request_id, @HR_ID;
exec HR_approval_on_accidental @request_id, @HR_ID;

end
go

-- 2.4 c)
create or alter proc HR_approval_unpaid 
@request_ID int, @HR_ID int
as 
begin

-- if the request does not exist in the unpaid table
if not exists(
	select * from Unpaid_Leave where request_ID=@request_ID
) return

if exists(
	select * from Leave where request_ID=@request_ID and final_approval_status='rejected'
) return

-- check if leave is already approved (prevents double deduction)
declare @current_status varchar(50) = (
    select top 1 final_approval_status from Leave where request_ID = @request_ID
);
if (@current_status = 'approved')
    return; -- already processed, don't deduct balance again

-- employee is not supposed to approve the request
-- either invalid request or invalid employee
if not exists(
	select * from Employee_Approve_Leave where Emp1_ID=@HR_ID and Leave_ID=@request_ID
) return


declare @status varchar(50) = 'approved';


-- if the request has been previously rejected
if exists(
	select * from Employee_Approve_Leave e where e.Leave_ID=@request_ID and e.status='rejected'
)
set @status = 'rejected';

declare @start_date date = (select top 1 start_date from Leave where request_ID=@request_ID);
declare @end_date date = (select top 1 end_date from Leave where request_ID=@request_ID);

if (@start_date <= cast(getdate() as date))
set @status = 'rejected'

-- check if employee already has overlapping approved leaves using Is_On_Leave function
if exists (select l.start_date,l.end_date from Leave l inner join Unpaid_Leave a on (l.request_ID=a.request_ID) where 
	l.request_ID=@request_ID and l.final_approval_status='approved' and l.start_date<=cast(@end_date as date) and l.end_date>=cast(@start_date as date))
set @status = 'rejected';

update Leave 
set final_approval_status = @status
where request_ID = @request_ID

update Employee_Approve_Leave
set status = @status
where Leave_ID=@request_ID and Emp1_ID=@HR_ID


end
go

-- 2.4 d)
create or alter proc HR_approval_comp 	
@request_ID int, @HR_ID int
as 
begin

-- if the request does not exist in the compensation table
if not exists(
	select * from Compensation_Leave where request_ID=@request_ID
) return

if exists(
	select * from Leave where request_ID=@request_ID and final_approval_status='rejected'
) return

-- employee is not supposed to approve the request
-- either invalid request or invalid employee
if not exists(
	select * from Employee_Approve_Leave where Emp1_ID=@HR_ID and Leave_ID=@request_ID
) return

-- check if leave is already approved (prevents double deduction)
declare @current_status varchar(50) = (
    select top 1 final_approval_status from Leave where request_ID = @request_ID
);
if (@current_status = 'approved')
    return; -- already processed, don't deduct balance again

declare @status varchar(50) = 'approved';

-- if the request has been previously rejected
if exists(
	select * from Employee_Approve_Leave e where e.Leave_ID=@request_ID and e.status='rejected'
)
set @status = 'rejected' 

-- useful variables
declare @emp_id int = (select top 1 e.employee_ID from Employee e 
						 inner join Compensation_Leave c on (c.emp_ID = e.employee_ID)
							where c.request_ID = @request_ID);
declare @date date = (select top 1 l.start_date from Leave l where l.request_ID=@request_ID); 
declare @day_off varchar(50) = (select top 1 official_day_off from Employee where employee_ID=@emp_id)
declare @date_of_original_work_day date = (select top 1 date_of_original_workday from Compensation_Leave where request_ID=@request_ID)
declare @replacement_emp int = (select top 1 replacement_emp from Compensation_Leave where request_id=@request_ID)


if (@date <= cast(getdate() as date))
set @status = 'rejected' 

-- if employee took another compensation leave using the same day off
if exists(
	select * from Compensation_Leave c inner join Leave l on (l.request_ID = c.request_ID)
	where l.request_ID<>@request_ID 
	and c.date_of_original_workday=@date_of_original_work_day
	and l.final_approval_status = 'approved'
) set @status = 'rejected'

if (MONTH(@date) <> MONTH(@date_of_original_work_day) OR YEAR(@date) <> YEAR(@date_of_original_work_day))
	set @status = 'rejected'

declare @hours_worked int = (
	select top 1 DATEDIFF(hour, check_in_time, check_out_time)
	from Attendance
	where emp_ID = @emp_id 
	  and date = @date_of_original_work_day
);

if (@hours_worked < 8)
	set @status = 'rejected'
if (@hours_worked is null)
	set @status = 'rejected' 


if exists (select l.start_date,l.end_date from Leave l inner join Unpaid_Leave u on (l.request_ID=u.request_ID)
	where l.final_approval_status='approved' and l.start_date<=cast(@date as date) and l.end_date>=cast(@date as date) and u.request_ID=@request_ID)
set @status = 'rejected';


-- if date_of_original_workday is not the employee's day off
if (datename(WEEKDAY, @date_of_original_work_day) <> @day_off)
set @status = 'rejected'


update Leave 
set final_approval_status = @status
where request_ID = @request_ID

update Employee_Approve_Leave
set status = @status
where Leave_ID=@request_ID and Emp1_ID=@HR_ID

if @status='approved'
begin
EXEC Replace_employee 
        @Emp1_ID=@emp_id,
        @Emp2_ID=@replacement_emp,
        @from_date=@date,
        @to_date=@date;
end
end
go

-- 2.4 e)
create or alter proc Deduction_hours	
@employee_ID int
as 
begin
	
	-- delete all previously added deductions from the current month
	delete from Deduction where
		 type = 'missing_hours' and @employee_ID = emp_ID and 
		 month(date)=month(getdate()) and year(date)=year(getdate());

	-- hourly rate = salary / (22 days * 8 hours)
	declare @rate decimal(10,2) = (select top 1 salary from Employee e	
		where e.employee_ID = @employee_ID) / (22 * 8);	
		
	declare @seconds int = (
		select sum(datediff(second, '00:00:00', total_duration)) from Attendance a 
		where a.emp_ID=@employee_ID and
		month(a.date) = month(getdate()) and year(a.date) = year(getdate())
	); 
	declare @hours int = @seconds / (60 * 60);

	declare @attendance int = (
		select top 1 attendance_ID from Attendance a
		where datepart(hour, a.total_duration) < 8 and a.emp_ID=@employee_ID and
		month(a.date) = month(getdate()) and year(a.date) = year(getdate())
		order by a.date asc
	);
	
	if (@hours >= (22 * 8))  return;				-- if employee has attended over the 22 * 8 hours

	--  			     (emp_ID, date, amount, type, status, attendance_ID)
	insert into Deduction(emp_ID, date, amount, type, status, attendance_ID) 
		values(@employee_ID, cast(getdate() as date), ((22 * 8) - @hours)*@rate, 'missing_hours', 'finalized', @attendance);
end
go

-- 2.4 f)
create or alter proc Deduction_days	
@employee_ID int
as 
begin

	declare @daily_rate decimal(10,2) = (select top 1 salary from Employee e	
			where e.employee_ID = @employee_ID) / 22;
	
	-- delete all previously added deductions from the current month
	delete from Deduction where
		 type = 'missing_days' and @employee_ID = emp_ID and 
		 month(date)=month(getdate()) and year(date)=year(getdate());


	--			Deduction(emp_ID, date, amount, type, status, unpaid_ID, attendance_ID)
	insert into Deduction(emp_ID, date, amount, type, status)
		select @employee_ID, datefromparts(year(getdate()), month(getdate()), day(a.date)), 
			@daily_rate, 'missing_days', 'finalized' 
		from Attendance a
		where month(a.date) = month(getdate()) and year(a.date)=year(getdate())
			and a.status = 'absent' and a.emp_ID = @employee_ID; 

end
go

-- 2.4 g)
create or alter proc Deduction_unpaid	
@employee_ID int
as 
begin

	-- delete all previously added deductions from the current month
	delete from Deduction where
		 type = 'unpaid' and @employee_ID = emp_ID and 
		 month(date)=month(getdate()) and year(date)=year(getdate());


	-- useful variables
	declare @CurrentMonthStart date = datefromparts(year(getdate()), month(getdate()), 1);
    declare @CurrentMonthEnd   date = eomonth(getdate());
	declare @daily_rate decimal(10,2) = (select top 1 salary from Employee e	
			where e.employee_ID = @employee_ID) / 22;


	-- ts is soo tuff
	create table #very_cool_tmp_table_67(unpaid_id int, start_date date, end_date date, cost decimal(10,2));

	-- insert all the leaves that overlap with the current month into the 67 table
	insert into #very_cool_tmp_table_67 (unpaid_id, start_date, end_date)
	select u.request_ID, l.start_date, l.end_date from 
	Unpaid_Leave u inner join Leave l on (u.request_ID = l.request_ID) WHERE 
		l.start_date <= @CurrentMonthEnd and l.end_date >= @CurrentMonthStart
		and @employee_ID = u.Emp_ID and l.final_approval_status='approved';

	-- we will only consider the part that overlap in our current month
	update #very_cool_tmp_table_67
		set start_date = @CurrentMonthStart 
		where start_date < @CurrentMonthStart;
	update #very_cool_tmp_table_67
		set end_date = @CurrentMonthEnd 
		where end_date > @CurrentMonthEnd;

	-- calculate the cost
	update #very_cool_tmp_table_67
		set cost = (DATEDIFF(day, start_date, end_date) + 1) * @daily_rate;


	insert into Deduction(emp_ID, date, amount, type, status, unpaid_ID) 
		select @employee_ID, cast(getdate() as date), cost, 'unpaid', 'finalized', unpaid_id
		from #very_cool_tmp_table_67;

	
end
go

-- 2.4 h)
create or alter function Bonus_amount(@employee_id int)
returns int as 
begin

	declare @seconds int = (
		select sum(datediff(second, '00:00:00', total_duration)) from Attendance a 
		where a.emp_ID=@employee_id and
		month(a.date) = month(getdate()) and year(a.date) = year(getdate())
	); 
	declare @hours int = @seconds / (60 * 60);

	declare @rate decimal(10,2) = (select top 1 salary from Employee e	
									where e.employee_ID = @employee_ID) / (22 * 8)

	declare @factor int = 
			(select top 1 r.percentage_overtime from Role r, Employee e, Employee_Role er where	
			@employee_id = e.employee_ID and @employee_id=er.emp_ID and r.role_name=er.role_name
			order by r.rank asc);

	declare @bonus int = (@hours - 22*8) * @rate * @factor * 0.01;
	if (@bonus is null or @bonus <= 0) return 0;
	return @bonus;

end
go

-- 2.4 i)
create or alter proc Add_Payroll
@employee_id int,
@from date, @to date	
as						
begin

declare @bonus decimal(10,2) = dbo.Bonus_amount(@employee_id)	
declare @deduction_amount decimal(10,2) = (select sum(amount) from Deduction d where d.emp_ID=@employee_id and d.date<=@to and d.date>=@from)
declare @salary decimal(10,2) = (select top 1 salary from Employee e where e.employee_ID = @employee_ID);		

if @deduction_amount is null
	set @deduction_amount = 0

-- payment_date, final_salary_amount, from_date, to_date, bonus_amount, deduction_amount, emp_ID
insert into Payroll(payment_date, final_salary_amount, from_date, to_date, bonus_amount, deductions_amount, emp_ID) 
			values(cast(getdate() as date), @salary + @bonus - @deduction_amount, @from, @to, @bonus, @deduction_amount, @employee_id);

end

go

-- 2.5 a):
Create or alter Function EmployeeLoginValidation(@employee_ID Int, @password varchar(50))
Returns Bit
As
Begin
	IF EXISTS (Select 1 From Employee Where Employee_ID = @employee_ID And Password = @password)
		Return 1;
	Return 0;
End;
Go

-- 2.5 b):
Create or alter Function MyPerformance(@employee_ID Int,@semester char(3))
Returns Table
As
Return
(
	Select P.semester, P.rating, P.comments
	From Performance P
	Where P.emp_ID = @employee_ID And P.semester = @semester
);
Go

-- 2.5 c)
Create or alter Function MyAttendance(@employee_ID Int)
Returns Table
As 
Return
(
	Select A.date, A.status, A.check_in_time, A.check_out_time, A.total_duration
	From Attendance A inner join Employee e on e.employee_ID = A.emp_ID
	Where A.emp_ID = @employee_ID 
			AND MONTH(A.date) = MONTH(GETDATE())
			AND YEAR(A.date) = YEAR(GETDATE())
			AND NOT(DATENAME(WEEKDAY, A.date) = e.official_day_off and A.status = 'absent') -- not unattended day off
);	
Go

-- 2.5 d):
Create or alter Function Last_month_payroll(@employee_ID Int)
Returns Table
As
Return
(
	Select P.payment_date, P.final_salary_amount, P.from_date, P.to_date, P.comments, P.bonus_amount, P.deductions_amount
	From Payroll P
	Where P.emp_ID = @employee_ID 
		  AND (DATEADD(MONTH, -1, GETDATE())) BETWEEN P.from_date AND P.to_date
);
Go

-- 2.5) e
create or alter function Deductions_Attendance
(@employee_ID int, @month int) -- we assume that the month is in the current year
returns Table
AS
return (
	select d.deduction_ID, d.date, d.amount, d.type, d.status, d.unpaid_ID, d.attendance_ID
	from Deduction d
	where d.emp_ID = @employee_ID AND month(d.date) = @month AND year(d.date) = year(getdate()) AND
		d.type IN ('missing_hours','missing_days')
) 

go

-- 2.5) f
create or alter function Is_On_Leave
(@employee_ID int, @from_date date, @to_date date)
returns bit
AS
begin
	IF  EXISTS ( 
		select * from Leave L
		WHERE 
		CAST(L.start_date AS DATE) <= @to_date AND CAST(L.end_date AS DATE) >= @from_date
		AND
		L.request_ID IN (
				SELECT request_ID FROM Annual_Leave WHERE emp_ID = @employee_ID
				UNION
				SELECT request_ID FROM Accidental_Leave WHERE emp_ID = @employee_ID
				UNION
				SELECT request_ID FROM Medical_Leave WHERE Emp_ID = @employee_ID
				UNION
				SELECT request_ID FROM Unpaid_Leave WHERE Emp_ID = @employee_ID
				UNION
				SELECT request_ID FROM Compensation_Leave WHERE emp_ID = @employee_ID
			)
	)	return 1
	return 0

end
go

-- 2.5) g
create or alter proc Submit_annual
@employee_id int,
@replacement_emp int,
@start_date date,
@end_date date
as
begin

-- if invalid request
if (cast(@start_date as date)>cast(@start_date as date)) 
return

-- update the leave tables
--			(date_of_request, start_date, end_date, final_approval_status)
insert into Leave(date_of_request, start_date, end_date) values (getdate(), @start_date, @end_date);	-- default status is pending
declare @request_id int = scope_identity()
--		(request_id, employee_id, replacement_id)
insert into Annual_Leave values(@request_id, @employee_id, @replacement_emp)

if (CAST(@start_date AS DATE) < CAST(GETDATE() AS DATE))
begin 
	update Leave
	set final_approval_status='rejected' where request_ID=@request_id
	return
end

-- if employee is part time
if exists (
	select * from Employee where type_of_contract='part_time'
	and employee_ID=@employee_id
) begin 
	update Leave
	set final_approval_status='rejected' where request_ID=@request_id
	return
end


-- useful variables
declare @role varchar(50) = (select top 1 r.role_name from Employee e inner join 
	Employee_Role er on (e.employee_ID=er.emp_ID) inner join Role r on (er.role_name = r.role_name)
	where employee_ID=@employee_id order by r.rank asc)
declare @dept_name varchar(50) = (select top 1 e.dept_name from Employee e where e.employee_ID=@employee_id);
declare @rank int = (select min(rank) from Employee e inner join 
	Employee_Role er on (e.employee_ID=er.emp_ID) inner join Role r on (er.role_name = r.role_name)
	where employee_ID=@employee_id)


-- if dean is submitting a request while vice dean is on leave, automatically reject the request and vice versa
if @role in ('Dean','Vice Dean')
begin
	if not exists (
		-- select both dean and vice dean in the same departement
		-- exclude the employee submitting the request and exclude the employees on leave
		select * from Employee e inner join Employee_Role er on (e.employee_ID=er.emp_ID)
		inner join Role r on (er.role_name=r.role_name)
		where e.dept_name=@dept_name and r.role_name in ('Dean','Vice Dean') and e.employee_ID<>@employee_id
		and dbo.Is_On_Leave(e.employee_ID, @start_date, @end_date) = 0
	) begin 
		update Leave
		set final_approval_status='rejected' where request_ID=@request_id
		return
	end
end

-- if employee is in the HR departement
if exists(
	select * from Employee e inner join Employee_Role er on (e.employee_ID=er.emp_ID)
	where er.role_name like 'HR%' and e.employee_ID=@employee_id
)
begin
	-- we only require approval from the manager
	declare @manager int = (select top 1 e.employee_ID from Employee e inner join Employee_Role er
			on (e.employee_ID=er.emp_ID) where er.role_name = 'HR Manager' and e.employment_status in ('active', 'notice_period'))
	if @manager is null
		begin 
			update Leave
			set final_approval_status='rejected' where request_ID=@request_id
			return
		end

	insert into Employee_Approve_Leave(Emp1_ID, Leave_ID) values(@manager, @request_id)
	return
end

-- hr representative
declare @hr_rep int = (select top 1 employee_ID from Employee e inner join Employee_Role r 
		on (e.employee_ID = r.emp_ID) where r.role_name = concat('HR_Representative_',@dept_name))


-- if @hr_rep is not active -> set @hr_representative to their replacement
if ((select employment_status from Employee e where employee_ID=@hr_rep) not in ('active', 'notice_period'))
	set @hr_rep = (select top 1 Emp1_ID from Employee_Replace_Employee where
		Emp2_ID=@hr_rep and from_date<=CAST(GETDATE() AS DATE) and to_date>=CAST(GETDATE() AS DATE))

-- if no replacement is avaliable sent it to the HR Manager
if @hr_rep is null
set @hr_rep = (select top 1 er.emp_ID from Employee e inner join 
		Employee_Role er on (e.employee_ID=er.emp_ID) where er.role_name = 'HR Manager' and e.employment_status in ('active', 'notice_period'))
if @hr_rep is null
	begin 
		update Leave
		set final_approval_status='rejected' where request_ID=@request_id
		return
	end

insert into Employee_Approve_Leave(Emp1_ID, Leave_ID) values(@hr_rep, @request_id)

-- if employee is a lecturer of a TA
if @rank>=5 
	begin
		-- select employees in the same departement 
		-- who have a rank of 3 or 4 (aka dean or vice dean) 
		-- who is not on leave
		-- dean takes priority over vice dean, i.e sort them by the rank ascending
		declare @dean int = (
			select top 1 employee_ID from Employee e inner join Employee_Role er on (e.employee_ID=er.emp_ID)
			inner join Role r on (er.role_name=r.role_name)
			where r.rank in (3,4) and e.employment_status in ('active', 'notice_period') and e.dept_name=@dept_name
			order by r.rank asc
		)
		if @dean is null
		begin 
			update Leave
			set final_approval_status='rejected' where request_ID=@request_id
			return
		end

		insert into Employee_Approve_Leave(Emp1_ID, Leave_ID) values(@dean, @request_id)
	end
if @rank<5 
	begin
		-- select employees with rank = 1 or 2 (president, vice president)
		-- we have assumed that if the president is on leave, the request will be handled by the vice president
		declare @president int = (
			select top 1 employee_ID from Employee e inner join Employee_Role er on (e.employee_ID=er.emp_ID)
			inner join Role r on (er.role_name=r.role_name)
			where r.rank in (1,2) and e.employment_status in ('active', 'notice_period')
			order by r.rank desc
		)
		-- if noone is available in the upper departement
		if @president is null
		begin 
			update Leave
			set final_approval_status='rejected' where request_ID=@request_id
			return
		end
		insert into Employee_Approve_Leave(Emp1_ID, Leave_ID) values(@president, @request_id)
	end
	
end
go

-- 2.5) h
CREATE OR ALTER FUNCTION Status_leaves(@employee_ID INT)
RETURNS TABLE
AS 
RETURN (
	(
	SELECT l.request_ID, l.date_of_request, l.final_approval_status
	FROM Leave l 
	INNER JOIN Annual_Leave a
	ON l.request_ID = a.request_ID AND a.emp_ID = @employee_ID
	WHERE MONTH(l.date_of_request) = MONTH(GETDATE())
	)
	UNION
	(
	SELECT l1.request_ID, l1.date_of_request, l1.final_approval_status
	FROM Leave l1 
	INNER JOIN Accidental_leave ac
	ON l1.request_ID = ac.request_ID AND ac.emp_ID = @employee_ID
	WHERE MONTH(l1.date_of_request) = MONTH(GETDATE())
	)
	);
GO

-- 2.5) i
create or alter proc Upperboard_approve_annual
@request_ID int, @Upperboard_ID int, @replacement_ID int
as 
begin

-- employee is not supposed to approve the request
-- either invalid request or invalid employee
if not exists(
	select * from Employee_Approve_Leave where Emp1_ID=@Upperboard_ID and Leave_ID=@request_ID
) return


declare @status varchar(50) = 'approved';

declare @start_date date = (select start_date from Leave where request_ID = @request_ID);
declare @end_date date = (select end_date from Leave where request_ID = @request_ID);

declare @employee_id int = (
    select top 1 emp_ID
    from (
        select emp_ID from Annual_Leave where request_ID = @request_id
								UNION
        select emp_ID from Accidental_Leave where request_ID = @request_id
								UNION
        select emp_ID from Compensation_Leave where request_ID = @request_id
								UNION 
        select emp_ID from Medical_Leave where request_ID = @request_id
								UNION 
        select emp_ID from Unpaid_Leave where request_ID = @request_id
    ) as six_sevennnnnn													-- ts is soo tuff
);


declare @dept_1 varchar(50) = (
	select dept_name from Employee e where e.employee_ID=@replacement_ID
);
declare @dept_2 varchar(50) = (
	select dept_name from Employee e where e.employee_ID=@employee_id
);

if dbo.Is_On_Leave(@replacement_ID, @start_date, @end_date) = 1
	set @status = 'rejected'
if @dept_1 <> @dept_2
	set @status = 'rejected'

update Employee_Approve_Leave 
set status = @status 
where Leave_ID=@request_ID and Emp1_ID=@Upperboard_ID;


if @status = 'rejected'
begin
	update Employee_Approve_Leave 
	set status='rejected' where Leave_ID=@request_ID

	update Leave
	set final_approval_status='rejected' where request_ID=@request_ID
end

end
go

-- 2.5) j
create or alter proc Submit_accidental
@employee_id int,
@start_date date,
@end_date date
as
begin

if (cast(@start_date as date)>cast(@start_date as date)) 
return

--		Leave(request_ID, date_of_request, start_date, end_date, final_approval_status)
insert into Leave(date_of_request, start_date, end_date) values (getdate(), @start_date, @end_date);	-- default status is pending
declare @request_id int = scope_identity()

--		(request_id, employee_id)
insert into Accidental_Leave values(@request_id, @employee_id)

if (CAST(@start_date AS DATE) < CAST(GETDATE() AS DATE))
begin 
	update Leave
	set final_approval_status='rejected' where request_ID=@request_id
	return
end


-- if invalid request
-- if duration is greater than 1 day skip the request
if (DATEDIFF(day,@start_date,@end_date)+1 > 1) 
begin 
	update Leave
	set final_approval_status='rejected' where request_ID=@request_id
	return
end

-- useful variables
declare @role varchar(50) = (select top 1 r.role_name from Employee e inner join 
	Employee_Role er on (e.employee_ID=er.emp_ID) inner join Role r on (er.role_name = r.role_name)
	where employee_ID=@employee_id order by r.rank asc)
declare @dept_name varchar(50) = (select e.dept_name from Employee e where e.employee_ID=@employee_id);


-- if dean is submitting a request while vice dean is on leave, skip the request and vice versa
if @role in ('Dean', 'Vice Dean')
begin
	if not exists (
		-- select both dean and vice dean in the same departement
		-- exclude the employee submitting the request and exclude the employees on leave
		select * from Employee e inner join Employee_Role er on (e.employee_ID=er.emp_ID)
		inner join Role r on (er.role_name=r.role_name)
		where e.dept_name=@dept_name and r.role_name in ('Dean', 'Vice Dean') and e.employee_ID<>@employee_id
		and dbo.Is_On_Leave(e.employee_ID, @start_date, @end_date) = 0
	) 
	begin 
		update Leave
		set final_approval_status='rejected' where request_ID=@request_id
		return
	end
end



declare @departement varchar(50) = (select top 1 dept_name from Employee where employee_ID=@employee_id);	-- departement the employee works in


-- if employee is in the HR departement
if exists(
	select * from Employee e inner join Employee_Role er on (e.employee_ID=er.emp_ID)
	where er.role_name like 'HR%' and e.employee_ID=@employee_id
)
begin
	-- we only require approval from the manager
	declare @manager int = (select top 1 e.employee_ID from Employee e inner join Employee_Role er
			on (e.employee_ID=er.emp_ID) where er.role_name = 'HR Manager' and e.employment_status in ('active', 'notice_period'))
	if @manager is null
	begin 
		update Leave
		set final_approval_status='rejected' where request_ID=@request_id
		return
	end

	insert into Employee_Approve_Leave(Emp1_ID, Leave_ID) values(@manager, @request_id)
	return
end

-- hr representative
declare @hr_rep int = (select top 1 employee_ID from Employee e inner join Employee_Role r 
		on (e.employee_ID = r.emp_ID) where r.role_name = concat('HR_Representative_',@dept_name))


-- if @hr_rep is not active -> set @hr_representative to their replacement
if ((select employment_status from Employee e where employee_ID=@hr_rep) not in ('active', 'notice_period'))
	set @hr_rep = (select top 1 Emp1_ID from Employee_Replace_Employee where
		Emp2_ID=@hr_rep and from_date<=CAST(GETDATE() AS DATE) and to_date>=CAST(GETDATE() AS DATE))

-- if no replacement is avaliable sent it to the HR Manager
if @hr_rep is null
set @hr_rep = (select top 1 er.emp_ID from Employee e inner join 
		Employee_Role er on (e.employee_ID=er.emp_ID) where er.role_name = 'HR Manager' and e.employment_status in ('active', 'notice_period'))

if @hr_rep is null
	begin 
		update Leave
		set final_approval_status='rejected' where request_ID=@request_id
		return
	end

insert into Employee_Approve_Leave(Emp1_ID, Leave_ID) values(@hr_rep, @request_id)
end

go

-- 2.5) k
create or alter proc Submit_medical
	@employee_ID int,
	@start_date date,
	@end_date date,
	@type varchar(50),
	@insurance_status bit,
	@disability_details varchar(50),
	@document_description varchar(50),
	@file_name varchar(50)
AS
begin

if (cast(@start_date as date)>cast(@start_date as date)) 
return


-- update the leave tables
--			(date_of_request, start_date, end_date, final_approval_status)
insert into Leave(date_of_request, start_date, end_date) values (getdate(), @start_date, @end_date);	-- default status is pending
declare @request_id int = scope_identity()

--		(request_id, insurance status, disability details, type, employee_id)
insert into Medical_Leave values(@request_id, @insurance_status, @disability_details, @type, @employee_ID)
insert into Document(type, description, file_name, emp_ID, medical_ID) 
	values('Medical', @document_description, @file_name, @employee_ID, @request_id)

if (CAST(@start_date AS DATE) < CAST(GETDATE() AS DATE))
begin 
	update Leave
	set final_approval_status='rejected' where request_ID=@request_id
	return
end

-- useful variables
declare @role varchar(50) = (select top 1 r.role_name from Employee e inner join 
	Employee_Role er on (e.employee_ID=er.emp_ID) inner join Role r on (er.role_name = r.role_name)
	where employee_ID=@employee_id order by r.rank asc)
declare @dept_name varchar(50) = (select top 1 e.dept_name from Employee e where e.employee_ID=@employee_ID);
declare @gender char(1) = (select top 1 gender from Employee where @employee_ID=employee_ID)
declare @type_of_contract varchar(50) = (select type_of_contract from Employee where @employee_ID=employee_ID)


-- if dean is submitting a request while vice dean is on leave, skip the request and vice versa
if @role in ('Dean', 'Vice Dean')
begin
	if not exists (
		-- select both dean and vice dean in the same departement
		-- exclude the employee submitting the request and exclude the employees on leave
		select * from Employee e inner join Employee_Role er on (e.employee_ID=er.emp_ID)
		inner join Role r on (er.role_name=r.role_name)
		where e.dept_name=@dept_name and r.role_name in ('Dean', 'Vice Dean') and e.employee_ID<>@employee_ID
		and dbo.Is_On_Leave(e.employee_ID, @start_date, @end_date) = 0
	) begin 
		update Leave
		set final_approval_status='rejected' where request_ID=@request_id
		return
	end
end

-- male and part time employees cannot submit maternity leaves
if (@type='maternity' and @gender='M')
begin 
	update Leave
	set final_approval_status='rejected' where request_ID=@request_id
	return
end
if (@type='maternity' and @type_of_contract='part_time')
begin 
	update Leave
	set final_approval_status='rejected' where request_ID=@request_id
	return
end

-- get the id of the doctor
declare @doctor int = (select top 1 employee_ID from Employee e where dept_name like 'Medical%' and e.employment_status in ('active', 'notice_period'))

-- request should be approved by a doctor
if @doctor is null
begin 
	update Leave
	set final_approval_status='rejected' where request_ID=@request_id
	return
end
insert into Employee_Approve_Leave values(@doctor, @request_id, 'pending');



-- if employee is in the HR departement
if exists(
	select * from Employee e inner join Employee_Role er on (e.employee_ID=er.emp_ID)
	where er.role_name like 'HR%' and e.employee_ID=@employee_id
)
begin
	-- we only require approval from the manager
	declare @manager int = (select top 1 e.employee_ID from Employee e inner join Employee_Role er
			on (e.employee_ID=er.emp_ID) where er.role_name = 'HR Manager' and e.employment_status IN ('active', 'notice_period'))
	if @manager is null
	begin 
		update Leave
		set final_approval_status='rejected' where request_ID=@request_id
		return
	end

	insert into Employee_Approve_Leave(Emp1_ID, Leave_ID) values(@manager, @request_id)
	return
end


-- hr representative
declare @hr_rep int = (select top 1 employee_ID from Employee e inner join Employee_Role r 
		on (e.employee_ID = r.emp_ID) where r.role_name = concat('HR_Representative_',@dept_name))


-- if @hr_rep is not active -> set @hr_representative to their replacement
if ((select employment_status from Employee e where employee_ID=@hr_rep) not in ('active', 'notice_period'))
	set @hr_rep = (select top 1 Emp1_ID from Employee_Replace_Employee where
		Emp2_ID=@hr_rep and from_date<=CAST(GETDATE() AS DATE) and to_date>=CAST(GETDATE() AS DATE))

-- if no replacement is avaliable sent it to the HR Manager
if @hr_rep is null
set @hr_rep = (select top 1 er.emp_ID from Employee e inner join 
		Employee_Role er on (e.employee_ID=er.emp_ID) where er.role_name like 'HR Manager' and e.employment_status in ('active', 'notice_period'))
if @hr_rep is null
begin 
	update Leave
	set final_approval_status='rejected' where request_ID=@request_id
	return
end

insert into Employee_Approve_Leave(Emp1_ID, Leave_ID) values(@hr_rep, @request_id)

end
go

-- 2.5) l
CREATE or alter proc Submit_unpaid
	@employee_ID INT,
	@start_date DATE,
	@end_date DATE,
	@document_description VARCHAR(50),
	@file_name VARCHAR(50)
AS
begin

if (cast(@start_date as date)>cast(@start_date as date)) 
return


-- update the leave tables
--			(date_of_request, start_date, end_date, final_approval_status)
insert into Leave(date_of_request, start_date, end_date) values (getdate(), @start_date, @end_date);	-- default status is pending
declare @request_id int = scope_identity()
insert into Unpaid_Leave values(@request_id, @employee_ID)

insert into Document(type, description, file_name, emp_ID, unpaid_ID) 
	values('Memo', @document_description, @file_name, @employee_ID, @request_id)

if (CAST(@start_date AS DATE) < CAST(GETDATE() AS DATE))
begin 
	update Leave
	set final_approval_status='rejected' where request_ID=@request_id
	return
end


-- useful variables
declare @role varchar(50) = (select top 1 r.role_name from Employee e inner join 
	Employee_Role er on (e.employee_ID=er.emp_ID) inner join Role r on (er.role_name = r.role_name)
	where employee_ID=@employee_ID order by r.rank asc)
declare @dept_name varchar(50) = (select e.dept_name from Employee e where e.employee_ID=@employee_ID);
declare @type_of_contract varchar(50) = (select type_of_contract from Employee where @employee_ID=employee_ID)
declare @duration int = datediff(day, @start_date, @end_date) + 1
declare @rank INT = (select top 1 r.rank from Employee e inner join 
	Employee_Role er on (e.employee_ID=er.emp_ID) inner join Role r on (er.role_name = r.role_name)
	where employee_ID=@employee_ID order by r.rank asc)

-- part time employees are not eligible for unpaid leave
if (@type_of_contract='part_time')
begin 
	update Leave
	set final_approval_status='rejected' where request_ID=@request_id
	return
end
-- cannot request more than 30 days
if (@duration > 30)
begin 
	update Leave
	set final_approval_status='rejected' where request_ID=@request_id
	return
end
-- maximum one approved request per year
if exists(
	select * from Unpaid_Leave u inner join Leave l on (u.request_ID = l.request_ID)
	where u.Emp_ID=@employee_ID and (year(l.end_date)=year(getdate()) or year(l.start_date)=year(getdate()))
	and l.final_approval_status='approved'
) begin 
	update Leave
	set final_approval_status='rejected' where request_ID=@request_id
	return
end

-- if employee is in the HR departement
if exists(
	select * from Employee e inner join Employee_Role er on (e.employee_ID=er.emp_ID)
	where er.role_name like 'HR%' and e.employee_ID=@employee_ID
)
begin
	-- we require approval from the manager and the president
	declare @manager int = (select top 1 e.employee_ID from Employee e inner join Employee_Role er
			on (e.employee_ID=er.emp_ID) where er.role_name = 'HR Manager' and e.employment_status in ('active','notice_period'))
	declare @president int = (select top 1 e.employee_ID from Employee e inner join Employee_Role er
			on (e.employee_ID=er.emp_ID) where er.role_name = 'President' and e.employment_status in ('active','notice_period'))
	
	if @manager is null or @president is null
	begin 
		update Leave
		set final_approval_status='rejected' where request_ID=@request_id
		return
	end

	insert into Employee_Approve_Leave(Emp1_ID, Leave_ID) values(@manager, @request_id)
	insert into Employee_Approve_Leave(Emp1_ID, Leave_ID) values(@president, @request_id)
	return
end


-- if dean is submitting a request while vice dean is on leave, skip the request and vice versa
if @role in ('Dean', 'Vice Dean')
begin
	if not exists (
		-- select both dean and vice dean in the same departement
		-- exclude the employee submitting the request and exclude the employees on leave
		select * from Employee e inner join Employee_Role er on (e.employee_ID=er.emp_ID)
		inner join Role r on (er.role_name=r.role_name)
		where e.dept_name=@dept_name and r.role_name in ('Dean', 'Vice Dean') and e.employee_ID<>@employee_ID
		and e.employment_status in ('active','notice_period')
		and dbo.Is_On_Leave(e.employee_ID, @start_date, @end_date) = 0
	) begin
		update Leave
		set final_approval_status='rejected' where request_ID=@request_id
		return
	end
end


-- upper board employee
-- higher ranking have higher priority
declare @upper_board int = (
	select top 1 employee_ID from Employee e inner join Employee_Role er on (e.employee_ID=er.emp_ID)
	inner join Role r on (r.role_name = er.role_name)
	where r.rank in (1,2) and e.employment_status in ('active', 'notice_period')
	order by r.rank asc 
) 
if @upper_board is null
begin 
	update Leave
	set final_approval_status='rejected' where request_ID=@request_id
	return
end

insert into Employee_Approve_Leave values(@upper_board, @request_id, 'pending')


-- hr representative
declare @hr_rep int = (select top 1 employee_ID from Employee e inner join Employee_Role r 
		on (e.employee_ID = r.emp_ID) where r.role_name = concat('HR_Representative_',@dept_name))


-- if @hr_rep is not active -> set @hr_representative to their replacement
if ((select employment_status from Employee e where employee_ID=@hr_rep) not in ('active', 'notice_period'))
	set @hr_rep = (select top 1 Emp1_ID from Employee_Replace_Employee where
		Emp2_ID=@hr_rep and from_date<=CAST(GETDATE() AS DATE) and to_date>=CAST(GETDATE() AS DATE))

-- if no replacement is avaliable sent it to the HR Manager
if @hr_rep is null
set @hr_rep = (select top 1 er.emp_ID from Employee e inner join 
		Employee_Role er on (e.employee_ID=er.emp_ID) where er.role_name = 'HR Manager' and e.employment_status in ('active', 'notice_period'))
if @hr_rep is null
begin 
	update Leave
	set final_approval_status='rejected' where request_ID=@request_id
	return
end

insert into Employee_Approve_Leave(Emp1_ID, Leave_ID) values(@hr_rep, @request_id)



-- if the employee submitting the request is a TA or a doctor
if @rank > 5
begin
	
	declare @higher_ranking int = (
		select top 1 employee_ID from Employee e inner join Employee_Role er on (e.employee_ID=er.emp_ID)
		inner join Role r on (r.role_name = er.role_name) 
		where r.rank<@rank and e.dept_name=@dept_name and e.employment_status in ('active', 'notice_period')
		order by r.rank desc
	)
	if @higher_ranking is null
	begin 
		update Leave
		set final_approval_status='rejected' where request_ID=@request_id
		return
	end

	insert into Employee_Approve_Leave values(@higher_ranking, @request_id, 'pending');

end

end
GO

-- 2.5) m
Create or alter Proc Upperboard_approve_unpaids
	@request_ID int,
	@Upperboard_ID int
As
Begin

-- employee is not supposed to approve the request
-- either invalid request or invalid employee
if not exists(
	select * from Employee_Approve_Leave where Emp1_ID=@Upperboard_ID and Leave_ID=@request_ID
) return

declare @status varchar(50) = 'approved'

-- just check if a memo document exists
if not exists(
	select d.document_ID from Leave l inner join Unpaid_Leave u on (l.request_ID = u.request_ID)
	inner join Document d on (d.unpaid_ID=u.request_ID) 
	where l.request_ID=@request_ID and d.type='Memo'
) set @status = 'rejected'

-- update the acceptance status
update Employee_Approve_Leave 
set status = @status
where @request_ID=Leave_ID and @Upperboard_ID=Emp1_ID

if @status = 'rejected'
begin
	update Employee_Approve_Leave 
	set status='rejected' where Leave_ID=@request_ID

	update Leave
	set final_approval_status='rejected' where request_ID=@request_ID
end


 IF @status='approved'
    BEGIN
        IF NOT EXISTS (
            SELECT * 
            FROM Employee_Approve_Leave
            WHERE Leave_ID=@request_ID AND status='pending'
        )
            UPDATE Leave
            SET final_approval_status='approved'
            WHERE request_ID=@request_ID;
    END

End;
Go

-- 2.5) n
Create or alter Proc Submit_compensation 
	@employee_ID Int,
	@compensation_date Date,
	@reason Varchar(50),
	@date_of_original_workday Date,
	@replacement_emp Int 
As
Begin
	
	--Inserting leave request into its tables
	Insert Into Leave (date_of_request, start_date, end_date) 
	Values (Cast(GetDate() As Date), @compensation_date, @compensation_date);
	Declare @leaveID Int = Scope_Identity();

	Insert Into Compensation_Leave (request_ID, emp_ID, date_of_original_workday, reason, replacement_emp)
	Values (@leaveID, @employee_ID, @date_of_original_workday, @reason, @replacement_emp)

	declare @role varchar(50) = (select top 1 r.role_name from Employee e inner join 
		Employee_Role er on (e.employee_ID=er.emp_ID) inner join Role r on (er.role_name = r.role_name)
		where employee_ID=@employee_ID order by r.rank asc)
	declare @dept_name varchar(50) = (select e.dept_name from Employee e where e.employee_ID=@employee_ID);


	-- if dean is submitting a request while vice dean is on leave, skip the request and vice versa
	if @role in ('Dean', 'Vice Dean')
	begin
		if not exists (
			-- select both dean and vice dean in the same departement
			-- exclude the employee submitting the request and exclude the employees on leave
			select * from Employee e inner join Employee_Role er on (e.employee_ID=er.emp_ID)
			inner join Role r on (er.role_name=r.role_name)
			where e.dept_name=@dept_name and r.role_name in ('Dean', 'Vice Dean') and e.employee_ID<>@employee_ID
			and dbo.Is_On_Leave(e.employee_ID, @compensation_date, @compensation_date) = 0
		) begin	
			update Leave
			set final_approval_status='rejected' where request_ID=@leaveID
			return
		end
	end



	if (CAST(@compensation_date AS DATE) < CAST(GETDATE() AS DATE))
	begin 
		update Leave
		set final_approval_status='rejected' where request_ID=@leaveID
		return
	end

	-- Will skip the Comensation Leave submission if they are not in the same month.
	If (Month(@compensation_date) <> Month(@date_of_original_workday))
		begin 
			update Leave
			set final_approval_status='rejected' where request_ID=@leaveID
			return
		end
	

	--Departement of the employee
	Declare @departement Varchar(50) = (Select top 1 dept_name From Employee e Where e.employee_ID=@employee_ID)

	-- if employee is in the HR departement
	if exists(
		select * from Employee e inner join Employee_Role er on (e.employee_ID=er.emp_ID)
		where er.role_name like 'HR%' and e.employee_ID=@employee_id
	)
	begin
		-- we only require approval from the manager
		declare @manager int = (select top 1 e.employee_ID from Employee e inner join Employee_Role er
				on (e.employee_ID=er.emp_ID) where er.role_name = 'HR Manager')
		if @manager is null
		begin 
			update Leave
			set final_approval_status='rejected' where request_ID=@leaveID
			return
		end

		insert into Employee_Approve_Leave(Emp1_ID, Leave_ID) values(@manager, @leaveID)
		return
	end

	-- hr representative
	declare @hr_rep int = (select top 1 employee_ID from Employee e inner join Employee_Role r 
			on (e.employee_ID = r.emp_ID) where r.role_name = concat('HR_Representative_',@dept_name))


	-- if @hr_rep is not active -> set @hr_representative to their replacement
	if ((select employment_status from Employee e where employee_ID=@hr_rep) not in ('active', 'notice_period'))
		set @hr_rep = (select top 1 Emp1_ID from Employee_Replace_Employee where
			Emp2_ID=@hr_rep and from_date<=CAST(GETDATE() AS DATE) and to_date>=CAST(GETDATE() AS DATE))

	-- if no replacement is avaliable sent it to the HR Manager
	if @hr_rep is null
	set @hr_rep = (select top 1 er.emp_ID from Employee e inner join 
			Employee_Role er on (e.employee_ID=er.emp_ID) where er.role_name = 'HR Manager' and e.employment_status in ('active', 'notice_period'))
	if @hr_rep is null
	begin 
		update Leave
		set final_approval_status='rejected' where request_ID=@leaveID
		return
	end

	insert into Employee_Approve_Leave(Emp1_ID, Leave_ID) values(@hr_rep, @leaveID)
End;
Go

--2.5 o)
create or alter proc Dean_andHR_Evaluation
    @employee_ID INT,
    @rating INT,
    @comment VARCHAR(50),
    @semester CHAR(3)
AS
BEGIN

    -- Insert the evaluation
    INSERT INTO Performance(rating, comments, semester, emp_ID)
    VALUES(@rating, @comment, @semester, @employee_ID);
END;



