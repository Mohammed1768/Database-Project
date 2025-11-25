-- بسم الله الرحمن الرحيم

/*   /\_/\
*   (= ._.)
*   / >  \>
*/

use University_HR_ManagementSystem_Team_No_12;
GO


-- 2.3 a):
CREATE OR ALTER PROC Update_Status_Doc
AS
    UPDATE Document
    SET status = 'expired'
    WHERE expiry_date < CAST(GETDATE() AS DATE);
GO

-- 2.3 b):
CREATE OR ALTER PROC Remove_Deductions
AS
    DELETE FROM Deduction
    WHERE EXISTS (SELECT 1 FROM Employee WHERE Employee.employee_ID = Deduction.emp_id AND Employee.employment_status = 'resigned')
GO

--2.3 c):
CREATE OR ALTER PROC Update_Employment_Status 
    @Employee_ID int
AS
BEGIN -- no need to update status if the employee is resigned
    IF EXISTS (SELECT 1 FROM Employee e WHERE e.employee_ID = @Employee_ID AND e.employment_status = 'resigned')
    BEGIN
    return;
    END
    DECLARE @Is_On_Leave BIT = dbo.Is_On_Leave(@Employee_ID, CAST(GETDATE() AS DATE), CAST(GETDATE() AS DATE));

    IF (@Is_On_Leave=1)
    BEGIN
        UPDATE Employee
        SET employment_status = 'onleave'
        WHERE employee_ID = @Employee_ID;
    END
END;
GO

-- 2.3 d):
CREATE OR ALTER PROC Create_Holiday
AS
    CREATE TABLE Holiday(
	    holiday_id INT PRIMARY KEY IDENTITY(1,1),
	    name VARCHAR(50),
	    from_date DATE,
	    to_date DATE,
	    CHECK (from_date <= to_date)
    );
GO

-- 2.3 e):
CREATE OR ALTER PROC  Add_Holiday
    @holiday_name VARCHAR(50),
    @from_date DATE,
    @to_date DATE
AS
    INSERT INTO Holiday (name, from_date, to_date)
    VALUES(@holiday_name, @from_date, @to_date)
GO

-- 2.3 f):
CREATE OR ALTER PROCEDURE Initiate_Attendance 
AS 
    INSERT INTO Attendance(emp_ID, date) 
    SELECT E.employee_ID, CAST(GETDATE() AS DATE) 
    FROM Employee E 
    WHERE NOT EXISTS ( 
        SELECT 1 
        FROM Attendance A 
        WHERE A.emp_ID = E.employee_ID 
          AND A.date = CAST(GETDATE() AS DATE) 
    ); 
GO

--2.3 g):
CREATE OR ALTER PROCEDURE Update_Attendance
    @employee_id INT,
    @check_in_time TIME,
    @check_out_time TIME
AS
    UPDATE Attendance 
    SET check_in_time = @check_in_time,
        check_out_time = @check_out_time,
        status = CASE WHEN (@check_in_time IS NOT NULL) AND (@check_out_time IS NOT NULL) THEN 'attended' ELSE 'absent' END
    WHERE emp_ID = @employee_id AND date = CAST(GETDATE() AS DATE);
GO

-- 2.3 h):
CREATE OR ALTER PROC Remove_Holiday
AS
    DELETE FROM Attendance
    WHERE EXISTS (
        SELECT 1
	    FROM Holiday
        WHERE Attendance.date Between Holiday.from_date AND Holiday.to_Date
    );
GO

-- 2.3 i):
CREATE OR ALTER PROCEDURE Remove_DayOff
    @Employee_ID INT
AS
BEGIN
    DECLARE @DayOff VARCHAR(50);

    SELECT @DayOff = official_day_off
    FROM Employee
    WHERE employee_ID = @Employee_ID;

    DELETE FROM Attendance
    WHERE emp_ID = @Employee_ID
      AND status = 'absent'
      AND DATENAME(WEEKDAY, date) = @DayOff
      AND MONTH(date) = MONTH(GETDATE())
      AND YEAR(date) = YEAR(GETDATE());
END;
GO

-- 2.3 j): 
CREATE OR ALTER PROCEDURE remove_approved_leaves
    @employee_id INT
AS
BEGIN
    DELETE FROM Attendance
    WHERE emp_ID = @employee_id
      AND EXISTS (
          SELECT 1
          FROM Leave L
          WHERE L.final_approval_status = 'approved'
           AND Attendance.date BETWEEN L.start_date AND L.end_date
            AND L.request_ID IN (
                SELECT request_ID FROM Annual_Leave WHERE emp_ID = @employee_id
                UNION
                SELECT request_ID FROM Accidental_Leave WHERE emp_ID = @employee_id
                UNION
                SELECT request_ID FROM Medical_Leave WHERE Emp_ID = @employee_id
                UNION
                SELECT request_ID FROM Unpaid_Leave WHERE Emp_ID = @employee_id
                UNION
                SELECT request_ID FROM Compensation_Leave WHERE emp_ID = @employee_id
            )
      );
END;
GO

--2.3 k): 
--Note: Employee 2 replaces employee 1 
CREATE OR ALTER PROCEDURE Replace_employee
    @Emp1_ID INT,    
    @Emp2_ID INT,     
    @from_date DATE,
    @to_date DATE
AS
BEGIN
    DECLARE @dept1 VARCHAR(50);
    DECLARE @dept2 VARCHAR(50);
    DECLARE @contract2 VARCHAR(50);
    DECLARE @status2 VARCHAR(50);

    -- Validate date range
    IF @from_date > @to_date
        RETURN;

    -- Employee cannot replace himself
    IF @Emp1_ID = @Emp2_ID
        RETURN;

    SELECT @dept1 = dept_name
    FROM Employee
    WHERE employee_ID = @Emp1_ID;

    -- Check if Emp1 exists
    IF @dept1 IS NULL
        RETURN;

    SELECT @dept2 = dept_name,
           @contract2 = type_of_contract,
           @status2 = employment_status
    FROM Employee
    WHERE employee_ID = @Emp2_ID;

    -- Check if Emp2 exists
    IF @dept2 IS NULL
        RETURN;

    -- Replacement Cannot be on leave or Part Time and active
    IF @status2 <> 'active'
        RETURN;

    IF @contract2 = 'part_time'
        RETURN;

    IF dbo.Is_On_Leave(@Emp2_ID, @from_date, @to_date) = 1
        RETURN;

    -- Same department check
    IF @dept1 <> @dept2
        RETURN;

    -- Check if Emp1 is actually on leave during this period
    IF dbo.Is_On_Leave(@Emp1_ID, @from_date, @to_date) = 0
        RETURN;

    -- Check if Emp1 already has a replacement during this period
    IF EXISTS (
        SELECT 1 
        FROM Employee_Replace_Employee
        WHERE Emp1_ID = @Emp1_ID 
          AND (
              (@from_date BETWEEN from_date AND to_date) OR
              (@to_date BETWEEN from_date AND to_date) OR
              (from_date BETWEEN @from_date AND @to_date)
          )
    )
        RETURN;

    -- Check if Emp2 is already replacing someone else during this period
    IF EXISTS (
        SELECT 1 
        FROM Employee_Replace_Employee
        WHERE Emp2_ID = @Emp2_ID 
          AND (
              (@from_date BETWEEN from_date AND to_date) OR
              (@to_date BETWEEN from_date AND to_date) OR
              (from_date BETWEEN @from_date AND @to_date)
          )
    )
        RETURN;

    INSERT INTO Employee_Replace_Employee (Emp1_ID, Emp2_ID, from_date, to_date)
    VALUES (@Emp1_ID, @Emp2_ID, @from_date, @to_date);
END;
GO
