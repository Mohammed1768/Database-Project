using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace University_HR_ManagementSystem.Models
{
    public class Department
    {
        [Key]
        [MaxLength(50)]
        public string DeptName { get; set; } = string.Empty;

        [MaxLength(50)]
        public string BuildingLocation { get; set; } = string.Empty;
    }
}