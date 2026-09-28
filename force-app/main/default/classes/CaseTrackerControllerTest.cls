/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 06-16-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
@IsTest
private class CaseTrackerControllerTest {

    @IsTest
    private static void testGetMermaidMarkUp() {

        User u = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_ADMIN_PERMISSION_SET, Constants.SYSTEM_ADMIN_PROFILE_NAME);

        System.runAs(u) {
            TestDataFactory.TestDataFactoryData data = TestDataFactory.createAllTestData('Account');

            CreateProcessFlowController.ProcessInput oneInput = new CreateProcessFlowController.ProcessInput();
            oneInput.ObjectId = data.thisObject.Id;
            oneInput.ObjectName = data.getSObjectName();
            oneInput.TemplateId = data.thisTemplate.Id;

            Test.startTest();
            
            CreateProcessFlowController.CreateProcess(new List<CreateProcessFlowController.ProcessInput> {
                oneInput
            });

            Test.stopTest();

            Case c =
                [
                    SELECT Id
                    FROM Case
                    WHERE Is_Simply_Tasks_Case__c = true
                    LIMIT 1
                ];

            PageReference pageRef = Page.VisualCaseTracker; // Add your VF page Name here
            pageRef.getParameters().put('id', c.Id);
            Test.setCurrentPage(pageRef);

            Assert.isNotNull(pageRef.getUrl(), 'The url should not be null');

            CaseTrackerController ctrl = new CaseTrackerController();
            String mermaidSyntax = ctrl.getMermaidForTemplate(c.Id);
            Assert.isNotNull(mermaidSyntax, 'Diagram syntax should not be null');
        }
    }
}