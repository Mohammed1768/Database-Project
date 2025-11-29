using System.Threading.Tasks;

namespace University_HR_ManagementSystem.Services
{
    public interface ILoginRepository
    {
        Task<bool> ValidateCredentialsAsync(string username, string password);
    }
}
