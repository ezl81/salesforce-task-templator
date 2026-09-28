/**
 * @description       : 
 * @author            : Brian Ezell (SimplyEZ)
 * @group             : 
 * @last modified on  : 06-16-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
@IsTest
private class CaseTemplateHelperTest {

    @IsTest
    private static void testUpdateCaseCounts() {

        User admin = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_ADMIN_PERMISSION_SET, Constants.SYSTEM_ADMIN_PROFILE_NAME);

        System.runAs(admin) {

           TestDataFactory.TestDataFactoryData data = TestDataFactory.createAllTestData('Account');

            CreateProcessFlowController.ProcessInput oneInput = new CreateProcessFlowController.ProcessInput();
            oneInput.ObjectId = data.thisObject.Id;
            oneInput.ObjectName = data.getSObjectName();
            oneInput.TemplateId = data.thisTemplate.Id;

            
            CreateProcessFlowController.CreateProcess(new List<CreateProcessFlowController.ProcessInput> {
                oneInput
            });

            Map<Id, Case> mapCaseIdToCase = new Map<Id, Case> (
                [
                    SELECT Id, Subject
                    FROM Case
                ]
            );
            
            CaseTemplateHelper.updateCaseCounts(mapCaseIdToCase.keySet());

            Case topLevelCase = 
                [
                    SELECT Id, Subject, Number_of_Tasks_To_Complete__c
                    FROM Case
                    WHERE Number_of_Tasks_To_Complete__c > 0
                    LIMIT 1
                ];

            System.assertNotEquals(0, topLevelCase.Number_of_Tasks_To_Complete__c, 'Should have created 1 task.');
            
        }
    }
}