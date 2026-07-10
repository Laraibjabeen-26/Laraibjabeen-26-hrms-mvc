using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using HRMS.Mvc.Models;

namespace HRMS.Mvc.Controllers
{
    public class DashboardController : Controller
    {
        private readonly ApplicationDbContext _context;
        public DashboardController(ApplicationDbContext context) => _context = context;

        public async Task<IActionResult> Index()
        {
            var totalEmployees = await _context.Employees.CountAsync();
            var activeEmployees = await _context.Employees.CountAsync(e => e.IsActive);
            var totalDepartments = await _context.Departments.CountAsync();
            var totalPayrollThisMonth = await _context.Payroll
                                       .Where(p => p.PayMonth == DateTime.Now.Month && p.PayYear == DateTime.Now.Year)
                                       .SumAsync(p => (decimal?)p.NetSalary) ?? 0;

            var months = Enumerable.Range(0, 6)
                .Select(i => DateTime.Now.AddMonths(-i))
                .Select(d => new {
                    Month = d.Month,
                    Year = d.Year,
                    TotalNet = _context.Payroll.Where(p => p.PayMonth == d.Month && p.PayYear == d.Year).Sum(p => (decimal?)p.NetSalary) ?? 0
                })
                .ToList();

            ViewBag.TotalEmployees = totalEmployees;
            ViewBag.ActiveEmployees = activeEmployees;
            ViewBag.TotalDepartments = totalDepartments;
            ViewBag.TotalPayrollThisMonth = totalPayrollThisMonth;
            ViewBag.MonthlyPayroll = months.Select(m => m.TotalNet).Reverse().ToArray();
            ViewBag.MonthLabels = months.Select(m => $"{m.Month}/{m.Year}").Reverse().ToArray();

            return View();
        }
    }
}
