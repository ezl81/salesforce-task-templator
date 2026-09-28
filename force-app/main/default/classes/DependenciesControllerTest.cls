/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 07-16-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
@IsTest
private class DependenciesControllerTest {


    @IsTest
    private static void testGetCurrentDependencies() {

        User adminUser = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_ADMIN_PERMISSION_SET, Constants.SYSTEM_ADMIN_PROFILE_NAME);
        System.runAs(adminUser) {
            TestDataFactory.TestDataFactoryData testData = TestDataFactory.createAllTestData('Contact');

            Task_Template_Step__c step =
                [
                    SELECT Id, Parent_Task_Template__c
                    FROM Task_Template_Step__c
                    LIMIT 1
                ];
            String strJson = DependenciesController.getCurrentDependencies(step.Parent_Task_Template__c, step.Id);
            List<DependenciesController.SimplyEzTasksResponse> response = (List<DependenciesController.SimplyEzTasksResponse>)JSON.deserialize(strJson, List<DependenciesController.SimplyEzTasksResponse>.class);
            Assert.isNotNull(response, 'Expected response to not be null');
        }

    }
    
    @IsTest
    private static void testUpdateCurrentDependencies() {

        User adminUser = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_ADMIN_PERMISSION_SET, Constants.SYSTEM_ADMIN_PROFILE_NAME);
        System.runAs(adminUser) {
            TestDataFactory.TestDataFactoryData testData = TestDataFactory.createAllTestData('Contact');

            CreateProcessFlowControllerTest.createCasesFromTemplateAndContact(testData.thisTemplate.Id, testData.thisObject.Id);

            Task_Template__c nonMasterTemplate =
                [
                    SELECT Id
                    FROM Task_Template__c
                    WHERE Is_Master_Template__c = false
                    LIMIT 1
                ];

            List<Task_Template_Step__c> steps =
                [
                    SELECT Id
                    FROM Task_Template_Step__c
                    WHERE Parent_Task_Template__c = :nonMasterTemplate.Id
                ];

            List<String> otherSteps = new List<String>();
            String currentId = steps[0].Id;
            for(Task_Template_Step__c s : steps) {
                if(s.Id != currentId) {
                    otherSteps.add(s.Id);
                }
            }
            Boolean hasErrors = false;

            Test.startTest();

            try {
                DependenciesController.updateDependencies(currentId, otherSteps);
            } catch (Exception ex) {
                hasErrors = true;
            }

            Test.stopTest();

            Assert.isFalse(hasErrors, 'There should not be errors updating the dependencies.');
            
        }
    }

    @IsTest
    private static void testGetTemplateStepInformation() {

        User adminUser = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_ADMIN_PERMISSION_SET, Constants.SYSTEM_ADMIN_PROFILE_NAME);
        System.runAs(adminUser) {
            TestDataFactory.TestDataFactoryData testData = TestDataFactory.createAllTestData('Contact');
                CreateProcessFlowControllerTest.createCasesFromTemplateAndContact(testData.thisTemplate.Id, testData.thisObject.Id);

                Task_Template__c nonMasterTemplate =
                    [
                        SELECT Id
                        FROM Task_Template__c
                        WHERE Is_Master_Template__c = false
                        LIMIT 1
                    ];

                List<Task_Template_Step__c> steps =
                    [
                        SELECT Id
                        FROM Task_Template_Step__c
                        WHERE Parent_Task_Template__c = :nonMasterTemplate.Id
                    ];

                String strResponse = DependenciesController.getTemplateStepInformation(steps[0].Id.toString());
                Task_Template_Step__c response = (Task_Template_Step__c)JSON.deserialize(strResponse, Task_Template_Step__c.class);

                Assert.isNotNull(response, 'Expected response to not be null');
        }

    }

    @IsTest
    private static void testGetTemplateSteps() {

        User adminUser = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_ADMIN_PERMISSION_SET, Constants.SYSTEM_ADMIN_PROFILE_NAME);
        System.runAs(adminUser) {
            TestDataFactory.TestDataFactoryData testData = TestDataFactory.createAllTestData('Contact');
            CreateProcessFlowControllerTest.createCasesFromTemplateAndContact(testData.thisTemplate.Id, testData.thisObject.Id);

            Task_Template__c nonMasterTemplate =
                [
                    SELECT Id
                    FROM Task_Template__c
                    WHERE Is_Master_Template__c = false
                    LIMIT 1
                ];

            List<Task_Template_Step__c> steps =
                [
                    SELECT Id
                    FROM Task_Template_Step__c
                    WHERE Parent_Task_Template__c = :nonMasterTemplate.Id
                ];

            String strResponse = DependenciesController.getTemplateSteps(nonMasterTemplate.Id.toString(), steps[0].Id.toString());
            List<DependenciesController.SimplyEzTasksResponse> response = (List<DependenciesController.SimplyEzTasksResponse>)JSON.deserialize(strResponse,  List<DependenciesController.SimplyEzTasksResponse>.class);

            Assert.isNotNull(response, 'Expected response to not be null');
        }

    }

}