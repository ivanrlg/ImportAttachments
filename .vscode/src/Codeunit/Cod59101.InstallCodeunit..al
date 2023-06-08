codeunit 59101 InstallCodeunit
{
    Subtype = Install;

    // Triggered when the app is installed per company.
    // Configures and publishes the 'ProcessSalesOrderAttachment' codeunit as a web service.
    trigger OnInstallAppPerCompany()
    var
        ModuleInfo: ModuleInfo;
        TenantWebService: Record "Tenant Web Service";
    begin
        // Get current app module information
        NavApp.GetCurrentModuleInfo(ModuleInfo);

        // Initialize a new 'Tenant Web Service' record
        TenantWebService.Init();
        TenantWebService."Object Type" := TenantWebService."Object Type"::Codeunit;
        TenantWebService."Object ID" := Codeunit::ProcessSalesOrderAttachment;
        TenantWebService."Service Name" := 'ProcessSalesOrderAttachment';

        // Publish the web service
        TenantWebService.Published := true;

        // Attempt to insert the new record
        // If the insertion fails, an error will be raised by default
        TenantWebService.Insert();
    end;

}