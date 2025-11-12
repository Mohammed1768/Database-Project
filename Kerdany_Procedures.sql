--2.2 d)
USE MS2
GO
CREATE VIEW allRejectedMedicals AS
SELECT
    ml.request_ID,
    ml.Emp_ID AS employee_ID,
    ml.insurance_status,
    ml.disability_details,
    ml.type,
    l.date_of_request,
    l.start_date,
    l.end_date,
    l.num_days,
    l.final_approval_status
FROM Medical_Leave ml
INNER JOIN Leave l ON ml.request_ID = l.request_ID
WHERE l.final_approval_status = 'rejected';
GO

-- 2.2 e) 
CREATE VIEW allEmployeeAttendance AS
SELECT 
    attendance_ID,
    emp_ID,
    date,
    check_in_time,
    check_out_time,
    total_duration,
    status
FROM Attendance
WHERE date = CAST(DATEADD(day, -1, GETDATE()) AS DATE);
GO

--2.3 h) 
CREATE PROCEDURE update_attendance
    @employee_id INT,
    @check_in_time TIME,
    @check_out_time TIME
AS
    UPDATE Attendance 
    SET check_in_time = @check_in_time,
        check_out_time = @check_out_time,
        total_duration = CAST(DATEADD(SECOND, DATEDIFF(SECOND, @check_in_time, @check_out_time), 0) AS TIME),
        status = CASE WHEN @check_in_time IS NOT NULL AND @check_out_time IS NOT NULL THEN 'attended' ELSE 'absent' END
    WHERE emp_ID = @employee_id 
      AND date = CAST(GETDATE() AS DATE);
GO

-- 2.3 
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