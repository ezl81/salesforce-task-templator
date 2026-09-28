/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 06-16-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
@IsTest
private class TemplateTriggerControllerTest {

    @IsTest
    private static void testTrigger() {

        User adminUser = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_ADMIN_PERMISSION_SET, Constants.SYSTEM_ADMIN_PROFILE_NAME);
        System.runAs(adminUser) {

            TestDataFactory.createAllTestData('Account');

            List<Task_Template__c> templates = 
                [
                    SELECT Id, Master_Task_Template__c
                    FROM Task_Template__c
                ];

            for(Task_Template__c t : templates) {
                Assert.isNotNull(t.Master_Task_Template__c, 'The top level template should not be null.');
            }
        }
    }

}