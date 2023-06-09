codeunit 59100 ProcessSalesOrderAttachment
{
    procedure SendPing(): Text
    begin
        exit('Pong');
    end;

    // Function to import attachments to Sales Orders. It reads input parameters,
    // retrieves the appropriate Sales Order, and returns the status of document processing.
    procedure ImportAttachmentsToSalesOrders(JsonObjectText: Text): Text
    var
        SalesOrder: Record "Sales Header";
        FromRecRef: RecordRef;
        No: Code[20];
        SalesDocumentType: enum "Sales Document Type";
        JsonObject: JsonObject;
        ParamToken: JsonToken;
        Base64String, FileExtension, FileName : Text;
        Processed: Boolean;
    begin
        // Parse input parameters from JSON
        JsonObject.ReadFrom(JsonObjectText);

        if JsonObject.Get('Base64', ParamToken) then
            Base64String := ParamToken.AsValue().AsText();

        if JsonObject.Get('FileName', ParamToken) then
            FileName := ParamToken.AsValue().AsText();

        if JsonObject.Get('FileExtension', ParamToken) then
            FileExtension := ParamToken.AsValue().AsText();

        if JsonObject.Get('No', ParamToken) then
            No := ParamToken.AsValue().AsCode();

        if JsonObject.Get('DocumentType', ParamToken) then
            SalesDocumentType := "Sales Document Type".FromInteger(ParamToken.AsValue().AsInteger());

        // Retrieve the Sales Order to attach the document to
        SalesOrder.Reset();
        SalesOrder.SetRange("No.", No);
        SalesOrder.SetRange("Document Type", SalesDocumentType);
        if not SalesOrder.FindLast() then
            Error('SalesOrder %1 does not exist', No);

        FromRecRef.GETTABLE(SalesOrder);

        // Validate FileName and FileExtension
        if FileName = '' then
            Error('FileName is empty');

        if FileExtension = '' then
            Error('FileExtension is empty');

        Processed := ConvertAndSaveBase64String(FromRecRef, Base64String, FileName, FileExtension);

        if Processed then
            exit(StrSubstNo('Document was %1.%2 imported successfully.', FileName, FileExtension))
        else
            exit(StrSubstNo('An error occurred while importing the Document %1.%2', FileName, FileExtension));
    end;

    // Function to process the Base64 string of the document and save it as an Instream.
    local procedure ConvertAndSaveBase64String(
    FromRecRef: RecordRef;
    Base64String: Text;
    FileName: Text;
    FileExtension: Text): Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        Count: Integer;
        OutStream: OutStream;
        InStream: InStream;
        Base64Convert: Codeunit "Base64 Convert";
    begin
        TempBlob.CreateOutStream(OutStream);
        Base64Convert.FromBase64(Base64String, OutStream);
        TempBlob.CreateInStream(InStream, TextEncoding::WINDOWS);

        exit(SaveAttachment(InStream, FromRecRef, FileName, FileExtension));
    end;

    // Function to insert the document into the list of attachments.
    local procedure SaveAttachment(DocStream: InStream; RecRef: RecordRef; FileName: Text; FileExtension: Text): Boolean;
    var
        DocAttach: Record "Document Attachment";
        Variable: Text;
    begin
        // Validate the file name and extension.
        DocAttach.Validate("File Name", FileName);
        DocAttach.Validate("File Extension", FileExtension);

        DocStream.ReadText(Variable);

        // Attach the file to the Document Reference ID.
        DocAttach."Document Reference ID".ImportStream(DocStream, '');
        if not DocAttach."Document Reference ID".HasValue then
            exit(false);

        // Insert appropriate information into "Table ID", "Document Type" and "No." fields based on the record reference.
        DocAttach.InitFieldsFromRecRef(RecRef);

        OnBeforeInsertAttachment(DocAttach, RecRef);

        exit(DocAttach.Insert(true));
    end;

    // Integration Event triggered before inserting a document attachment.
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertAttachment(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef)
    begin
    end;
}
