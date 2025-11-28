using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using University_HR_ManagementSystem.Data;
using University_HR_ManagementSystem.Models;

namespace University_HR_ManagementSystem.Pages.Departements
{
    public class DetailsModel : PageModel
    {
        private readonly University_HR_ManagementSystem.Data.University_HR_ManagementSystemContext _context;

        public DetailsModel(University_HR_ManagementSystem.Data.University_HR_ManagementSystemContext context)
        {
            _context = context;
        }

        public Department Department { get; set; } = default!;

        public async Task<IActionResult> OnGetAsync(string id)
        {
            if (id == null)
            {
                return NotFound();
            }

            var department = await _context.Department.FirstOrDefaultAsync(m => m.Name == id);
            if (department == null)
            {
                return NotFound();
            }
            else
            {
                Department = department;
            }
            return Page();
        }
    }
}
