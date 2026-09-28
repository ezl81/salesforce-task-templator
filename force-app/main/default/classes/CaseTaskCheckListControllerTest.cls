/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 08-13-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
@IsTest
private class CaseTaskCheckListControllerTest {
    
    @IsTest
    private static void testGetTaskList() {

        User adminUser = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_ADMIN_PERMISSION_SET, Constants.SYSTEM_ADMIN_PROFILE_NAME);
        System.runAs(adminUser) {
            TestDataFactory.TestDataFactoryData testData = TestDataFactory.createAllTestData('Contact');

                    Task_Template__c masterTemplate =
                        [
                            SELECT Id
                            FROM Task_Template__c
                            WHERE Is_Master_Template__c = true
                            LIMIT 1
                        ];

                    CreateProcessFlowControllerTest.createCasesFromTemplateAndContact(masterTemplate.Id, testData.thisObject.Id);

                    Case childCase =
                        [
                            SELECT Id
                            FROM Case
                            WHERE ParentId != NULL
                            LIMIT 1
                        ];
                    List<Task> tasks =
                        [
                            SELECT Id, Subject
                            FROM Task
                            WHERE WhatId = :childCase.Id
                        ];

                    String response = CaseTaskCheckListController.getTaskList(childCase.Id);
                    CaseTaskCheckListController.TaskListResponse responseObject = (CaseTaskCheckListController.TaskListResponse)JSON.deserialize(response, CaseTaskCheckListController.TaskListResponse.class);
                    Assert.areEqual(tasks.size(), responseObject.TaskItems.size(), 'The number of tasks returned is not correct.');
        }
    }

    @IsTest
    private static void testUpdateTaskList() {

        User u = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_ADMIN_PERMISSION_SET, Constants.SYSTEM_ADMIN_PROFILE_NAME);

        System.runAs(u) {

            TestDataFactory.TestDataFactoryData testData = TestDataFactory.createAllTestData('Contact');

            TestDataFactory.createCaseFromTemplate(testData);
            
            Task incompleteTask =
                [
                    SELECT Id, Subject, WhatId
                    FROM Task
                    LIMIT 1
                ];

            Case childCase =
                [
                    SELECT Id
                    FROM Case
                    WHERE Id = :incompleteTask.WhatId
                    LIMIT 1
                ];

            List<String> completedItems = new List<String>();

            completedItems.add(incompleteTask.Id);
            String completedListJson = Json.serialize(completedItems);

            Test.startTest();

            CaseTaskCheckListController.updateTaskList(childCase.Id, completedListJson);

            Test.stopTest();

            Task finishedTask =
                [
                    SELECT Id, Status, WhatId
                    FROM Task
                    WHERE WhatId = :childCase.Id
                        AND Subject = :incompleteTask.Subject
                    LIMIT 1
                ];
            Assert.areEqual(Constants.TASK_COMPLETED_STATUS, finishedTask.Status, 'This task should be completed now.');

            Case childCaseAfter =
                [
                    SELECT Id, Number_of_Tasks_Completed__c, Number_of_Tasks_To_Complete__c
                    FROM Case
                    WHERE Id = :childCase.Id
                ];

            Assert.areEqual(1, childCaseAfter.Number_of_Tasks_Completed__c, 'There should be a completed task on this case now.');

        }

    }
}