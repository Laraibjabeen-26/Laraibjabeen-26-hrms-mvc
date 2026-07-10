using Microsoft.EntityFrameworkCore;

namespace HRMS.Mvc.Models
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options) { }

        public DbSet<Employee> Employees { get; set; }
        public DbSet<Department> Departments { get; set; }
        public DbSet<Designation> Designations { get; set; }
        public DbSet<Payroll> Payroll { get; set; }
        public DbSet<AllowanceType> AllowanceTypes { get; set; }
        public DbSet<DeductionType> DeductionTypes { get; set; }
        public DbSet<SalaryAllowance> SalaryAllowances { get; set; }
        public DbSet<SalaryDeduction> SalaryDeductions { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
            // if you prefer database-first, run scaffolding locally to replace these models
        }
    }
}
