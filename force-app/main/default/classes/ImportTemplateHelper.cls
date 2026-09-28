/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 08-12-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
public with sharing class ImportTemplateHelper {

    private List<Task_Template__c> oldTemplates;
    private Master_Task_Template__c newMasterCase;

    //private Map<Id, Task_Template__c> mapTemplateIdToTemplate = new Map<Id, Task_Template__c>();
    private Map<Id, Task_Template__c> mapOldTemplateIdToNewTemplate = new Map<Id, Task_Template__c>();
    private Map<Id, Task_Template_Step__c> mapOldStepIdToNewStep = new Map<Id, Task_Template_Step__c>();
    private Map<Id, Task_Template_Step_Dependency__c> mapOldDependsIdToNewDependency = new Map<Id, Task_Template_Step_Dependency__c>();

    /**
    * @description Takes a JSON version of templates and imports them into the system.
    * @author Brian Ezell (Simply EZ) | 09-08-2024 
    * @param jsonTemplates 
    **/
    public Id importJsonTemplates(String jsonTemplates) {
        oldTemplates = (List<Task_Template__c>)JSON.deserialize(jsonTemplates, List<Task_Template__c>.class);
        newMasterCase = new Master_Task_Template__c();
        insert as user newMasterCase;

        insertTemplates();
        insertSteps();
        insertDependencies();

        return newMasterCase.Id;
    }

    /**
    * @description Creates the new templates
    * @author Brian Ezell (Simply EZ) | 09-08-2024 
    **/
    private void insertTemplates() {

        for(Task_Template__c t : oldTemplates) {
            Task_Template__c newTemp = new Task_Template__c (
                Name = t.Name,
                Master_Task_Template__c = newMasterCase.Id,
                Assigned_Type__c = t.Assigned_Type__c,
                Is_Active__c = true,
                //Templated_Objects__c = t.Templated_Objects__c,
                Level__c = t.Level__c
            );
            mapOldTemplateIdToNewTemplate.put(t.Id, newTemp);

            for(Task_Template_Step__c s : t.Parent_Task_Template_Steps__r) {
                Task_Template_Step__c newStep = new Task_Template_Step__c (
                    Name = s.Name,
                    Activity_Type__c = s.Activity_Type__c,
                    Assigned_Type__c = s.Assigned_Type__c,
                    Description__c = s.Description__c,
                    Duration_In_Days__c = s.Duration_In_Days__c,
                    Order__c = s.Order__c,
                    Templated_Name__c = s.Templated_Name__c
                );
                mapOldStepIdToNewStep.put(s.Id, newStep);
            }
        }

        insert as user mapOldTemplateIdToNewTemplate.values();

    }

    /**
    * @description Creates the new template steps
    * @author Brian Ezell (Simply EZ) | 09-08-2024 
    **/
    private void insertSteps() {
        for(Task_Template__c t : oldTemplates) {

            Task_Template__c newTemplate = mapOldTemplateIdToNewTemplate.get(t.Id);

            if(t.Parent_Template__c != null) {
                newTemplate.Parent_Template__c = mapOldTemplateIdToNewTemplate.get(t.Parent_Template__c).Id;
            }

            for(Task_Template_Step__c s : t.Parent_Task_Template_Steps__r) {
                Task_Template_Step__c newStep = new Task_Template_Step__c (
                    Name = s.Name,
                    Activity_Type__c = s.Activity_Type__c,
                    Assigned_Type__c = s.Assigned_Type__c,
                    Description__c = s.Description__c,
                    Duration_In_Days__c = s.Duration_In_Days__c,
                    Order__c = s.Order__c,
                    Templated_Name__c = s.Templated_Name__c,
                    Parent_Task_Template__c = newTemplate.Id
                );
                mapOldStepIdToNewStep.put(s.Id, newStep);
            }
        }
        
        update as user mapOldTemplateIdToNewTemplate.values();
    }

    private void insertDependencies() {
        List<Task_Template_Step_Dependency__c> dependencies = new List<Task_Template_Step_Dependency__c>();
        for(Task_Template__c t : oldTemplates) {
            Task_Template__c newTemplate = mapOldTemplateIdToNewTemplate.get(t.Id);

            for(Task_Template_Step_Dependency__c dep : t.Task_Template_Step_Dependencies__r) {
                Task_Template_Step_Dependency__c newDepends = new Task_Template_Step_Dependency__c (
                    Depends_On_Step__c = mapOldStepIdToNewStep.get(dep.Depends_On_Step__c).Id,
                    Step__c = mapOldStepIdToNewStep.get(dep.Step__c).Id,
                    Description__c = dep.Description__c,
                    Task_Template__c = mapOldTemplateIdToNewTemplate.get(dep.Task_Template__c).Id
                );
                dependencies.add(newDepends);
            }
        }

        insert as user dependencies;
    }
    
}