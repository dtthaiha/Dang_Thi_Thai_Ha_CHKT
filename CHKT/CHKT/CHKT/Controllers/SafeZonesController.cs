using CHKT.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CHKT.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class SafeZonesController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public SafeZonesController(ApplicationDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var zones = await _context.SafeZones.OrderByDescending(z => z.Id).ToListAsync();
            return Ok(zones);
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] SafeZone zone)
        {
            _context.SafeZones.Add(zone);
            await _context.SaveChangesAsync();
            return Ok(zone);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromBody] SafeZone updated)
        {
            var existing = await _context.SafeZones.FindAsync(id);
            if (existing == null) return NotFound();

            existing.ZoneName = updated.ZoneName;
            existing.Latitude = updated.Latitude;
            existing.Longitude = updated.Longitude;
            existing.RadiusMeters = updated.RadiusMeters;
            existing.DeviceId = updated.DeviceId;
            existing.NotifyOnExit = updated.NotifyOnExit;

            await _context.SaveChangesAsync();
            return Ok(existing);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var existing = await _context.SafeZones.FindAsync(id);
            if (existing == null) return NotFound();

            _context.SafeZones.Remove(existing);
            await _context.SaveChangesAsync();
            return Ok(new { Message = "Đã xóa vùng an toàn" });
        }
    }
}
