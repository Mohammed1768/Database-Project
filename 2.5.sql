
create database University_HR_ManagementSystem_Team_No1;
use University_HR_ManagementSystem_Team_No1;
go;

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