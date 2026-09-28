/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 06-16-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
@IsTest
private class CloneAllTemplatesTest {

    @IsTest
    private static void testCloneTemplate() {

        User u = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_ADMIN_PERMISSION_SET, Constants.SYSTEM_ADMIN_PROFILE_NAME);

        System.runAs(u) {

            TestDataFactory.createAllTestData('Account');

            List<Task_Template__c> oldMasterTemplates = 
                [
                    SELECT Id
                    FROM Task_Template__c
                    WHERE Is_Master_Template__c = true
                    LIMIT 1
                ];

            Assert.areEqual(oldMasterTemplates.size(), 1, 'There should only be one master template.');

            CloneAllTemplates clone = new CloneAllTemplates(oldMasterTemplates[0].Id);
            Id newTemplateId = clone.cloneTemplate('Clone Test');

            Assert.isNotNull(newTemplateId, 'Expected new template id to not be null');
            Assert.isTrue([SELECT Id FROM Task_Template__c WHERE Is_Master_Template__c = true].size() > 1, 'Expected more than one master template');
        }
    }

}