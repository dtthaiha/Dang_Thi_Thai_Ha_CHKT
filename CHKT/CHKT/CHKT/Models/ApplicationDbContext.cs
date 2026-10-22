using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace CHKT.Models
{
    // Kế thừa IdentityDbContext thay vì DbContext
    public class ApplicationDbContext : IdentityDbContext<ApplicationUser>
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options) { }

        public DbSet<Device> Devices { get; set; }
        public DbSet<SafeZone> SafeZones { get; set; }
        public DbSet<AlertLog> AlertLogs { get; set; }

        protected override void OnModelCreating(ModelBuilder builder)
        {
            base.OnModelCreating(builder);

            // Đổi tên schema mặc định thành 'identity' giống database của thầy
            builder.HasDefaultSchema("identity");

            // Cấu hình bảng Devices và bỏ qua 2 thuộc tính alias JSON
            builder.Entity<Device>(entity =>
            {
                entity.ToTable("Devices", schema: "identity");
                entity.Ignore(d => d.ChildName);
                entity.Ignore(d => d.DeviceCode);
            });

            builder.Entity<SafeZone>().ToTable("SafeZones", schema: "identity");
            builder.Entity<AlertLog>().ToTable("AlertLogs", schema: "identity");
        }
    }
}
