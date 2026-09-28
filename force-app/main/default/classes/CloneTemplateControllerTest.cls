/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 06-16-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
@IsTest
private class CloneTemplateControllerTest {

    @IsTest
    private static void testCloneTemplate() {

        User u = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_ADMIN_PERMISSION_SET, Constants.SYSTEM_ADMIN_PROFILE_NAME);

        System.runAs(u) {

            TestDataFactory.TestDataFactoryData testData = TestDataFactory.createAllTestData('Account');

            List<Task_Template__c> oldMasterTemplates = 
                [
                    SELECT Id
                    FROM Task_Template__c
                    WHERE Is_Master_Template__c = true
                    LIMIT 1
                ];

            Assert.areEqual(oldMasterTemplates.size(), 1, 'There should only be one master template.');

            CloneTemplateController.CloneTemplateRequest request = new CloneTemplateController.CloneTemplateRequest();
            request.templateId = oldMasterTemplates[0].Id;
            request.newName = 'Test Template - Clone';

            String strRequest = JSON.serialize(request);

            String strResponse = CloneTemplateController.cloneTemplate(strRequest);
            CloneTemplateController.CloneTemplateResponse response = (CloneTemplateController.CloneTemplateResponse) JSON.deserialize(strResponse, CloneTemplateController.CloneTemplateResponse.class);

            Assert.isNotNull(strResponse, 'Response should not be null');
            Assert.isTrue([SELECT Id FROM Task_Template__c WHERE Is_Master_Template__c = true].size() > 1, 'Expected more than one master template');

        }
        
    }

    @IsTest
    private static void testGetTemplate() {
        
        User u = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_ADMIN_PERMISSION_SET, Constants.SYSTEM_ADMIN_PROFILE_NAME);

        System.runAs(u) {
            TestDataFactory.TestDataFactoryData testData = TestDataFactory.createAllTestData('Account');
            Task_Template__c template = 
                [
                    SELECT Id
                    FROM Task_Template__c
                    LIMIT 1
                ];

            String jsonResponse = CloneTemplateController.getTemplate(template.Id);

            Task_Template__c returnedTemplate = (Task_Template__c) JSON.deserialize(jsonResponse, Task_Template__c.class);
            Assert.isNotNull(returnedTemplate, 'Expected response to not be null');
        }
        
    }

}