
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


-- 2.4 b)
create proc HR_approval_an_acc 
@request_ID int, @HR_ID int
as 
begin
declare @status bit

declare @annual_balance int = (
	select top 1 annual_balance from Employee e inner join Annual_Leave a on (e.employee_ID = a.emp_ID)
	where a.request_ID = @request_ID
);

declare @accidental_balance int = (
	select top 1 accidental_balance from Employee e inner join Accidental_Leave a on (e.employee_ID = a.emp_ID)
	where a.request_ID = @request_ID
);

-- request does not exist in the table
if (@annual_balance is null and @accidental_balance is null) return;

if (@annual_balance is null) set @annual_balance = 0;
if (@accidental_balance is null) set @accidental_balance = 0;


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



-- 2.4 c)
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


-- 2.4 d)
create proc HR_approval_comp 	
@request_ID int, @HR_ID int
as 
begin
	
	declare @emp_id int =	(select top 1 e.employee_ID from Employee e 
							inner join Compensation_Leave c on (c.emp_ID = e.employee_ID)
							where c.request_ID = @request_ID);


	declare @day_off varchar(50) = (select top 1 e.official_day_off from Employee e where e.employee_ID = @emp_id); 

	declare @status bit = case when exists(
		select * from Attendance a where a.emp_ID=@emp_id
		and a.status='attended' and 
		datename(WEEKDAY, a.date) = @day_off 
		and month(a.date) = month(getdate()) and a.total_duration >= 8
	) then 1 else 0 end; 

	

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


-- 2.4 e)
create proc Deduction_hours	
@employee_ID int
as 
begin
	declare @hours int, @rate decimal(10,2), @attendance int

	-- base salary hourly rate = salary / (22 days * 8 hours)
	declare @base_salary decimal(10,2)= (select top 1 salary from Employee e	
		where e.employee_ID = @employee_ID) / (22 * 8);		
	
	declare @years int = (select top 1 e.years_of_experience from Employee e 
		where e.employee_ID = @employee_ID);


	set @rate = @base_salary * (1 +  @years * 0.01);
		
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

	
	if (@hours >= (22 * 8))  return;				-- if employee has attended over the 22 * 8 hours

	--  			     (emp_ID, date, amount, type, status, attendance_ID)
	insert into Deduction(emp_ID, date, amount, type, status, attendance_ID) 
		values(@employee_ID, getdate(), ((22 * 8) - @hours)*@rate, 'missing_hours', 'finalized', @attendance);
end
go;


-- 2.4 f)
create proc Deduction_days	
@employee_ID int
as 
begin

	declare @base_salary decimal(10,2)= (select top 1 salary from Employee e	
		where e.employee_ID = @employee_ID) / 22;		
	
	declare @years int = (select top 1 e.years_of_experience from Employee e 
		where e.employee_ID = @employee_ID);


	declare @daily_rate decimal(10,2) = @base_salary * (1 + @years * 0.01);
	
	-- delete all previously added deductions from the current month
	delete from Deduction where
		 type = 'missing_days' and @employee_ID = emp_ID and 
		 month(date)=month(getdate()) and year(date)=year(getdate());


		-- Deduction(emp_ID, date, amount, type, status, unpaid_ID, attendance_ID)
	insert into Deduction(emp_ID, date, amount, type, status)
		select @employee_ID, datefromparts(year(getdate()), month(getdate()), a.date), 
			@daily_rate, 'missing_days', 'finalized' 
		from Attendance a
		where month(a.date) = month(getdate()) and year(a.date)=year(getdate())
			and a.status = 'absent' and a.emp_ID = @employee_ID; 

end
go;

-- 2.4 g)
create proc Deduction_unpaid	
@employee_ID int
as 
begin
	declare @CurrentMonthStart date = datefromparts(year(getdate()), month(getdate()), 1);
    declare @CurrentMonthEnd   date = eomonth(getdate());


	create table #very_cool_tmp_table_67(start_date date, end_date date, duration int);

	-- all the leaves that overlap with the current month
	insert into #very_cool_tmp_table_67 (start_date, end_date)
	select l.start_date, l.end_date from 
	Unpaid_Leave u inner join Leave l on (u.request_ID = l.request_ID) WHERE 
		l.start_date <= @CurrentMonthEnd and l.end_date >= @CurrentMonthStart
		and @employee_ID = u.Emp_ID;

	update #very_cool_tmp_table_67
		set start_date = @CurrentMonthStart 
		where start_date < @CurrentMonthStart;

	update #very_cool_tmp_table_67
		set end_date = @CurrentMonthEnd 
		where end_date > @CurrentMonthEnd;

	update #very_cool_tmp_table_67
		set duration = end_date - start_date;
		
	
	declare @base_salary decimal(10,2)= (select top 1 salary from Employee e	
		where e.employee_ID = @employee_ID) / 22;		
	
	declare @years int = (select top 1 e.years_of_experience from Employee e 
		where e.employee_ID = @employee_ID);

	declare @daily_rate decimal(10,2) = @base_salary * (1 + @years * 0.01);


	declare @count int = (select sum(duration) from #very_cool_tmp_table_67);

	insert into Deduction(emp_ID, date, amount, type, status, unpaid_ID) 
		values(@employee_ID, getdate(), @daily_rate * @count, 'unpaid', 'finalized');

	
end
go;

-- 2.4 h)
create function Bonus_amount(@employee_id int)
returns int as 
begin

	declare @count int = (
		select sum(total_duration) from Attendance a
		where
		month(a.date) = month(getdate()) and year(a.date) = year(getdate())
	);

	declare @base_salary decimal(10,2)= (select top 1 salary from Employee e	
		where e.employee_ID = @employee_ID) / (22 * 8);		
	
	declare @years int = (select top 1 e.years_of_experience from Employee e 
		where e.employee_ID = @employee_ID);

	declare @rate decimal(10,2) = @base_salary * (1 + @years * 0.01);

	declare @factor int = 
			(select top 1 r.percentage_overtime from Role r, Employee e, Employee_Role er where	
			@employee_id = e.employee_ID and @employee_id=er.emp_ID and r.role_name=er.role_name
			order by r.rank desc);

	declare @bonus int = (@count - 22*8) * @rate * @factor * 0.01;
	if (@bonus <= 0) return 0;
	return @bonus;

end
go;



-- 2.4 i)

/* 
* we are going to assume that the from and to date are the first and last date of the current month 
*  this is assumed so that the function call to the bonus method is correct
*  may be changed later 
*/
create proc Add_Payroll
@employee_id int,
@from date, @to date	
as						
begin

declare @bonus int = dbo.Bonus_amount(@employee_id)	
declare @deduction_amount int = (select sum(amount) from Deduction d where d.date<=@to and d.date>=@from)

declare @base_salary decimal(10,2)= (select top 1 salary from Employee e where e.employee_ID = @employee_ID);		
declare @years int = (select top 1 e.years_of_experience from Employee e where e.employee_ID = @employee_ID);
declare @salary decimal(10,2) = @base_salary * (1 + @years * 0.01);

-- payment_date, final_salary_amount, from_date, to_date, comments, bonus_amount, deduction_amount, emp_ID
insert into Payroll(payment_date, final_salary_amount, from_date, to_date, bonus_amount, deductions_amount, emp_ID) 
			values(getdate(), @salary + @bonus - @deduction_amount, @from, @to, @bonus, @deduction_amount, @employee_id);

end


/* 

- DeductionDay is it one deduction for all days or one for every day

- what is the dates in DeductionDay, DeductionLeave, and deduction Hours

- Employee will have DeductionDay until he attends the day.
	i.e if today's date is 17/4, do we add a deduction for dates yet to come?
- status parameter in HR_approval_unpaid

- formula for salary? is it years_of_experience squared

- How do we handle the case that for example the president needs to approve the request?  
	is the HR_ID in the procedure going to be the id of the president?
	if the HR representative is processing the request before the president? does he reject it or pass it

- if the Dean wants a compensation leave? does he also require approval from the president? or just check if he attended during his holiday?
	same in accidental leave
	what is the purpose of HR_id in compensation leave request if its done systematically anyways

- what decides whether an unpaid leave request is accepted or rejected

- is friday also considered a day off?

- what does he mean by valid reason in compensation leave approval
*/