/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 08-12-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
public with sharing class DependenciesController {

    /**
    * @description Gets information on the template step
    * @author Brain Ezell (Simply EZ) | 5/13/2020
    * @param stepId
    * @return string
    **/
    @AuraEnabled
    public static string getTemplateStepInformation(String stepId) {
        try {
            
            if(String.isBlank(stepId)) {
                throw new AuraHandledException('Step Id cannot be blank.');
            }
            Task_Template_Step__c step =
                [
                    SELECT Id, Parent_Task_Template__c
                    FROM Task_Template_Step__c
                    WHERE Id = :stepId
                    WITH USER_MODE
                ];
                 return Json.serialize(step);
        } catch(Exception ex) {
            throw new AuraHandledException(CommonFunctions.getExceptionError(ex));
        }
    }

    /**
    * @description Gets a list of steps under a template
    * @author Brain Ezell (Simply EZ) | 5/12/2020
    * @param templateId
    * @return string
    **/
    @AuraEnabled
    public static string getTemplateSteps(String templateId, String stepId){

        try {


            Map<String, SimplyEzTasksResponse> mapResponses = new Map<String, SimplyEzTasksResponse>();

            //List of dependencies currently selected
            List<Task_Template_Step_Dependency__c> currentDependencies =
                [
                    SELECT 
                        Id, 
                        Step__c, 
                        Depends_On_Step__c,
                        Task_Template__r.Name,
                        Step__r.Parent_Task_Template__r.Name,
                        Depends_On_Step__r.Name
                    FROM Task_Template_Step_Dependency__c
                    WHERE Step__c = :stepId
                    WITH USER_MODE
                ];

            //List of steps currently available based on which template
            //is selected.
            //Update: Make sure to not include events since a "dependency"
            //on an event may not make sense.
            List<Task_Template_Step__c> templateSteps =
                [
                    SELECT Id, Name, Parent_Task_Template__r.Name
                    FROM Task_Template_Step__c
                    WHERE Parent_Task_Template__c = :templateId
                        AND Id != :stepId
                        AND Activity_Type__c != 'Event'
                    WITH USER_MODE
                    ORDER BY Name
                ];

            //Add the template steps first, so
            //if there are selected dependencies the
            //"IsDependency" doesn't get overwritten

            for(Task_Template_Step__c t : templateSteps) {
                mapResponses.put(t.Id,
                    new SimplyEzTasksResponse(
                        t.Parent_Task_Template__r.Name + ' - ' + t.Name,
                        t.Id,
                        false
                    )
                );
            }

            for(Task_Template_Step_Dependency__c d : currentDependencies) {
                mapResponses.put(d.Depends_On_Step__c,
                    new SimplyEzTasksResponse(
                        d.Step__r.Parent_Task_Template__r.Name + ' - ' + d.Depends_On_Step__r.Name,
                        d.Depends_On_Step__c,
                        true
                    )
                );
            }

            return JSON.serialize(mapResponses.values());
        } catch(Exception ex) {
            throw new AuraHandledException(CommonFunctions.getExceptionError(ex));
        }
    }

    /**
    * @description Gets dependencies this step already depends on.
    * @author Brain Ezell (Simply EZ) | 5/12/2020
    * @param stepId
    * @return String
    **/
    @AuraEnabled
    public static String getCurrentDependencies(string templateId, String stepId) {

        try {
            if(String.isBlank(templateId)) {
                throw new AuraHandledException('The template Id cannot be blank.');
            }

            if(String.isBlank(stepId)) {
                throw new AuraHandledException('The step Id cannot be blank.');
            }

            Task_Template_Step__c currentStep =
                [
                    SELECT Id, Name, Parent_Task_Template__c
                    FROM Task_Template_Step__c
                    WHERE Id = :stepId
                    WITH USER_MODE
                ];

            List<Task_Template_Step__c> allSteps =
                [
                    SELECT Id, Name, (
                        SELECT Id, Step__c, Depends_On_Step__c
                        FROM Task_Template_Step_Dependencies1__r
                        WHERE Step__c = :stepId
                    )
                    FROM Task_Template_Step__c
                    WHERE Parent_Task_Template__c = :currentStep.Parent_Task_Template__c
                        AND Id != :stepId
                    WITH USER_MODE
                ];

            List<SimplyEzTasksResponse> responses = new List<SimplyEzTasksResponse>();
            for(Task_Template_Step__c s : allSteps) {
                responses.add(new SimplyEzTasksResponse(
                    s.Name,
                    s.Id,
                    !s.Task_Template_Step_Dependencies1__r.isEmpty()
                ));
            }

            return Json.serialize(responses);
        } catch(Exception ex) {
            throw new AuraHandledException(CommonFunctions.getExceptionError(ex));
        }
    }

    /**
    * @description Updates the dependencies of this template step
    * @author Brain Ezell (Simply EZ) | 5/12/2020
    * @param stepId
    * @param options
    * @return void
    **/
    @AuraEnabled
    public static void updateDependencies(String stepId, List<String> options) {
        try {
            
            if(String.isBlank(stepId)) {
                throw new AuraHandledException('The step Id cannot be blank.');
            }
            List<Task_Template_Step_Dependency__c> currentDependencies =
                [
                    SELECT Id, Step__c, Depends_On_Step__c
                    FROM Task_Template_Step_Dependency__c
                    WHERE Step__c = :stepId
                    WITH USER_MODE
                ];

            Map<Id, Id> currentStepIds = new Map<Id, Id>();
            for(Task_Template_Step_Dependency__c d : currentDependencies) {
                currentStepIds.put(d.Depends_On_Step__c, d.Id);
            }
            Set<Id> currentOptionIds = new Set<Id>();
            for(String o : options) {
                currentOptionIds.add(o);
            }

            List<Task_Template_Step_Dependency__c> deleteRecords = new List<Task_Template_Step_Dependency__c>();
            List<Task_Template_Step_Dependency__c> createRecords = new List<Task_Template_Step_Dependency__c>();

            //Add steps not already in system
            for(Id o : currentOptionIds) {
                if(!currentStepIds.containsKey(o)) {
                    createRecords.add(new Task_Template_Step_Dependency__c(
                        Step__c = stepId,
                        Depends_On_Step__c = o
                    ));
                }
            }

            //Remove steps that are in the system
            for(Id s : currentStepIds.keySet()) {
                if(!currentOptionIds.contains(s)) {
                    deleteRecords.add(new Task_Template_Step_Dependency__c (
                        Id = currentStepIds.get(s)
                    ));
                }
            }

            delete as user deleteRecords;

            insert as user createRecords;
            
        } catch(Exception ex) {
            throw new AuraHandledException(CommonFunctions.getExceptionError(ex));
        }
    }

    /**
    * @description Gets all templates associated with this
    * @author Brain Ezell (Simply EZ) | 5/12/2020
    * @param templateStepId
    * @return string
    **/
    @AuraEnabled
    public static string getTemplateList(string templateStepId){
        try {

            if(String.isBlank(templateStepId)) {
                throw new AuraHandledException('Step Id cannot be blank.');
            }

            Task_Template_Step__c templateStep =
                [
                    SELECT Id, Parent_Task_Template__r.Master_Task_Template__r.Task_Template__c
                    FROM Task_Template_Step__c
                    WHERE Id = :templateStepId
                    WITH USER_MODE
                ];

            List<Task_Template__c> templates =
                [
                    SELECT Id, Name
                    FROM Task_Template__c
                    WHERE Master_Task_Template__c = :templateStep.Parent_Task_Template__r.Master_Task_Template__c
                    WITH USER_MODE
                    ORDER BY Name
                ];
            return Json.serialize(templates);

        } catch(Exception ex) {
            throw new AuraHandledException(CommonFunctions.getExceptionError(ex));
        }
    }


    public class SimplyEzTasksResponse {
        public SimplyEzTasksResponse(String lbl, String val, Boolean dep) {
            label = lbl;
            value = val;
            isDependency = dep;
        }

        public String label;
        public String value;
        public Boolean isDependency;
    }

}