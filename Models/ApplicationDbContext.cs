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
        public DbSet<User> Users { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<SalaryAllowance>(e =>
            {
                e.HasOne(x => x.AllowanceType).WithMany().HasForeignKey(x => x.AllowanceTypeID);
                e.HasOne(x => x.Employee).WithMany().HasForeignKey(x => x.EmployeeID);
            });

            modelBuilder.Entity<SalaryDeduction>(e =>
            {
                e.HasOne(x => x.DeductionType).WithMany().HasForeignKey(x => x.DeductionTypeID);
                e.HasOne(x => x.Employee).WithMany().HasForeignKey(x => x.EmployeeID);
            });

            modelBuilder.Entity<Payroll>(e =>
            {
                e.ToTable("Payroll");
                e.HasOne(x => x.Employee).WithMany().HasForeignKey(x => x.EmployeeID);
            });
        }
    }
}
