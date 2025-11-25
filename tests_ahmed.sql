use University_HR_ManagementSystem_Team_No_12;

go

-- employee info

SELECT e.employee_ID, e.employment_status, e.type_of_contract, e.dept_name, r.role_name, r.rank
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


EXEC Submit_compensation 