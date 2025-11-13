
-- بسم الله الرحمن الرحيم

/*   /\_/\
*   (= ._.)
*   / >  \>
*/


create database University_HR_ManagementSystem_Team_No1;
use University_HR_ManagementSystem_Team_No1;
go;


-- mohamed et2aked mn el schema 34an byetla3 3eny wana ba3adelha wallahy
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
		constraint Emp_deptFK foreign key (dept_name) references Department(name),
		CHECK (type_of_contract IN ('full_time', 'part_time')),
		CHECK (employment_status IN ('active', 'onleave', 'notice_period','resigned'))
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
		 return 1
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

if (@accidental_balance>0 or @annual_balance>0)
	 set @status = 1;
else
	 set @status = 0;

update Employee_Approve_Leave
set status = case 
    when @status = 1 then 'approved'
    else 'rejected'
end
where Emp1_ID = @HR_ID and Leave_ID = @request_ID;

update Leave
set final_approval_status = case 
    when @status = 1 then 'approved'
    else 'rejected'
end
where request_ID = @request_ID;


end
go;



create proc HR_approval_unpaid 
@request_ID int, @HR_ID int, @status bit
as 
begin
	update Employee_Approve_Leave
	set status = case 
		when @status = 1 then 'approved'
		else 'rejected'
	end
	where Emp1_ID = @HR_ID and Leave_ID = @request_ID;

	update Leave
	set final_approval_status = case 
		when @status = 1 then 'approved'
		else 'rejected'
	end
	where request_ID = @request_ID;
end
go;


create proc HR_approval_comp 
@request_ID int, @HR_ID int, @status bit
as 
begin
	update Employee_Approve_Leave
	set status = case 
		when @status = 1 then 'approved'
		else 'rejected'
	end
	where Emp1_ID = @HR_ID and Leave_ID = @request_ID;

	update Leave
	set final_approval_status = case 
		when @status = 1 then 'approved'
		else 'rejected'
	end
	where request_ID = @request_ID;
end
go;

create proc Deduction_hours	
@employee_ID int
as 
begin
	declare @sum int, @rate decimal(10,2), @attendance int, @first_date date

	set @rate = (
		select top 1 salary from Employee where @employee_ID = @employee_ID
	);
	set @sum = (
		select sum(total_duration) from Attendance a 
		where
		month(a.date) = month(getdate()) and year(a.date) = year(getdate())
	);
	set @attendance = (
		select top 1 attendance_ID from Attendance a
		where total_duration < 8 and 
		month(a.date) = month(getdate()) and year(a.date) = year(getdate())
		order by total_duration asc
	);
	set @first_date = (
		select top 1 date from Attendance a
		where attendance_ID = @attendance
		order by total_duration asc
	);

	if (@sum = 0 or @sum>=176)  return;

	--  			     (emp_ID, date, amount, type, status, attendance_ID)
	insert into Deduction(emp_ID, date, amount, type, status, attendance_ID) 
		values(@employee_ID, @first_date, (176 - @sum)*@rate, 'missing_hours', 'finalized', @attendance);
end
go;


create proc Deduction_days	
@employee_ID int
as 
begin
	declare @count int, @rate decimal(10,2), @first_date date

	set @rate = (
		select top 1 salary from Employee where @employee_ID = @employee_ID
	);
	set @count = (
		select count(*) from Attendance a
		where 
		month(a.date) = month(getdate()) and year(a.date) = year(getdate())
	);

	if (@count >= 22) return;

	insert into Deduction(emp_ID, amount, type, status) 
		values(@employee_ID, (22 - @count)*@rate*8, 'missing_days', 'finalized');
end
go;

create proc Deduction_unpaid	
@employee_ID int
as 
begin
	declare @count int, @rate decimal(10,2)

	set @rate = (
		select top 1 salary from Employee where @employee_ID = @employee_ID
	);
	
	create table tmp(start_date date, end_date date, days int);

	insert into tmp(start_date, end_date)
		select l.start_date,l.end_date
		from Unpaid_Leave u inner join Leave l on (u.request_ID = l.request_ID)
		where month(end_date) = month(getdate()) and year(end_date) = year(getdate())

	update tmp set start_date = 
	datefromparts(
			year(getdate()),    -- year
			month(getdate()),   -- month
			1                   -- day
	)
	where month(start_date) != month(getdate());
	update tmp set days = day(end_date-start_date) + 1;

	set @count = (select sum(days) from tmp);

	--  	(emp_ID, date, amount, type, status, attendance_ID)
	insert into Deduction(emp_ID, amount, type, status) 
		values(@employee_ID, 8*@count*@rate, 'unpaid', 'finalized');
end
go;

create function Bonus_amount(@employee_id int)
returns int as 
begin
	declare @sum int, @rate int, @bonus int;

	set @sum = (
		select sum(total_duration) from Attendance a
		where
		month(a.date) = month(getdate()) and year(a.date) = year(getdate())
	);
	set @rate = (
		select top 1 salary from Employee where @employee_ID = @employee_ID
	);
	
	set @bonus = (@sum - 22*8) * @rate;
	if (@bonus <= 0) return 0;
	return @bonus;

end
go;

create proc Add_Payroll
@employee_id int,
@from date, @to date
as 
begin
declare @bonus int, @deduction_amount int, @rate int

set @bonus = dbo.Bonus_amount(@employee_id)	
set @deduction_amount = (select sum(amount) from Deduction d where d.date<=@to and d.date>=@from)
set @rate = (select top 1 salary from Employee where @employee_ID = @employee_ID);

-- payment_date, final_salary_amount, from_date, to_date, comments, bonus_amount, deduction_amount, emp_ID
insert into Payroll(payment_date, final_salary_amount, from_date, to_date, bonus_amount, deductions_amount, emp_ID) 
			values(getdate(), 22*8*@rate + @bonus - @deduction_amount, @from, @to, @bonus, @deduction_amount, @employee_id);

end


