use University_HR_ManagementSystem_Team_No_12;

go

-- employee info

SELECT e.employee_ID, e.employment_status, e.type_of_contract, e.dept_name, e.official_day_off, r.role_name, r.rank
FROM Employee e, Role r, Employee_Role re WHERE re.emp_ID = e.employee_ID AND re.role_name = r.role_name

-- leave

SELECT L.*, c.* FROM Leave l, Compensation_Leave c WHERE c.request_ID = l.request_ID

-- employee replaces employee

SELECT e1.employee_ID, e1.employment_status, e1.type_of_contract, e1.dept_name,
		e2.employee_ID, e2.employment_status, e2.type_of_contract, e2.dept_name
FROM Employee_Replace_Employee ee, Employee e1, Employee e2 
WHERE e1.employee_ID = ee.Emp1_ID AND e2.employee_ID = ee.Emp2_ID

-- employee approve leave

SELECT e.employee_ID, e.employment_status, e.type_of_contract, e.dept_name, l.*, c.* FROM Employee_Approve_Leave el, Leave l, Compensation_Leave c, Employee e 
WHERE c.request_ID = l.request_ID AND l.request_ID = el.Leave_ID AND e.employee_ID = el.Emp1_ID

-- get an employee for every role
SELECT er.role_name, MIN(er.emp_ID) AS Sample_emp_ID
FROM Employee e 
INNER JOIN   Employee_Role er ON (e.employee_ID = er.emp_ID) 
GROUP BY er.role_name;

-- show the details of a specific employee
select * from Employee e where e.employee_ID=4;

-- submit a request for the selcted employee
EXEC Submit_annual
    11, 5,
    '2025-11-26',
    '2025-11-26';

-- check the leave tables and Employee_Approve_Leave table
SELECT * FROM Compensation_Leave a 
JOIN Leave l ON a.request_ID = l.request_ID 
where l.request_ID >1;

SELECT * FROM Employee_Approve_Leave el
JOIN Employee_Role er ON (er.emp_ID = el.Emp1_ID)
WHERE Leave_ID > 1;


-- check that the status of the leave after the review from the HR and the Upper board 

-- exec Upperboard_approve_annual
-- exec HR_approval_an_acc  


-- check the leave tables and Employee_Approve_Leave table
SELECT * FROM Compensation_Leave a 
JOIN Leave l ON a.request_ID = l.request_ID 
where l.request_ID >1;

SELECT * FROM Employee_Approve_Leave el
JOIN Employee_Role er ON (er.emp_ID = el.Emp1_ID)
WHERE Leave_ID > 1;

-- if annual/accidental leave you might want to check whether the employee's balance chnaged or not
select * from Employee e where e.employee_ID=4;

-------------------------------------------------------------------------------

INSERT INTO Attendance(emp_ID, status, date)
VALUES (1, 'attended', '11-15-2025');

SELECT * FROM Attendance;

EXEC Submit_compensation 5, '11-29-2025', '1231', '11-16-2025', 4;

