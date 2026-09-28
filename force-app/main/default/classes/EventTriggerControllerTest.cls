/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 06-16-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
@IsTest
private class EventTriggerControllerTest {
 
    @IsTest
    private static void testUpdateCase() {

        User adminUser = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_ADMIN_PERMISSION_SET, Constants.SYSTEM_ADMIN_PROFILE_NAME);
        System.runAs(adminUser) {

            TestDataFactory.TestDataFactoryData testData = TestDataFactory.createAllTestData('Contact');
            CreateProcessFlowControllerTest.createCasesFromTemplateAndContact(testData.thisTemplate.Id, testData.thisObject.Id);

            Task oneTask = 
                [
                    SELECT Id, WhatId, OwnerId, Task_Template_Step__c
                    FROM Task
                    WHERE Is_Simply_Tasks_Created__c = true
                    LIMIT 1
                ];

            Case caseBefore = 
                [
                    SELECT Id, ParentId, Number_of_Tasks_To_Complete__c
                    FROM Case
                    WHERE Id = :oneTask.WhatId
                ];

            Event evt = new Event(
                WhatId = oneTask.WhatId,
                ActivityDate = Date.today().addDays(-1),
                OwnerId = oneTask.OwnerId,
                Is_Simply_Tasks_Created__c = true,
                Subject = 'Test Subject',
                Task_Template_Step__c = oneTask.Task_Template_Step__c,
                Dependent_Tasks_To_Complete__c = 0,
                Type = 'Meeting',
                IsAllDayEvent = true
            );
            insert as user evt;

            Case caseAfter = 
                [
                    SELECT Id, ParentId, Number_of_Tasks_To_Complete__c
                    FROM Case
                    WHERE Id = :oneTask.WhatId
                ];

            Assert.isTrue(caseAfter.Number_of_Tasks_To_Complete__c > 0, 'Case should have been updated');
        }
    }

}