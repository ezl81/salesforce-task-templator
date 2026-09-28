/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 06-16-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
public with sharing class CreateObjectTemplateController {

    /**
    * @description Gets a list of templates for the given object name
    * @author Brian Ezell (Simply EZ) | 05-21-2024 
    * @param objectApiName 
    * @return string 
    **/
    @AuraEnabled
    public static string getTemplates(String objectApiName) {
        try {
            if(String.isBlank(objectApiName)) {
                throw new AuraHandledException('Object name cannot be blank.');
            }

            List<Task_Template__c> templates = 
                [
                    SELECT Id, Name
                    FROM Task_Template__c
                    WHERE Is_Master_Template__c = true
                        AND Is_Active__c = true
                        //AND Templated_Objects__c INCLUDES (:objectApiName)
                    WITH USER_MODE
                    ORDER BY Name DESC
                ];
            return JSON.serialize(templates);
        } catch (Exception e) {
            throw new AuraHandledException(CommonFunctions.getExceptionError(e));
        }
    }

    /**
    * @description Takes in a request to create
    *   a new case(s) from a master template.
    * @author Brian Ezell (Simply EZ) | 05-21-2024 
    * @param request 
    * @return string 
    **/
    @AuraEnabled
    public static string createTemplate(String request) {
        try {
            CreateTemplateRequest templateRequest = (CreateTemplateRequest)JSON.deserialize(request, CreateTemplateRequest.class);
            CreateProcessFlowController.ProcessInput inputs = new CreateProcessFlowController.ProcessInput();
            inputs.ObjectId = templateRequest.objectId;
            inputs.ObjectName = templateRequest.objectName;
            inputs.TemplateId = templateRequest.templateId;

            CreateTemplateResponse response = new CreateTemplateResponse();
            List<Id> idList = CreateProcessFlowController.CreateProcess(new List<CreateProcessFlowController.ProcessInput> { inputs });

            if(idList != null && idList.size() > 0) {
                response.caseId = idList[0];
            }
            return JSON.serialize(response);
        } catch (Exception e) {
            throw new AuraHandledException(CommonFunctions.getExceptionError(e));
        }
    }

    public class CreateTemplateRequest {
        public String objectId;
        public String objectName;
        public String templateId;
    }

    public class CreateTemplateResponse {
        public String caseId;
    }

}