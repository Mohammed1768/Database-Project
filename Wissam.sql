
-- بسم الله الرحمن الرحيم

/*   /\_/\
*   (= ._.)
*   / >  \>
*/


create database University_HR_ManagementSystem_Team_No;
use University_HR_ManagementSystem_Team_No;
go;

create proc createAllTables as
begin
	-- create the tables here
end;
go;

create proc dropAllTables as 
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

create proc dropAllProceduresFunctionsViews as 
begin
	-- drop procedures here
end;
go;

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

