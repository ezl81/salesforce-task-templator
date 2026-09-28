/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 08-12-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
public with sharing class TemplateDeleteController {

    @AuraEnabled
    public static void deleteTemplate(String request) {
        try {
            
            DeleteTemplateRequest deleteRequest = (DeleteTemplateRequest) JSON.deserialize(request, DeleteTemplateRequest.class);

            //Find the master record
            Task_Template__c template =
                [
                    SELECT Id, Name, Master_Task_Template__c
                    FROM Task_Template__c
                    WHERE Id = :deleteRequest.templateId
                    WITH USER_MODE
                ];

            //See if any cases are associated with this template
            List<Case> cases =
                [
                    SELECT Id
                    FROM Case
                    WHERE Task_Template_Step__r.Parent_Task_Template__r.Master_Task_Template__c = :template.Master_Task_Template__c
                    WITH USER_MODE
                ];

            if(cases.size() > 0) {
                throw new AuraHandledException('Cannot delete template with (' + cases.size() + ') associated cases.');
            }

            List<Task_Template_Step_Dependency__c> deleteDependencies = 
            [
                SELECT Id
                FROM Task_Template_Step_Dependency__c
                WHERE Task_Template__r.Master_Task_Template__c = :template.Master_Task_Template__c
                WITH USER_MODE
            ];

            delete as user deleteDependencies;

            List<Task_Template_Step__c> deleteSteps = 
            [
                SELECT Id
                FROM Task_Template_Step__c
                WHERE Parent_Task_Template__r.Master_Task_Template__c = :template.Master_Task_Template__c
                WITH USER_MODE
            ];

            delete as user deleteSteps;

            List<Task_Template__c> deleteTemplates =
            [
                SELECT Id
                FROM Task_Template__c
                WHERE Master_Task_Template__c = :template.Master_Task_Template__c
                WITH USER_MODE
            ];

            delete as user deleteTemplates;
        } catch (Exception e) {
            throw new AuraHandledException(CommonFunctions.getExceptionError(e));
        }
    }

    public class DeleteTemplateRequest {
        public String templateId;
    }

}