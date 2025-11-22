-- بسم الله الرحمن الرحيم

/*   /\_/\
*   (= ._.)
*   / >  \>
*/

use University_HR_ManagementSystem_Team_No_12;
go


DECLARE @id INT;

EXEC Submit_accidental 
    2,
    '2025-11-22',
    '2025-11-22';

SET @id = SCOPE_IDENTITY();

SELECT * 
FROM Accidental_Leave a 
JOIN Leave l ON a.request_ID = l.request_ID
WHERE l.request_ID = @id;

SELECT * 
FROM Employee_Approve_Leave el
JOIN Employee_Role er ON (er.emp_ID = el.Emp1_ID)
WHERE Leave_ID = @id;
