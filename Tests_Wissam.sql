-- بسم الله الرحمن الرحيم

/*   /\_/\
*   (= ._.)
*   / >  \>
*/

use University_HR_ManagementSystem_Team_No_12;
go


-- request_idd = 22

select * from Leave where request_ID=1

select * from Employee_Approve_Leave el inner join Employee_Role er on (er.emp_ID = el.Emp1_ID)
where Leave_ID=1

EXEC Submit_accidental 
        2,
    '2025-11-22',
    '2025-11-22';



select * from Accidental_Leave a inner join Leave l on (a.request_ID=l.request_ID) where l.request_ID=26

select * from Employee_Approve_Leave el inner join Employee_Role er on (er.emp_ID = el.Emp1_ID)
where Leave_ID=26