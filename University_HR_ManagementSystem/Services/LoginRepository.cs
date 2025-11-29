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
            _connectionString = config.GetConnectionString("DefaultConnection")
                ?? config.GetConnectionString("University_HR_ManagementSystemContext")
                ?? throw new InvalidOperationException("No connection string 'DefaultConnection' or 'University_HR_ManagementSystemContext' was found in configuration.");
        }

        public async Task<bool> ValidateCredentialsAsync(string username, string password)
        {
            if (string.IsNullOrWhiteSpace(username) || string.IsNullOrWhiteSpace(password))
                return false;

            // First, get the employee_id from email
            const string getSql = @"
                SELECT [employee_id]
                FROM [Employee]
                WHERE [email] = @username";

            // Then call the EmployeeLoginValidation function with employee_id and password
            const string validateSql = @"
                SELECT dbo.EmployeeLoginValidation(@employee_id, @password)";

            await using var conn = new SqlConnection(_connectionString);
            await conn.OpenAsync();

            // Step 1: Get employee_id by email
            await using var getCmd = new SqlCommand(getSql, conn);
            getCmd.CommandType = CommandType.Text;
            getCmd.Parameters.AddWithValue("@username", username);
            var employeeIdScalar = await getCmd.ExecuteScalarAsync();

            if (employeeIdScalar == null || employeeIdScalar == DBNull.Value)
                return false;

            int employeeId = Convert.ToInt32(employeeIdScalar);

            // Step 2: Call EmployeeLoginValidation function
            await using var validateCmd = new SqlCommand(validateSql, conn);
            validateCmd.CommandType = CommandType.Text;
            validateCmd.Parameters.AddWithValue("@employee_id", employeeId);
            validateCmd.Parameters.AddWithValue("@password", password);

            var result = await validateCmd.ExecuteScalarAsync();
            if (result == null || result == DBNull.Value)
                return false;

            return Convert.ToInt32(result) == 1;
        }
    }
}
