using CHKT.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Net;
using System.Net.Mail;
using System.Security.Claims;
using System.Text;

namespace CHKT.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthenticateController : ControllerBase
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly RoleManager<IdentityRole> _roleManager;
        private readonly IConfiguration _configuration;

        public AuthenticateController(
            UserManager<ApplicationUser> userManager,
            RoleManager<IdentityRole> roleManager,
            IConfiguration configuration)
        {
            _userManager = userManager;
            _roleManager = roleManager;
            _configuration = configuration;
        }

        // 1. ĐĂNG KÝ TÀI KHOẢN QUA EMAIL
        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegistrationModel model)
        {
            if (string.IsNullOrWhiteSpace(model.Email) || string.IsNullOrWhiteSpace(model.Password))
            {
                return BadRequest(new { Status = "Error", Message = "Vui lòng nhập đầy đủ Email và Mật khẩu!" });
            }

            var username = !string.IsNullOrWhiteSpace(model.Username)
                ? model.Username.Trim()
                : model.Email.Split('@')[0];

            var userByEmail = await _userManager.FindByEmailAsync(model.Email);
            if (userByEmail != null)
            {
                return BadRequest(new { Status = "Error", Message = "Email này đã được đăng ký!" });
            }

            var userByName = await _userManager.FindByNameAsync(username);
            if (userByName != null)
            {
                username = username + Random.Shared.Next(10, 99);
            }

            string otp = Random.Shared.Next(100000, 999999).ToString();

            var user = new ApplicationUser
            {
                Email = model.Email.Trim(),
                UserName = username,
                FullName = !string.IsNullOrWhiteSpace(model.Name) ? model.Name : username,
                SecurityStamp = Guid.NewGuid().ToString(),
                EmailConfirmed = true,
                OtpCode = otp,
                OtpExpiry = DateTime.UtcNow.AddMinutes(10)
            };

            var result = await _userManager.CreateAsync(user, model.Password);
            if (!result.Succeeded)
            {
                var errors = string.Join("; ", result.Errors.Select(e => e.Description));
                return BadRequest(new { Status = "Error", Message = "Đăng ký thất bại: " + errors });
            }

            // Phân quyền: Admin, Staff (Nhân viên), Customer (Khách hàng / Phụ huynh)
            string role = NormalizeRole(model.Role);
            if (!await _roleManager.RoleExistsAsync(role))
            {
                await _roleManager.CreateAsync(new IdentityRole(role));
            }
            await _userManager.AddToRoleAsync(user, role);

            // Gửi email xác nhận đăng ký kèm OTP
            await TrySendOtpEmailAsync(user.Email!, user.FullName ?? user.UserName!, otp, "Xác nhận đăng ký tài khoản Child Guard");

            return Ok(new
            {
                Status = "Success",
                Message = $"Đăng ký thành công qua email {user.Email} với quyền {role}!",
                Username = user.UserName,
                Email = user.Email,
                Role = role,
                DemoOtp = otp
            });
        }

        // 2. ĐĂNG NHẬP BƯỚC 1 (KIỂM TRA USERNAME/EMAIL + PASSWORD -> GỬI MÃ OTP QUA EMAIL)
        // HOẶC ĐĂNG NHẬP LUÔN NẾU ĐÃ CÓ MÃ OTP
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginModel model)
        {
            string identifier = !string.IsNullOrWhiteSpace(model.Username)
                ? model.Username.Trim()
                : (model.Email?.Trim() ?? string.Empty);

            if (string.IsNullOrWhiteSpace(identifier) || string.IsNullOrWhiteSpace(model.Password))
            {
                return BadRequest(new { Status = "Error", Message = "Vui lòng nhập Tên đăng nhập/Email và Mật khẩu!" });
            }

            var user = await _userManager.FindByNameAsync(identifier)
                       ?? await _userManager.FindByEmailAsync(identifier);

            if (user == null || !await _userManager.CheckPasswordAsync(user, model.Password))
            {
                return Unauthorized(new { Status = "Error", Message = "Tên đăng nhập hoặc mật khẩu không chính xác!" });
            }

            // Nếu người dùng chưa gửi kèm mã OTP -> Sinh OTP, gửi qua Email và yêu cầu nhập OTP
            if (string.IsNullOrWhiteSpace(model.Otp))
            {
                string otp = Random.Shared.Next(100000, 999999).ToString();
                user.OtpCode = otp;
                user.OtpExpiry = DateTime.UtcNow.AddMinutes(5);
                await _userManager.UpdateAsync(user);

                await TrySendOtpEmailAsync(user.Email ?? identifier, user.FullName ?? user.UserName!, otp, "Mã xác thực OTP đăng nhập Child Guard");

                return Ok(new
                {
                    RequireOtp = true,
                    Username = user.UserName,
                    Email = user.Email,
                    DemoOtp = otp,
                    Message = $"Đã gửi mã OTP 6 số tới email {user.Email}. (Mã OTP: {otp})"
                });
            }

            // Nếu đã gửi kèm OTP -> Xác thực OTP luôn
            return await CompleteOtpLoginAsync(user, model.Otp.Trim());
        }

        // 3. XÁC THỰC MÃ OTP (BƯỚC 2 CỦA ĐĂNG NHẬP)
        [HttpPost("verify-otp")]
        public async Task<IActionResult> VerifyOtp([FromBody] VerifyOtpModel model)
        {
            if (string.IsNullOrWhiteSpace(model.UsernameOrEmail) || string.IsNullOrWhiteSpace(model.Otp))
            {
                return BadRequest(new { Status = "Error", Message = "Vui lòng nhập thông tin tài khoản và mã OTP!" });
            }

            var user = await _userManager.FindByNameAsync(model.UsernameOrEmail.Trim())
                       ?? await _userManager.FindByEmailAsync(model.UsernameOrEmail.Trim());

            if (user == null)
            {
                return NotFound(new { Status = "Error", Message = "Không tìm thấy người dùng!" });
            }

            return await CompleteOtpLoginAsync(user, model.Otp.Trim());
        }

        // 4. QUẢN LÝ NGƯỜI DÙNG & PHÂN QUYỀN (CHO ADMIN CRUD)
        [HttpGet("users")]
        public async Task<IActionResult> GetAllUsers()
        {
            var users = await _userManager.Users.ToListAsync();
            var result = new List<object>();

            foreach (var u in users)
            {
                var roles = await _userManager.GetRolesAsync(u);
                result.Add(new
                {
                    id = u.Id,
                    userName = u.UserName,
                    email = u.Email,
                    fullName = u.FullName ?? u.UserName,
                    role = roles.FirstOrDefault() ?? "Customer"
                });
            }

            return Ok(result);
        }

        [HttpPut("users/{id}/role")]
        public async Task<IActionResult> UpdateUserRole(string id, [FromQuery] string newRole)
        {
            var user = await _userManager.FindByIdAsync(id);
            if (user == null)
                return NotFound(new { Message = "Không tìm thấy người dùng" });

            var normalizedRole = NormalizeRole(newRole);
            if (!await _roleManager.RoleExistsAsync(normalizedRole))
            {
                await _roleManager.CreateAsync(new IdentityRole(normalizedRole));
            }

            var currentRoles = await _userManager.GetRolesAsync(user);
            await _userManager.RemoveFromRolesAsync(user, currentRoles);
            await _userManager.AddToRoleAsync(user, normalizedRole);

            return Ok(new { Message = $"Đã cập nhật quyền thành {normalizedRole}", Role = normalizedRole });
        }

        [HttpDelete("users/{id}")]
        public async Task<IActionResult> DeleteUser(string id)
        {
            var user = await _userManager.FindByIdAsync(id);
            if (user == null)
                return NotFound(new { Message = "Không tìm thấy người dùng" });

            await _userManager.DeleteAsync(user);
            return Ok(new { Message = "Đã xóa người dùng thành công" });
        }

        private async Task<IActionResult> CompleteOtpLoginAsync(ApplicationUser user, string otp)
        {
            bool isValidOtp = (user.OtpCode == otp && (!user.OtpExpiry.HasValue || user.OtpExpiry.Value >= DateTime.UtcNow))
                              || otp == "123456"; // Hỗ trợ mã OTP mặc định 123456 khi demo nhanh

            if (!isValidOtp)
            {
                return Unauthorized(new { Status = "Error", Message = "Mã OTP không chính xác hoặc đã hết hạn!" });
            }

            // Xóa OTP sau khi sử dụng thành công
            user.OtpCode = null;
            user.OtpExpiry = null;
            await _userManager.UpdateAsync(user);

            var userRoles = await _userManager.GetRolesAsync(user);
            string primaryRole = userRoles.FirstOrDefault() ?? "Customer";

            var authClaims = new List<Claim>
            {
                new Claim(ClaimTypes.Name, user.UserName ?? ""),
                new Claim(ClaimTypes.Email, user.Email ?? ""),
                new Claim(ClaimTypes.NameIdentifier, user.Id),
                new Claim(ClaimTypes.Role, primaryRole),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            };

            var secret = _configuration["JWT:Secret"] ?? "DayLaChuoiBiMatDaiItNhat32KyTuChoungDungChildGuard2026!";
            var authSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secret));

            var token = new JwtSecurityToken(
                issuer: _configuration["JWT:ValidIssuer"] ?? "ChildGuardBackend",
                audience: _configuration["JWT:ValidAudience"] ?? "ChildGuardClient",
                expires: DateTime.Now.AddHours(12),
                claims: authClaims,
                signingCredentials: new SigningCredentials(authSigningKey, SecurityAlgorithms.HmacSha256)
            );

            return Ok(new
            {
                RequireOtp = false,
                Token = new JwtSecurityTokenHandler().WriteToken(token),
                Expiration = token.ValidTo,
                UserId = user.Id,
                Username = user.UserName,
                Email = user.Email,
                FullName = user.FullName ?? user.UserName,
                Role = primaryRole,
                Message = "Đăng nhập xác thực OTP thành công!"
            });
        }

        private static string NormalizeRole(string? role)
        {
            if (string.IsNullOrWhiteSpace(role)) return "Customer";
            var r = role.Trim().ToLowerInvariant();
            if (r.Contains("admin") || r.Contains("quản trị")) return "Admin";
            if (r.Contains("staff") || r.Contains("nhân viên") || r.Contains("nhanvien") || r.Contains("employee")) return "Staff";
            return "Customer";
        }

        private async Task TrySendOtpEmailAsync(string toEmail, string fullName, string otp, string subject)
        {
            Console.WriteLine($"====================================================");
            Console.WriteLine($"[EMAIL OTP] Gửi tới: {toEmail} ({fullName})");
            Console.WriteLine($"[EMAIL OTP] Tiêu đề: {subject}");
            Console.WriteLine($"[EMAIL OTP] Mã xác thực OTP của bạn là: {otp}");
            Console.WriteLine($"====================================================");

            try
            {
                var smtpHost = _configuration["Smtp:Host"];
                var smtpUser = _configuration["Smtp:Username"];
                var smtpPass = _configuration["Smtp:Password"];
                int smtpPort = int.TryParse(_configuration["Smtp:Port"], out var p) ? p : 587;

                if (!string.IsNullOrWhiteSpace(smtpHost) &&
                    !string.IsNullOrWhiteSpace(smtpUser) &&
                    !string.IsNullOrWhiteSpace(smtpPass))
                {
                    using var client = new SmtpClient(smtpHost, smtpPort)
                    {
                        Credentials = new NetworkCredential(smtpUser, smtpPass),
                        EnableSsl = true
                    };

                    var mail = new MailMessage
                    {
                        From = new MailAddress(smtpUser, "Child Guard App"),
                        Subject = subject,
                        Body = $"Xin chào {fullName},\n\nMã xác thực OTP của bạn trên ứng dụng Quản lý Điện thoại Trẻ em (Child Guard) là: {otp}\nMã có hiệu lực trong vòng 5 phút.\n\nTrân trọng,\nĐội ngũ Child Guard",
                        IsBodyHtml = false
                    };
                    mail.To.Add(toEmail);
                    await client.SendMailAsync(mail);
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[SMTP Fallback] Chưa cấu hình SMTP hoặc lỗi gửi mail: {ex.Message}. Đã dùng OTP nội bộ: {otp}");
            }
        }
    }
}
