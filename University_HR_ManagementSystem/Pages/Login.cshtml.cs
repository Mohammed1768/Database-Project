using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace University_HR_ManagementSystem.Pages
{
public class LoginModel : PageModel
{
    [BindProperty] 
    public InputModel Input { get; set; } 
    
    public string ReturnUrl { get; set; } 
    public bool IsAdmin { get; set; } 
    
    public class InputModel 
    {
        public string Email { get; set; } 
        public string Password { get; set; }
    }

    public IActionResult OnPost(string returnUrl = null)
    {
        // return LocalRedirect(returnUrl ?? "/Index");

        ModelState.AddModelError(string.Empty, 
            "Invalid login attempt. Please check your email and password.");
        return Page(); 
    }
}}