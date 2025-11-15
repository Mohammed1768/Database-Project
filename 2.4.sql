
-- بسم الله الرحمن الرحيم

/*   /\_/\
*   (= ._.)
*   / >  \>
*/


create database University_HR_ManagementSystem_Team_No1;
use University_HR_ManagementSystem_Team_No1;
go;


-- 2.4 a)
create function HRLoginValidation(@employee_id int, @password varchar(50)) 
returns bit as 
begin	
	if exists (select * from Employee where employee_ID = @employee_id and password=@password)
		 return 1;
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

set @annual_balance = 0
set @accidental_balance = 0

set @annual_balance = (
	select top 1 annual_balance from Employee e inner join Annual_Leave a on (e.employee_ID = a.emp_ID)
	where a.request_ID = @request_ID
);
set @accidental_balance = (
	select top 1 accidental_balance from Employee e inner join Accidental_Leave a on (e.employee_ID = a.emp_ID)
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
@request_ID int, @HR_ID int, @status bit	-- extra parameter 'status' should be passed to the proc
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
@request_ID int, @HR_ID int, @status bit	-- extra parameter 'status' should be passed to the proc
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
	declare @hours int, @rate decimal(10,2), @attendance int

	set @rate = (select top 1 salary from Employee 				-- hourly rate = salary / (22 days * 8 hours)
		where @employee_ID = @employee_ID) / (22 * 8);		

	set @hours = (
		select sum(total_duration) from Attendance a 
		where
		month(a.date) = month(getdate()) and year(a.date) = year(getdate())
	);

	set @attendance = (
		select top 1 attendance_ID from Attendance a
		where total_duration < 8 and 
		month(a.date) = month(getdate()) and year(a.date) = year(getdate())
		order by a.date asc
	);

	
	if (@hours = 0 or @hours >= (22 * 8))  return;

	--  			     (emp_ID, date, amount, type, status, attendance_ID)
	insert into Deduction(emp_ID, date, amount, type, status, attendance_ID) 
		values(@employee_ID, getdate(), ((22 * 8) - @hours)*@rate, 'missing_hours', 'finalized', @attendance);
end
go;


create proc Deduction_days	
@employee_ID int
as 
begin
	declare @count int, @rate decimal(10,2), @first_date date

	set @rate = (select top 1 salary from Employee 				-- daily rate = salary / 22 days
		where @employee_ID = @employee_ID) / (22 * 8);	

	set @count = (
		select count(a.attendance_ID) from Attendance a
		where 
		month(a.date) = month(getdate()) and year(a.date) = year(getdate())
	);

	if (@count >= 22) return;

	insert into Deduction(emp_ID, date, amount, type, status) 
		values(@employee_ID, getdate(), (22 - @count)*@rate, 'missing_days', 'finalized');
end
go;

create proc Deduction_unpaid	
@employee_ID int
as 
begin
	

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


