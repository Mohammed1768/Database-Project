using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace University_HR_ManagementSystem.Models
{
    public class Employee
    {
        [Key]
        public int EmployeeId { get; set; }

        [Required]
        [MaxLength(50)]
        public string FirstName { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        public string LastName { get; set; } = string.Empty;

        [Required]
        [EmailAddress]
        [MaxLength(50)]
        public string Email { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        public string Password { get; set; } = string.Empty;

        [MaxLength(50)]
        public string Address { get; set; } = string.Empty;

        [Required]
        [StringLength(1)]
        public char Gender { get; set; }

        [MaxLength(50)]
        public string OfficialDayOff { get; set; } = string.Empty;

        public int YearsOfExperience { get; set; }

        [StringLength(16)]
        public string NationalID { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        [RegularExpression("active|onleave|notice_period|resigned",
            ErrorMessage = "Employment status must be active, onleave, notice_period, or resigned")]
        public string EmploymentStatus { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        [RegularExpression("full_time|part_time",
            ErrorMessage = "Type of contract must be full_time or part_time")]
        public string TypeOfContract { get; set; } = string.Empty;

        [MaxLength(50)]
        public string EmergencyContactName { get; set; } = string.Empty;

        [StringLength(11)]
        public string EmergencyContactPhone { get; set; } = string.Empty;

        public int AnnualBalance { get; set; }
        public int AccidentalBalance { get; set; }

        // Salary is computed in the database
        [DatabaseGenerated(DatabaseGeneratedOption.Computed)]
        public decimal Salary { get; set; }

        public DateTime? HireDate { get; set; }
        public DateTime? LastWorkingDate { get; set; }

        // Foreign key
        [MaxLength(50)]
        public string DeptName { get; set; } = string.Empty;

        [ForeignKey("DeptName")]
        public Department? Department { get; set; }

    }
}
