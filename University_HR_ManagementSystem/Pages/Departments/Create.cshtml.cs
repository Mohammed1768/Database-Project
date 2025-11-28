using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.AspNetCore.Mvc.Rendering;
using University_HR_ManagementSystem.Data;
using University_HR_ManagementSystem.Models;

namespace University_HR_ManagementSystem.Pages.Departments
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
            return Page();
        }

        [BindProperty]
        public Department Department { get; set; } = default!;

        // For more information, see https://aka.ms/RazorPagesCRUD.
        public async Task<IActionResult> OnPostAsync()
        {
            if (!ModelState.IsValid)
            {
                return Page();
            }

            _context.Department.Add(Department);
            await _context.SaveChangesAsync();

            return RedirectToPage("./Index");
        }
    }
}
