use University_HR_ManagementSystem_Team_No_12;
go -- Keep this to switch the database context


SELECT er.role_name, MIN(er.emp_ID) AS Sample_emp_ID
FROM Employee e 
INNER JOIN   Employee_Role er ON (e.employee_ID = er.emp_ID) 
GROUP BY er.role_name;


EXEC Submit_annual
    7, 11,
    '2025-11-26',
    '2025-11-26';


SELECT * FROM Annual_Leave a 
JOIN Leave l ON a.request_ID = l.request_ID
WHERE l.request_ID > 50;

SELECT * FROM Employee_Approve_Leave el
JOIN Employee_Role er ON (er.emp_ID = el.Emp1_ID)
WHERE Leave_ID > 50;