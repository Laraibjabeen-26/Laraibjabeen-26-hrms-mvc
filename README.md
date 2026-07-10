# HRMS MVC Starter

This repository contains a starter ASP.NET Core MVC project (NET 7) for the HRMS/Payroll system. It includes basic models, DbContext, controllers and Razor views for Employees and a Dashboard.

How to run:
1. Install .NET 7 SDK: https://dotnet.microsoft.com/en-us/download/dotnet/7.0
2. Update `appsettings.json` connection string to point to your SQL Server (Database: HRMS).
3. From the project folder run:
   dotnet restore
   dotnet build
   dotnet run

Notes:
- This starter uses EF Core packages; you can scaffold your full database models locally with the `dotnet ef dbcontext scaffold` command if you prefer database-first.
- The repository includes example controllers and views for Employees and a Dashboard. You should add the rest of entities (Allowances, Deductions, Payroll) via scaffolding or by copying controller/view patterns.
