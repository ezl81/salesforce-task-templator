/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 08-01-2024
 * @last modified by  : Brian Ezell (Simply EZ)
**/
@IsTest
public with sharing class CaseProgressTrackerControllerTest {

    @IsTest
    private static void testGetCasesOffObject() {

        User adminUser = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_ADMIN_PERMISSION_SET, Constants.SYSTEM_ADMIN_PROFILE_NAME);
        System.runAs(adminUser) {
            TestDataFactory.TestDataFactoryData testData = TestDataFactory.createAllTestData('Contact');
            CreateProcessFlowControllerTest.createCasesFromTemplateAndContact(testData.thisTemplate.Id, testData.thisObject.Id);
            
            Case c = 
                [
                    SELECT Id
                    FROM Case
                    LIMIT 1
                ];

            String summaryJson = CaseProgressTrackerController.getChildTasksSummary(c.Id);
            List<CasesOnObjectController.ObjectSummaryByCases> summaries = (List<CasesOnObjectController.ObjectSummaryByCases>)JSON.deserialize(summaryJson, List<CasesOnObjectController.ObjectSummaryByCases>.class);
            Assert.isNotNull(summaries, 'Summaries shoud not be null.');
            Assert.isTrue(summaries.size() > 0, 'There should be child tasks returned.');
        }
    }
}