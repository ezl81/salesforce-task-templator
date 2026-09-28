/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 06-16-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
@IsTest
private class TemplateBuilderControllerTest {

    @IsTest
    private static void testFlowDependencies() {

        User adminUser = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_ADMIN_PERMISSION_SET, Constants.SYSTEM_ADMIN_PROFILE_NAME);
        System.runAs(adminUser) {
            TestDataFactory.TestDataFactoryData testData = TestDataFactory.createAllTestData('Contact');
            String response = TemplateBuilderController.flowDependencies(testData.thisTemplate.Id.toString());
            List<TemplateBuilderController.TaskTemplateNode> templateNodes = (List<TemplateBuilderController.TaskTemplateNode>) JSON.deserialize(response, List<TemplateBuilderController.TaskTemplateNode>.class);
            Assert.isNotNull(templateNodes, 'Expected response to not be null');
        }

    }

    @IsTest
    private static void testDeleteTaskRecord() {

        User adminUser = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_ADMIN_PERMISSION_SET, Constants.SYSTEM_ADMIN_PROFILE_NAME);
        System.runAs(adminUser) {
            TestDataFactory.TestDataFactoryData testData = TestDataFactory.createAllTestData('Contact');
            String response = TemplateBuilderController.flowDependencies(testData.thisTemplate.Id.toString());

            Task_Template_Step__c step =
                [
                    SELECT Id
                    FROM Task_Template_Step__c
                    LIMIT 1
                ];

            List<Task_Template_Step_Dependency__c> depends = [SELECT Id FROM Task_Template_Step_Dependency__c];
            delete depends;
            
            TemplateBuilderController.deleteTaskRecord(step.Id.toString());

            Assert.isTrue([SELECT Id FROM Task_Template_Step__c WHERE Id = :step.Id].isEmpty(), 'Step should be deleted.');
        } 

    }

    @IsTest
    private static void testDeleteTemplateRecord() {

        User adminUser = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_ADMIN_PERMISSION_SET, Constants.SYSTEM_ADMIN_PROFILE_NAME);
        System.runAs(adminUser) {
            TestDataFactory.TestDataFactoryData testData = TestDataFactory.createAllTestData('Contact');
            String response = TemplateBuilderController.flowDependencies(testData.thisTemplate.Id.toString());

            Task_Template__c template =
                [
                    SELECT Id
                    FROM Task_Template__c
                    LIMIT 1
                ];

            List<Task_Template_Step_Dependency__c> depends = [SELECT Id FROM Task_Template_Step_Dependency__c];
            delete depends;
                
            TemplateBuilderController.deleteTemplateRecord(template.Id.toString());

            Assert.isTrue([SELECT Id FROM Task_Template__c WHERE Id = :template.Id].isEmpty(), 'Template should be deleted.');
        }
    }

}