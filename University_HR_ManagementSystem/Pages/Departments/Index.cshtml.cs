using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using University_HR_ManagementSystem.Data;
using University_HR_ManagementSystem.Models;

namespace University_HR_ManagementSystem.Pages.Departments
{
    public class IndexModel : PageModel
    {
        private readonly University_HR_ManagementSystem.Data.University_HR_ManagementSystemContext _context;

        public IndexModel(University_HR_ManagementSystem.Data.University_HR_ManagementSystemContext context)
        {
            _context = context;
        }

        public IList<Department> Department { get;set; } = default!;

        public async Task OnGetAsync()
        {
            Department = await _context.Department.ToListAsync();
        }
    }
}
