
-- بسم الله الرحمن الرحيم

/*   /\_/\
*   (= ._.)
*   / >  \>
*/


create database University_HR_ManagementSystem_Team_No;
go
use University_HR_ManagementSystem_Team_No;

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
	num_days as (DATEDIFF(day, start_date, end_date)),
	final_approval_status varchar(50) DEFAULT 'pending',
	CHECK (final_approval_status IN ('pending', 'approved', 'rejected'))
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
	constraint Pay_empFK foreign key (emp_ID) references Employee(employee_ID)
);

create table Attendance (
    attendance_ID int primary key identity(1,1),
    date date, 
    check_in_time time, 
    check_out_time time, 
    total_duration time, 
    status varchar(50) DEFAULT 'absent', 
    emp_ID int,
    constraint Att_empFK foreign key (emp_ID) references Employee(employee_ID),
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

