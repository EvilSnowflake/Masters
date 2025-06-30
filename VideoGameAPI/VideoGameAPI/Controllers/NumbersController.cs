using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Threading.Tasks;
using VideoGameAPI.Controllers.Data;
using VideoGameAPI.Models;

namespace VideoGameAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class NumbersController(VideoGameDbContext context) : ControllerBase
    {
        private readonly VideoGameDbContext _context = context;

        //https://localhost:7218/api/Numbers
        [HttpGet]
        public async Task<ActionResult<List<MultiNumbers>>> GetNumbers()
        {
            return Ok(await _context.MultipleNumbers.ToListAsync());
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<MultiNumbers>> GetMultNumbersById(int id)
        {
            var multNum = await _context.MultipleNumbers.FindAsync(id);
            if (multNum is null)
                return NotFound();
            return Ok(multNum);
        }

        [HttpPost]
        public async Task<ActionResult<MultiNumbers>> AddMultiNumber(MultiNumbers newMultNum) {
            if (newMultNum is null)
                return BadRequest();
            _context.MultipleNumbers.Add(newMultNum);
            await _context.SaveChangesAsync();
            return CreatedAtAction(nameof(GetMultNumbersById), new { id = newMultNum.Id }, newMultNum);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateMultiNumbers(int id, MultiNumbers updatedMultiNumbers)
        {
            var multNum = await _context.MultipleNumbers.FindAsync(id);
            if (multNum is null)
                return NotFound();

            multNum.numberOne = updatedMultiNumbers.numberOne;
            multNum.numberTwo = updatedMultiNumbers.numberTwo;

            await _context.SaveChangesAsync();

            return NoContent();
        }
    }
}
