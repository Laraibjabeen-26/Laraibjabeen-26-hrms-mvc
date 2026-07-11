using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using HRMS.Mvc.Models;
using Microsoft.AspNetCore.Authorization;

namespace HRMS.Mvc.Controllers
{
    [Authorize]
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

        public async Task<IActionResult> Edit(int? id, int? month, int? year)
        {
            if (id == null) return NotFound();
            var employee = await _context.Employees.FindAsync(id);
            if (employee == null) return NotFound();

            var payMonth = month ?? DateTime.Now.Month;
            var payYear = year ?? DateTime.Now.Year;
            await LoadEditLookupsAsync(employee.EmployeeID, payMonth, payYear);
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
                    TempData["Success"] = "Employee details saved.";
                }
                catch (DbUpdateConcurrencyException)
                {
                    if (!_context.Employees.Any(e => e.EmployeeID == employee.EmployeeID)) return NotFound();
                    else throw;
                }
                return RedirectToAction(nameof(Edit), new { id });
            }
            await LoadEditLookupsAsync(id, DateTime.Now.Month, DateTime.Now.Year);
            return View(employee);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> AddAllowance(int employeeId, int allowanceTypeId, decimal amount, int payMonth, int payYear)
        {
            if (!_context.Employees.Any(e => e.EmployeeID == employeeId)) return NotFound();
            if (allowanceTypeId <= 0 || amount <= 0)
            {
                TempData["Error"] = "Select an allowance type and enter a valid amount.";
                return RedirectToAction(nameof(Edit), new { id = employeeId, month = payMonth, year = payYear });
            }

            _context.SalaryAllowances.Add(new SalaryAllowance
            {
                EmployeeID = employeeId,
                AllowanceTypeID = allowanceTypeId,
                Amount = amount,
                PayMonth = payMonth,
                PayYear = payYear
            });
            await _context.SaveChangesAsync();
            TempData["Success"] = "Allowance added.";
            return RedirectToAction(nameof(Edit), new { id = employeeId, month = payMonth, year = payYear });
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> AddDeduction(int employeeId, int deductionTypeId, decimal amount, int payMonth, int payYear)
        {
            if (!_context.Employees.Any(e => e.EmployeeID == employeeId)) return NotFound();
            if (deductionTypeId <= 0 || amount <= 0)
            {
                TempData["Error"] = "Select a deduction type and enter a valid amount.";
                return RedirectToAction(nameof(Edit), new { id = employeeId, month = payMonth, year = payYear });
            }

            _context.SalaryDeductions.Add(new SalaryDeduction
            {
                EmployeeID = employeeId,
                DeductionTypeID = deductionTypeId,
                Amount = amount,
                PayMonth = payMonth,
                PayYear = payYear
            });
            await _context.SaveChangesAsync();
            TempData["Success"] = "Deduction added.";
            return RedirectToAction(nameof(Edit), new { id = employeeId, month = payMonth, year = payYear });
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> DeleteAllowance(int allowanceId, int employeeId, int payMonth, int payYear)
        {
            var item = await _context.SalaryAllowances.FirstOrDefaultAsync(a => a.AllowanceID == allowanceId && a.EmployeeID == employeeId);
            if (item != null)
            {
                _context.SalaryAllowances.Remove(item);
                await _context.SaveChangesAsync();
                TempData["Success"] = "Allowance removed.";
            }
            return RedirectToAction(nameof(Edit), new { id = employeeId, month = payMonth, year = payYear });
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> DeleteDeduction(int deductionId, int employeeId, int payMonth, int payYear)
        {
            var item = await _context.SalaryDeductions.FirstOrDefaultAsync(d => d.DeductionID == deductionId && d.EmployeeID == employeeId);
            if (item != null)
            {
                _context.SalaryDeductions.Remove(item);
                await _context.SaveChangesAsync();
                TempData["Success"] = "Deduction removed.";
            }
            return RedirectToAction(nameof(Edit), new { id = employeeId, month = payMonth, year = payYear });
        }

        private async Task LoadEditLookupsAsync(int employeeId, int payMonth, int payYear)
        {
            ViewData["Departments"] = await _context.Departments.ToListAsync();
            ViewData["Designations"] = await _context.Designations.ToListAsync();
            ViewData["AllowanceTypes"] = await _context.AllowanceTypes.OrderBy(a => a.AllowanceTypeName).ToListAsync();
            ViewData["DeductionTypes"] = await _context.DeductionTypes.OrderBy(d => d.DeductionTypeName).ToListAsync();
            ViewData["PayMonth"] = payMonth;
            ViewData["PayYear"] = payYear;

            ViewBag.Allowances = await _context.SalaryAllowances
                .Include(a => a.AllowanceType)
                .Where(a => a.EmployeeID == employeeId && a.PayMonth == payMonth && a.PayYear == payYear)
                .OrderByDescending(a => a.AllowanceID)
                .ToListAsync();

            ViewBag.Deductions = await _context.SalaryDeductions
                .Include(d => d.DeductionType)
                .Where(d => d.EmployeeID == employeeId && d.PayMonth == payMonth && d.PayYear == payYear)
                .OrderByDescending(d => d.DeductionID)
                .ToListAsync();
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
            return RedirectToAction("Index", "Payroll", new { month, year, employeeId });
        }
    }
}
