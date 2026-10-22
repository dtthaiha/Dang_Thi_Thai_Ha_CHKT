using CHKT.Models;
using CHKT.Repositories;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;

namespace CHKT.Controllers
{
    [Route("api/[controller]")]
    [Route("api/ChildDevices")]
    [ApiController]
    public class DeviceApiController : ControllerBase
    {
        private readonly IDeviceRepository _deviceRepository;

        public DeviceApiController(IDeviceRepository deviceRepository)
        {
            _deviceRepository = deviceRepository; // Tiêm dependency (DI)
        }

        // 1. READ ALL: Lấy danh sách thiết bị
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var devices = await _deviceRepository.GetAllDevicesAsync();
            return Ok(devices);
        }

        // 2. READ BY ID: Lấy chi tiết 1 thiết bị
        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var device = await _deviceRepository.GetDeviceByIdAsync(id);
            if (device == null)
                return NotFound(new { Message = "Không tìm thấy thiết bị" });
            return Ok(device);
        }

        // 3. CREATE: Thêm thiết bị mới
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] Device device)
        {
            var created = await _deviceRepository.AddDeviceAsync(device);
            return Ok(created);
        }

        // 4. UPDATE: Cập nhật thông tin thiết bị, tọa độ GPS, cảm biến, giới hạn thời gian
        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromBody] Device device)
        {
            var updated = await _deviceRepository.UpdateDeviceAsync(id, device);
            if (updated == null)
                return NotFound(new { Message = "Không tìm thấy thiết bị cần cập nhật" });
            return Ok(updated);
        }

        // 5. PATCH: Khóa / Mở khóa màn hình thiết bị từ xa
        [HttpPost("{id}/toggle-lock")]
        public async Task<IActionResult> ToggleLock(int id)
        {
            var existing = await _deviceRepository.GetDeviceByIdAsync(id);
            if (existing == null)
                return NotFound(new { Message = "Không tìm thấy thiết bị" });

            existing.IsLocked = !existing.IsLocked;
            var updated = await _deviceRepository.UpdateDeviceAsync(id, existing);
            return Ok(updated);
        }

        // 6. POST: Thưởng thêm thời gian sử dụng khi trẻ giải toán thành công (Tính năng mới Edu-Unlock)
        [HttpPost("{id}/reward-time")]
        public async Task<IActionResult> RewardScreenTime(int id, [FromQuery] int bonusMinutes = 15)
        {
            var existing = await _deviceRepository.GetDeviceByIdAsync(id);
            if (existing == null)
                return NotFound(new { Message = "Không tìm thấy thiết bị" });

            existing.ScreenTimeLimitMinutes += bonusMinutes;
            existing.IsLocked = false;
            var updated = await _deviceRepository.UpdateDeviceAsync(id, existing);
            return Ok(updated);
        }

        // 7. DELETE: Xóa thiết bị
        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var deleted = await _deviceRepository.DeleteDeviceAsync(id);
            if (!deleted)
                return NotFound(new { Message = "Không tìm thấy thiết bị cần xóa" });
            return Ok(new { Message = "Xóa thiết bị thành công" });
        }
    }
}
