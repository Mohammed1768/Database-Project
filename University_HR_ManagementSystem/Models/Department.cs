using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace University_HR_ManagementSystem.Models
{
    public class Department
    {
        [Key]
        [MaxLength(50)]
        [Column("name")]
        public string Name { get; set; } = string.Empty;

        [MaxLength(50)]
        [Column("building_location")]
        public string BuildingLocation { get; set; } = string.Empty;
    }
}