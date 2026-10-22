using CHKT.Models;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace CHKT.Repositories
{
    public class DeviceRepository : IDeviceRepository
    {
        private readonly ApplicationDbContext _context;

        public DeviceRepository(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<IEnumerable<Device>> GetAllDevicesAsync()
        {
            return await _context.Devices.OrderByDescending(d => d.Id).ToListAsync();
        }

        public async Task<Device?> GetDeviceByIdAsync(int id)
        {
            return await _context.Devices.FindAsync(id);
        }

        public async Task<Device> AddDeviceAsync(Device device)
        {
            if (string.IsNullOrWhiteSpace(device.DeviceName))
                device.DeviceName = "Thiết bị của trẻ";
            if (string.IsNullOrWhiteSpace(device.MacAddress))
                device.MacAddress = "DEV-" + Random.Shared.Next(1000, 9999);
            device.LastUpdated = DateTime.Now;

            _context.Devices.Add(device);
            await _context.SaveChangesAsync();
            return device;
        }

        public async Task<Device?> UpdateDeviceAsync(int id, Device updated)
        {
            var existing = await _context.Devices.FindAsync(id);
            if (existing == null) return null;

            if (!string.IsNullOrWhiteSpace(updated.DeviceName))
                existing.DeviceName = updated.DeviceName;
            if (!string.IsNullOrWhiteSpace(updated.MacAddress))
                existing.MacAddress = updated.MacAddress;
            if (updated.ParentId != 0)
                existing.ParentId = updated.ParentId;
            if (updated.Latitude.HasValue)
                existing.Latitude = updated.Latitude;
            if (updated.Longitude.HasValue)
                existing.Longitude = updated.Longitude;
            if (updated.NoiseLevel.HasValue)
                existing.NoiseLevel = updated.NoiseLevel;
            if (updated.Acceleration.HasValue)
                existing.Acceleration = updated.Acceleration;
            if (updated.Pressure.HasValue)
                existing.Pressure = updated.Pressure;

            existing.IsSafe = updated.IsSafe;
            existing.IsLocked = updated.IsLocked;
            if (updated.ScreenTimeLimitMinutes > 0)
                existing.ScreenTimeLimitMinutes = updated.ScreenTimeLimitMinutes;
            if (updated.UsedScreenTimeMinutes >= 0)
                existing.UsedScreenTimeMinutes = updated.UsedScreenTimeMinutes;
            if (!string.IsNullOrWhiteSpace(updated.PostureStatus))
                existing.PostureStatus = updated.PostureStatus;

            existing.LastUpdated = DateTime.Now;

            await _context.SaveChangesAsync();
            return existing;
        }

        public async Task<bool> DeleteDeviceAsync(int id)
        {
            var existing = await _context.Devices.FindAsync(id);
            if (existing == null) return false;

            _context.Devices.Remove(existing);
            await _context.SaveChangesAsync();
            return true;
        }
    }
}
