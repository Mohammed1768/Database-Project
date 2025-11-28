using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using University_HR_ManagementSystem.Models;

namespace University_HR_ManagementSystem.Data
{
    public class University_HR_ManagementSystemContext : DbContext
    {
        public University_HR_ManagementSystemContext (DbContextOptions<University_HR_ManagementSystemContext> options)
            : base(options)
        {
        }

        public DbSet<University_HR_ManagementSystem.Models.Employee> Employee { get; set; } = default!;
        public DbSet<University_HR_ManagementSystem.Models.Department> Department { get; set; } = default!;
    }
}
