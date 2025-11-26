using A_debug_a_day_keeps_the_stress_away_API.Services;

// Create a WebApplicationBuilder to configure services, middleware, and app settings
var builder = WebApplication.CreateBuilder(args);

// Register your services **before building the app**
builder.Services.AddSingleton<SqlService>();

// Add services to the container.
builder.Services.AddControllers();
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();

