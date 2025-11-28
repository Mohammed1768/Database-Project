using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace University_HR_ManagementSystem.Models
{
    public class Employee
    {
        [Key]
        [Column("employee_id")]
        public int EmployeeId { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("first_name")]
        public string FirstName { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        [Column("last_name")]
        public string LastName { get; set; } = string.Empty;

        [Required]
        [EmailAddress]
        [MaxLength(50)]
        [Column("email")]
        public string Email { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        [Column("password")]
        public string Password { get; set; } = string.Empty;

        [MaxLength(50)]
        [Column("address")]
        public string Address { get; set; } = string.Empty;

        [Required]
        [Column("gender")]
        public char Gender { get; set; }

        [MaxLength(50)]
        [Column("official_day_off")]
        public string OfficialDayOff { get; set; } = string.Empty;

        [Column("years_of_experience")]
        public int YearsOfExperience { get; set; }

        [StringLength(16)]
        [Column("national_ID")]
        public string NationalID { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        [RegularExpression("active|onleave|notice_period|resigned",
            ErrorMessage = "Employment status must be active, onleave, notice_period, or resigned")]
        [Column("employment_status")]
        public string EmploymentStatus { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        [RegularExpression("full_time|part_time",
            ErrorMessage = "Type of contract must be full_time or part_time")]
        [Column("type_of_contract")]
        public string TypeOfContract { get; set; } = string.Empty;

        [MaxLength(50)]
        [Column("emergency_contact_name")]
        public string EmergencyContactName { get; set; } = string.Empty;

        [StringLength(11)]
        [Column("emergency_contact_phone")]
        public string EmergencyContactPhone { get; set; } = string.Empty;

        [Column("annual_balance")]
        public int AnnualBalance { get; set; }

        [Column("accidental_balance")]
        public int AccidentalBalance { get; set; }

        // Salary is computed in the database. To avoid SQL Server OUTPUT issues
        // we do not map it directly to the EF model (EF would include it in
        // INSERT ... OUTPUT which SQL Server rejects when the computed column
        // depends on functions that perform data access). Use a separate query
        // to read the computed salary when needed.
        [NotMapped]
        public decimal Salary { get; set; }

        [Column("hire_date")]
        public DateTime? HireDate { get; set; }

        [Column("last_working_date")]
        public DateTime? LastWorkingDate { get; set; }

        // Foreign key
        [MaxLength(50)]
        [Column("dept_name")]
        public string DeptName { get; set; } = string.Empty;

        [ForeignKey("DeptName")]
        public Department? Department { get; set; }
        
    }
}
