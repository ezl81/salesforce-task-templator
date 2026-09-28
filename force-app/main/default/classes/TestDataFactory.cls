/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 06-16-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
@IsTest
public with sharing class TestDataFactory {

    public static final List<String> SIMPLY_TASKS_ADMIN_PERMISSION_SET = new List<String> { 'Simply_Tasks_Administrator' };
    public static final List<String> SIMPLY_TASKS_USER_PERMISSION_SET = new List<String> { 'Simply_Tasks_User' };

    public static User createUserWithPermissionSets(List<String> permissionSetList, String profile) {

        String userProfile = String.isBlank(profile) ? 
            Constants.STANDARD_USER_PROFILE_NAME :
            profile;
        Profile p = 
            [
                SELECT Id 
                FROM Profile 
                WHERE Name = :userProfile
            ]; 

        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        String uid = h.SubString(0,8);
        String userName = uid + '@simply-tasks.com';

        User u = new User
            (
                Alias = 'standt', 
                Email = 'thisisrandom@iamnowhererandomly.com', 
                EmailEncodingKey = 'UTF-8', 
                LastName = 'Testing', 
                LanguageLocaleKey = 'en_US', 
                LocaleSidKey = 'en_US', 
                ProfileId = p.Id, 
                TimeZoneSidKey = 'America/Los_Angeles', 
                UserName = userName
            );
        insert u;
        List<PermissionSet> permissionSets = 
            [
                SELECT Id
                FROM PermissionSet
                WHERE Name = :permissionSetList
            ];
        List<PermissionSetAssignment> permissionSetAssignments = new List<PermissionSetAssignment>();
        for(PermissionSet ps : permissionSets) {
            permissionSetAssignments.add(new permissionSetAssignment (
                PermissionSetId = ps.Id,
                AssigneeId = u.Id
            ));
        }
        if(permissionSetAssignments.size() > 0) {
            insert permissionSetAssignments;
        }
        return u;

    }

    public static TestDataFactoryData createAllTestData(String objectApiName) {
        TestDataFactoryData factoryData = new TestDataFactoryData();
        factoryData.thisTemplate = createAllTemplatesAndSteps();
        factoryData.thisObject = getSObject(objectApiName);
        //factoryData.thisTemplate.Templated_Object__c = objectApiName;
        return factoryData;
    }

    public static void createCaseFromTemplate(TestDataFactoryData testData) {
        CreateProcessHelper.CreateCaseRequest request = new CreateProcessHelper.CreateCaseRequest();
        request.templateId = testData.thisTemplate.Id;
        request.objectApiName = testData.thisObject.getSObjectType().getDescribe().getName();
        request.objectId = testData.thisObject.Id;
        CreateProcessHelper processHelper = new CreateProcessHelper(request);
        processHelper.createCases();
    }

    public static Integer completeSomeTasks() {

        //Need to avoid dependent tasks taht can't be completed yet.
        List<Task_Dependency__c> dependencies = 
            [
                SELECT Id, Task_Depends_On_Id__c, Task_Id__c
                FROM Task_Dependency__c
            ];

        Set<Id> excludeIds = new Set<Id>();
        for(Task_Dependency__c d : dependencies) {
            excludeIds.add(d.Task_Id__c);
        }

        List<Task> someTasks = 
            [
                SELECT Id, Subject, Status
                FROM Task
                WHERE Id NOT IN :excludeIds
            ];

        for(Task t : someTasks) {
            t.Status = Constants.TASK_COMPLETED_STATUS;
        }
        update someTasks;
        return someTasks.size();
    }

    private static Task_Template__c createAllTemplatesAndSteps() {
        Task_Template__c topLevelTemplate = createTopLevelTemplate();
        Master_Task_Template__c masterTemplate = new Master_Task_Template__c();
        masterTemplate.Task_Template__c = topLevelTemplate.Id;
        insert masterTemplate;

        topLevelTemplate.Master_Task_Template__c = masterTemplate.Id;
        update topLevelTemplate;

        List<Task_Template__c> childTemplates = createChildTemplates(masterTemplate.Id, topLevelTemplate.Id, 3);
        List<Task_Template_Step__c> steps = new List<Task_Template_Step__c>();
        Integer idx = 0;

        for(Task_Template__c t : childTemplates) {
            steps.addAll(createTemplateSteps(t, 5));
            idx++;
        }

        insert steps;

        List<Task_Template_Step_Dependency__c> depends = createTemplateStepDependencies(childTemplates, steps);
        insert depends;
        return topLevelTemplate;
    }

    private static SObject getSObject(String objectApiName) {
        SObject so = SObjectData.makeObject(objectApiName);
        insert so;
        return so;
    }

    private static Task_Template__c createTopLevelTemplate() {
        Task_Template__c topLevelTemplate = new Task_Template__c (
            Is_Active__c = true,
            Name = 'Top Level Test Template'
        );
        insert topLevelTemplate;
        return topLevelTemplate;
    }


    /**
    * @description Creates the child templates.
    * @author Brian Ezell (Simply EZ) | 07-31-2024 
    * @param masterTemplate 
    * @param numberOfTemplates 
    * @return List<Task_Template__c> 
    **/
    private static List<Task_Template__c> createChildTemplates(Id masterTemplateId, Id topLevelTemplateId, Integer numberOfTemplates) {
        List<Task_Template__c> childTemplates = new List<Task_Template__c>();

        for(Integer i = 0; i < numberOfTemplates; i++) {
            childTemplates.add(new Task_Template__c (
                Is_Active__c = true,
                Name = 'Child Test Template ' + string.valueOf(i),
                Parent_Template__c = topLevelTemplateId,
                Master_Task_Template__c = masterTemplateId
            ));
        }

        insert childTemplates;
        return childTemplates;
    }

    /**
    * @description Creates the template steps.
    * @author Brian Ezell (Simply EZ) | 07-31-2024 
    * @param template 
    * @param numberOfSteps 
    * @return List<Task_Template_Step__c> 
    **/
    private static List<Task_Template_Step__c> createTemplateSteps(Task_Template__c template, Integer numberOfSteps) {
        List<Task_Template_Step__c> steps = new List<Task_Template_Step__c>();
        for(Integer i = 0; i < numberOfSteps; i++) {
            steps.add(new Task_Template_Step__c(
                Parent_Task_Template__c = template.Id,
                Order__c = i,
                Name = template.Name + ' ' + String.valueOf(i),
                Activity_Type__c = i == numberOfSteps - 1 ? 'Event' : 'Task'
                //Math.MOD(i, 2) == 0 ? 'Task' : 'Event'
            ));
        }
        return steps;
    }

    private static List<Task_Template_Step_Dependency__c> createTemplateStepDependencies(
        List<Task_Template__c> templateList, 
        List<Task_Template_Step__c> stepList) {

        List<Task_Template_Step_Dependency__c> depends = new List<Task_Template_Step_Dependency__c>();
        List<Task_Template_Step__c> justTasks = new List<Task_Template_Step__c>();

        for(Task_Template_Step__c step : stepList) {
            if(step.Activity_Type__c == 'Task') {
                justTasks.add(step);
            }
        }

        Task_Template_Step__c mainStep = justTasks[0];
        for(Task_Template__c t : templateList) {
            Integer currentIndex = 0;
            Integer maxIndex = justTasks.size() - 2;
            for(Task_Template_Step__c step : justTasks) {
                if(step.Parent_Task_Template__c == t.Id && step.Id != mainStep.Id) {
                    depends.add( 
                        new Task_Template_Step_Dependency__c (
                            Step__c = step.Id,
                            Depends_On_Step__c = mainStep.Id,
                            Task_Template__c = t.Id
                        )
                    );
                    currentIndex++;
                    if(currentIndex >= maxIndex) {
                        break;
                    }
                }
            }
        }
        
        return depends;
    }

    public class TestDataFactoryData {
        public TestDataFactoryData() {
            thisTemplate = null;
            thisObject = null;
        }

        public Task_Template__c thisTemplate;
        public SObject thisObject;

        public String getSObjectName() {
            return this.thisObject.getSObjectType().getDescribe().getName();
        }
    }
}