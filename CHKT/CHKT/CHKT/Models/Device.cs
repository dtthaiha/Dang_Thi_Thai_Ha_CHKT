using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace CHKT.Models
{
    public class Device
    {
        [Key]
        public int Id { get; set; }

        public string DeviceName { get; set; } = string.Empty;
        public string MacAddress { get; set; } = string.Empty;
        public int ParentId { get; set; }

        // Các trường mở rộng phục vụ giám sát vị trí, cảm biến, giới hạn giờ và tính năng mới
        public double? Latitude { get; set; } = 10.7769;
        public double? Longitude { get; set; } = 106.7009;
        public double? NoiseLevel { get; set; } = 45.0;
        public double? Acceleration { get; set; } = 0.2;
        public double? Pressure { get; set; } = 1013.25;
        public bool IsSafe { get; set; } = true;
        public bool IsLocked { get; set; } = false;
        public int ScreenTimeLimitMinutes { get; set; } = 120;
        public int UsedScreenTimeMinutes { get; set; } = 45;
        public string PostureStatus { get; set; } = "Tư thế chuẩn";
        public DateTime LastUpdated { get; set; } = DateTime.Now;

        // Thuộc tính tương thích trực tiếp với model ChildDevice trên Flutter
        [JsonPropertyName("childName")]
        public string ChildName
        {
            get => DeviceName;
            set => DeviceName = value;
        }

        [JsonPropertyName("deviceCode")]
        public string DeviceCode
        {
            get => MacAddress;
            set => MacAddress = value;
        }
    }
}
