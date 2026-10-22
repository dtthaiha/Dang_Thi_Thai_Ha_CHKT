using CHKT.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace CHKT.Repositories
{
    public interface IDeviceRepository
    {
        Task<IEnumerable<Device>> GetAllDevicesAsync();
        Task<Device?> GetDeviceByIdAsync(int id);
        Task<Device> AddDeviceAsync(Device device);
        Task<Device?> UpdateDeviceAsync(int id, Device device);
        Task<bool> DeleteDeviceAsync(int id);
    }
}
