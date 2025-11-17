
-- بسم الله الرحمن الرحيم

/*   /\_/\
*   (= ._.)
*   / >  \>
*/


create database University_HR_ManagementSystem_Team_No1;
use University_HR_ManagementSystem_Team_No1;
go;


create function EmployeeLoginValidation
(@employee_ID int, @password varchar(50))
returns bit
AS
begin

	declare @result bit
	if exists (select employee_ID, password
		from employee
		where @employee_ID = employee_ID AND @password = password)

		set @result = 1
	else
		set @result = 0

	return @result
end

go

create function myPerformance
(@employee_ID int, @semester char(3))
returns table
AS
	return (select p.*
		from Performance p
		where p.emp_ID = @employee_ID AND p.semester = @semester)
go

create function MyAttendance ---- not complete
(@employee_ID INT)
returns Table
AS	
	return (
	select * 
	from Employee e1, (
	select a.*
	from Attendance a, employee e
	where a.emp_ID = @employee_ID AND year(a.date) = year(getdate()) AND
		month(a.date) = month(getdate()) AND e.employee_ID = @employee_ID
	) AS out
	where e1.employee_ID = @employee_ID and 
	(e1.official_day_off <> datename(weekday, out.date) OR out.check_in_time = null AND out.check_out_time = null)
	)

go

create function Last_month_payroll
(@employee_ID int)
returns Table
AS

return (select p.*
	from payroll p 
	where (month(p.payment_date) = month(getdate()) - 1 AND year(p.payment_date) = year(getdate()))
		or (year(p.payment_date) = year(getdate())-1 AND month(p.payment_date) = 12 and month(getdate()) = 1)
		)

go

create function Deductions_Attendance
(@employee_ID int, @month int)
returns Table
AS
return (
	select d.*
	from Deduction d
	where d.emp_ID = @employee_ID AND month(d.date) = @month AND 
	d.type IN ('missing_hours','missing_days')
)

go

create function Is_On_Leave
(@employee_ID int, @from_date date, @to_date date)
returns bit
AS
begin
	declare @result bit
	IF  EXISTS ( 
		select 1
		from Leave L
		WHERE 
		CAST(L.start_date AS DATE) <= @to_date AND CAST(L.end_date AS DATE) >= @from_date
		AND
		L.request_ID IN (
				SELECT request_ID FROM Annual_Leave WHERE emp_ID = @employee_ID
				UNION
				SELECT request_ID FROM Accidental_Leave WHERE emp_ID = @employee_ID
				UNION
				SELECT request_ID FROM Medical_Leave WHERE Emp_ID = @employee_ID
				UNION
				SELECT request_ID FROM Unpaid_Leave WHERE Emp_ID = @employee_ID
				UNION
				SELECT request_ID FROM Compensation_Leave WHERE emp_ID = @employee_ID
			)
		)

		set @result = 1
	ELSE
		set @result = 0

	return @result
end

go

create proc Submit_annual
	@employee int,
	@replacement_emp int,
	@start_date date,
	@end_date date
AS
	DECLARE @leaveID int
	DECLARE @approves int

	-- save employee details
	SELECT *
	INTO #tempEmpDetails
	FROM Employee e
	INNER JOIN Employee_Role er
	ON er.emp_ID = e.employee_ID


	-- dont submit if employee is part-time
	IF NOT EXISTS (
		select 1
		from #tempEmpDetails
		Where #tempEmpDetails.type_of_contract = 'part-time'
	)
	return

	INSERT INTO Leave(date_of_request, start_date, end_date)
	VALUES(GETDATE(), @start_date, @end_date);
	SELECT @leaveID = SCOPE_IDENTITY(); 

	INSERT INTO Annual_Leave
	VALUES(@leaveID, @employee, @replacement_emp);

	-- employee is dean or vice dean
	IF EXISTS (
		SELECT 1  
		FROM #tempEmpDetails
		WHERE #tempEmpDetails.role_name IN ('Dean', 'Vice Dean')
	) 
	BEGIN
		
		IF EXISTS (
			SELECT 1  
			FROM #tempEmpDetails
			WHERE #tempEmpDetails.role_name = 'Dean' -- requesting employee is dean
			AND EXISTS (
				SELECT 1
				FROM Employee e3
				INNER JOIN Employee_Role er3
				ON er3.emp_ID = e3.employee_ID
				WHERE e3.dept_name = #tempEmpDetails.dept_name
				AND er3.role_name = 'Vice Dean' AND e3.employment_status = 'on-leave' 
			)
		)
		return; --- dont submit if the vice dean is on leave

		IF EXISTS (
			SELECT 1  
			FROM #tempEmpDetails
			WHERE #tempEmpDetails.role_name = 'Vice Dean' -- requesting employee is dean
			AND EXISTS (
				SELECT 1
				FROM Employee e3
				INNER JOIN Employee_Role er3
				ON er3.emp_ID = e3.employee_ID
				WHERE e3.dept_name = #tempEmpDetails.dept_name
				AND er3.role_name = 'Dean' AND e3.employment_status = 'on-leave'
			)
		)
		return;

		SELECT top 1 @approves = er.employee_ID
		FROM Employee_Role er
		INNER JOIN Employee e
		ON e.employee_ID = er.emp_ID
		WHERE er.role_name LIKE 'HR_Representative%' AND e.dept_name = (select top 1 #tempEmpDetails.dept_name from #tempEmpDetails)
			AND e.employment_status = 'active'
		ORDER BY NEWID(); --- select random hr representative

		INSERT INTO Employee_Approve_Leave(Emp1_ID, Leave_ID)
		VALUES (@approves, @leaveID);

		SELECT top 1 @approves= er.emp_ID
		FROM Employee_Role er 
		WHERE er.role_name = 'president';

		INSERT INTO Employee_Approve_Leave(Emp1_ID, Leave_ID)
		VALUES (@approves, @leaveID);
		return;	
	END
	-- hr employee
	IF EXISTS (
		SELECT 1  
		FROM #tempEmpDetails
		WHERE #tempEmpDetails.role_name LIKE 'HR%'
	)
	BEGIN
		SELECT top 1 @approves = er.emp_ID
		FROM Employee_Role er 
		INNER JOIN Employee e
		ON e.employee_ID = er.emp_ID
		WHERE er.role_name LIKE 'HR_Manager%' AND e.employment_status = 'active'
		ORDER BY NEWID(); --- select random hr manager

		INSERT INTO Employee_Approve_Leave(Emp1_ID, Leave_ID)
		VALUES (@approves, @leaveID);
		return;
	END

	-- not hr or dean or vice dean
	SELECT top 1 @approves = er.employee_ID
	FROM Employee_Role er
	INNER JOIN Employee e
	ON e.employee_ID = er.emp_ID
	WHERE er.role_name LIKE 'HR_Representative%' AND e.dept_name = (select top 1 #tempEmpDetails.dept_name from #tempEmpDetails)
		AND e.employment_status = 'active'
	ORDER BY NEWID(); --- select random hr representative

	INSERT INTO Employee_Approve_Leave(Emp1_ID, Leave_ID)
	VALUES (@approves, @leaveID);

	SELECT top 1 @approves = er.employee_ID
	FROM Employee_Role er
	INNER JOIN Employee e
	ON e.employee_ID = er.emp_ID
	WHERE er.role_name = 'Dean' AND e.dept_name = (select top 1 #tempEmpDetails.dept_name from #tempEmpDetails) AND e.employment_status = 'active'
	
	IF (dbo.Is_On_Leave(@approves, @start_date, @end_date) = 1)
	BEGIN
		SELECT top 1 @approves = er.employee_ID
		FROM Employee_Role er
		INNER JOIN Employee e
		ON e.employee_ID = er.emp_ID
		WHERE er.role_name = 'Vice Dean' AND e.dept_name = (select top 1 #tempEmpDetails.dept_name from #tempEmpDetails) AND e.employment_status = 'active'

		INSERT INTO Employee_Approve_Leave(Emp1_ID, Leave_ID)
		VALUES (@approves, @leaveID);

	END

go



-- 2.5) h
create function Status_leaves() 
returns Table
as 
return (
	select l.request_ID, l.date_of_request, l.final_approval_status 
	from Leave l left outer join Annual_Leave a on (l.request_ID = a.request_ID)
	left outer join Accidental_Leave ac on (l.request_ID = ac.request_ID)

	where month(l.date_of_request) = month(getdate()) and 
	(a.request_ID is not null or ac.request_ID is not null)
);
go


-- 2.5) i
create proc Upperboard_approve_annual
@request_ID int, @Upperboard_ID int, @replacement_ID int
as 
begin

declare @status varchar(50) = 'approved';

declare @start_date date = (select start_date from Leave where request_ID = @request_ID);
declare @end_date date = (select end_date from Leave where request_ID = @request_ID);

declare @employee_id int = (
    select top 1 emp_ID
    from (
        select emp_ID from Annual_Leave where request_ID = @request_id
								UNION
        select emp_ID FROM Accidental_Leave where request_ID = @request_id
								UNION
        select emp_ID FROM Compensation_Leave where request_ID = @request_id
								UNION 
        select emp_ID FROM Medical_Leave where request_ID = @request_id
								UNION 
        select emp_ID FROM Unpaid_Leave where request_ID = @request_id
    ) as six_sevennnnnn
);

-- if replacement is on Accidental Leave
if exists(
	select * from Employee e inner join Accidental_Leave a on (e.employee_ID=a.emp_ID)
	inner join Leave l on (a.request_ID = l.request_ID)

	where e.employee_ID=@replacement_ID and l.end_date>=@start_date and l.start_date<=@end_date
) set @status = 'rejected';

-- if replacement is on Compensation Leave
if exists(
	select * from Employee e inner join Compensation_Leave a on (e.employee_ID=a.emp_ID)
	inner join Leave l on (a.request_ID = l.request_ID)

	where e.employee_ID=@replacement_ID and l.end_date>=@start_date and l.start_date<=@end_date
) set @status = 'rejected';

-- if replacement is on Medical Leave
if exists(
	select * from Employee e inner join Medical_Leave a on (e.employee_ID=a.emp_ID)
	inner join Leave l on (a.request_ID = l.request_ID)

	where e.employee_ID=@replacement_ID and l.end_date>=@start_date and l.start_date<=@end_date
) set @status = 'rejected';

-- if replacement is on Unpaid Leave
if exists(
	select * from Employee e inner join Unpaid_Leave a on (e.employee_ID=a.emp_ID)
	inner join Leave l on (a.request_ID = l.request_ID)

	where e.employee_ID=@replacement_ID and l.end_date>=@start_date and l.start_date<=@end_date
) set @status = 'rejected';

-- if replacement is on Annual Leave
if exists(
	select * from Employee e inner join Annual_Leave a on (e.employee_ID=a.emp_ID)
	inner join Leave l on (a.request_ID = l.request_ID)

	where e.employee_ID=@replacement_ID and l.end_date>=@start_date and l.start_date<=@end_date
) set @status = 'rejected';


declare @dept_1 int = (
	select dept_name from Employee e where e.employee_ID=@replacement_ID
);

declare @dept_2 int = (
	select dept_name from Employee e where e.employee_ID=@employee_id
);

update Employee_Approve_Leave 
set status = @status 
where Leave_ID=@request_ID;

end
go




---j

create proc Submit_accidental
	@employee int,
	@start_date date,
	@end_date date
AS
	IF (datepart(day, @start_date, @end_date) > 1)
		return;
	DECLARE @approves INT
	DECLARE @leaveID int

	SELECT top 1 @approves = er.employee_ID
		FROM Employee_Role er
		INNER JOIN Employee e
		ON e.employee_ID = er.emp_ID
		WHERE er.role_name LIKE 'HR_Representative%' AND e.dept_name = (select top 1 #tempEmpDetails.dept_name from #tempEmpDetails)
			AND e.employment_status = 'active'
		ORDER BY NEWID(); --- select random hr representative

	INSERT INTO Leave(date_of_request, start_date, end_date)
	VALUES(GETDATE(), @start_date, @end_date);
	SELECT @leaveID = SCOPE_IDENTITY(); 

	INSERT INTO Accidental_Leave
	VALUES(@leaveID, @employee);

	INSERT INTO Employee_Approve_Leave(Emp1_ID, Leave_ID)
	VALUES(@approves, @leaveID);

GO



/*

- What happens if both the dean and vice dean took an accidental leave 


*/
