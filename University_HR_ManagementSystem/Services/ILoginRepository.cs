using System.Threading.Tasks;

namespace University_HR_ManagementSystem.Services
{
    public interface ILoginRepository
    {
        /// <summary>
        /// Validates the provided username/email and password against the database.
        /// Returns true when the credentials are valid.
        /// </summary>
        Task<bool> ValidateCredentialsAsync(string username, string password);
    }
}
