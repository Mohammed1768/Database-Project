-- بسم الله الرحمن الرحيم

/*   /\_/\
*   (= ._.)
*   / >  \>
*/

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

create function MyAttendance 
(@employee_ID INT)
returns Table
AS	
	return (
	select out.* 
	from Employee e, 
	(
		select a.*
		from Attendance a
		where a.emp_ID = @employee_ID AND year(a.date) = year(getdate()) AND
			month(a.date) = month(getdate())
	) AS out
	where e.employee_ID = @employee_ID and 
	(
		(e.official_day_off <> datename(weekday, out.date)) OR 
		(out.check_in_time = null AND out.check_out_time = null)
	)
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
		VALUES(GETDATE(), @start_date, @end_date);
		SELECT @leaveID = SCOPE_IDENTITY(); 

		INSERT INTO Annual_Leave
		VALUES(@leaveID, @employee, @replacement_emp); 

		SELECT top 1 @approves = er.emp_ID
		FROM Employee_Role er
		INNER JOIN Employee e
		ON e.employee_ID = er.emp_ID
		WHERE er.role_name LIKE 'HR_Rep%' AND e.dept_name = (select top 1 #tempEmpDetails.dept_name from #tempEmpDetails)
			AND (dbo.Is_On_Leave(e.employee_ID, @start_date, @end_date) = 0) AND e.employee_ID <> @employee
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

	-- dean or vice dean
	
	
	INSERT INTO Leave(date_of_request, start_date, end_date)
	VALUES(GETDATE(), @start_date, @end_date);
	SELECT @leaveID = SCOPE_IDENTITY(); 

	INSERT INTO Annual_Leave
	VALUES(@leaveID, @employee, @replacement_emp); 
	
	SELECT top 1 @approves = er.emp_ID
	FROM Employee_Role er
	INNER JOIN Employee e
	ON e.employee_ID = er.emp_ID
	WHERE er.role_name LIKE 'HR_Representative%' AND e.dept_name = (select top 1 #tempEmpDetails.dept_name from #tempEmpDetails)
		 AND (dbo.Is_On_Leave(e.employee_ID, @start_date, @end_date) = 0) AND e.employee_ID <> @employee
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


---j

create proc Submit_accidental
	@employee int,
	@start_date date,
	@end_date date
AS
	IF (DATEDIFF(day, @start_date, @end_date)+1 > 1) -- if duration is greater than 1 day
		BEGIN
		return;
		END
	DECLARE @approves INT
	DECLARE @leaveID int

	SELECT top 1 @approves = er.emp_ID
		FROM Employee_Role er
		INNER JOIN Employee e
		ON e.employee_ID = er.emp_ID
		WHERE er.role_name LIKE 'HR_Representative%' AND e.dept_name = (select top 1 #tempEmpDetails.dept_name from #tempEmpDetails)
			AND (dbo.Is_On_Leave(e.employee_ID, @start_date, @end_date) = 0) AND e.employee_ID <> @employee
		ORDER BY NEWID(); --- select random hr representative

	INSERT INTO Leave(date_of_request, start_date, end_date)
	VALUES(GETDATE(), @start_date, @end_date);
	SELECT @leaveID = SCOPE_IDENTITY(); 

	INSERT INTO Accidental_Leave
	VALUES(@leaveID, @employee);

	INSERT INTO Employee_Approve_Leave(Emp1_ID, Leave_ID)
	VALUES(@approves, @leaveID);

GO

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

