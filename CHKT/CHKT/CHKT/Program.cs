using CHKT.Models;
using CHKT.Repositories;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// Đăng ký Identity với cấu hình mật khẩu linh hoạt để dễ test khi thuyết trình
builder.Services.AddIdentity<ApplicationUser, IdentityRole>(options =>
{
    options.Password.RequireDigit = false;
    options.Password.RequireLowercase = false;
    options.Password.RequireNonAlphanumeric = false;
    options.Password.RequireUppercase = false;
    options.Password.RequiredLength = 4;
    options.User.RequireUniqueEmail = true;
})
    .AddEntityFrameworkStores<ApplicationDbContext>()
    .AddDefaultTokenProviders();

// Đăng ký JWT Authentication
var secret = builder.Configuration["JWT:Secret"] ?? "DayLaChuoiBiMatDaiItNhat32KyTuChoungDungChildGuard2026!";
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.SaveToken = true;
    options.RequireHttpsMetadata = false;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidAudience = builder.Configuration["JWT:ValidAudience"] ?? "ChildGuardClient",
        ValidIssuer = builder.Configuration["JWT:ValidIssuer"] ?? "ChildGuardBackend",
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secret))
    };
});

// Đăng ký Dependency Injection cho Repository
builder.Services.AddScoped<IDeviceRepository, DeviceRepository>();

// Bật CORS cho phép máy ảo Android (10.0.2.2), máy thật qua LAN và Windows/Web truy cập
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Tự động cập nhật cấu trúc bảng và khởi tạo dữ liệu mẫu (Admin, Nhân viên, Khách hàng, Thiết bị)
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    try
    {
        var context = services.GetRequiredService<ApplicationDbContext>();
        await context.Database.EnsureCreatedAsync();

        // Bổ sung các cột và bảng mới an toàn nếu DB đã được tạo từ bản Migration cũ
        var upgradeSql = @"
            IF SCHEMA_ID('identity') IS NULL EXEC('CREATE SCHEMA [identity]');

            IF COL_LENGTH('identity.AspNetUsers', 'OtpCode') IS NULL
                ALTER TABLE [identity].[AspNetUsers] ADD [OtpCode] NVARCHAR(20) NULL;
            IF COL_LENGTH('identity.AspNetUsers', 'OtpExpiry') IS NULL
                ALTER TABLE [identity].[AspNetUsers] ADD [OtpExpiry] DATETIME2 NULL;

            IF COL_LENGTH('identity.Devices', 'Latitude') IS NULL
                ALTER TABLE [identity].[Devices] ADD [Latitude] FLOAT NULL DEFAULT 10.7769;
            IF COL_LENGTH('identity.Devices', 'Longitude') IS NULL
                ALTER TABLE [identity].[Devices] ADD [Longitude] FLOAT NULL DEFAULT 106.7009;
            IF COL_LENGTH('identity.Devices', 'NoiseLevel') IS NULL
                ALTER TABLE [identity].[Devices] ADD [NoiseLevel] FLOAT NULL DEFAULT 45.0;
            IF COL_LENGTH('identity.Devices', 'Acceleration') IS NULL
                ALTER TABLE [identity].[Devices] ADD [Acceleration] FLOAT NULL DEFAULT 0.2;
            IF COL_LENGTH('identity.Devices', 'Pressure') IS NULL
                ALTER TABLE [identity].[Devices] ADD [Pressure] FLOAT NULL DEFAULT 1013.25;
            IF COL_LENGTH('identity.Devices', 'IsSafe') IS NULL
                ALTER TABLE [identity].[Devices] ADD [IsSafe] BIT NOT NULL DEFAULT 1;
            IF COL_LENGTH('identity.Devices', 'IsLocked') IS NULL
                ALTER TABLE [identity].[Devices] ADD [IsLocked] BIT NOT NULL DEFAULT 0;
            IF COL_LENGTH('identity.Devices', 'ScreenTimeLimitMinutes') IS NULL
                ALTER TABLE [identity].[Devices] ADD [ScreenTimeLimitMinutes] INT NOT NULL DEFAULT 120;
            IF COL_LENGTH('identity.Devices', 'UsedScreenTimeMinutes') IS NULL
                ALTER TABLE [identity].[Devices] ADD [UsedScreenTimeMinutes] INT NOT NULL DEFAULT 45;
            IF COL_LENGTH('identity.Devices', 'PostureStatus') IS NULL
                ALTER TABLE [identity].[Devices] ADD [PostureStatus] NVARCHAR(200) NOT NULL DEFAULT N'Tư thế chuẩn';
            IF COL_LENGTH('identity.Devices', 'LastUpdated') IS NULL
                ALTER TABLE [identity].[Devices] ADD [LastUpdated] DATETIME2 NOT NULL DEFAULT GETDATE();

            IF OBJECT_ID('identity.SafeZones', 'U') IS NULL
            BEGIN
                CREATE TABLE [identity].[SafeZones] (
                    [Id] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
                    [ZoneName] NVARCHAR(256) NOT NULL,
                    [Latitude] FLOAT NOT NULL,
                    [Longitude] FLOAT NOT NULL,
                    [RadiusMeters] FLOAT NOT NULL DEFAULT 200,
                    [DeviceId] INT NOT NULL DEFAULT 1,
                    [NotifyOnExit] BIT NOT NULL DEFAULT 1
                );
            END

            IF OBJECT_ID('identity.AlertLogs', 'U') IS NULL
            BEGIN
                CREATE TABLE [identity].[AlertLogs] (
                    [Id] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
                    [DeviceId] INT NOT NULL,
                    [ChildName] NVARCHAR(256) NOT NULL,
                    [AlertType] NVARCHAR(100) NOT NULL,
                    [Message] NVARCHAR(MAX) NOT NULL,
                    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
                    [IsResolved] BIT NOT NULL DEFAULT 0,
                    [ResolvedBy] NVARCHAR(256) NULL
                );
            END
        ";
        await context.Database.ExecuteSqlRawAsync(upgradeSql);

        var roleManager = services.GetRequiredService<RoleManager<IdentityRole>>();
        var userManager = services.GetRequiredService<UserManager<ApplicationUser>>();

        string[] roles = { "Admin", "Staff", "Customer" };
        foreach (var r in roles)
        {
            if (!await roleManager.RoleExistsAsync(r))
                await roleManager.CreateAsync(new IdentityRole(r));
        }

        async Task SeedUser(string username, string email, string fullName, string password, string role)
        {
            var u = await userManager.FindByNameAsync(username) ?? await userManager.FindByEmailAsync(email);
            if (u == null)
            {
                u = new ApplicationUser
                {
                    UserName = username,
                    Email = email,
                    FullName = fullName,
                    EmailConfirmed = true
                };
                var res = await userManager.CreateAsync(u, password);
                if (res.Succeeded)
                {
                    await userManager.AddToRoleAsync(u, role);
                }
            }
        }

        await SeedUser("admin", "admin@childguard.vn", "Quản Trị Viên Hệ Thống", "123456", "Admin");
        await SeedUser("nhanvien", "staff@childguard.vn", "Nhân Viên Giám Sát Hỗ Trợ", "123456", "Staff");
        await SeedUser("phuhuynh", "parent@childguard.vn", "Phụ Huynh Đặng Thị Thái Hà", "123456", "Customer");

        if (!await context.Devices.AnyAsync())
        {
            context.Devices.AddRange(
                new Device
                {
                    DeviceName = "Bé Gia Bảo (Lớp 4A)",
                    MacAddress = "IMEI-8891-GB01",
                    ParentId = 1,
                    Latitude = 10.7769,
                    Longitude = 106.7009,
                    NoiseLevel = 48.5,
                    Acceleration = 0.8,
                    Pressure = 1012.8,
                    IsSafe = true,
                    IsLocked = false,
                    ScreenTimeLimitMinutes = 120,
                    UsedScreenTimeMinutes = 65,
                    PostureStatus = "Tư thế ngồi chuẩn (Góc 65°)",
                    LastUpdated = DateTime.Now
                },
                new Device
                {
                    DeviceName = "Bé Minh Anh (Lớp 2B)",
                    MacAddress = "IMEI-5520-MA02",
                    ParentId = 1,
                    Latitude = 10.7805,
                    Longitude = 106.6982,
                    NoiseLevel = 82.4,
                    Acceleration = 1.5,
                    Pressure = 1011.5,
                    IsSafe = false,
                    IsLocked = false,
                    ScreenTimeLimitMinutes = 90,
                    UsedScreenTimeMinutes = 85,
                    PostureStatus = "Cảnh báo: Đang nằm xem điện thoại!",
                    LastUpdated = DateTime.Now
                }
            );
            await context.SaveChangesAsync();
        }

        if (!await context.SafeZones.AnyAsync())
        {
            context.SafeZones.AddRange(
                new SafeZone
                {
                    ZoneName = "Trường Tiểu học Nguyễn Bỉnh Khiêm",
                    Latitude = 10.7769,
                    Longitude = 106.7009,
                    RadiusMeters = 250,
                    DeviceId = 1,
                    NotifyOnExit = true
                },
                new SafeZone
                {
                    ZoneName = "Nhà riêng (Quận 1, TP.HCM)",
                    Latitude = 10.7801,
                    Longitude = 106.6990,
                    RadiusMeters = 150,
                    DeviceId = 1,
                    NotifyOnExit = true
                }
            );
            await context.SaveChangesAsync();
        }

        if (!await context.AlertLogs.AnyAsync())
        {
            context.AlertLogs.AddRange(
                new AlertLog
                {
                    DeviceId = 2,
                    ChildName = "Bé Minh Anh (Lớp 2B)",
                    AlertType = "Noise",
                    Message = "Phát hiện tiếng ồn môi trường cao bất thường (82.4 dB) gần khu vực cổng trường.",
                    CreatedAt = DateTime.Now.AddMinutes(-15),
                    IsResolved = false
                },
                new AlertLog
                {
                    DeviceId = 2,
                    ChildName = "Bé Minh Anh (Lớp 2B)",
                    AlertType = "Posture",
                    Message = "AI Posture Shield: Trẻ vừa nằm ngửa vừa nhìn màn hình quá 5 phút (nguy cơ hại mắt).",
                    CreatedAt = DateTime.Now.AddMinutes(-5),
                    IsResolved = false
                },
                new AlertLog
                {
                    DeviceId = 1,
                    ChildName = "Bé Gia Bảo (Lớp 4A)",
                    AlertType = "SafeZone",
                    Message = "Trẻ đã đến Trường Tiểu học Nguyễn Bỉnh Khiêm an toàn.",
                    CreatedAt = DateTime.Now.AddHours(-2),
                    IsResolved = true,
                    ResolvedBy = "Hệ thống tự động"
                }
            );
            await context.SaveChangesAsync();
        }
    }
    catch (Exception ex)
    {
        Console.WriteLine($"[Database Init Warning] {ex.Message}");
    }
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("AllowAll");
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
