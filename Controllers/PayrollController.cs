using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using HRMS.Mvc.Models;

namespace HRMS.Mvc.Controllers
{
    public class PayrollController : Controller
    {
        private readonly ApplicationDbContext _context;

        public PayrollController(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<IActionResult> Index(int? month, int? year, int? employeeId)
        {
            var payMonth = month ?? DateTime.Now.Month;
            var payYear = year ?? DateTime.Now.Year;

            var query = _context.Payroll
                .Include(p => p.Employee)
                    .ThenInclude(e => e!.Department)
                .Include(p => p.Employee)
                    .ThenInclude(e => e!.Designation)
                .Where(p => p.PayMonth == payMonth && p.PayYear == payYear)
                .AsQueryable();

            if (employeeId.HasValue && employeeId.Value > 0)
            {
                query = query.Where(p => p.EmployeeID == employeeId.Value);
            }

            var payrolls = await query
                .OrderByDescending(p => p.PayrollID)
                .ToListAsync();

            ViewData["PayMonth"] = payMonth;
            ViewData["PayYear"] = payYear;
            ViewData["EmployeeId"] = employeeId;
            ViewData["Employees"] = await _context.Employees
                .OrderBy(e => e.FirstName)
                .ThenBy(e => e.LastName)
                .ToListAsync();

            ViewBag.TotalNet = payrolls.Sum(p => p.NetSalary);
            ViewBag.TotalGross = payrolls.Sum(p => p.GrossSalary);
            ViewBag.TotalDeductions = payrolls.Sum(p => p.TotalDeductions);
            ViewBag.Count = payrolls.Count;

            return View(payrolls);
        }

        public async Task<IActionResult> Details(int? id)
        {
            if (id == null) return NotFound();

            var payroll = await _context.Payroll
                .Include(p => p.Employee)
                    .ThenInclude(e => e!.Department)
                .Include(p => p.Employee)
                    .ThenInclude(e => e!.Designation)
                .FirstOrDefaultAsync(p => p.PayrollID == id);

            if (payroll == null) return NotFound();

            ViewBag.Allowances = await _context.SalaryAllowances
                .Include(a => a.AllowanceType)
                .Where(a => a.EmployeeID == payroll.EmployeeID
                            && a.PayMonth == payroll.PayMonth
                            && a.PayYear == payroll.PayYear)
                .OrderBy(a => a.AllowanceType!.AllowanceTypeName)
                .ToListAsync();

            ViewBag.Deductions = await _context.SalaryDeductions
                .Include(d => d.DeductionType)
                .Where(d => d.EmployeeID == payroll.EmployeeID
                            && d.PayMonth == payroll.PayMonth
                            && d.PayYear == payroll.PayYear)
                .OrderBy(d => d.DeductionType!.DeductionTypeName)
                .ToListAsync();

            return View(payroll);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Generate(int employeeId, int month, int year)
        {
            try
            {
                await _context.Database.ExecuteSqlInterpolatedAsync($"EXEC usp_GeneratePayroll {employeeId}, {month}, {year}");
                TempData["Success"] = $"Payroll generated for employee {employeeId} · {month}/{year}.";
            }
            catch (Exception ex)
            {
                TempData["Error"] = "Payroll generation failed: " + ex.Message;
            }

            return RedirectToAction(nameof(Index), new { month, year, employeeId });
        }
    }
}
