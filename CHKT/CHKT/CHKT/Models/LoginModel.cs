namespace CHKT.Models
{
    public class LoginModel
    {
        public string? Username { get; set; }
        public string? Email { get; set; }
        public string Password { get; set; } = string.Empty;
        public string? Otp { get; set; }
    }

    public class VerifyOtpModel
    {
        public string UsernameOrEmail { get; set; } = string.Empty;
        public string Otp { get; set; } = string.Empty;
    }
}
