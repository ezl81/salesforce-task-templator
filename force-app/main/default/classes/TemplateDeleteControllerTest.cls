/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 06-16-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
@IsTest
private class TemplateDeleteControllerTest {

    @IsTest
    private static void testDeleteTemplateTaskAdmin() {

        User adminUser = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_ADMIN_PERMISSION_SET, Constants.SYSTEM_ADMIN_PROFILE_NAME);

        System.runAs(adminUser) {
            TestDataFactory.createAllTestData('Contact');
        }

        User stdUser = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_ADMIN_PERMISSION_SET, Constants.STANDARD_USER_PROFILE_NAME);

        System.runAs(stdUser) {

            Test.startTest();

            List<Task_Template__c> templates = 
                [
                    SELECT Id, Master_Task_Template__c
                    FROM Task_Template__c
                ];

            Assert.isTrue(templates.size() > 0, 'There should be at least one template.');

            Id deleteId = templates[0].Id;

            TemplateDeleteController.DeleteTemplateRequest request = new TemplateDeleteController.DeleteTemplateRequest();
            request.templateId = deleteId;
            String jsonRequest = JSON.serialize(request);

            TemplateDeleteController.deleteTemplate(jsonRequest);
            Assert.isTrue([SELECT Id FROM Task_Template__c WHERE Id = :deleteId].size() == 0, 'The template should have been deleted.');

            Test.stopTest();

        }

    }

    @IsTest
    private static void testDeleteTemplateTaskUser() {

        User adminUser = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_ADMIN_PERMISSION_SET, Constants.SYSTEM_ADMIN_PROFILE_NAME);
        System.runAs(adminUser) {
            TestDataFactory.createAllTestData('Account');
        }

        User u = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_USER_PERMISSION_SET, Constants.STANDARD_USER_PROFILE_NAME);
        Boolean hasError = false;

        System.runAs(u) {

            Test.startTest();

            try {
                List<Task_Template__c> templates = 
                    [
                        SELECT Id, Master_Task_Template__c
                        FROM Task_Template__c
                    ];

                Assert.isTrue(templates.size() > 0, 'There should be at least one template.');

                Id deleteId = templates[0].Id;

                TemplateDeleteController.DeleteTemplateRequest request = new TemplateDeleteController.DeleteTemplateRequest();
                request.templateId = deleteId;

                String jsonRequest = JSON.serialize(request);

                TemplateDeleteController.deleteTemplate(jsonRequest);
            } catch (Exception ex) {
                hasError = true;
            } finally {
                Test.stopTest();
            }
        }
        
        Assert.isTrue(hasError, 'The user should not be able delete the template.');

    }

}