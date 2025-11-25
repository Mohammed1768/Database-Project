
use University_HR_ManagementSystem_Team_No_12;
go -- Keep this to switch the database context

-- get an employee for every role
SELECT er.role_name, MIN(er.emp_ID) AS Sample_emp_ID
FROM Employee e 
INNER JOIN   Employee_Role er ON (e.employee_ID = er.emp_ID) 
GROUP BY er.role_name;

-- show the details of a specific employee
select * from Employee e inner join Employee_Role er on (e.employee_ID=er.emp_ID) where e.employee_ID=11
select * from Employee e inner join Employee_Role er on (e.employee_ID=er.emp_ID) where e.employee_ID=12
select * from Employee e inner join Employee_Role er on (e.employee_ID=er.emp_ID) where er.role_name='Vice Dean'

-- submit a request for the selcted employee
EXEC Submit_annual
    11, 12,
    '2025-11-26',
    '2025-11-27';

-- check the leave tables and Employee_Approve_Leave table
SELECT * FROM Annual_Leave a 
JOIN Leave l ON a.request_ID = l.request_ID 
where l.request_ID > 48

SELECT * FROM Employee_Approve_Leave el
JOIN Employee_Role er ON (er.emp_ID = el.Emp1_ID)
WHERE Leave_ID > 48


-- check that the status of the leave after the review from the HR and the Upper board 

exec Upperboard_approve_annual 49, 16, 12;
exec HR_approval_an_acc 49,5;


-- check the leave tables and Employee_Approve_Leave table
SELECT * FROM Annual_Leave a 
JOIN Leave l ON a.request_ID = l.request_ID 
where l.request_ID >1

SELECT * FROM Employee_Approve_Leave el
JOIN Employee_Role er ON (er.emp_ID = el.Emp1_ID)
WHERE Leave_ID > 1;

-- if annual/accidental leave you might want to check whether the employee's balance chnaged or not
select * from Employee e where e.employee_ID=4
