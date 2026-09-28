/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 06-16-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
@IsTest
private class ExportTemplateControllerTest {

    @IsTest
    private static void testExportTemplate() {

        User admin = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_ADMIN_PERMISSION_SET, Constants.SYSTEM_ADMIN_PROFILE_NAME);

        System.runAs(admin) {
            TestDataFactory.TestDataFactoryData testData = TestDataFactory.createAllTestData('Contact');

            Task_Template__c template = 
                [
                    SELECT Id
                    FROM Task_Template__c
                    LIMIT 1
                ];

                ExportTemplateController.ExportTemplateRequest request = new ExportTemplateController.ExportTemplateRequest();
                request.templateId = template.Id;
                
                String responseJson = ExportTemplateController.exportTemplate(JSON.serialize(request));
                ExportTemplateController.ExportTemplateResponse response = (ExportTemplateController.ExportTemplateResponse)JSON.deserialize(responseJson, ExportTemplateController.ExportTemplateResponse.class);
                Assert.areNotEqual(null, response.exportTemplateId, 'Response should not be null.');

                Template_Export__c exportTemplate = 
                    [
                        SELECT Id
                        FROM  Template_Export__c
                    ];

                Assert.areNotEqual(null, exportTemplate, 'There should be an export template');
                Assert.areNotEqual(0, [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :response.exportTemplateId].size(), 'There should be a file on this object');
        }

    }

}