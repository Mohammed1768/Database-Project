-- بسم الله الرحمن الرحيم

/*   /\_/\
*   (= ._.)
*   / >  \>
*/

Use University_HR_ManagementSystem_Team_No_12;
Go
Use University_HR_ManagementSystem_Team_12;
Go


-- 2.5 a):
Create Function EmployeeLoginValidation(@employee_ID Int, @password varchar(50))
Returns Bit
As
Begin
	IF EXISTS (Select 1 From Employee Where Employee_ID = @employee_ID And Password = @password)
		Return 1;
	Return 0;
End;
Go


-- 2.5 b):
Create Function MyPerformance(@employee_ID Int,@semester char(3))
Returns Table
As
Return
(
	Select P.semester, P.rating, P.comments
	From Performance P
	Where P.emp_ID = @employee_ID And P.semester = @semester
);
Go


-- 2.5 c): Assumed that admin removes unattended official day off records from Attendance table(2.3 i)
Create Function MyAttendance(@employee_ID Int)
Returns Table
As 
Return
(
	Select A.date, A.status, A.check_in_time, A.check_out_time, A.total_duration
	From Attendance A 
	Where A.emp_ID = @employee_ID 
		  AND MONTH(A.date) = MONTH(GETDATE())
		  AND YEAR(A.date) = YEAR(GETDATE())
);
Go

-- 2.5 d):
Create Function Last_month_payroll(@employee_ID Int)
Returns Table
As
Return
(
	Select P.payment_date, P.final_salary_amount, P.from_date, P.to_date, P.comments, P.bonus_amount, P.deductions_amount
	From Payroll P
	Where P.emp_ID = @employee_ID 
		  AND (DATEADD(MONTH, -1, GETDATE())) BETWEEN P.from_date AND P.to_date
);
Go


-- 2.5) h
create function Status_leaves() 
returns Table
as 
return (
	select l.request_ID, l.date_of_request, l.final_approval_status 
	from Leave l left outer join Annual_Leave a on (l.request_ID = a.request_ID)
	left outer join Accidental_Leave ac on (l.request_ID = ac.request_ID)

	where month(l.date_of_request) = month(getdate()) and 
	(a.request_ID is not null or ac.request_ID is not null)
);
go


-- 2.5) i
create proc Upperboard_approve_annual
@request_ID int, @Upperboard_ID int, @replacement_ID int
as 
begin

declare @status varchar(50) = 'approved';

declare @start_date date = (select start_date from Leave where request_ID = @request_ID);
declare @end_date date = (select end_date from Leave where request_ID = @request_ID);

declare @employee_id int = (
    select top 1 emp_ID
    from (
        select emp_ID from Annual_Leave where request_ID = @request_id
								UNION
        select emp_ID FROM Accidental_Leave where request_ID = @request_id
								UNION
        select emp_ID FROM Compensation_Leave where request_ID = @request_id
								UNION 
        select emp_ID FROM Medical_Leave where request_ID = @request_id
								UNION 
        select emp_ID FROM Unpaid_Leave where request_ID = @request_id
    ) as six_sevennnnnn
);

-- if replacement is on Accidental Leave
if exists(
	select * from Employee e inner join Accidental_Leave a on (e.employee_ID=a.emp_ID)
	inner join Leave l on (a.request_ID = l.request_ID)

	where e.employee_ID=@replacement_ID and l.end_date>=@start_date and l.start_date<=@end_date
) set @status = 'rejected';

-- if replacement is on Compensation Leave
if exists(
	select * from Employee e inner join Compensation_Leave a on (e.employee_ID=a.emp_ID)
	inner join Leave l on (a.request_ID = l.request_ID)

	where e.employee_ID=@replacement_ID and l.end_date>=@start_date and l.start_date<=@end_date
) set @status = 'rejected';

-- if replacement is on Medical Leave
if exists(
	select * from Employee e inner join Medical_Leave a on (e.employee_ID=a.emp_ID)
	inner join Leave l on (a.request_ID = l.request_ID)

	where e.employee_ID=@replacement_ID and l.end_date>=@start_date and l.start_date<=@end_date
) set @status = 'rejected';

-- if replacement is on Unpaid Leave
if exists(
	select * from Employee e inner join Unpaid_Leave a on (e.employee_ID=a.emp_ID)
	inner join Leave l on (a.request_ID = l.request_ID)

	where e.employee_ID=@replacement_ID and l.end_date>=@start_date and l.start_date<=@end_date
) set @status = 'rejected';

-- if replacement is on Annual Leave
if exists(
	select * from Employee e inner join Annual_Leave a on (e.employee_ID=a.emp_ID)
	inner join Leave l on (a.request_ID = l.request_ID)

	where e.employee_ID=@replacement_ID and l.end_date>=@start_date and l.start_date<=@end_date
) set @status = 'rejected';


declare @dept_1 int = (
	select dept_name from Employee e where e.employee_ID=@replacement_ID
);

declare @dept_2 int = (
	select dept_name from Employee e where e.employee_ID=@employee_id
);

update Employee_Approve_Leave 
set status = @status 
where Leave_ID=@request_ID;

end
go



/*

- What happens if both the dean and vice dean took an accidental leave 


*/