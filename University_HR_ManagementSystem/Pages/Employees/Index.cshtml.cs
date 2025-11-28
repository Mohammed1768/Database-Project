using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using University_HR_ManagementSystem.Data;
using University_HR_ManagementSystem.Models;

namespace University_HR_ManagementSystem.Pages.Employees
{
    public class IndexModel : PageModel
    {
        private readonly University_HR_ManagementSystem.Data.University_HR_ManagementSystemContext _context;

        public IndexModel(University_HR_ManagementSystem.Data.University_HR_ManagementSystemContext context)
        {
            _context = context;
        }

        public IList<Employee> Employee { get;set; } = default!;

        public async Task OnGetAsync()
        {
            Employee = await _context.Employee
                .Include(e => e.Department).ToListAsync();
        }
    }
}
