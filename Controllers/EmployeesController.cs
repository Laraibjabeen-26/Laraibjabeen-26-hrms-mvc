using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using HRMS.Mvc.Models;

namespace HRMS.Mvc.Controllers
{
    public class EmployeesController : Controller
    {
        private readonly ApplicationDbContext _context;
        public EmployeesController(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<IActionResult> Index()
        {
            var employees = await _context.Employees
                  .Include(e => e.Department)
                  .Include(e => e.Designation)
                  .OrderByDescending(e => e.BasicSalary)
                  .ToListAsync();
            return View(employees);
        }

        public async Task<IActionResult> Details(int? id)
        {
            if (id == null) return NotFound();

            var employee = await _context.Employees
                .Include(e => e.Department)
                .Include(e => e.Designation)
                .FirstOrDefaultAsync(m => m.EmployeeID == id);
            if (employee == null) return NotFound();

            return View(employee);
        }

        public IActionResult Create()
        {
            ViewData["Departments"] = _context.Departments.ToList();
            ViewData["Designations"] = _context.Designations.ToList();
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create([Bind("FirstName,LastName,Gender,DateOfBirth,DateOfJoining,DepartmentID,DesignationID,Email,Phone,BasicSalary,IsActive")] Employee employee)
        {
            if (ModelState.IsValid)
            {
                _context.Add(employee);
                await _context.SaveChangesAsync();
                return RedirectToAction(nameof(Index));
            }
            ViewData["Departments"] = _context.Departments.ToList();
            ViewData["Designations"] = _context.Designations.ToList();
            return View(employee);
        }

        public async Task<IActionResult> Edit(int? id)
        {
            if (id == null) return NotFound();
            var employee = await _context.Employees.FindAsync(id);
            if (employee == null) return NotFound();
            ViewData["Departments"] = _context.Departments.ToList();
            ViewData["Designations"] = _context.Designations.ToList();
            return View(employee);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(int id, [Bind("EmployeeID,FirstName,LastName,Gender,DateOfBirth,DateOfJoining,DepartmentID,DesignationID,Email,Phone,BasicSalary,IsActive")] Employee employee)
        {
            if (id != employee.EmployeeID) return NotFound();

            if (ModelState.IsValid)
            {
                try
                {
                    _context.Update(employee);
                    await _context.SaveChangesAsync();
                }
                catch (DbUpdateConcurrencyException)
                {
                    if (!_context.Employees.Any(e => e.EmployeeID == employee.EmployeeID)) return NotFound();
                    else throw;
                }
                return RedirectToAction(nameof(Index));
            }
            ViewData["Departments"] = _context.Departments.ToList();
            ViewData["Designations"] = _context.Designations.ToList();
            return View(employee);
        }

        public async Task<IActionResult> Delete(int? id)
        {
            if (id == null) return NotFound();
            var employee = await _context.Employees
                .Include(e => e.Department)
                .Include(e => e.Designation)
                .FirstOrDefaultAsync(m => m.EmployeeID == id);
            if (employee == null) return NotFound();
            return View(employee);
        }

        [HttpPost, ActionName("Delete")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> DeleteConfirmed(int id)
        {
            var employee = await _context.Employees.FindAsync(id);
            if (employee != null)
            {
                _context.Employees.Remove(employee);
                await _context.SaveChangesAsync();
            }
            return RedirectToAction(nameof(Index));
        }

        [HttpPost]
        public async Task<IActionResult> GeneratePayroll(int employeeId, int month, int year)
        {
            try
            {
                await _context.Database.ExecuteSqlInterpolatedAsync($"EXEC usp_GeneratePayroll {employeeId}, {month}, {year}");
                TempData["Success"] = $"Payroll generated for employee {employeeId} for {month}/{year}.";
            }
            catch (Exception ex)
            {
                TempData["Error"] = "Payroll generation failed: " + ex.Message;
            }
            return RedirectToAction(nameof(Index));
        }
    }
}
