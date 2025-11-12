--2.2 d)
USE MS2
GO

go
-- 2.2 
Create view allEmployeeProfiles as 
select 
employee_ID , first_name , last_name, gender , email, address, years_of_experience, 
official_day_off, type_of_contract, employment_status, annual_balance, accidental_balance

from Employee;
go 

create view NoEmployeeDept as 
select dept_name, count(employee_ID) as NoOfEmployees
from Employee
where dept_name is not null
group by dept_name;
go

create view allPerformance as 
select * from Performance;
where semester LIKE 'W%';
go






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

