using System.ComponentModel.DataAnnotations;

namespace CHKT.Models
{
    public class AlertLog
    {
        [Key]
        public int Id { get; set; }
        public int DeviceId { get; set; }
        public string ChildName { get; set; } = string.Empty;
        public string AlertType { get; set; } = "SOS"; // SOS, Noise, Fall, Posture, SafeZone
        public string Message { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public bool IsResolved { get; set; } = false;
        public string? ResolvedBy { get; set; }
    }
}
