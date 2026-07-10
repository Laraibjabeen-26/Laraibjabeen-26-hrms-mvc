using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace HRMS.Mvc.Models
{
    public class Employee
    {
        [Key]
        public int EmployeeID { get; set; }
        [Required]
        public string FirstName { get; set; }
        [Required]
        public string LastName { get; set; }
        public string Gender { get; set; }
        public DateTime? DateOfBirth { get; set; }
        public DateTime? DateOfJoining { get; set; }
        public int? DepartmentID { get; set; }
        public int? DesignationID { get; set; }
        public string Email { get; set; }
        public string Phone { get; set; }
        [Column(TypeName = "decimal(10,2)")]
        public decimal BasicSalary { get; set; }
        public bool IsActive { get; set; } = true;

        public Department? Department { get; set; }
        public Designation? Designation { get; set; }
    }

    public class Department
    {
        [Key]
        public int DepartmentID { get; set; }
        public string DepartmentName { get; set; }
        public string Location { get; set; }
    }

    public class Designation
    {
        [Key]
        public int DesignationID { get; set; }
        public string DesignationName { get; set; }
        public int DepartmentID { get; set; }

        public Department? Department { get; set; }
    }

    public class AllowanceType
    {
        [Key]
        public int AllowanceTypeID { get; set; }
        public string AllowanceTypeName { get; set; }
    }

    public class DeductionType
    {
        [Key]
        public int DeductionTypeID { get; set; }
        public string DeductionTypeName { get; set; }
    }

    public class SalaryAllowance
    {
        [Key]
        public int AllowanceID { get; set; }
        public int EmployeeID { get; set; }
        public int AllowanceTypeID { get; set; }
        public int PayMonth { get; set; }
        public int PayYear { get; set; }
        [Column(TypeName = "decimal(10,2)")]
        public decimal Amount { get; set; }
        public int? PayrollID { get; set; }

        public AllowanceType? AllowanceType { get; set; }
        public Employee? Employee { get; set; }
    }

    public class SalaryDeduction
    {
        [Key]
        public int DeductionID { get; set; }
        public int EmployeeID { get; set; }
        public int DeductionTypeID { get; set; }
        public int PayMonth { get; set; }
        public int PayYear { get; set; }
        [Column(TypeName = "decimal(10,2)")]
        public decimal Amount { get; set; }
        public int? PayrollID { get; set; }

        public DeductionType? DeductionType { get; set; }
        public Employee? Employee { get; set; }
    }

    public class Payroll
    {
        [Key]
        public int PayrollID { get; set; }
        public int EmployeeID { get; set; }
        public int PayMonth { get; set; }
        public int PayYear { get; set; }
        [Column(TypeName = "decimal(10,2)")]
        public decimal BasicSalary { get; set; }
        [Column(TypeName = "decimal(10,2)")]
        public decimal GrossSalary { get; set; }
        [Column(TypeName = "decimal(10,2)")]
        public decimal TotalDeductions { get; set; }
        [Column(TypeName = "decimal(10,2)")]
        public decimal NetSalary { get; set; }
        public DateTime? PaymentDate { get; set; }

        public Employee? Employee { get; set; }
    }
}
