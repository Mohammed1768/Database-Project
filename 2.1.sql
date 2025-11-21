-- بسم الله الرحمن الرحيم

/*   /\_/\
*   (= ._.)
*   / >  \>
*/

-- 2.1 a):
create database University_HR_ManagementSystem_Team_No_12;
go
use University_HR_ManagementSystem_Team_No_12;
go




-- 2.1 b):
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
		date_of_original_work_day date,
		emp_ID int,
		replacement_emp_ID int,
		constraint Com_empFK foreign key (emp_ID) references Employee (employee_ID),
		constraint Com_repEmpFK foreign key (replacement_emp_ID) references Employee (employee_ID),
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
		deduction_ID int primary key identity(1,1), 
		emp_ID int, 
		date date,
		amount decimal(10, 2),
		type varchar(50), 
		status varchar(50) DEFAULT 'pending',
		unpaid_ID int, 
		attendance_ID int, 
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
		Emp1_ID int, 
		Emp2_ID int, 
		from_date date, 
		to_date date,
		primary key (Emp1_ID, Emp2_ID, from_date),
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
create procedure dropAllTables as 
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
create proc dropAllProceduresFunctionsViews as		
begin
	-- all functions
	drop function getsalary, HRLoginValidation, Bonus_amount, EmployeeLoginValidation, MyPerformance,
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
go




-- helper function:
create function getsalary(@employee_id int)
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
