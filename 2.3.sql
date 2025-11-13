USE University_HR_ManagementSystem_Team_12;
GO

-- 2.3 a)
CREATE PROC Update_Status_Doc
AS
    UPDATE Document
    SET status = 'expired'
    WHERE expiry_date < CAST(GETDATE() AS DATE);
GO

-- 2.3 b)
CREATE PROC Remove_Deductions
AS
    DELETE FROM Deduction
    WHERE EXISTS (SELECT 1 FROM Employee WHERE Employee.employee_ID = Deduction.emp_id AND Employee.employment_status = 'resigned')
GO

--2.3 c)

-- 2.3 d)
CREATE PROC Create_Holiday
AS
    CREATE TABLE Holiday(
	    holiday_id INT PRIMARY KEY IDENTITY(1,1),
	    name VARCHAR(50),
	    from_date DATE,
	    to_date DATE,
	    CHECK (from_date <= to_date)
    );
GO

-- 2.3 e)
CREATE PROC  Add_Holiday
    @holiday_name VARCHAR(50),
    @from_date DATE,
    @to_date DATE
AS
    INSERT INTO Holiday (name, from_date, to_date)
    VALUES(@holiday_name, @from_date, @to_date)
GO

-- 2.3 f)
CREATE PROC Initiate_Attendance 
AS 
    INSERT INTO Attendance(emp_ID, date) 
    SELECT E.employee_ID, CAST(GETDATE() AS DATE) 
    FROM Employee E 
    WHERE E.employment_status = 'active' 
        AND NOT EXISTS ( 
            SELECT 1 
            FROM Attendance A 
            WHERE A.emp_ID = E.employee_ID AND A.date = CAST(GETDATE() AS DATE) 
        ); 
GO

--2.3 g)
CREATE PROCEDURE Update_Attendance
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

-- 2.3 h)
CREATE PROC Remove_Holiday
AS
    DELETE FROM Attendance
    WHERE EXISTS (
        SELECT 1
	    FROM Holiday
        WHERE Attendance.date Between Holiday.from_date AND Holiday.to_Date
    );
GO

-------------------------(Unchecked yet)---------------------------------------------
-- 2.3 i)
CREATE PROCEDURE Remove_DayOff
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

-- 2.3 j) 
CREATE PROCEDURE remove_approved_leaves
    @employee_id INT
AS
BEGIN
    DELETE FROM Attendance
    WHERE emp_ID = @employee_id
      AND EXISTS (
          SELECT 1
          FROM Leave L
          WHERE L.final_approval_status = 'approved'
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
            AND Attendance.date BETWEEN L.start_date AND L.end_date
      );
END;
GO

--2.3 k) 
CREATE PROCEDURE Replace_employee
    @Emp1_ID INT,
    @Emp2_ID INT,
    @from_date DATE,
    @to_date DATE
AS
BEGIN
    INSERT INTO Employee_Replace_Employee (Emp1_ID, Emp2_ID, from_date, to_date)
    VALUES (@Emp1_ID, @Emp2_ID, @from_date, @to_date);
END;
GO