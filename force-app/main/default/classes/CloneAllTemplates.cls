/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 08-12-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
public with sharing class CloneAllTemplates {

    //Maps Ids for template, steps and dependencies
    private Map<Id, Task_Template__c> mapOldTemplateIdToNewTemplate = new Map<Id, Task_Template__c>();
    private Map<Id, Task_Template_Step__c> mapOldStepIdToNewStep = new Map<Id, Task_Template_Step__c>();
    private Map<Id, Task_Template_Step_Dependency__c> mapOldDependencyIdToNewDependency = new Map<Id, Task_Template_Step_Dependency__c>();

    private Map<Id, Task_Template__c> mapOldTemplateIdToOldTemplate = new Map<Id, Task_Template__c>();
    private List<Task_Template_Step__c> oldSteps = new List<Task_Template_Step__c>();
    private List<Task_Template_Step_Dependency__c> oldDependencies = new List<Task_Template_Step_Dependency__c>();
    private Master_Task_Template__c newMaster;

    private Task_Template__c oldTopLevelTemplate;
    private Task_Template__c newTopLevelTemplate;

    /**
    * @description Takes master template and the templates associated with it
    *   and create a clone with the new template name.
    * @author Brian Ezell (Simply EZ) | 07-08-2024 
    * @param templateId 
    **/
    public CloneAllTemplates(String templateId) {

        if(String.isBlank(templateId)) {
            throw new DmlException('You must provide a template id.');
        }

        loadTemplateData(templateId);
        
    }

    /**
    * @description Creates the cloned templates and returns the top level new template id
    * @author Brian Ezell (Simply EZ) | 06-01-2024 
    * @return Id 
    **/
    public Id cloneTemplate(String newName) {

        //Create the new templates and link them.
        createTemplates(newName);

        //Update the master with the new top level template.
        newTopLevelTemplate = mapOldTemplateIdToNewTemplate.get(oldTopLevelTemplate.Id);
        newMaster.Task_Template__c = mapOldTemplateIdToNewTemplate.get(oldTopLevelTemplate.Id).Id;

        update as user newMaster;

        //Make sure to parent the new templates.
        updateNewTemplateParents(newName);

        createTemplateSteps();
        createStepDependencies();

        return newMaster.Task_Template__c;
    }

    private void loadTemplateData(String templateId) {
        //First make the new Master Template
        newMaster = new Master_Task_Template__c();
        insert as user newMaster;

        Task_Template__c currentTemplate = 
            [
                SELECT Id, Master_Task_Template__c
                FROM Task_Template__c
                WHERE Id = :templateId
                WITH USER_MODE
            ];

       mapOldTemplateIdToOldTemplate = new Map<Id, Task_Template__c> (
            [
                SELECT Id, Name, 
                    Master_Task_Template__c,
                    Assigned_To_Name__c,
                    Assigned_Type__c,
                    Assignee_Id__c,
                    Case_Record_Type__c,
                    Case_Type__c,
                    Is_Active__c,
                    Templated_Object__c,
                    Parent_Template__c,
                    Record_Owner__c,
                    Level__c,
                    Templated_Name__c,
                    Is_Master_Template__c,
                    (
                        SELECT Id, Name, 
                            Step__c, 
                            Depends_On_Step__c,
                            Task_Template__c,
                            Description__c
                        FROM Task_Template_Step_Dependencies__r
                    ),
                    (
                        SELECT Id, Name, 
                            Master_Task_Template__c,
                            Assigned_To_Name__c,
                            Assigned_Type__c,
                            Assignee_Id__c,
                            Case_Record_Type__c,
                            Case_Type__c,
                            Is_Active__c,
                            Templated_Object__c,
                            Parent_Template__c,
                            Record_Owner__c,
                            Level__c,
                            Templated_Name__c
                        FROM Task_Templates__r
                    ),
                    (
                        SELECT Id, Name,
                            Activity_Type__c,
                            Assigned_To_Name__c,
                            Assigned_Type__c,
                            Assignee_Id__c,
                            Description__c,
                            Duration_In_Days__c,
                            Order__c,
                            Parent_Task_Template__c,
                            Template_Master__c,
                            Templated_Name__c
                        FROM Parent_Task_Template_Steps__r
                    )
                FROM Task_Template__c
                WHERE Master_Task_Template__c = :currentTemplate.Master_Task_Template__c
                WITH USER_MODE
                ORDER BY Level__c DESC
            ]);

        //Find the top level template
        for(Task_Template__c temp : mapOldTemplateIdToOldTemplate.values()) {
            if(temp.Is_Master_Template__c) {
                this.oldTopLevelTemplate = temp;
                break;
            }
        }
    }
    
    private void createStepDependencies() {
        for(Task_Template__c t : mapOldTemplateIdToOldTemplate.values()) {
            for(Task_Template_Step_Dependency__c d : t.Task_Template_Step_Dependencies__r) {
                Task_Template_Step_Dependency__c newDependency = createCloneOfDependency(d);
                mapOldDependencyIdToNewDependency.put(d.Id, newDependency);
            }
        }
        insert as user mapOldDependencyIdToNewDependency.values();

    }

    /**
    * @description Assigns the parent to the new templates
    * @author Brian Ezell (Simply EZ) | 07-08-2024 
    * @param newName 
    **/
    private void updateNewTemplateParents(String newName) {

        if(newName == null) {
            throw new DmlException('You must provide a new name.');
        }

        List<Task_Template__c> updateTemplates = new List<Task_Template__c>();

        for(Id tId : mapOldTemplateIdToOldTemplate.keySet()) {
            Task_Template__c oldTemplate = mapOldTemplateIdToOldTemplate.get(tId);
            Task_Template__c newTemplate = mapOldTemplateIdToNewTemplate.get(tId);
            
            if(oldTemplate.Parent_Template__c != null) {

                updateTemplates.add(new Task_Template__c (
                    Id = newTemplate.Id,
                    Parent_Template__c = mapOldTemplateIdToNewTemplate.get(oldTemplate.Parent_Template__c).Id
                ));
            } else {

                //Top level - just make sure to set the new name
                updateTemplates.add(new Task_Template__c (
                    Id = newTemplate.Id,
                    Parent_Template__c = null,
                    Name = newName
                ));
            }
        }
        update as user updateTemplates;
    }

    /**
    * @description Creates the template steps
    * @author Brian Ezell (Simply EZ) | 06-01-2024 
    **/
    private void createTemplateSteps() {
        for(Task_Template__c t : mapOldTemplateIdToOldTemplate.values()) {
            for(Task_Template_Step__c s : t.Parent_Task_Template_Steps__r) {
                Task_Template_Step__c newStep = createCloneOfOneStep(s);
                mapOldStepIdToNewStep.put(s.Id, newStep);
            }
        }
        insert as user mapOldStepIdToNewStep.values();
        
    }

    /**
    * @description Creates a new set of templates based on the old 
    * template and related objects.
    * @author Brian Ezell (SimplyEZ) | 08-13-2024 
    * @param newName 
    **/
    private void createTemplates(String newName) {
        if(newName == null) {
            throw new DmlException('You must provide a new name.');
        }
        
        //Create a copy of each template 

        for(Task_Template__c t : mapOldTemplateIdToOldTemplate.values()) {
            Task_Template__c newTemplate = createCloneOfOneTemplate(t);
            if(t.Parent_Template__c == null) {
                newTemplate.Name = newName;
            }
            mapOldTemplateIdToNewTemplate.put(t.Id, newTemplate);
        }

        insert as user mapOldTemplateIdToNewTemplate.values();

        //Establish the parent of each template
        linkNewTemplates();
    }

    
    /**
    * @description Now that the new templates are created, link them to the parent
    * @author Brian Ezell (Simply EZ) | 06-01-2024 
    **/
    private void linkNewTemplates() {

        //Go through each newly created template and link to the parent
        for(Id id : mapOldTemplateIdToOldTemplate.keySet()) {
            Task_Template__c oldTemplate = mapOldTemplateIdToOldTemplate.get(id);
            Task_Template__c newTemplate = mapOldTemplateIdToNewTemplate.get(id);
            if(oldTemplate.Parent_Template__c != null) {
                newTemplate.Parent_Template__c = mapOldTemplateIdToNewTemplate.get(oldTemplate.Parent_Template__c).Id;
            }
        }
        update as user mapOldTemplateIdToNewTemplate.values();  
    }

    /**
    * @description Creates a copy of the template
    * @author Brian Ezell (Simply EZ) | 06-01-2024 
    * @param template 
    * @return Task_Template__c 
    **/
    private Task_Template__c createCloneOfOneTemplate(Task_Template__c template) {
        Task_Template__c newTemplate = new Task_Template__c(
            Name = template.Name,
            Templated_Name__c = template.Templated_Name__c,
            Master_Task_Template__c  = newMaster.Id,
            Assigned_To_Name__c = template.Assigned_To_Name__c,
            Assigned_Type__c = template.Assigned_Type__c,
            Assignee_Id__c = template.Assignee_Id__c,
            Case_Record_Type__c = template.Case_Record_Type__c,
            Case_Type__c = template.Case_Type__c,
            Is_Active__c = true,
            Templated_Object__c = template.Templated_Object__c,
            Parent_Template__c = null,
            Record_Owner__c = template.Record_Owner__c,
            Level__c = template.Level__c
        );
        return newTemplate;
    }


    /**
    * @description Creates a copy of the step
    * @author Brian Ezell (Simply EZ) | 06-01-2024 
    * @param step 
    * @return Task_Template_Step__c 
    **/
    private Task_Template_Step__c createCloneOfOneStep(Task_Template_Step__c step) {
        String templateName = step.Name + '-Clone';

        Task_Template_Step__c newTemplateStep = new Task_Template_Step__c(
            Name = templateName.left(50),
            Activity_Type__c = step.Activity_Type__c,
            Assigned_To_Name__c = step.Assigned_To_Name__c,
            Assigned_Type__c = step.Assigned_Type__c,
            Assignee_Id__c = step.Assignee_Id__c,
            Description__c = step.Description__c,
            Duration_In_Days__c = step.Duration_In_Days__c,
            Order__c = step.Order__c,
            Parent_Task_Template__c = mapOldTemplateIdToNewTemplate.get(step.Parent_Task_Template__c).Id,
            Templated_Name__c = step.Templated_Name__c
        );
        return newTemplateStep;
    }

    /**
    * @description Creates a copy of the dependency
    * @author Brian Ezell (Simply EZ) | 06-01-2024 
    * @param dependency 
    * @return Task_Template_Step_Dependency__c 
    **/
    private Task_Template_Step_Dependency__c createCloneOfDependency(Task_Template_Step_Dependency__c dependency) {
        Task_Template_Step_Dependency__c newDependency = new Task_Template_Step_Dependency__c(
            Step__c = mapOldStepIdToNewStep.get(dependency.Step__c).Id,
            Depends_On_Step__c = mapOldStepIdToNewStep.get(dependency.Depends_On_Step__c).Id,
            Task_Template__c = mapOldTemplateIdToNewTemplate.get(dependency.Task_Template__c).Id,
            Description__c = dependency.Description__c
        );
        return newDependency;
    }
    
}