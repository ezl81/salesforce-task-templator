/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 06-16-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
public with sharing class ImportTemplateController {

    @AuraEnabled
    public static String importTemplate(String request) {
        try {
            ImportTemplateRequest req = (ImportTemplateRequest) JSON.deserialize(request, ImportTemplateRequest.class);
            Id masterTemplateId = importTemplateFromRecord(req.importRequestId);
            ImportTemplateResponse response = new ImportTemplateResponse();
            response.masterTemplateId = masterTemplateId;
            return JSON.serialize(response);
        } catch (Exception ex) {
            throw new AuraHandledException(CommonFunctions.getExceptionError(ex));
        }
    }

    /**
    * @description Get the content document files on this import request and
    *   create the templates.
    * @author Brian Ezell (Simply EZ) | 09-08-2024 
    * @param importRequestId 
    **/
    private static Id importTemplateFromRecord(String importRequestId) {

        ContentDocumentLink cdl = 
            [
                SELECT Id, LinkedEntityId, ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :importRequestId
                WITH USER_MODE
                LIMIT 1
            ];

        Id documentId = cdl.ContentDocumentId;

        ContentVersion version = 
            [
                SELECT Id, ContentDocumentId, VersionData
                FROM ContentVersion
                WHERE ContentDocumentId = :documentId
                WITH USER_MODE
                LIMIT 1
            ];
        String jsonData = version.VersionData.toString();
        ImportTemplateHelper importHelper = new ImportTemplateHelper();

        Id masterTemplateId =  importHelper.importJsonTemplates(jsonData);
        Master_Task_Template__c masterTemplate = 
            [
                SELECT Id, Name, Task_Template__c
                FROM Master_Task_Template__c
                WHERE Id = :masterTemplateId
                WITH USER_MODE
            ];

        return masterTemplate.Task_Template__c;
    }   

    public class ImportTemplateRequest {
        public String importRequestId;
    }

    public class ImportTemplateResponse {
        public String masterTemplateId;
    }
    
}