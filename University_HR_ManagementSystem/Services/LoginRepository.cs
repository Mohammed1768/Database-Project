using System;
using System.Data;
using System.Threading.Tasks;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace University_HR_ManagementSystem.Services
{
    public class LoginRepository : ILoginRepository
    {
        private readonly string _connectionString;

        public LoginRepository(IConfiguration config)
        {
            // Prefer "DefaultConnection" but fall back to the EF context connection if present
            _connectionString = config.GetConnectionString("DefaultConnection")
                ?? config.GetConnectionString("University_HR_ManagementSystemContext")
                ?? throw new InvalidOperationException("No connection string 'DefaultConnection' or 'University_HR_ManagementSystemContext' was found in configuration.");
        }

        public async Task<bool> ValidateCredentialsAsync(string username, string password)
        {
            if (string.IsNullOrWhiteSpace(username) || string.IsNullOrWhiteSpace(password))
                return false;

            // Query the employees table for a matching email/username and password.
            // Adjust the table name ([Employee]) if your DB uses a different name (e.g., [Employees]).
            const string sql = @"
SELECT COUNT(1)
FROM [Employee]
WHERE [email] = @username AND [password] = @password";

            await using var conn = new SqlConnection(_connectionString);
            await using var cmd = new SqlCommand(sql, conn);
            cmd.CommandType = CommandType.Text;
            cmd.Parameters.AddWithValue("@username", username);
            cmd.Parameters.AddWithValue("@password", password);

            await conn.OpenAsync();
            var scalar = await cmd.ExecuteScalarAsync();
            if (scalar == null || scalar == DBNull.Value) return false;

            return Convert.ToInt32(scalar) > 0;
        }
    }
}
