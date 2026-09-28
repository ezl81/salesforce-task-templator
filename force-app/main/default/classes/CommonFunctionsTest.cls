/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 09-12-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
@IsTest
private class CommonFunctionsTest {
    @IsTest
    private static void testGetException() {

        String msg;
        try {
            throw new TestException('Test');
        } catch (Exception e) {
            msg = CommonFunctions.getExceptionError(e);
        }
        Assert.isFalse(String.isBlank(msg), 'Error message should have been set and thrown.');
    }

    @IsTest
    private static void testMermaidSafe() {
        String testString = 'This is a (Test) string';
        String safeString = CommonFunctions.makeMermaidSafe(testString);
        Assert.areNotEqual(safeString, testString, 'The string should be made safe.');
    }

    @IsTest
    private static void testPrintSObjectList() {

        User u = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_ADMIN_PERMISSION_SET, Constants.SYSTEM_ADMIN_PROFILE_NAME);
        System.runAs(u) {

            TestDataFactory.TestDataFactoryData testData = TestDataFactory.createAllTestData('Account');
            List<Task_Template__c> objList = 
                [
                    SELECT Id, Name
                    FROM Task_Template__c
                    WHERE Id = :testdata.thisTemplate.Id
                ];
            CommonFunctions.printSObjectList(objList);
            Assert.isNotNull(objList, 'This list should not be null and the debug should be printed out.');
        }
    }

    @IsTest
    private static void testIsColumnInSObject() {
        User u = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_ADMIN_PERMISSION_SET, Constants.SYSTEM_ADMIN_PROFILE_NAME);
        System.runAs(u) {

            TestDataFactory.TestDataFactoryData testData = TestDataFactory.createAllTestData('Account');
            Assert.isTrue(CommonFunctions.isColumnInSObject('Task_Template__c', 'Name'), 'The name column should be in the object.');
            Assert.isFalse(CommonFunctions.isColumnInSObject('Task_Template__c', 'ThisDOesNotExists'), 'The [ThisDOesNotExists] column should NOT be in the object.');
        }
    }

    @IsTest
    private static void testLoadStaticResource() {
        
        StaticResource sr = 
            [
                SELECT Id, Name 
                FROM StaticResource 
                WHERE ContentType = 'text/javascript'
                LIMIT 1
            ];

        String body = CommonFunctions.loadStaticResource(sr.Name);

        Assert.isNotNull(body, 'The body of the resource was not found.');

    }

    @IsTest
    private static void testGetStaticResourceUrl() {
        String url = CommonFunctions.getStaticResourceUrl('task');
        System.debug('URL: ' + url);
        Assert.isNotNull(url, 'The URL should have been returned.');
        Assert.isTrue(url.endsWith('/resource/task'), 'The URL is not correct: ' + url);
    }

    @IsTest
    private static void testGetAllTemplates() {

        User u = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_ADMIN_PERMISSION_SET, Constants.SYSTEM_ADMIN_PROFILE_NAME);
        System.runAs(u) {

            TestDataFactory.TestDataFactoryData testData = TestDataFactory.createAllTestData('Account');
            Task_Template__c template = 
                [
                    SELECT Id
                    FROM Task_Template__c
                    WHERE Id = :testdata.thisTemplate.Id
                ];
            List<Task_Template__c> templates = CommonFunctions.getAllTemplates(template.Id);
            Assert.areNotEqual(0, templates.size(), 'Templates should have been found.');
        }
        
    }

    @IsTest
    private static void testGetPicklistValues() {

        User u = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_ADMIN_PERMISSION_SET, Constants.SYSTEM_ADMIN_PROFILE_NAME);
        System.runAs(u) {
            List<Schema.PicklistEntry> picklistValues = CommonFunctions.getPicklistValues('Case', 'Status');
            Assert.isNotNull(picklistValues, 'PicklistValues should have been returned.');
            Assert.isTrue(picklistValues.size() > 0, 'The list of picklist values should have been returned.');
        }
    }

    @IsTest
    private static void testCreateObjectDocument() {
        
        User admin = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_ADMIN_PERMISSION_SET, Constants.SYSTEM_ADMIN_PROFILE_NAME);
        System.runAs(admin) {

            TestDataFactory.TestDataFactoryData testData = TestDataFactory.createAllTestData('Contact');
            
            String docText = 'Hello, World!';
            String docName = 'Test.txt';

            CommonFunctions.createObjectDocument(testData.thisObject.Id, docName,  Blob.ValueOf(JSON.serialize(docText)));

            Assert.areNotEqual(0, [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :testData.thisObject.Id].size(), 'The document is not there.');
        }   
        
    }

    private class TestException extends Exception {}
}