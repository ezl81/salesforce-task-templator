/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 06-16-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/

public with sharing class CloneTemplateController {

    @AuraEnabled
    public static string cloneTemplate(String request) {
        try {
            CloneTemplateRequest cloneRequest = (CloneTemplateRequest) JSON.deserialize(request, CloneTemplateRequest.class);
            CloneAllTemplates clone = new CloneAllTemplates(cloneRequest.templateId);

            CloneTemplateResponse response = new CloneTemplateResponse();
            response.newTemplateId = clone.cloneTemplate(cloneRequest.newName);
            return JSON.serialize(response);
        } catch (Exception ex) {
            throw new AuraHandledException(CommonFunctions.getExceptionError(ex));
        }
    }

    @AuraEnabled
    public static string getTemplate(String templateId) {
        try {

            if(String.isBlank(templateId)) {
                throw new AuraHandledException('Template id cannot be blank.');
            }

            Task_Template__c currentTemplate = 
                [
                    SELECT Id, Master_Task_Template__c,
                        Master_Task_Template__r.Task_Template__c
                    FROM Task_Template__c
                    WHERE Id = :templateId
                    WITH USER_MODE
                ];

            Task_Template__c topLevelTemplate = 
                [
                    SELECT Id, Name
                    FROM Task_Template__c
                    WHERE Id = :currentTemplate.Master_Task_Template__r.Task_Template__c
                    WITH USER_MODE
                ];
            return JSON.serialize(topLevelTemplate);
        } catch (Exception ex) {
            throw new AuraHandledException(CommonFunctions.getExceptionError(ex));
        }
    }

    public class CloneTemplateRequest {
        public String templateId;
        public String newName;
    }

    public class CloneTemplateResponse {
        public String newTemplateId;
    }

}