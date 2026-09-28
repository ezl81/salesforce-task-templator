/**
 * @description       : 
 * @author            : Brian Ezell (SImplyEZ)
 * @group             : 
 * @last modified on  : 07-15-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
@IsTest
private class TemplateHelperTest {

    @IsTest
    private static void testUpdateTemplateLevelCounts() {

        User admin = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_ADMIN_PERMISSION_SET, Constants.SYSTEM_ADMIN_PROFILE_NAME);
        System.runAs(admin) {
            
            TestDataFactory.TestDataFactoryData testData = TestDataFactory.createAllTestData('Contact');

            //Get the lowest level so far
            Task_Template__c temp = 
                [
                    SELECT Id, Level__c, Master_Task_Template__c
                    FROM Task_Template__c
                    ORDER BY Level__c DESC
                    LIMIT 1
                ];

            //Create a child case under this to insure it gets the correct level.
            Task_Template__c newTemplate = new Task_Template__c (
                Master_Task_Template__c = temp.Master_Task_Template__c,
                Parent_Template__c = temp.Id,
                Name = 'Next Level Child'
            );

            insert as user newTemplate;
            
            Task_Template__c retriveChild = 
                [
                    SELECT Id, Level__c, Master_Task_Template__c
                    FROM Task_Template__c
                    WHERE Id = :newTemplate.Id
                    LIMIT 1
                ];

            System.debug('Child = ' + retriveChild);

            Assert.areEqual(temp.Level__c+1, retriveChild.Level__c, 'This template should be at the next level from the parent.');

        }

    }

}