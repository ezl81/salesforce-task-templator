/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 08-12-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
public with sharing class ExportTemplateController {

    /**
    * @description Exports the template as a file attached to the Export Template object.
    * @author Brian Ezell (Simply EZ) | 09-07-2024 
    * @param request 
    **/
    @AuraEnabled
    public static String exportTemplate(String request) {
        try {
            ExportTemplateRequest expRequest = (ExportTemplateRequest)JSON.deserialize(request, ExportTemplateRequest.class);

            Template_Export__c expTemplate = new Template_Export__c(
                Task_Template__c = expRequest.templateId
            );

            insert as user expTemplate;
                
            generateContent(expTemplate.Id, expRequest.templateId);

            ExportTemplateResponse response = new ExportTemplateResponse();
            response.exportTemplateId = expTemplate.Id;
            return JSON.serialize(response);

        } catch(Exception ex) {
            throw new AuraHandledException(CommonFunctions.getExceptionError(ex));
        }
    }

    /**
    * @description Creates the json files from the template and saves it to a 
    *   JSON file attached to the export template.
    * @author Brian Ezell (Simply EZ) | 09-07-2024 
    * @param exportTemplateId 
    * @param templateId 
    **/
    private static void generateContent(String exportTemplateId, String templateId) {

        List<Task_Template__c> templates = CommonFunctions.getAllTemplates(templateId);

        String fileName = null;

        Master_Task_Template__c masterTemplate = 
            [
                SELECT Id, Name,
                    (
                        SELECT Id, Level__c, Name
                        FROM Task_Templates__r
                        WHERE Level__c = 0
                    )
                FROM Master_Task_Template__c
                WHERE Id = :templates[0].Master_Task_Template__c
                WITH USER_MODE
            ];

            fileName = String.format('{0}_{1}.json',
                new List<Object> {
                    masterTemplate.Task_Templates__r[0].Name,
                    DateTime.now()
                }
            );
        Blob templateBlob = Blob.valueOf(JSON.serialize(templates));
        CommonFunctions.createObjectDocument(exportTemplateId, fileName, templateBlob);
    }

    public class ExportTemplateRequest {
        public String templateId;
    }

    public class ExportTemplateResponse {
        public String exportTemplateId;
    }
    
}