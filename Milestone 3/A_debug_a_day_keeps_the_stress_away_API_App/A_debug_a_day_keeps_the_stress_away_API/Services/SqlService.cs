using System.Data;
using Microsoft.Data.SqlClient;

namespace A_debug_a_day_keeps_the_stress_away_API.Services
{
    public class SqlService
    {
        // The connection string to the SQL Server database
        private readonly string _connectionString;


        // Constructor
        public SqlService(IConfiguration config)
        {
            _connectionString = config.GetConnectionString("DefaultConnection");
        }


        // For stored procedures/queries that DON'T return data
        public async Task ExecuteNonQuery(string procedure, Dictionary<string, object>? parameters = null)
        {
            // Create connection to database
            using var connection = new SqlConnection(_connectionString);

            // Create a command representing the stored procedure
            using var command = new SqlCommand(procedure, connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            // Add parameters to the command, if there is any
            if (parameters != null)
                foreach (var p in parameters)
                    command.Parameters.AddWithValue(p.Key, p.Value);

            // Open the connection created above
            await connection.OpenAsync();
            // Execute the sql command, then do nothing with the result
            await command.ExecuteNonQueryAsync();
        }

        // For procedures/functions that return Tables
        public async Task<DataTable> ExecuteTable(string procedure, Dictionary<string, object>? parameters = null)
        {
            // Create connection to database
            using var connection = new SqlConnection(_connectionString);

            // Create a command representing the stored procedure/function
            using var command = new SqlCommand(procedure, connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            // Add parameters to the command, if there is any
            if (parameters != null)
                foreach (var p in parameters)
                    command.Parameters.AddWithValue(p.Key, p.Value);

            // Table to hold the result
            var table = new DataTable();

            // Open the connection created above
            await connection.OpenAsync();

            // Execute the command and load the results into the Table
            using var reader = await command.ExecuteReaderAsync();
            table.Load(reader);

            // Return the resulting Table
            return table;
        }


        // For procedures/functions that return a scalar value
        public async Task<object?> ExecuteScalar(string procedure, Dictionary<string, object>? parameters = null)
        {
            // Create connection to database
            using var connection = new SqlConnection(_connectionString);

            // Create a command representing the stored procedure/function
            using var command = new SqlCommand(procedure, connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            // Add parameters to the command, if there is any
            if (parameters != null)
                foreach (var p in parameters)
                    command.Parameters.AddWithValue(p.Key, p.Value ?? DBNull.Value);

            // Open the connection created above
            await connection.OpenAsync();

            // Execute the command and return the scalar result
            return await command.ExecuteScalarAsync();
        }


        // For views that return Tables
        public async Task<DataTable> ExecuteView(string viewName, Dictionary<string, object>? parameters = null)
        {
            // Build the SQL query for the view
            var sql = $"SELECT * FROM {viewName}";

            // Create connection to database
            using var connection = new SqlConnection(_connectionString);

            // Create a command representing the View
            using var command = new SqlCommand(sql, connection);

            // Add parameters to the command, if there is any (for WHERE)
            if (parameters != null)
                foreach (var p in parameters)
                    command.Parameters.AddWithValue(p.Key, p.Value ?? DBNull.Value);

            // Table to hold the result
            var table = new DataTable();

            // Open the connection created above
            await connection.OpenAsync();

            // Execute the command and load the results into the Table
            using var reader = await command.ExecuteReaderAsync();
            table.Load(reader);

            // Return the resulting Table
            return table;
        }

    }
}

