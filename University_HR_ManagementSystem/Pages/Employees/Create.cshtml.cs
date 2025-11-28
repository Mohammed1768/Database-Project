using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.AspNetCore.Mvc.Rendering;
using University_HR_ManagementSystem.Data;
using University_HR_ManagementSystem.Models;

namespace University_HR_ManagementSystem.Pages.Employees
{
    public class CreateModel : PageModel
    {
        private readonly University_HR_ManagementSystem.Data.University_HR_ManagementSystemContext _context;

        public CreateModel(University_HR_ManagementSystem.Data.University_HR_ManagementSystemContext context)
        {
            _context = context;
        }

        public IActionResult OnGet()
        {
        ViewData["DeptName"] = new SelectList(_context.Department, "Name", "Name");
            return Page();
        }

        [BindProperty]
        public Employee Employee { get; set; } = default!;

        // For more information, see https://aka.ms/RazorPagesCRUD.
        public async Task<IActionResult> OnPostAsync()
        {
            if (!ModelState.IsValid)
            {
                return Page();
            }

            _context.Employee.Add(Employee);
            await _context.SaveChangesAsync();

            return RedirectToPage("./Index");
        }
    }
}
