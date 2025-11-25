-- بسم الله الرحمن الرحيم

/*   /\_/\
*   (= ._.)
*   / >  \>
*/

use University_HR_ManagementSystem_Team_No_12
go


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
begin
	update Leave 
	set final_approval_status = 'rejected'			
	where request_ID = @request_ID
	return
end

-- check if leave is already approved (prevents double deduction)
declare @current_status varchar(50) = (
    select final_approval_status from Leave where request_ID = @request_ID
);
if (@current_status = 'approved')
    return -- already processed, don't deduct balance again


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
declare @replacement_emp int = (select top 1 replacement_emp from Annual_Leave where request_id=@request_ID)


if (@start_date <= cast(getdate() as date))
begin
	update Leave 
	set final_approval_status = 'rejected'			
	where request_ID = @request_ID
	return
end

declare @final_status varchar(50) = 'approved'
-- if insufficient leave balance
if (@balance is null or @balance<@num_days) set @final_status = 'rejected'; 


-- check if employee already has overlapping approved leaves using Is_On_Leave function
if @final_status = 'approved'
begin
    if (dbo.Is_On_Leave(@employee_id, @start_date, @end_date) = 1)
        set @final_status = 'rejected'; -- employee already has overlapping leave
end

update Leave 
set final_approval_status = @final_status			
where request_ID = @request_ID

update Employee_Approve_Leave
set status = @final_status
where Leave_ID=@request_ID and Emp1_ID=@HR_ID

if @final_status = 'approved'
begin
	-- deduct balance AFTER validation but BEFORE replacement
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
begin
	update Leave 
	set final_approval_status = 'rejected'			
	where request_ID = @request_ID
	return
end

-- check if leave is already approved (prevents double deduction)
declare @current_status varchar(50) = (
    select final_approval_status from Leave where request_ID = @request_ID
);
if (@current_status = 'approved')
    return; -- already processed, don't deduct balance again

-- check if submitted within 48 hours (from date_of_request to start_date)
declare @date_of_request datetime = (select date_of_request from Leave where request_ID=@request_ID);
declare @start_date datetime = (select start_date from Leave where request_ID=@request_ID);
declare @employee_id int = (
	select top 1 a.emp_ID from Accidental_Leave a
	where a.request_ID = @request_ID
);
declare @balance int = (
	select top 1 accidental_balance from Employee e
	where e.employee_ID = @employee_id
);
declare @end_date date = (select end_date from Leave where request_ID=@request_ID);


if (@start_date <= cast(getdate() as date))
begin
	update Leave 
	set final_approval_status = 'rejected'			
	where request_ID = @request_ID
	return
end


if (DATEDIFF(hour, @date_of_request, @start_date) > 48)
begin
    update Leave 
    set final_approval_status = 'rejected'
    where request_ID = @request_ID
    
    update Employee_Approve_Leave
    set status = 'rejected'
    where Leave_ID=@request_ID and Emp1_ID=@HR_ID
    
    return
end


if (@start_date <= cast(getdate() as date))
begin
	update Leave 
	set final_approval_status = 'rejected'			
	where request_ID = @request_ID
	return
end



-- request or employee does not exist in the table
if (@balance is null) 
begin
	update Leave 
	set final_approval_status = 'rejected'			
	where request_ID = @request_ID
	return
end


-- if insufficient leave balance
declare @hr_status varchar(50) = 'approved'
if (@balance<1) set @hr_status = 'rejected'; 

-- check if employee already has overlapping approved leaves using Is_On_Leave function
if @hr_status = 'approved'
begin
    if (dbo.Is_On_Leave(@employee_id, @start_date, @end_date) = 1)
        set @hr_status = 'rejected'; -- employee already has overlapping leave
end

update Leave 
set final_approval_status = @hr_status
where request_ID = @request_ID

update Employee_Approve_Leave
set status = @hr_status
where Leave_ID=@request_ID and Emp1_ID=@HR_ID

if @hr_status = 'approved'
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

if exists(
	select * from Leave where request_ID=@request_ID and final_approval_status='rejected'
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
begin
	update Leave 
	set final_approval_status = 'rejected'			
	where request_ID = @request_ID
	return
end

declare @start_date datetime = (select start_date from Leave where request_ID=@request_ID);
if (@start_date <= cast(getdate() as date))
begin
	update Leave 
	set final_approval_status = 'rejected'			
	where request_ID = @request_ID
	return
end


declare @status varchar(50) = 'approved';

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

if exists(
	select * from Leave where request_ID=@request_ID and final_approval_status='rejected'
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
begin
	update Leave 
	set final_approval_status = 'rejected'			
	where request_ID = @request_ID
	return
end

-- useful variables
declare @emp_id int = (select top 1 e.employee_ID from Employee e 
						 inner join Compensation_Leave c on (c.emp_ID = e.employee_ID)
							where c.request_ID = @request_ID);
declare @date date = (select top 1 l.start_date from Leave l where l.request_ID=@request_ID); 
declare @day_off varchar(50) = (select official_day_off from Employee where employee_ID=@emp_id)
declare @date_of_original_work_day date = (select date_of_original_workday from Compensation_Leave where request_ID=@request_ID)
declare @replacement_emp int = (select replacement_emp from Compensation_Leave where request_id=@request_ID)

declare @status varchar(50) = 'approved'

if (@date <= cast(getdate() as date))
begin
	update Leave 
	set final_approval_status = 'rejected'			
	where request_ID = @request_ID
	return
end

-- if employee took another compensation leave using the same day off
if exists(
	select * from Compensation_Leave 
	where request_ID<>@request_ID 
	and date_of_original_workday=@date_of_original_work_day
) set @status = 'rejected'

if (MONTH(@date) <> MONTH(@date_of_original_work_day) OR YEAR(@date) <> YEAR(@date_of_original_work_day))
	set @status = 'rejected'

declare @hours_worked int = (
	select DATEDIFF(hour, check_in_time, check_out_time)
	from Attendance
	where emp_ID = @emp_id 
	  and date = @date_of_original_work_day
);
if (@hours_worked < 8 OR @hours_worked IS NULL)
	set @status = 'rejected'

if (dbo.Is_On_Leave(@replacement_emp, @date, @date) = 1)
	set @status = 'rejected'


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


