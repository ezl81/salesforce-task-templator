/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 06-16-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
@IsTest
private class CreateProcessHelperTest {

    @IsTest
    private static void testCreateCases() {

        User adminUser = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_ADMIN_PERMISSION_SET, Constants.SYSTEM_ADMIN_PROFILE_NAME);
        System.runAs(adminUser) {
            TestDataFactory.TestDataFactoryData testData = TestDataFactory.createAllTestData('Contact');

            List<Case> cases =
                [
                    SELECT Id
                    FROM Case
                    WHERE Is_Simply_Tasks_Case__c = true
                ];

            Assert.areEqual(true, cases.isEmpty(), 'No cases to start');

            Task_Template__c masterTemplate =
                [
                    SELECT Id
                    FROM Task_Template__c
                    WHERE Is_Master_Template__c = true
                    LIMIT 1
                ];
                
            createCasesFromTemplateAndContact(masterTemplate.Id, testData.thisObject.Id);

            List<Task_Template_Step__c> steps =
                [
                    SELECT Id
                    FROM Task_Template_Step__c
                ];

            cases =
                [
                    SELECT Id
                    FROM Case
                    WHERE Is_Simply_Tasks_Case__c = true
                ];

            Assert.areEqual(false, cases.isEmpty(), 'Cases should have been created for the template');

            List<Task> tasks =
                [
                    SELECT Id
                    FROM Task
                    WHERE WhatId = :cases
                ];
            Assert.areEqual(false, tasks.isEmpty(), 'Tasks should have been created for the template steps.');

            List<Task_Dependency__c> dependencies =
                [
                    SELECT Id, Task_Id__c, Task_Depends_On_Id__c
                    FROM Task_Dependency__c
                    WHERE Case__c = :cases
                ];
            System.assertNotEquals(true, dependencies.isEmpty(), 'There should be dependencies amongst the tasks');
        }

    }

    @TestVisible
    private static void createCasesFromTemplateAndContact(Id masterTemplateId, Id contactId) {

        CreateProcessHelper.CreateCaseRequest request = new CreateProcessHelper.CreateCaseRequest();
        request.objectApiName = 'Contact';
        request.objectId = contactId;
        request.templateId = masterTemplateId;

        User adminUser = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_ADMIN_PERMISSION_SET, Constants.SYSTEM_ADMIN_PROFILE_NAME);
        System.runAs(adminUser) {
            CreateProcessHelper processHelper = new CreateProcessHelper(request);
            processHelper.createCases();
        }
    }

}