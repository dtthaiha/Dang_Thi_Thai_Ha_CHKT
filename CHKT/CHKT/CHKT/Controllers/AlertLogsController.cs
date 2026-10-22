using CHKT.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CHKT.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AlertLogsController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public AlertLogsController(ApplicationDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var logs = await _context.AlertLogs.OrderByDescending(a => a.CreatedAt).ToListAsync();
            return Ok(logs);
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] AlertLog log)
        {
            log.CreatedAt = DateTime.Now;
            _context.AlertLogs.Add(log);
            await _context.SaveChangesAsync();
            return Ok(log);
        }

        [HttpPut("{id}/resolve")]
        public async Task<IActionResult> Resolve(int id, [FromQuery] string resolvedBy = "Nhân viên hỗ trợ")
        {
            var existing = await _context.AlertLogs.FindAsync(id);
            if (existing == null) return NotFound();

            existing.IsResolved = true;
            existing.ResolvedBy = resolvedBy;
            await _context.SaveChangesAsync();
            return Ok(existing);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var existing = await _context.AlertLogs.FindAsync(id);
            if (existing == null) return NotFound();

            _context.AlertLogs.Remove(existing);
            await _context.SaveChangesAsync();
            return Ok(new { Message = "Đã xóa nhật ký cảnh báo" });
        }
    }
}
