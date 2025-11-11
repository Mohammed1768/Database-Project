
--بسم الله الرحمن الرحيم  

/*   /\_/\
*   (= ._.)
*   / >  \>
*/


create database MS2;
use MS2;

create table Department(
	name varchar(50) primary key, 
	building_location varchar(50)
);

create table Employee(
	employee_ID int primary key, 
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
	dept_name varchar (50) foreign key references Department(name)
);

create table Employee_Phone (
	emp_ID int foreign key references Employee(employee_ID), 
	phone_num char(11),
	primary key(emp_ID, phone_num)
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
