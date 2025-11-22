-- بسم الله الرحمن الرحيم

/*   /\_/\
*   (= ._.)
*   / >  \>
*/

Use University_HR_ManagementSystem_Team_No_12;
Go

-- 2.5 a):
Create or alter Function EmployeeLoginValidation(@employee_ID Int, @password varchar(50))
Returns Bit
As
Begin
	IF EXISTS (Select 1 From Employee Where Employee_ID = @employee_ID And Password = @password)
		Return 1;
	Return 0;
End;
Go

-- 2.5 b):
Create or alter Function MyPerformance(@employee_ID Int,@semester char(3))
Returns Table
As
Return
(
	Select P.semester, P.rating, P.comments
	From Performance P
	Where P.emp_ID = @employee_ID And P.semester = @semester
);
Go

-- 2.5 c)
Create or alter Function MyAttendance(@employee_ID Int)
Returns Table
As 
Return
(
	Select A.date, A.status, A.check_in_time, A.check_out_time, A.total_duration
	From Attendance A inner join Employee e on e.employee_ID = A.emp_ID
	Where A.emp_ID = @employee_ID 
			AND MONTH(A.date) = MONTH(GETDATE())
			AND YEAR(A.date) = YEAR(GETDATE())
			AND NOT(DATENAME(WEEKDAY, A.date) = e.official_day_off and A.status = 'absent') -- not unattended day off
);	
Go

-- 2.5 d):
Create or alter Function Last_month_payroll(@employee_ID Int)
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

-- 2.5) e
create or alter function Deductions_Attendance
(@employee_ID int, @month int)
returns Table
AS
return (
	select d.deduction_ID, d.date, d.amount, d.type, d.status, d.unpaid_ID, d.attendance_ID
	from Deduction d
	where d.emp_ID = @employee_ID AND month(d.date) = @month AND 
	d.type IN ('missing_hours','missing_days')
)

go

-- 2.5) f
create or alter function Is_On_Leave
(@employee_ID int, @from_date date, @to_date date)
returns bit
AS
begin
	IF  EXISTS ( 
		select * from Leave L
		WHERE 
		CAST(L.start_date AS DATE) <= @to_date AND CAST(L.end_date AS DATE) >= @from_date
		AND
		L.request_ID IN (
				SELECT request_ID FROM Annual_Leave WHERE emp_ID = @employee_ID
				UNION
				SELECT request_ID FROM Accidental_Leave WHERE emp_ID = @employee_ID
				UNION
				SELECT request_ID FROM Medical_Leave WHERE Emp_ID = @employee_ID
				UNION
				SELECT request_ID FROM Unpaid_Leave WHERE Emp_ID = @employee_ID
				UNION
				SELECT request_ID FROM Compensation_Leave WHERE emp_ID = @employee_ID
			)
	)	return 1
	return 0

end
go

-- 2.5) g
create or alter proc Submit_annual
@employee_id int,
@replacement_emp int,
@start_date date,
@end_date date
as
begin

-- if invalid request
if (@start_date>@end_date) 
return

-- update the leave tables
--			(date_of_request, start_date, end_date, final_approval_status)
insert into Leave(date_of_request, start_date, end_date) values (getdate(), @start_date, @end_date);	-- default status is pending
declare @request_id int = scope_identity()
--		(request_id, employee_id, replacement_id)
insert into Annual_Leave values(@request_id, @employee_id, @replacement_emp)

if (CAST(@start_date AS DATE) < CAST(GETDATE() AS DATE))
begin 
	update Leave
	set final_approval_status='rejected' where request_ID=@request_id
	return
end

-- if employee is part time
if exists (
	select * from Employee where type_of_contract='part_time'
	and employee_ID=@employee_id
) begin 
	update Leave
	set final_approval_status='rejected' where request_ID=@request_id
	return
end


-- useful variables
declare @role varchar(50) = (select top 1 r.role_name from Employee e inner join 
	Employee_Role er on (e.employee_ID=er.emp_ID) inner join Role r on (er.role_name = r.role_name)
	where employee_ID=@employee_id order by r.rank asc)
declare @dept_name varchar(50) = (select e.dept_name from Employee e where e.employee_ID=@employee_id);

declare @rank int = (select min(rank) from Employee e inner join 
	Employee_Role er on (e.employee_ID=er.emp_ID) inner join Role r on (er.role_name = r.role_name)
	where employee_ID=@employee_id)


-- if dean is submitting a request while vice dean is on leave, automatically reject the request and vice versa
if @role in ('Dean','Vice Dean')
begin
	if not exists (
		-- select both dean and vice dean in the same departement
		-- exclude the employee submitting the request and exclude the employees on leave
		select * from Employee e inner join Employee_Role er on (e.employee_ID=er.emp_ID)
		inner join Role r on (er.role_name=r.role_name)
		where e.dept_name=@dept_name and r.role_name in ('Dean','Vice Dean') and e.employee_ID<>@employee_id
		and dbo.Is_On_Leave(e.employee_ID, @start_date, @end_date) = 0
	) begin 
		update Leave
		set final_approval_status='rejected' where request_ID=@request_id
		return
	end
end


-- if employee is in the HR departement
if exists(
	select * from Employee e inner join Employee_Role er on (e.employee_ID=er.emp_ID)
	where er.role_name like 'HR%' and e.employee_ID=@employee_id
)
begin
	-- we only require approval from the manager
	declare @manager int = (select top 1 e.employee_ID from Employee e inner join Employee_Role er
			on (e.employee_ID=er.emp_ID) where er.role_name = 'HR Manager')

	insert into Employee_Approve_Leave(Emp1_ID, Leave_ID) values(@manager, @request_id)
	return
end

declare @hr_rep int = (select top 1 employee_ID from Employee e inner join Employee_Role r 
		on (e.employee_ID = r.emp_ID) where dept_name=@dept_name and r.role_name like 'HR_Rep%' )


insert into Employee_Approve_Leave(Emp1_ID, Leave_ID) values(@hr_rep, @request_id)

-- if employee is a lecturer of a TA
if @rank>=5 
	begin
		-- select employees in the same departement 
		-- who have a rank of 3 or 4 (aka dean or vice dean) 
		-- who is not on leave
		-- dean takes priority over vice dean, i.e sort them by the rank ascending
		declare @dean int = (
			select top 1 employee_ID from Employee e inner join Employee_Role er on (e.employee_ID=er.emp_ID)
			inner join Role r on (er.role_name=r.role_name)
			where r.rank in (3,4) and e.employment_status = 'active' and e.dept_name=@dept_name
			order by r.rank asc
		)
		insert into Employee_Approve_Leave(Emp1_ID, Leave_ID) values(@dean, @request_id)
	end
else 
	begin
		-- select employees with rank = 1 or 2 (president, vice president)
		-- we have assumed that if the president is on leave, the request will be handled by the vice president
		declare @president int = (
			select top 1 employee_ID from Employee e inner join Employee_Role er on (e.employee_ID=er.emp_ID)
			inner join Role r on (er.role_name=r.role_name)
			where r.rank in (1,2) and e.employment_status = 'active'
			order by r.rank asc
		)
		insert into Employee_Approve_Leave(Emp1_ID, Leave_ID) values(@president, @request_id)
	end
	
end
go


-- 2.5) h
create or alter function Status_leaves() 
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
create or alter proc Upperboard_approve_annual
@request_ID int, @Upperboard_ID int, @replacement_ID int
as 
begin

-- employee is not supposed to approve the request
-- either invalid request or invalid employee
if not exists(
	select * from Employee_Approve_Leave where Emp1_ID=@Upperboard_ID and Leave_ID=@request_ID
) return


declare @status varchar(50) = 'approved';

declare @start_date date = (select start_date from Leave where request_ID = @request_ID);
declare @end_date date = (select end_date from Leave where request_ID = @request_ID);

declare @employee_id int = (
    select top 1 emp_ID
    from (
        select emp_ID from Annual_Leave where request_ID = @request_id
								UNION
        select emp_ID from Accidental_Leave where request_ID = @request_id
								UNION
        select emp_ID from Compensation_Leave where request_ID = @request_id
								UNION 
        select emp_ID from Medical_Leave where request_ID = @request_id
								UNION 
        select emp_ID from Unpaid_Leave where request_ID = @request_id
    ) as six_sevennnnnn														-- ts is soo tuff
);


declare @dept_1 int = (
	select dept_name from Employee e where e.employee_ID=@replacement_ID
);
declare @dept_2 int = (
	select dept_name from Employee e where e.employee_ID=@employee_id
);

if dbo.Is_On_Leave(@replacement_ID, @start_date, @end_date) = 1
	set @status = 'rejected'
if @dept_1 <> @dept_2
	set @status = 'rejected'

update Employee_Approve_Leave 
set status = @status 
where Leave_ID=@request_ID and Emp1_ID=@Upperboard_ID;

end
go

-- 2.5) j
create or alter proc Submit_accidental
@employee_id int,
@start_date date,
@end_date date
as
begin

if (@start_date>@end_date) 
return

--		Leave(request_ID, date_of_request, start_date, end_date, final_approval_status)
insert into Leave(date_of_request, start_date, end_date) values (getdate(), @start_date, @end_date);	-- default status is pending
declare @request_id int = scope_identity()

--		(request_id, employee_id)
insert into Accidental_Leave values(@request_id, @employee_id)

if (CAST(@start_date AS DATE) < CAST(GETDATE() AS DATE))
begin 
	update Leave
	set final_approval_status='rejected' where request_ID=@request_id
	return
end


-- if invalid request
-- if duration is greater than 1 day skip the request
if (DATEDIFF(day,@start_date,@end_date)+1 > 1) 
begin 
	update Leave
	set final_approval_status='rejected' where request_ID=@request_id
	return
end

-- useful variables
declare @role varchar(50) = (select top 1 r.role_name from Employee e inner join 
	Employee_Role er on (e.employee_ID=er.emp_ID) inner join Role r on (er.role_name = r.role_name)
	where employee_ID=@employee_id order by r.rank asc)
declare @dept_name varchar(50) = (select e.dept_name from Employee e where e.employee_ID=@employee_id);


-- if dean is submitting a request while vice dean is on leave, skip the request and vice versa
if @role in ('Dean', 'Vice Dean')
begin
	if not exists (
		-- select both dean and vice dean in the same departement
		-- exclude the employee submitting the request and exclude the employees on leave
		select * from Employee e inner join Employee_Role er on (e.employee_ID=er.emp_ID)
		inner join Role r on (er.role_name=r.role_name)
		where e.dept_name=@dept_name and r.role_name in ('Dean', 'Vice Dean') and e.employee_ID<>@employee_id
		and dbo.Is_On_Leave(e.employee_ID, @start_date, @end_date) = 0
	) 
	begin 
		update Leave
		set final_approval_status='rejected' where request_ID=@request_id
		return
	end
end



declare @departement varchar(50) = (select dept_name from Employee where employee_ID=@employee_id);	-- departement the employee works in

declare @role_name varchar(50);												-- role of the employee who will approve the request
if @departement like 'HR%'		-- employee is in the HR departement
	set @role_name = 'HR Manager';
else 
	set @role_name = concat('HR_Representative_', @departement) 

-- get the id of the employee with the the above role
declare @hr_employee int = (
	select top 1 employee_ID from Employee e inner join Employee_Role er on (e.employee_ID = er.emp_ID)
	where role_name = @role_name
)

insert into Employee_Approve_Leave values(@hr_employee, @request_id, 'pending');
end

go

-- 2.5) k
create or alter proc Submit_medical
	@employee_ID int,
	@start_date date,
	@end_date date,
	@type varchar(50),
	@insurance_status bit,
	@disability_details varchar(50),
	@document_description varchar(50),
	@file_name varchar(50)
AS
begin

if (@start_date>@end_date) 
return


-- update the leave tables
--			(date_of_request, start_date, end_date, final_approval_status)
insert into Leave(date_of_request, start_date, end_date) values (getdate(), @start_date, @end_date);	-- default status is pending
declare @request_id int = scope_identity()

--		(request_id, insurance status, disability details, type, employee_id)
insert into Medical_Leave values(@request_id, @insurance_status, @disability_details, @type, @employee_ID)
insert into Document(type, description, file_name, emp_ID, medical_ID) 
	values('Medical', @document_description, @file_name, @employee_ID, @request_id)

if (CAST(@start_date AS DATE) < CAST(GETDATE() AS DATE))
begin 
	update Leave
	set final_approval_status='rejected' where request_ID=@request_id
	return
end

-- useful variables
declare @role varchar(50) = (select top 1 r.role_name from Employee e inner join 
	Employee_Role er on (e.employee_ID=er.emp_ID) inner join Role r on (er.role_name = r.role_name)
	where employee_ID=@employee_id order by r.rank asc)
declare @dept_name varchar(50) = (select e.dept_name from Employee e where e.employee_ID=@employee_ID);
declare @gender char(1) = (select gender from Employee where @employee_ID=employee_ID)
declare @type_of_contract varchar(50) = (select type_of_contract from Employee where @employee_ID=employee_ID)


-- if dean is submitting a request while vice dean is on leave, skip the request and vice versa
if @role in ('Dean', 'Vice Dean')
begin
	if not exists (
		-- select both dean and vice dean in the same departement
		-- exclude the employee submitting the request and exclude the employees on leave
		select * from Employee e inner join Employee_Role er on (e.employee_ID=er.emp_ID)
		inner join Role r on (er.role_name=r.role_name)
		where e.dept_name=@dept_name and r.role_name in ('Dean', 'Vice Dean') and e.employee_ID<>@employee_ID
		and dbo.Is_On_Leave(e.employee_ID, @start_date, @end_date) = 0
	) begin 
		update Leave
		set final_approval_status='rejected' where request_ID=@request_id
		return
	end
end

-- male and part time employees cannot submit maternity leaves
if (@type='maternity' and @gender='M')
begin 
	update Leave
	set final_approval_status='rejected' where request_ID=@request_id
	return
end
if (@type='maternity' and @type_of_contract='part_time')
begin 
	update Leave
	set final_approval_status='rejected' where request_ID=@request_id
	return
end


-- get the id of the doctor
declare @doctor int = (select top 1 employee_ID from Employee e where dept_name like 'Medical%' and e.employment_status = 'active')

-- request should be approved by a doctor
insert into Employee_Approve_Leave values(@doctor, @request_id, 'pending');

declare @role_name varchar(50);												-- role of the hr employee who will approve the request
if @dept_name like 'HR%'		-- employee is in the HR departement
	set @role_name = 'HR_Manager';
else 
	set @role_name = concat('HR_Representative_', @dept_name) 

-- get the id of the employee with the the above role
declare @hr_employee int = (
	select top 1 employee_ID from Employee e inner join Employee_Role er on (e.employee_ID = er.emp_ID)
	where role_name = @role_name
)

insert into Employee_Approve_Leave values(@hr_employee, @request_id, 'pending');

end
go

-- 2.5) l
CREATE or alter proc Submit_unpaid
	@employee_ID INT,
	@start_date DATE,
	@end_date DATE,
	@document_description VARCHAR(50),
	@file_name VARCHAR(50)
AS
begin

if (@start_date>@end_date) 
return


-- update the leave tables
--			(date_of_request, start_date, end_date, final_approval_status)
insert into Leave(date_of_request, start_date, end_date) values (getdate(), @start_date, @end_date);	-- default status is pending
declare @request_id int = scope_identity()
insert into Unpaid_Leave values(@request_id, @employee_ID)

insert into Document(type, description, file_name, emp_ID, unpaid_ID) 
	values('Memo', @document_description, @file_name, @employee_ID, @request_id)

if (CAST(@start_date AS DATE) < CAST(GETDATE() AS DATE))
begin 
	update Leave
	set final_approval_status='rejected' where request_ID=@request_id
	return
end


-- useful variables
declare @role varchar(50) = (select top 1 r.role_name from Employee e inner join 
	Employee_Role er on (e.employee_ID=er.emp_ID) inner join Role r on (er.role_name = r.role_name)
	where employee_ID=@employee_ID order by r.rank asc)
declare @dept_name varchar(50) = (select e.dept_name from Employee e where e.employee_ID=@employee_ID);
declare @gender char(1) = (select gender from Employee where @employee_ID=employee_ID)
declare @type_of_contract varchar(50) = (select type_of_contract from Employee where @employee_ID=employee_ID)
declare @duration int = datediff(day, @start_date, @end_date) + 1
declare @rank varchar(50) = (select top 1 r.rank from Employee e inner join 
	Employee_Role er on (e.employee_ID=er.emp_ID) inner join Role r on (er.role_name = r.role_name)
	where employee_ID=@employee_ID order by r.rank asc)

-- part time employees are not eligible 
if (@type_of_contract='part_time')
begin 
	update Leave
	set final_approval_status='rejected' where request_ID=@request_id
	return
end
-- cannot request more than 30 dats
if (@duration > 30)
begin 
	update Leave
	set final_approval_status='rejected' where request_ID=@request_id
	return
end
-- maximum one approved request per year
if exists(
	select * from Unpaid_Leave u inner join Leave l on (u.request_ID = l.request_ID)
	where u.Emp_ID=@employee_ID and (year(l.end_date)=year(getdate()) or year(l.start_date)=year(getdate()))
	and l.final_approval_status='approved'
) begin 
	update Leave
	set final_approval_status='rejected' where request_ID=@request_id
	return
end



-- if dean is submitting a request while vice dean is on leave, skip the request and vice versa
if @role in ('Dean', 'Vice Dean')
begin
	if not exists (
		-- select both dean and vice dean in the same departement
		-- exclude the employee submitting the request and exclude the employees on leave
		select * from Employee e inner join Employee_Role er on (e.employee_ID=er.emp_ID)
		inner join Role r on (er.role_name=r.role_name)
		where e.dept_name=@dept_name and r.role_name in ('Dean', 'Vice Dean') and e.employee_ID<>@employee_ID
		and dbo.Is_On_Leave(e.employee_ID, @start_date, @end_date) = 0
	) begin
		update Leave
		set final_approval_status='rejected' where request_ID=@request_id
		return
	end
end


-- upper board employee
-- higher ranking have higher priority
declare @upper_board int = (
	select top 1 employee_ID from Employee e inner join Employee_Role er on (e.employee_ID=er.emp_ID)
	inner join Role r on (r.role_name = er.role_name)
	where r.role_name like 'Upper%' and e.employment_status = 'active'
	order by r.rank asc
) 
insert into Employee_Approve_Leave values(@upper_board, @request_id, 'pending')


declare @role_name varchar(50);									-- role of the hr employee who will approve the request
if @dept_name like 'HR%'		-- employee is in the HR departement
	set @role_name = 'HR Manager';
else 
	set @role_name = concat('HR_Representative_', @dept_name) 

-- get the id of the employee with the the above role
declare @hr_employee int = (
	select top 1 employee_ID from Employee e inner join Employee_Role er on (e.employee_ID = er.emp_ID)
	where role_name = @role_name
)

insert into Employee_Approve_Leave values(@hr_employee, @request_id, 'pending');


-- if the employee submitting the request is a TA or a doctor
if @rank > 5
begin
	
	declare @higher_ranking int = (
		select top 1 employee_ID from Employee e inner join Employee_Role er on (e.employee_ID=er.emp_ID)
		inner join Role r on (r.role_name = er.role_name) 
		where r.rank<@rank and e.dept_name=@dept_name and e.employment_status = 'active'
		order by r.rank asc
	)
	insert into Employee_Approve_Leave values(@higher_ranking, @request_id, 'pending');

end

end
GO

-- 2.5) m
Create or alter Proc Upperboard_approve_unpaids
	@request_ID int,
	@Upperboard_ID int
As
Begin

-- employee is not supposed to approve the request
-- either invalid request or invalid employee
if not exists(
	select * from Employee_Approve_Leave where Emp1_ID=@Upperboard_ID and Leave_ID=@request_ID
) return

declare @status varchar(50) = 'approved'

-- just check if a memo document exists
if not exists(
	select d.document_ID from Leave l inner join Unpaid_Leave u on (l.request_ID = u.request_ID)
	inner join Document d on (d.unpaid_ID=u.request_ID) 
	where l.request_ID=@request_ID and d.type='Memo'
) set @status = 'rejected'

-- update the acceptance status
update Employee_Approve_Leave 
set status = @status
where @request_ID=Leave_ID and @Upperboard_ID=Emp1_ID

End;
Go

-- 2.5) n
Create or alter Proc Submit_compensation 
	@employee_ID Int,
	@compensation_date Date,
	@reason Varchar(50),
	@date_of_original_workday Date,
	@replacement_emp Int 
As
Begin
	
	--Inserting leave request into its tables
	Insert Into Leave (date_of_request, start_date, end_date) 
	Values (Cast(GetDate() As Date), @compensation_date, @compensation_date);
	Declare @leaveID Int = Scope_Identity();

	Insert Into Compensation_Leave (request_ID, emp_ID, date_of_original_workday, reason, replacement_emp)
	Values (@leaveID, @employee_ID, @date_of_original_workday, @reason, @replacement_emp)

	declare @role varchar(50) = (select top 1 r.role_name from Employee e inner join 
		Employee_Role er on (e.employee_ID=er.emp_ID) inner join Role r on (er.role_name = r.role_name)
		where employee_ID=@employee_ID order by r.rank asc)
	declare @dept_name varchar(50) = (select e.dept_name from Employee e where e.employee_ID=@employee_ID);


	-- if dean is submitting a request while vice dean is on leave, skip the request and vice versa
	if @role in ('Dean', 'Vice Dean')
	begin
		if not exists (
			-- select both dean and vice dean in the same departement
			-- exclude the employee submitting the request and exclude the employees on leave
			select * from Employee e inner join Employee_Role er on (e.employee_ID=er.emp_ID)
			inner join Role r on (er.role_name=r.role_name)
			where e.dept_name=@dept_name and r.role_name in ('Dean', 'Vice Dean') and e.employee_ID<>@employee_ID
			and dbo.Is_On_Leave(e.employee_ID, @compensation_date, @compensation_date) = 0
		) begin
			update Leave
			set final_approval_status='rejected' where request_ID=@leaveID
			return
		end
	end



	if (CAST(@compensation_date AS DATE) < CAST(GETDATE() AS DATE))
	begin 
		update Leave
		set final_approval_status='rejected' where request_ID=@leaveID
		return
	end

	-- Will skip the Comensation Leave submission if they are not in the same month.
	If (Month(@compensation_date) <> Month(@date_of_original_workday))
		begin 
			update Leave
			set final_approval_status='rejected' where request_ID=@leaveID
			return
		end
	

	--Departement of the employee
	Declare @departement Varchar(50) = (Select top 1 dept_name From Employee e Where e.employee_ID=@employee_ID)

	-- Role of the employee who will approve/reject this request
	Declare @role_name Varchar(50);											
	if (@departement like 'HR%')		-- employee is in the HR departement
		set @role_name = 'HR_Manager';
	else 
		set @role_name = concat('HR_Representative_', @departement); 

	-- ID of the employee who will approve/reject this request
	declare @hr_employee int = (
				select top 1 employee_ID from Employee e inner join Employee_Role er on (e.employee_ID = er.emp_ID)
				where role_name = @role_name
				)
	insert into Employee_Approve_Leave values(@hr_employee, @leaveID, 'pending')
End;
Go

--2.5 o)
create or alter proc Dean_andHR_Evaluation
    @employee_ID INT,
    @rating INT,
    @comment VARCHAR(50),
    @semester CHAR(3)
AS
BEGIN

    -- Insert the evaluation
    INSERT INTO Performance(rating, comments, semester, emp_ID)
    VALUES(@rating, @comment, @semester, @employee_ID);
END;


