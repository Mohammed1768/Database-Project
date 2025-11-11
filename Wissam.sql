
-- بسم الله الرحمن الرحيم

/*   /\_/\
*   (= ._.)
*   / >  \>
*/


create database University_HR_ManagementSystem_Team_No1;
use University_HR_ManagementSystem_Team_No1;

go;
create proc createAllTables as
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
		salary decimal(10,2), 
		hire_date date, 
		last_working_date date, 
		dept_name varchar (50), 
		constraint deptFK foreign key (dept_name) references Department(name),
		CHECK (type_of_contract IN ('full_time', 'part_time')),
		CHECK (employment_status IN ('active', 'onleave', 'notice_period','resigned'))
	);

	create table Employee_Phone (
		emp_ID int, 
		phone_num char(11),
		primary key(emp_ID, phone_num),
		constraint empFK foreign key (emp_ID) references Employee(employee_ID)
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
		num_days as (DATEDIFF(day, start_date, end_date)),
		final_approval_status varchar(50) DEFAULT 'pending',
		CHECK (final_approval_status IN ('pending', 'approved', 'rejected'))
	);

	create table Annual_Leave(
		request_ID int primary key,
		emp_ID int,
		replacement_emp int,
		constraint empFK foreign key (emp_ID) references Employee (employee_ID),
		constraint leaveFK foreign key (request_ID) references Leave (request_ID),
		constraint repEmpFK foreign key (replacement_emp) references Employee (employee_ID)
	);

	create table Accidental_Leave(
		request_ID int primary key,
		emp_ID int,
		constraint empFK foreign key (emp_ID) references Employee (employee_ID),
		constraint leaveFK foreign key (request_ID) references Leave (request_ID)
	);

	create table Medical_Leave(
		request_ID int primary key,
		insurance_status bit,
		disability_details VARCHAR(50),
		type VARCHAR(50),
		Emp_ID int,
		constraint empFK foreign key (Emp_ID) references Employee (employee_ID),
		constraint leaveFK foreign key (request_ID) references Leave (request_ID),
		CHECK (type IN ('sick', 'maternity'))
	);

	create table Unpaid_Leave(
		request_ID int primary key,
		Emp_ID int,
		constraint empFK foreign key (Emp_ID) references Employee (employee_ID),
		constraint leaveFK foreign key (request_ID) references Leave (request_ID)
	);

	create table Compensation_Leave(
		request_ID int primary key,
		reason varchar(50),
		date_of_original_work_day date,
		emp_ID int,
		replacement_emp_ID int,
		constraint empFK foreign key (emp_ID) references Employee (employee_ID),
		constraint repEmpFK foreign key (replacement_emp_ID) references Employee (employee_ID),
		constraint leaveFK foreign key (request_ID) references Leave (request_ID)
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
		constraint empFK foreign key (emp_ID) references Employee(employee_ID),
		constraint medicalFK foreign key (medical_ID) references Medical_Leave(request_ID),
		constraint unpaidFK foreign key (unpaid_ID) references Unpaid_Leave(request_ID),
		CHECK (status IN ('valid', 'expired'))
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
		constraint empFK foreign key (emp_ID) references Employee(employee_ID)
	);

	create table Attendance (
		attendance_ID int primary key identity(1,1),
		date date, 
		check_in_time time, 
		check_out_time time, 
		total_duration time, 
		status varchar(50) DEFAULT 'absent', 
		emp_ID int,
		constraint empFK foreign key (emp_ID) references Employee(employee_ID),
		CHECK (status IN ('absent', 'attended'))
	);

	create table Deduction (
		deduction_ID int primary key identity(1,1), 
		emp_ID int, 
		date date,
		amount decimal(10, 2),
		type varchar(50), 
		status varchar(50) DEFAULT 'pending',
		unpaid_ID int, 
		attendance_ID int, 
		constraint empFK foreign key (emp_ID) references Employee(employee_ID), 
		constraint unpaidFK foreign key (unpaid_ID) references Unpaid_Leave(request_ID),
		constraint attendanceFK foreign key (attendance_ID) references Attendance(attendance_ID),
		CHECK (type IN ('unpaid', 'missing_hours', 'missing_days')),
		CHECK (status IN ('pending', 'finalized'))
	);

	create table Performance (
		performance_ID int primary key identity(1,1),
		rating int, 
		comments varchar(50), 
		semester char(3), 
		emp_ID int, 
		constraint empFK foreign key (emp_ID) references Employee(employee_ID),
		CHECK (rating >= 1 AND rating <= 5)
	);

	create table Employee_Replace_Employee (
		Emp1_ID int, 
		Emp2_ID int, 
		from_date date, 
		to_date date,
		primary key (Emp1_ID, Emp2_ID, from_date),
		foreign key (Emp1_ID) references Employee(employee_ID), 
		foreign key (Emp2_ID) references Employee(employee_ID) 
	);

	create table Employee_Approve_Leave (
		Emp1_ID int, 
		Leave_ID int, 
		status varchar(50), 
		primary key (Emp1_ID, Leave_ID),
		foreign key (Emp1_ID) references Employee(employee_ID), 
		foreign key (Leave_ID) references Leave(request_ID) 
	);
end;

go;


create proc dropAllTables as 
begin
	drop table if exists Employee_Approve_Leave;
	drop table if exists  Employee_Replace_Employee;
	drop table if exists  Performance;
	drop table if exists  Deduction;
	drop table if exists  Attendance;	
	drop table if exists  Payroll;
	drop table if exists  Document;
	drop table if exists  Compensation_Leave;
	drop table if exists  Unpaid_Leave;
	drop table if exists  Medical_Leave;
	drop table if exists  Accidental_Leave;
	drop table if exists  Annual_Leave;
	drop table if exists  Leave;
	drop table if exists  Role_existsIn_Department;
	drop table if exists  Employee_Role;
	drop table if exists  Role;
	drop table if exists  Employee_Phone;
	drop table if exists  Employee;
	drop table if exists  Department;
end;
go;

/*
create proc dropAllProceduresFunctionsViews as 
begin
	-- drop procedures here
end;
go;
*/

create procedure clearAllTables as 
begin
	truncate table Employee_Approve_Leave;
	truncate table Employee_Replace_Employee;
	truncate table Performance;
	truncate table Deduction;
	truncate table Attendance;	
	truncate table Payroll;
	truncate table Document;
	truncate table Compensation_Leave;
	truncate table Unpaid_Leave;
	truncate table Medical_Leave;
	truncate table Accidental_Leave;
	truncate table Annual_Leave;
	truncate table Leave;
	truncate table Role_existsIn_Department;
	truncate table Employee_Role;
	truncate table Role;
	truncate table Employee_Phone;
	truncate table Employee;
	truncate table Department;
end;
go;


create function HRLoginValidation(@employee_id int, @password varchar(50)) 
returns bit as 
begin	
	if exists (select * from Employee where employee_ID = @employee_id and password=@password)
		begin return 1; end
	return 0;
end;
go;

create proc HR_approval_an_acc 
@request_ID int, @HR_ID int
as 
begin
declare @status bit
declare @annual_balance int
declare @accidental_balance int

set @annual_balance = (
	select top 1 annual_balance from Employee e inner join Annual_Leave a on(e.employee_ID = a.emp_ID)
	where a.request_ID = @request_ID
);
set @accidental_balance = (
	select top 1 accidental_balance from Employee e inner join Accidental_Leave a on(e.employee_ID = a.emp_ID)
	where a.request_ID = @request_ID
);

if (@accidental_balance>1 or @annual_balance>1)
	begin set @status = 1 end;
else
	begin set @status = 0 end;

update Employee_Approve_Leave 
set status = @status 
where Emp1_ID=@HR_ID and Leave_ID=@request_ID;
end
go;


create proc HR_approval_unpaid 
@request_ID int, @HR_ID int
as 
begin
declare @status bit
/* 
Unpaid leave can be requested when an employee has no annual leave balance remaining. The
request must include a memo document, and it requires approval from a higher-ranking
employee, the Upper Board department, and the HR representative as in section 2, . The
maximum number of unpaid leave days allowed is 30.
*/
create table a7a(id int);
end
go;


create proc HR_approval_comp 
@request_ID int, @HR_ID int
as 
begin
declare @status bit
/*
Compensation leave is granted when an employee works on their official day off. In return, the
employee is allowed to take another working day off within the same month. The request must
include the reason and the date of the original extra workday.
Compensations are approved by the employee’s HR representative.
When an employee applies for a compensation leave, another employee must replace them.
*/
create table a7a(id int);
end
go;
