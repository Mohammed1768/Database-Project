-- بسم الله الرحمن الرحيم

/*   /\_/\
*   (= ._.)
*   / >  \>
*/

Use University_HR_ManagementSystem_Team_No_12;
Go


-- 2.5 a):
Create Function EmployeeLoginValidation(@employee_ID Int, @password varchar(50))
Returns Bit
As
Begin
	IF EXISTS (Select 1 From Employee Where Employee_ID = @employee_ID And Password = @password)
		Return 1;
	Return 0;
End;
Go


-- 2.5 b):
Create Function MyPerformance(@employee_ID Int,@semester char(3))
Returns Table
As
Return
(
	Select P.semester, P.rating, P.comments
	From Performance P
	Where P.emp_ID = @employee_ID And P.semester = @semester
);
Go


-- 2.5 c): Assumed that admin removes unattended official day off records from Attendance table(2.3 i)
Create Function MyAttendance(@employee_ID Int)
Returns Table
As 
Return
(
	Select A.date, A.status, A.check_in_time, A.check_out_time, A.total_duration
	From Attendance A 
	Where A.emp_ID = @employee_ID 
		  AND MONTH(A.date) = MONTH(GETDATE())
		  AND YEAR(A.date) = YEAR(GETDATE())
);
Go


-- 2.5 d):
Create Function Last_month_payroll(@employee_ID Int)
Returns Table
As
Return
(
	Select P.payment_date, P.final_salary_amount, P.from_date, P.to_date, P.comments, P.bonus_amount, P.deductions_amount
	From Payroll P
	Where P.emp_ID = @employee_ID 
		  AND (DATEADD(MONTH, -1, GETDATE())) BETWEEN P.from_date AND P.to_date
);
Go

-- 2.5) e
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

-- 2.5) f
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

-- 2.5) g
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
	WHERE e.employee_ID = @employee


	-- dont submit if employee is part-time
	IF NOT EXISTS (
		select 1
		from #tempEmpDetails
		Where #tempEmpDetails.type_of_contract = 'part-time'
	)

	BEGIN
	return;
	END

	INSERT INTO Leave(date_of_request, start_date, end_date)
	VALUES(GETDATE(), @start_date, @end_date);
	SELECT @leaveID = SCOPE_IDENTITY(); 

	INSERT INTO Annual_Leave
	VALUES(@leaveID, @employee, @replacement_emp); 
		
	IF EXISTS (
		SELECT 1
		FROM #tempEmpDetails
		WHERE #tempEmpDetails.role_name IN ('Dean', 'Vice-dean')
	)
	BEGIN
		IF EXISTS (
			SELECT 1  
			FROM #tempEmpDetails
			WHERE #tempEmpDetails.role_name = 'Dean' -- requesting employee is dean
			AND EXISTS (
				SELECT 1
				FROM Employee e
				INNER JOIN Employee_Role er
				ON er.emp_ID = e.employee_ID
				WHERE e.dept_name = #tempEmpDetails.dept_name
				AND er.role_name = 'Vice-dean' AND (dbo.Is_On_Leave(e.employee_ID, @start_date, @end_date) = 1) 
			)
		)

		BEGIN
		return; --- dont submit if the vice dean is on leave
		END

		IF EXISTS (
			SELECT 1  
			FROM #tempEmpDetails
			WHERE #tempEmpDetails.role_name = 'Vice-dean' -- requesting employee is vice dean
			AND EXISTS (
				SELECT 1
				FROM Employee e
				INNER JOIN Employee_Role er
				ON er.emp_ID = e.employee_ID
				WHERE e.dept_name = #tempEmpDetails.dept_name
				AND er.role_name = 'Dean' AND (dbo.Is_On_Leave(e.employee_ID, @start_date, @end_date) = 1)
			)
		)

		BEGIN
		return; --- dont submit if the dean is on leave
		END
	
		SELECT top 1 @approves = er.emp_ID
		FROM Employee_Role er
		INNER JOIN Employee e
		ON e.employee_ID = er.emp_ID
		WHERE er.role_name LIKE 'HR_Rep%' AND e.dept_name = (select top 1 #tempEmpDetails.dept_name from #tempEmpDetails)
			AND (dbo.Is_On_Leave(e.employee_ID, @start_date, @end_date) = 0)
		ORDER BY NEWID(); --- select random hr representative

		INSERT INTO Employee_Approve_Leave(Emp1_ID, Leave_ID)
		VALUES (@approves, @leaveID);

		SELECT top 1 @approves= er.emp_ID
		FROM Employee_Role er 
		WHERE er.role_name = 'President' AND (dbo.Is_On_Leave(e.employee_ID, @start_date, @end_date) = 0);

		INSERT INTO Employee_Approve_Leave(Emp1_ID, Leave_ID)
		VALUES (@approves, @leaveID);

		BEGIN
		return;
		END
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
		WHERE er.role_name LIKE 'HR_Manager%' AND (dbo.Is_On_Leave(e.employee_ID, @start_date, @end_date) = 0)
		ORDER BY NEWID(); --- select random hr manager

		INSERT INTO Employee_Approve_Leave(Emp1_ID, Leave_ID)
		VALUES (@approves, @leaveID);
		
		BEGIN
		return;
		END
	END

	-- not hr or dean or vice dean
	SELECT top 1 @approves = er.emp_ID
	FROM Employee_Role er
	INNER JOIN Employee e
	ON e.employee_ID = er.emp_ID
	WHERE er.role_name LIKE 'HR_Representative%' AND e.dept_name = (select top 1 #tempEmpDetails.dept_name from #tempEmpDetails)
		 AND (dbo.Is_On_Leave(e.employee_ID, @start_date, @end_date) = 0)
	ORDER BY NEWID(); --- select random hr representative

	INSERT INTO Employee_Approve_Leave(Emp1_ID, Leave_ID)
	VALUES (@approves, @leaveID);

	IF EXISTS(
		SELECT top 1 er.emp_ID
		FROM Employee_Role er
		INNER JOIN Employee e
		ON e.employee_ID = er.emp_ID
		WHERE er.role_name = 'Dean' AND e.dept_name = (select top 1 #tempEmpDetails.dept_name from #tempEmpDetails) 
			AND (dbo.Is_On_Leave(e.employee_ID, @start_date, @end_date) = 0)
	)
	
		SELECT top 1 @approves = er.emp_ID
		FROM Employee_Role er
		INNER JOIN Employee e
		ON e.employee_ID = er.emp_ID
		WHERE er.role_name = 'Dean' AND e.dept_name = (select top 1 #tempEmpDetails.dept_name from #tempEmpDetails) 
			AND (dbo.Is_On_Leave(e.employee_ID, @start_date, @end_date) = 0);

	ELSE

		SELECT top 1 @approves = er.emp_ID
		FROM Employee_Role er
		INNER JOIN Employee e
		ON e.employee_ID = er.emp_ID
		WHERE er.role_name = 'Vice-dean' AND e.dept_name = (select top 1 #tempEmpDetails.dept_name from #tempEmpDetails) AND e.employment_status = 'active'
	
	INSERT INTO Employee_Approve_Leave(Emp1_ID, Leave_ID)
	VALUES (@approves, @leaveID);

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
        select emp_ID from Accidental_Leave where request_ID = @request_id
								UNION
        select emp_ID from Compensation_Leave where request_ID = @request_id
								UNION 
        select emp_ID from Medical_Leave where request_ID = @request_id
								UNION 
        select emp_ID from Unpaid_Leave where request_ID = @request_id
    ) as six_sevennnnnn														-- BOI ts is soo tuff
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


-- 2.5) j
create proc Submit_accidental
@employee int,
@start_date date,
@end_date date
as
begin
-- if duration is greater than 1 day skip the request
IF (DATEDIFF(day, @start_date, @end_date) + 1 > 1) 
	return;

--			Leave(request_ID, date_of_request, start_date, end_date, final_approval_status)
insert into Leave(date_of_request, start_date, end_date) values (getdate(), @start_date, @end_date);	-- default status is pending
declare @request_id int = scope_identity()

--		(request_id, employee_id)
insert into Accidental_Leave values(@request_id, @employee)


declare @departement varchar(50) = (select dept_name from Employee where employee_ID=@employee);	-- departement the employee works in

declare @role_name varchar(50);												-- role of the employee who will approve the request
if @departement like 'HR%'		-- employee is in the HR departement
	set @role_name = 'HR_Manager';
else 
	set @role_name = concat('HR_Representative_', @departement) 

-- get the id of the employee with the the above role
declare @hr_employee int = (
	select top 1 employee_ID from Employee e inner join Employee_Role er on (e.employee_ID = er.emp_ID)
	where role_name = @role_name
)

insert into Employee_Approve_Leave values(@hr_employee, @request_id, 'pending');
end

go


-- 2.5) k
CREATE PROC Submit_medical
	@employee_ID INT,
	@start_date DATE,
	@end_date DATE,
	@type VARCHAR(50),
	@insurance_status BIT,
	@disability_details VARCHAR(50),
	@document_description VARCHAR(50),
	@file_name VARCHAR(50)
AS
	DECLARE @leaveID int
	DECLARE @approves int

	-- save employee details
	SELECT *
	INTO #tempEmpDetails
	FROM Employee e
	INNER JOIN Employee_Role er
	ON er.emp_ID = e.employee_ID
	WHERE e.employee_ID = @employee_ID

	IF EXISTS (
		SELECT 1
		FROM #tempEmpDetails
		WHERE #tempEmpDetails.role_name IN ('Dean', 'Vice-dean')
	)
	BEGIN
		IF EXISTS (
			SELECT 1  
			FROM #tempEmpDetails
			WHERE #tempEmpDetails.role_name = 'Dean' -- requesting employee is dean
			AND EXISTS (
				SELECT 1
				FROM Employee e
				INNER JOIN Employee_Role er
				ON er.emp_ID = e.employee_ID
				WHERE e.dept_name = #tempEmpDetails.dept_name
				AND er.role_name = 'Vice-dean' AND (dbo.Is_On_Leave(e.employee_ID, @start_date, @end_date) = 1) 
			)
		)

		BEGIN
		return; --- dont submit if the vice dean is on leave
		END

		IF EXISTS (
			SELECT 1  
			FROM #tempEmpDetails
			WHERE #tempEmpDetails.role_name = 'Vice-dean' -- requesting employee is vice dean
			AND EXISTS (
				SELECT 1
				FROM Employee e
				INNER JOIN Employee_Role er
				ON er.emp_ID = e.employee_ID
				WHERE e.dept_name = #tempEmpDetails.dept_name
				AND er.role_name = 'Dean' AND (dbo.Is_On_Leave(e.employee_ID, @start_date, @end_date) = 1)
			)
		)

		BEGIN
		return; --- dont submit if the dean is on leave
		END
	END

	IF @type = 'maternity'
	BEGIN
		-- dont submit if employee is part-timer or a male requesting maternity leave
		IF EXISTS (
		select 1
		from #tempEmpDetails
		Where #tempEmpDetails.type_of_contract = 'part-time' OR #tempEmpDetails.gender = 'M'
		) 
		BEGIN
		return;
		END
	END
	
	INSERT INTO Leave(date_of_request, start_date, end_date)
	VALUES(getdate(), @start_date, @end_date)
	SELECT @leaveID = SCOPE_IDENTITY(); 

	INSERT INTO Medical_Leave
	VALUES(@leaveID, @insurance_status, @disability_details, @type, @employee_ID);

	UPDATE Document
	SET medical_ID = @leaveID
	WHERE emp_ID = @employee_ID AND file_name = @file_name AND description = @document_description;

	SELECT top 1 @approves = er.emp_ID
	FROM Employee_Role er
	INNER JOIN Employee e
	ON e.employee_ID = er.emp_ID
	WHERE er.role_name LIKE 'Medical%' AND (dbo.Is_On_Leave(e.employee_ID, @start_date, @end_date) = 0) AND e.employee_ID <> @employee_ID
	ORDER BY NEWID(); --- select random medical doctor

	INSERT INTO Employee_Approve_Leave(Emp1_ID, Leave_ID)
	VALUES (@approves, @leaveID);

	SELECT top 1 @approves = er.emp_ID
	FROM Employee_Role er
	INNER JOIN Employee e
	ON e.employee_ID = er.emp_ID
	WHERE er.role_name LIKE 'HR_Representative%' AND e.dept_name = (select top 1 #tempEmpDetails.dept_name from #tempEmpDetails)
		 AND (dbo.Is_On_Leave(e.employee_ID, @start_date, @end_date) = 0) AND e.employee_ID <> @employee_ID
	ORDER BY NEWID(); --- select random hr representative

	INSERT INTO Employee_Approve_Leave(Emp1_ID, Leave_ID)
	VALUES (@approves, @leaveID);

go

-- 2.5) l
CREATE proc Submit_unpaid
	@employee_ID INT,
	@start_date DATE,
	@end_date DATE,
	@document_description VARCHAR(50),
	@file_name VARCHAR(50)
AS
	DECLARE @leaveID int
	DECLARE @approves int

	-- save employee details
	SELECT *
	INTO #tempEmpDetails
	FROM Employee e
	INNER JOIN Employee_Role er
	ON er.emp_ID = e.employee_ID
	WHERE e.employee_ID = @employee_ID


	-- dont submit if employee is part-time
	IF EXISTS (
		select 1
		from #tempEmpDetails
		Where #tempEmpDetails.type_of_contract = 'part-time'
	)
	BEGIN
	return;
	END
		
	IF EXISTS (
		SELECT 1
		FROM #tempEmpDetails
		WHERE #tempEmpDetails.role_name IN ('Dean', 'Vice-dean')
	)
	BEGIN
		IF EXISTS (
			SELECT 1  
			FROM #tempEmpDetails
			WHERE #tempEmpDetails.role_name = 'Dean' -- requesting employee is dean
			AND EXISTS (
				SELECT 1
				FROM Employee e
				INNER JOIN Employee_Role er
				ON er.emp_ID = e.employee_ID
				WHERE e.dept_name = #tempEmpDetails.dept_name
				AND er.role_name = 'Vice-dean' AND (dbo.Is_On_Leave(e.employee_ID, @start_date, @end_date) = 1) 
			)
		)

		BEGIN
		return; --- dont submit if the vice dean is on leave
		END

		IF EXISTS (
			SELECT 1  
			FROM #tempEmpDetails
			WHERE #tempEmpDetails.role_name = 'Vice-dean' -- requesting employee is vice dean
			AND EXISTS (
				SELECT 1
				FROM Employee e
				INNER JOIN Employee_Role er
				ON er.emp_ID = e.employee_ID
				WHERE e.dept_name = #tempEmpDetails.dept_name
				AND er.role_name = 'Dean' AND (dbo.Is_On_Leave(e.employee_ID, @start_date, @end_date) = 1)
			)
		)

		BEGIN
		return; --- dont submit if the dean is on leave
		END

		INSERT INTO Leave(date_of_request, start_date, end_date)
		VALUES(GETDATE(), @start_date, @end_date)
		SELECT @leaveID = SCOPE_IDENTITY();

		INSERT INTO Unpaid_Leave
		VALUES(@leaveID, @employee_ID); 

		UPDATE Document
		SET unpaid_ID = @leaveID
		WHERE emp_ID = @employee_ID AND file_name = @file_name AND description = @document_description;

		SELECT top 1 @approves = er.emp_ID
		FROM Employee_Role er
		INNER JOIN Employee e
		ON e.employee_ID = er.emp_ID
		WHERE er.role_name LIKE 'HR_Rep%' AND e.dept_name = (select top 1 #tempEmpDetails.dept_name from #tempEmpDetails)
			AND (dbo.Is_On_Leave(e.employee_ID, @start_date, @end_date) = 0)
		ORDER BY NEWID(); --- select random hr representative

		INSERT INTO Employee_Approve_Leave(Emp1_ID, Leave_ID)
		VALUES (@approves, @leaveID);

		SELECT top 1 @approves= er.emp_ID
		FROM Employee_Role er 
		WHERE er.role_name = 'President' AND (dbo.Is_On_Leave(er.emp_ID, @start_date, @end_date) = 0);

		INSERT INTO Employee_Approve_Leave(Emp1_ID, Leave_ID)
		VALUES (@approves, @leaveID);

		BEGIN
		return;
		END
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
		WHERE er.role_name LIKE 'HR_Manager%' AND (dbo.Is_On_Leave(e.employee_ID, @start_date, @end_date) = 0)
		ORDER BY NEWID(); --- select random hr manager
		
		INSERT INTO Leave(date_of_request, start_date, end_date)
		VALUES(GETDATE(), @start_date, @end_date);
		SELECT @leaveID = SCOPE_IDENTITY();

		INSERT INTO Unpaid_Leave
		VALUES(@leaveID, @employee_ID); 

		UPDATE Document
		SET unpaid_ID = @leaveID
		WHERE emp_ID = @employee_ID AND file_name = @file_name AND description = @document_description;

		INSERT INTO Employee_Approve_Leave(Emp1_ID, Leave_ID)
		VALUES (@approves, @leaveID);
		
		BEGIN
		return;
		END
	END

	-- non hr or dean or vice dean
	INSERT INTO Leave(date_of_request, start_date, end_date)
	VALUES(GETDATE(), @start_date, @end_date);
	SELECT @leaveID = SCOPE_IDENTITY(); 

	INSERT INTO Unpaid_Leave
	VALUES(@leaveID, @employee_ID); 
	
	UPDATE Document
	SET unpaid_ID = @leaveID
	WHERE emp_ID = @employee_ID AND file_name = @file_name AND description = @document_description;

	SELECT top 1 @approves = er.emp_ID
	FROM Employee_Role er
	INNER JOIN Employee e
	ON e.employee_ID = er.emp_ID
	WHERE er.role_name LIKE 'HR_Representative%' AND e.dept_name = (select top 1 #tempEmpDetails.dept_name from #tempEmpDetails)
			AND (dbo.Is_On_Leave(e.employee_ID, @start_date, @end_date) = 0)
	ORDER BY NEWID(); --- select random hr representative

	INSERT INTO Employee_Approve_Leave(Emp1_ID, Leave_ID)
	VALUES (@approves, @leaveID);

	IF EXISTS(
		SELECT top 1 er.emp_ID
		FROM Employee_Role er
		INNER JOIN Employee e
		ON e.employee_ID = er.emp_ID
		WHERE er.role_name = 'Dean' AND e.dept_name = (select top 1 #tempEmpDetails.dept_name from #tempEmpDetails) 
			AND (dbo.Is_On_Leave(e.employee_ID, @start_date, @end_date) = 0)
	)
	
		SELECT top 1 @approves = er.emp_ID
		FROM Employee_Role er
		INNER JOIN Employee e
		ON e.employee_ID = er.emp_ID
		WHERE er.role_name = 'Dean' AND e.dept_name = (select top 1 #tempEmpDetails.dept_name from #tempEmpDetails) 
			AND (dbo.Is_On_Leave(e.employee_ID, @start_date, @end_date) = 0);

	ELSE

		SELECT top 1 @approves = er.emp_ID
		FROM Employee_Role er
		INNER JOIN Employee e
		ON e.employee_ID = er.emp_ID
		WHERE er.role_name = 'Vice-dean' AND e.dept_name = (select top 1 #tempEmpDetails.dept_name from #tempEmpDetails) AND e.employment_status = 'active'
	
	INSERT INTO Employee_Approve_Leave(Emp1_ID, Leave_ID)
	VALUES (@approves, @leaveID);

GO

