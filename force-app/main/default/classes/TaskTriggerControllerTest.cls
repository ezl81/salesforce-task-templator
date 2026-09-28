/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 06-16-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
@IsTest
private class TaskTriggerControllerTest {


    @IsTest
    private static void testTaskTriggerStatusChanged() {

        User adminUser = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_ADMIN_PERMISSION_SET, Constants.SYSTEM_ADMIN_PROFILE_NAME);
        System.runAs(adminUser) {
            TestDataFactory.TestDataFactoryData testData = TestDataFactory.createAllTestData('Contact');
            
                CreateProcessFlowControllerTest.createCasesFromTemplateAndContact(testData.thisTemplate.Id, testData.thisObject.Id);

                Case childCase =
                [
                    SELECT Id, Number_of_Tasks_Completed__c, Number_of_Tasks_To_Complete__c
                    FROM Case
                    WHERE ParentId != null
                    LIMIT 1
                ];

                Assert.areEqual(0, childCase.Number_of_Tasks_Completed__c, 'No tasks should be completed.');

                List<Task> tasks =
                    [
                        SELECT Id
                        FROM Task
                        WHERE WhatId = :childCase.Id
                    ];

                for(Task t : tasks) {
                    t.Status = Constants.TASK_COMPLETED_STATUS;
                }
                update tasks;
                childCase =
                    [
                        SELECT Id, Number_of_Tasks_Completed__c, Number_of_Tasks_To_Complete__c, ParentId
                        FROM Case
                        WHERE Id = :childCase.Id
                    ];
                Assert.areNotEqual(0, childCase.Number_of_Tasks_Completed__c, 'All tasks should be completed now');

                Case masterCase =
                    [
                        SELECT Id, Number_of_Tasks_Completed__c, Number_of_Tasks_To_Complete__c
                        FROM Case
                        WHERE Id = :childCase.ParentId
                    ];
                System.assertNotEquals(0, masterCase.Number_of_Tasks_Completed__c, 'Some tasks should have been marked as completed.');
        }

 
    }

   @IsTest
    private static void testTaskTriggerStatusRefresh() {

        User adminUser = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_ADMIN_PERMISSION_SET, Constants.SYSTEM_ADMIN_PROFILE_NAME);
        System.runAs(adminUser) {

            TestDataFactory.TestDataFactoryData testData = TestDataFactory.createAllTestData('Contact');
            
                CreateProcessFlowControllerTest.createCasesFromTemplateAndContact(testData.thisTemplate.Id, testData.thisObject.Id);

                Case childCase =
                [
                    SELECT Id, Number_of_Tasks_Completed__c, Number_of_Tasks_To_Complete__c
                    FROM Case
                    WHERE ParentId != null
                    LIMIT 1
                ];

                Assert.areEqual(0, childCase.Number_of_Tasks_Completed__c, 'No tasks should be completed.');

                List<Task> tasks =
                    [
                        SELECT Id
                        FROM Task
                        WHERE WhatId = :childCase.Id
                    ];

                for(Task t : tasks) {
                    t.Status = Constants.TASK_COMPLETED_STATUS;
                }
                update tasks;
                childCase =
                    [
                        SELECT Id, Number_of_Tasks_Completed__c, Number_of_Tasks_To_Complete__c, ParentId
                        FROM Case
                        WHERE Id = :childCase.Id
                    ];
                Assert.areNotEqual(0, childCase.Number_of_Tasks_Completed__c, 'Some tasks should now be completed');

                List<Case> allCases =
                    [
                        SELECT Id
                        FROM Case
                    ];
                Set<Id> allCaseIds = new Set<Id>();
                for(Case c : allCases) {
                    allCaseIds.add(c.Id);
                }

                Task unmarkClosedTask = new Task (
                    Id = tasks[0].Id,
                    Status = Constants.TASK_START_STATUS
                );
                update unmarkClosedTask;
                Case childCaseAfterUnmarked = 
                    [
                        SELECT Id, Number_of_Tasks_Completed__c, Number_of_Tasks_To_Complete__c, ParentId
                        FROM Case
                        WHERE Id = :childCase.Id
                    ];

                Assert.areNotEqual(childCase.Number_of_Tasks_Completed__c, childCaseAfterUnmarked.Number_of_Tasks_Completed__c, 'Not all of the tasks should be completdd now.');
        }

 
    }

    @IsTest
    private static void testTaskDependencyNotCompleted() {

        User adminUser = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_ADMIN_PERMISSION_SET, Constants.SYSTEM_ADMIN_PROFILE_NAME);
        System.runAs(adminUser) {
            TestDataFactory.TestDataFactoryData testData = TestDataFactory.createAllTestData('Contact');
            CreateProcessFlowControllerTest.createCasesFromTemplateAndContact(testData.thisTemplate.Id, testData.thisObject.Id);

            List<Task_Dependency__c> allTaskDependencies =
            [
                SELECT Id, Task_Id__c, Task_Depends_On_Id__c
                FROM Task_Dependency__c
            ];

            Map<Id, Id> mapTaskIdToDependsOnTaskId = new Map<Id, Id>();

            for(Task_Dependency__c dep : allTaskDependencies) {
                mapTaskIdToDependsOnTaskId.put(dep.Task_Id__c, dep.Task_Depends_On_Id__c);
            }

            Task taskThatDependsOnOthers = 
                [
                    SELECT Id, Subject, IsClosed
                    FROM Task
                    WHERE Id IN :mapTaskIdToDependsOnTaskId.keySet()
                        AND IsClosed = false
                    LIMIT 1
                ];

            Boolean hasError = false;
            try {
                Task completedTask = new Task(
                    Id = taskThatDependsOnOthers.Id,
                    Status = Constants.TASK_COMPLETED_STATUS
                );
                update completedTask;
            } catch (Exception ex) {
                hasError = true;
            }

            Assert.areEqual(true, hasError, 'This should have errored since there is a dependency that is not completed.');
        }

    }
}