using Microsoft.AspNetCore.Identity;

namespace CHKT.Models
{
    public class ApplicationUser : IdentityUser
    {
        public string? FullName { get; set; }
        public string? OtpCode { get; set; }
        public DateTime? OtpExpiry { get; set; }
    }
}
