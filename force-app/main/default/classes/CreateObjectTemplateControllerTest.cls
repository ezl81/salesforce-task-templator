/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 06-16-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
@IsTest
private class CreateObjectTemplateControllerTest {

    @IsTest
    private static void testGetTemplates() {
        User u = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_ADMIN_PERMISSION_SET, Constants.SYSTEM_ADMIN_PROFILE_NAME);

        System.runAs(u) {
            TestDataFactory.TestDataFactoryData testData = TestDataFactory.createAllTestData('Account');
            String strResponse = CreateObjectTemplateController.getTemplates(testData.getSObjectName());
            List<Task_Template__c> templates = (List<Task_Template__c>) JSON.deserialize(strResponse, List<Task_Template__c>.class);
            Assert.isNotNull(templates, 'Expected response to not be null');
        }
    }

    @IsTest
    private static void testCreateTemplate() {

        User u = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_ADMIN_PERMISSION_SET, Constants.SYSTEM_ADMIN_PROFILE_NAME);

        System.runAs(u) {
            TestDataFactory.TestDataFactoryData testData = TestDataFactory.createAllTestData('Account');

            CreateObjectTemplateController.CreateTemplateRequest request = new CreateObjectTemplateController.CreateTemplateRequest();
            request.objectId = testData.thisObject.Id;
            request.objectName = testData.getSObjectName();
            request.templateId = testData.thisTemplate.Id; 

            String strRequest = JSON.serialize(request);
            String strResponse = CreateObjectTemplateController.createTemplate(strRequest);   

            CreateObjectTemplateController.CreateTemplateResponse response = (CreateObjectTemplateController.CreateTemplateResponse) JSON.deserialize(strResponse, CreateObjectTemplateController.CreateTemplateResponse.class);

            Assert.isNotNull(strResponse, 'Expected response to not be null');
            Assert.isNotNull(response, 'Expected response to not be null');
        }

    }

}