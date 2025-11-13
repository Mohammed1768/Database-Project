Use University_HR_ManagementSystem_Team_12
Go

-- 2.2 a)
Create View allEmployeeProfiles As 
    Select 
        employee_ID , first_name , last_name, gender , email, address, years_of_experience, 
            official_day_off, type_of_contract, employment_status, annual_balance, accidental_balance
    From Employee;
Go 

--2.2 b)
Create View NoEmployeeDept As 
    Select dept_name, count(employee_ID) as NoOfEmployees
    from Employee
    where dept_name is not null
    group by dept_name;
Go

--2.2 c)
Create View allPerformance As 
    Select * 
    From Performance
    Where semester LIKE 'W%';
Go

--2.2 d)
Create View allRejectedMedicals As
    Select
        ml.request_ID, ml.Emp_ID AS employee_ID, ml.insurance_status, ml.disability_details, ml.type,
            l.date_of_request, l.start_date, l.end_date, l.num_days, l.final_approval_status
    From Medical_Leave ml INNER JOIN Leave l 
    On ml.request_ID = l.request_ID
    Where l.final_approval_status = 'rejected';
Go

-- 2.2 e) 
Create View allEmployeeAttendance As
    Select 
        attendance_ID, emp_ID, date, check_in_time, check_out_time, total_duration, status
    From Attendance
    Where date = CAST(DATEADD(day, -1, GETDATE()) AS DATE);
Go
