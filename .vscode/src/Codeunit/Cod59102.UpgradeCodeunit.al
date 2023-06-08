codeunit 59102 AppUpgradeCodeunit
{
    Subtype = Upgrade;

    // Triggered during an upgrade of the app per company.
    // Configures and publishes the 'ProcessSalesOrderAttachment' codeunit as a web service.
    // If the service already exists, its existing record is modified.
    trigger OnUpgradePerCompany()
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

        // Set the web service to be published
        TenantWebService.Published := true;

        // Attempt to insert a new record
        // If the insertion fails (likely because a record for this service already exists), modify the existing record
        if not TenantWebService.Insert() then
            TenantWebService.Modify();
    end;
}
