/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 08-12-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
public with sharing class CreateProcessHelper {

    //Allows for different versions of this request to be passed in.  The one allows for just certain templates
    //to be selected, and the other is everything under the master template.
    private CreateCaseRequestBase request;

    private Map<Id, Task_Template__c> mapTemplateIdToTemplate = new Map<Id, Task_Template__c>();
    private Map<Id, Case> mapAllTemplateIdsToCases = new Map<Id, Case>();
    private Map<Id, SObject> mapTemplateStepIdToStep = new Map<Id, SObject>();
    private Map<Id, Integer> mapStepIdToDependencyCount = new Map<Id, Integer>();

    private Master_Case__c masterCase;
    private Case topLevelCase;
    private SObject currentObject;
    private String objectApiName;
    private String objectName;
    private Task_Template__c topLevelTemplate;

    /**
    * @description Setup the data for creating the cases from the templates
    * @author Brian Ezell (Simply EZ) | 07-24-2024 
    **/
    public CreateProcessHelper(CreateCaseRequestBase request) {
        this.request = request;
        this.currentObject = request.getSObject();
        this.objectApiName = request.objectApiName;
        String mainFieldName = CommonFunctions.getObjectMainField(request.objectApiName);

        System.debug(this.currentObject);

        this.objectName = this.currentObject.get(mainFieldName) == null ? '' : this.currentObject.get(mainFieldName).toString();
        mapTemplateIdToTemplate = request.getTemplatesMap();

        //Figure out which template is the top of the chain
        for(Task_Template__c template : mapTemplateIdToTemplate.values()) {
            if(template.Is_Master_Template__c) {
                this.topLevelTemplate = template;
                break;
            }
        }
        
        mapAllTemplateIdsToCases = new Map<Id, Case>();
        mapTemplateStepIdToStep = new Map<Id, SObject>();

        loadTemplateMap();
        createDependencyCounts();
    }

    /**
    * @description Creates the cases/tasks/events from the template and template steps
    * @author Brian Ezell (Simply EZ) | 07-24-2024 
    **/
    public void createCases() {
        createMasterCase();
        createCasesFromTemplates();
        updateCaseParents();
        createCaseSteps();
        createStepDependencies();
    }

    /**
    * @description Gets the top level case id
    * @author Brian Ezell (Simply EZ) | 10-03-2024 
    * @return Id 
    **/
    public Id getTopLevelCaseId() {
        return this.topLevelCase.Id;
    }

    /**
    * @description Gets the id of the master case object
    * @author Brian Ezell (Simply EZ) | 10-03-2024 
    * @return Id 
    **/
    public Id getMasterCaseId() {
        return this.masterCase.Id;
    }


    /**
    * @description Used in constructor:
    *   Loads up a map of template ids and step ids to corresponding maps.
    * @author Brian Ezell (Simply EZ) | 07-29-2024 
    **/
    private void loadTemplateMap() {
        //Load up the template maps
        for(Task_Template__c template : mapTemplateIdToTemplate.values()) {
            for(Task_Template_Step__c step : template.Parent_Task_Template_Steps__r) {
                mapTemplateStepIdToStep.put(step.Id, null);
                mapStepIdToDependencyCount.put(step.Id, 0);
            }
        }
    }

    /**
    * @description Creates a map of step dependencies.  Assumed mapStepIdToDependencyCount has been populated.
    * @author Brian Ezell (Simply EZ) | 07-29-2024 
    **/
    private void createDependencyCounts() {
        List<AggregateResult> dependencyCounts = 
            [
                SELECT Step__c, COUNT(Depends_On_Step__c) DependentCount
                FROM Task_Template_Step_Dependency__c
                WHERE Step__c = :this.mapStepIdToDependencyCount.keySet()
                WITH SYSTEM_MODE
                GROUP BY Step__c
            ];
        for(AggregateResult dep : dependencyCounts) {
            Id stepId = Id.valueOf(dep.get('Step__c')?.toString());
            this.mapStepIdToDependencyCount.put(stepId, Integer.valueOf(dep.get('DependentCount').toString()));
        }
    }

    /**
    * @description Add step dependencies between case tasks
    * @author Brian Ezell (Simply EZ) | 07-29-2024 
    **/
    private void createStepDependencies() {

        List<Task_Dependency__c> newDependencies = new List<Task_Dependency__c>();

        for(Task_Template__c template : mapTemplateIdToTemplate.values()) {
            Case c = this.mapAllTemplateIdsToCases.get(template.Id);

            for(Task_Template_Step_Dependency__c dep : template.Task_Template_Step_Dependencies__r) {

                Id taskId = this.mapTemplateStepIdToStep.get(dep.Step__c).Id;
                Id dependsOnTaskId = this.mapTemplateStepIdToStep.get(dep.Depends_On_Step__c).Id;

                Task_Dependency__c newDependency = new Task_Dependency__c (
                    Case__c = c.Id,
                    Task_Template_Step__c = dep.Id,
                    Task_Depends_On_Id__c = dependsOnTaskId,
                    Task_Id__c = taskId
                );
                newDependencies.add(newDependency);
            }
        }

        insert as user newDependencies;
    }

    /**
    * @description Creates the steps for the templates to cases
    * @author Brian Ezell (Simply EZ) | 07-29-2024 
    **/
    private void createCaseSteps() {

        List<Task> newTasks = new List<Task>();
        List<Event> newEvents = new List<Event>();

        for(Task_Template__c template : mapTemplateIdToTemplate.values()) {
            Id caseId = mapAllTemplateIdsToCases.get(template.Id).Id;
            for(Task_Template_Step__c step : template.Parent_Task_Template_Steps__r) {
                SObject newTemplateStep = createStep(step, caseId, template);
                this.mapTemplateStepIdToStep.put(step.Id, newTemplateStep);

                if(newTemplateStep.getSObjectType().getDescribe().getName() == 'Task') {
                    newTasks.add((Task)newTemplateStep);
                } else {
                    newEvents.add((Event)newTemplateStep);
                }
            }
        }

        addTasks(newTasks);
        addEvents(newEvents);
    }

    /**
    * @description Adds new tasks to system.  Checks in place for security and size
    * @author Brian Ezell (Simply EZ) | 08-07-2025 
    * @param newTasks 
    **/
    private void addTasks(List<Task> newTasks) {
        if(newTasks.size() > 0) {
            insert as user newTasks;
        }
    }

    /**
    * @description Adds new events to system.  Checks in place for security and size
    * @author Brian Ezell (Simply EZ) | 08-07-2025 
    * @param newEvents 
    **/
    private void addEvents(List<Event> newEvents) {
        if(newEvents.size() > 0) {
            insert as user newEvents;
        }
    }

    /**
    * @description Creates an SObject step from the task template step object
    * @author Brian Ezell (Simply EZ) | 10-03-2024 
    * @param step 
    * @param caseId 
    * @param template 
    * @return SObject 
    **/
    private SObject createStep(Task_Template_Step__c step, Id caseId, Task_Template__c template) {
        
        //The dependency count is used to count down the number of
        //dependent tasks this task is waiting on.  When it gets to 0
        //then this task gets set to "Not Started" and the Activity
        //Date is set from that point.
        Integer dependentCount = mapStepIdToDependencyCount.get(step.Id);
        String taskSubject = step.Templated_Name__c == null ? step.Name :
        step.Templated_Name__c?.Replace('[Name]', this.objectName)?.Replace('[StepOrder]',
        step.Order__c == null ? 
            '' : 
            string.valueOf(step.Order__c));

        if(step.Activity_Type__c == 'Task') {
            return new Task(
                ActivityDate = dependentCount > 0 ? null :
                    step.Duration_In_Days__c == null ? null :
                    Date.today() + (Integer)step.Duration_In_Days__c,
                OwnerId = getOwnerIdFromTemplateStep(step, template, this.currentObject),
                WhatId = caseId,
                Is_Simply_Tasks_Created__c = true,
                Subject = taskSubject,
                Task_Template_Step__c = step.Id,
                Dependent_Tasks_To_Complete__c = dependentCount,
                Status = dependentCount == 0 ? 
                    Constants.TASK_START_STATUS : 
                    Constants.TASK_PENDING_STATUS
            );
        } else {
            return new Event(
                ActivityDate = //dependentCount > 0 ? Date.today() :
                    step.Duration_In_Days__c == null ? Date.today() :
                    Date.today() + (Integer)step.Duration_In_Days__c,
                OwnerId = getOwnerIdFromTemplateStep(step, template, this.currentObject),
                WhatId = caseId,
                Is_Simply_Tasks_Created__c = true,
                Subject = taskSubject,
                Task_Template_Step__c = step.Id,
                Dependent_Tasks_To_Complete__c = dependentCount,
                Type = 'Meeting',
                IsAllDayEvent = true
            );
        }
    }


    /**
    * @description Fills in the mapAllTemplateIdsToCases with the new cases. 
    * @author Brian Ezell (Simply EZ) | 07-29-2024 
    **/
    private void createCasesFromTemplates() {

        String mainFieldName = CommonFunctions.getObjectMainField(objectApiName);
        String objectRecordName = String.valueOf(this.currentObject?.get(mainFieldName));

        for(Task_Template__c template : mapTemplateIdToTemplate.values()) {

            //Allow templating names for dynamic creation
            String caseTemplatedName = 
                template.Templated_Name__c == null ?
                template.Name : 
                template.Templated_Name__c.replace('[Name]', objectRecordName);

            Case newCase = new Case (
                Task_Template__c = template.Id,
                ContactId = this.request.objectApiName == 'Contact' ? this.currentObject.Id : null,
                AccountId = this.request.objectApiName == 'Account' ? this.currentObject.Id :
                    this.request.objectApiName == 'Opportunity' ? 
                        String.valueOf(this.currentObject.get('AccountId')) :
                        null,
                OwnerId = getOwnerIdFromTemplate(template, this.currentObject),
                Number_of_Tasks_To_Complete__c = template.Total_Number_Of_Steps__c,
                Number_of_Tasks_Completed__c = 0,
                Subject = caseTemplatedName,
                Master_Case__c = masterCase.Id,
                RecordTypeId = Constants.SIMPLY_TASK_CASE_RECORD_TYPE_ID,
                Level__c = template.Level__c
            );
            this.mapAllTemplateIdsToCases.put(template.Id, newCase);
        }


        addCases(this.mapAllTemplateIdsToCases.values());

        this.topLevelCase = mapAllTemplateIdsToCases.get(this.topLevelTemplate.Id);
        this.masterCase.Case__c = this.topLevelCase.Id;
        update as user this.masterCase;
    }


    /**
    * @description 
    * @author Brian Ezell (Simply EZ) | 08-07-2025 
    * @param newCases 
    **/
    private void addCases(List<Case> newCases) {
        if(newCases.size() > 0) {
            insert as user newCases;
        }
    }

    /**
    * @description Update the parent case ids
    * @author Brian Ezell (Simply EZ) | 07-30-2024 
    **/
    private void updateCaseParents() {

        Integer count = 0;

        for(Task_Template__c template : mapTemplateIdToTemplate.values()) {
            
            //If it has a parent, lookup the parent template
            if(template.Parent_Template__c != null) {
                Case parentCase = this.mapAllTemplateIdsToCases.get(template.Parent_Template__c);
                this.mapAllTemplateIdsToCases.get(template.Id).ParentId = parentCase.Id;
                count++;
            }
        }
        
        update as user this.mapAllTemplateIdsToCases.values();
    
    }


    /**
    * @description Generates the master case objects mapped from the template ids
    * @author Brian Ezell (Simply EZ) | 07-24-2024 
    **/
    private void createMasterCase() {
        Master_Case__c newMasterCase = new Master_Case__c();
        insert as user newMasterCase;
        this.masterCase = newMasterCase;
    }
    
   /**
   * @description Returns who the owner should be based on the template
   * @author Brian Ezell (Simply EZ) | 07-29-2024 
   * @param template 
   * @param targetObject 
   * @return Id 
   **/
   private static Id getOwnerIdFromTemplate(Task_Template__c template, SObject targetObject) {

        if(template.Assigned_Type__c == 'Object Owner') {
            return (Id)(targetObject.get('OwnerId'));
        }

        if(template.Assigned_Type__c == 'Specific User' && template.Assignee_Id__c != null) {
            return template.Assignee_Id__c;
        }

        return UserInfo.getUserId();
    }

    /**
    * @description Returns the owner from the template step.
    * @author Brian Ezell (Simply EZ) | 07-29-2024 
    * @param step 
    * @param template 
    * @param targetObject 
    * @return Id 
    **/
    private static Id getOwnerIdFromTemplateStep(Task_Template_Step__c step, Task_Template__c template, SObject targetObject) {
        if(step.Assigned_Type__c == 'Specific User' && step.Assignee_Id__c != null) {
            return step.Assignee_Id__c;
        }

        if(step.Assigned_Type__c == 'Case Owner') {
            return getOwnerIdFromTemplate(template, targetObject);
        }

        return UserInfo.getUserId();
    }

    public virtual class CreateCaseRequestBase {
        public String objectApiName;
        public String objectId;
        public String templateId;

       /**
       * @description Gets the SObject associated with this request
       * @author Brian Ezell (Simply EZ) | 07-24-2024 
       * @return SObject 
       **/
       public virtual SObject getSObject() {

            List<SObject> objList = new List<SObject>();
            Id thisId = objectId;
            List<String> mainFields = CommonFunctions.getObjectMainFieldList(objectApiName);
            String fieldsToQuery = String.join(mainFields, ', ');
            String sql = String.format('SELECT {0} FROM {1} WHERE Id = :objectId WITH USER_MODE',
                new List<String> {
                    fieldsToQuery,
                    objectApiName
                });

            objList = Database.query(String.escapeSingleQuotes(sql));
            return objList.size() == 0 ? null : objList[0];
        }

        public virtual Map<Id, Task_Template__c> getTemplatesMap() {
            return new Map<Id, Task_Template__c>();
        }

    }


    //Creates an container for creating a task template case list from a template and object
    public class CreateCaseRequest extends CreateCaseRequestBase {

        /**
        * @description Gets a map of the template Id to the template all associated with the templates
        *   used with this template.
        * @author Brian Ezell (Simply EZ) | 07-24-2024 
        * @return Map<Id, Task_Template__c> 
        **/
        public override Map<Id, Task_Template__c> getTemplatesMap() {

            System.debug('***STARTING CreateCaseRequest.getTemplatesMap***');
            System.debug('This =  ' + this);
            System.debug('templateId = ' + templateId);
            System.debug('objectApiName = ' + objectApiName);   

            Task_Template__c template = 
                [
                    SELECT Id, Master_Task_Template__c
                    FROM Task_Template__c
                    WHERE Id = :templateId
                    WITH USER_MODE
                ];

            return
                new Map<Id, Task_Template__c> (
                [
                    SELECT Id, Name, Is_Active__c, Total_Number_Of_Steps__c, Parent_Template__r.Name, 
                        Templated_Name__c, Is_Master_Template__c, Parent_Template__c,
                        Assignee_Id__c, Assigned_Type__c, Level__c,
                        (
                            SELECT Id, Name, Description__c, Assignee_Id__c, Assigned_Type__c,
                                Templated_Name__c, Duration_In_Days__c, Order__c, 
                                Activity_Type__c
                            FROM Parent_Task_Template_Steps__r
                            ORDER BY Order__c, Templated_Name__c
                        ),
                        (
                            SELECT Id, Depends_On_Step__c, Step__c, Task_Template__c
                            FROM Task_Template_Step_Dependencies__r
                        )
                    FROM Task_Template__c
                    WHERE Master_Task_Template__c = :template.Master_Task_Template__c
                        AND Is_Active__c = true
                    WITH USER_MODE
                ]);
        }

    }


    //Creates an container for creating a task template case list from a template and object
    public class CreateCaseWithHierarchyRequest extends CreateCaseRequestBase {
        public List<Id> selectedTemplateIds;

        /**
        * @description Gets a map of the template Id to the template all associated with the templates
        *   used with this template.
        * @author Brian Ezell (Simply EZ) | 07-24-2024 
        * @return Map<Id, Task_Template__c> 
        **/
        public override Map<Id, Task_Template__c> getTemplatesMap() {

            System.debug('***STARTING CreateCaseWithHierarchyRequest.getTemplatesMap***');
            System.debug('This =  ' + this);
            System.debug('templateId = ' + templateId);
            System.debug('objectApiName = ' + objectApiName);  


            Task_Template__c template = 
                [
                    SELECT Id, Master_Task_Template__c
                    FROM Task_Template__c
                    WHERE Id = :selectedTemplateIds
                    WITH USER_MODE
                    LIMIT 1
                ];

            return
                new Map<Id, Task_Template__c> (
                [
                    SELECT Id, Name, Is_Active__c, Total_Number_Of_Steps__c, Parent_Template__r.Name, 
                        Templated_Name__c, Is_Master_Template__c, Parent_Template__c,
                        Assignee_Id__c, Assigned_Type__c, Level__c,
                        (
                            SELECT Id, Name, Description__c, Assignee_Id__c, Assigned_Type__c,
                                Templated_Name__c, Duration_In_Days__c, Order__c, 
                                Activity_Type__c
                            FROM Parent_Task_Template_Steps__r
                            ORDER BY Order__c, Templated_Name__c
                        ),
                        (
                            SELECT Id, Depends_On_Step__c, Step__c, Task_Template__c
                            FROM Task_Template_Step_Dependencies__r
                        )
                    FROM Task_Template__c
                    WHERE Master_Task_Template__c = :template.Master_Task_Template__c
                        AND Id IN :selectedTemplateIds
                        AND Is_Active__c = true
                    WITH USER_MODE
                ]);
        }

    }


}