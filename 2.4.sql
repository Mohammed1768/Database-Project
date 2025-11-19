-- بسم الله الرحمن الرحيم

/*   /\_/\
*   (= ._.)
*   / >  \>
*/

use University_HR_ManagementSystem_Team_No_12;
go


-- 2.4 a)
create or alter function HRLoginValidation(@employee_id int, @password varchar(50)) 
returns bit as 
begin	
	if exists (select * from Employee where employee_ID = @employee_id and password=@password)
		 return 1;
	return 0;
end;
go


create or alter proc HR_approval_on_annual 
@request_ID int, @HR_ID int
as
begin

-- useful variables
declare @num_days int = (select l.num_days from Leave l where l.request_ID = @request_ID);
declare @employee_id int = (
	select top 1 a.emp_ID from Annual_Leave a
	where a.request_ID = @request_ID
);
declare @balance int = (
	select top 1 annual_balance from Employee e
	where e.employee_ID = @employee_id
);
declare @start_date date = (select l.start_date from Leave l where l.request_ID=@request_ID);
declare @end_date date = (select l.end_date from Leave l where l.request_ID=@request_ID);

-- request or employee does not exist in the table
if (@balance is null) return;


declare @hr_status varchar(50) = 'approved'

-- if insufficient leave balance
if (@balance<@num_days) set @hr_status = 'rejected'; 


declare @final_status varchar(50) = @hr_status;
-- if it has been rejected previously (by a dean, president, etc..)
if exists (
	select * from Employee_Approve_Leave e where e.Leave_ID=@request_ID and e.status='rejected')
set @final_status = 'rejected';

update Leave 
set final_approval_status = @final_status			
where request_ID = @request_ID

update Employee_Approve_Leave
set status = @hr_status
where Leave_ID=@request_ID and Emp1_ID=@HR_ID

if @final_status = 'approved'
begin
	update Employee
	set annual_balance = annual_balance - @num_days
	where employee_ID=@employee_id
end

end
go
-- this is line 67 in the IDE, we have reserved it for TUFFness


create or alter proc HR_approval_on_accidental
@request_ID int, @HR_ID int
as
begin

declare @num_days int = (
	select l.num_days from Leave l where l.request_ID = @request_ID
);
declare @employee_id int = (
	select top 1 a.emp_ID from Accidental_Leave a
	where a.request_ID = @request_ID
);
declare @balance int = (
	select top 1 accidental_balance from Employee e
	where e.employee_ID = @employee_id
);

-- request or employee does not exist in the table
if (@balance is null) return;


-- if insufficient leave balance
declare @hr_status varchar(50) = 'approved'
if (@balance<@num_days) set @hr_status = 'rejected'; 


update Leave 
set final_approval_status = @hr_status
where request_ID = @request_ID

update Employee_Approve_Leave
set status = @hr_status
where Leave_ID=@request_ID and Emp1_ID=@HR_ID

if @hr_status = 'approved'
begin
	update Employee
	set annual_balance = annual_balance - @num_days
	where employee_ID=@employee_id
end

end
go


-- 2.4 b)
create or alter proc HR_approval_an_acc 
@request_ID int, @HR_ID int
as 
begin

exec HR_approval_on_annual @request_id, @HR_ID;
exec HR_approval_on_accidental @request_id, @HR_ID;

end
go


-- 2.4 c)
create or alter proc HR_approval_unpaid 
@request_ID int, @HR_ID int
as 
begin
	
declare @status varchar(50) = 'approved';

-- if the request has been previously rejected in the heirarchy
if exists (
	select * from Employee_Approve_Leave e where 
	e.Leave_ID=@request_ID and e.status='rejected' 
) set @status = 'rejected';

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

declare @emp_id int = (select top 1 e.employee_ID from Employee e 
						 inner join Compensation_Leave c on (c.emp_ID = e.employee_ID)
							where c.request_ID = @request_ID);


declare @day_off varchar(50) = (select top 1 e.official_day_off from Employee e where e.employee_ID = @emp_id); 

declare @date date = (select top 1 l.start_date from Leave l where l.request_ID=@request_ID); 

-- number of extra days the employee has worked
declare @no_days int = (
	select count(*) from Attendance a where datepart(hour, @date)>=8 and
	month(a.date) = month(@date) and year(a.date) = year(@date) and 
	@day_off = datename(weekday, a.date)
);

-- number of compensation leaves the employee took
declare @previous_leaves int = (
	select count(*) from Compensation_Leave c inner join Leave l on (c.request_ID = l.request_ID) 
	where month(l.start_date) = month(@date) and year(l.start_date)=year(@date)
	and l.final_approval_status='approved'
);

declare @status varchar(50) = 'approved';

if (@no_days <= @previous_leaves) set @status = 'rejected';


update Leave 
set final_approval_status = @status
where request_ID = @request_ID

update Employee_Approve_Leave
set status = @status
where Leave_ID=@request_ID and Emp1_ID=@HR_ID


end
go

-- 2.4 e)
create or alter proc Deduction_hours	
@employee_ID int
as 
begin

	-- hourly rate = salary / (22 days * 8 hours)

	declare @rate decimal(10,2) = (select top 1 salary from Employee e	
		where e.employee_ID = @employee_ID) / (22 * 8);	
		
	declare @seconds int = (
		select sum(datediff(second, '00:00:00', total_duration)) from Attendance a 
		where
		month(a.date) = month(getdate()) and year(a.date) = year(getdate())
	); 
	declare @hours int = @seconds / (60 * 60);

	declare @attendance int = (
		select top 1 attendance_ID from Attendance a
		where datepart(hour, a.total_duration) < 8 and 
		month(a.date) = month(getdate()) and year(a.date) = year(getdate())
		order by a.date asc
	);

	
	if (@hours >= (22 * 8))  return;				-- if employee has attended over the 22 * 8 hours

	--  			     (emp_ID, date, amount, type, status, attendance_ID)
	insert into Deduction(emp_ID, date, amount, type, status, attendance_ID) 
		values(@employee_ID, getdate(), ((22 * 8) - @hours)*@rate, 'missing_hours', 'finalized', @attendance);
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
	
	-- useful variables
	declare @CurrentMonthStart date = datefromparts(year(getdate()), month(getdate()), 1);
    declare @CurrentMonthEnd   date = eomonth(getdate());
		declare @daily_rate decimal(10,2) = (select top 1 salary from Employee e	
			where e.employee_ID = @employee_ID) / 22;


	-- BOI ts is soo tuff
	create table #very_cool_tmp_table_67(unpaid_id int, start_date date, end_date date, cost decimal(10,2));

	-- insert all the leaves that overlap with the current month into the 67 table
	insert into #very_cool_tmp_table_67 (unpaid_id, start_date, end_date)
	select u.request_ID, l.start_date, l.end_date from 
	Unpaid_Leave u inner join Leave l on (u.request_ID = l.request_ID) WHERE 
		l.start_date <= @CurrentMonthEnd and l.end_date >= @CurrentMonthStart
		and @employee_ID = u.Emp_ID;

	-- we will only consider the part that overlap in our current month
	update #very_cool_tmp_table_67
		set start_date = @CurrentMonthStart 
		where start_date < @CurrentMonthStart;
	update #very_cool_tmp_table_67
		set end_date = @CurrentMonthEnd 
		where end_date > @CurrentMonthEnd;

	-- calculate the cost
	update #very_cool_tmp_table_67
		set cost = day(end_date - start_date + 1) * @daily_rate;


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
		where
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
	if (@bonus <= 0) return 0;
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
declare @deduction_amount decimal(10,2) = (select sum(amount) from Deduction d where d.date<=@to and d.date>=@from)

declare @salary decimal(10,2)= (select top 1 salary from Employee e where e.employee_ID = @employee_ID);		

-- payment_date, final_salary_amount, from_date, to_date, comments, bonus_amount, deduction_amount, emp_ID
insert into Payroll(payment_date, final_salary_amount, from_date, to_date, bonus_amount, deductions_amount, emp_ID) 
			values(cast(getdate() as date), @salary + @bonus - @deduction_amount, @from, @to, @bonus, @deduction_amount, @employee_id);

end

go