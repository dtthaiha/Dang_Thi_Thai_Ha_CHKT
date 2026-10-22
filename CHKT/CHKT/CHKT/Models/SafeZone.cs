using System.ComponentModel.DataAnnotations;

namespace CHKT.Models
{
    public class SafeZone
    {
        [Key]
        public int Id { get; set; }
        public string ZoneName { get; set; } = string.Empty;
        public double Latitude { get; set; }
        public double Longitude { get; set; }
        public double RadiusMeters { get; set; } = 200;
        public int DeviceId { get; set; }
        public bool NotifyOnExit { get; set; } = true;
    }
}
