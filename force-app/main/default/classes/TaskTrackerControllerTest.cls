/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 06-23-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
@IsTest
private class TaskTrackerControllerTest {

    @IsTest
    private static void testGetMermaidMarkUp() {

        User u = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_ADMIN_PERMISSION_SET, Constants.SYSTEM_ADMIN_PROFILE_NAME);

        System.runAs(u) {

            TestDataFactory.TestDataFactoryData testData = TestDataFactory.createAllTestData('Account');

            Test.startTest();

            CreateProcessFlowController.ProcessInput input = new CreateProcessFlowController.ProcessInput();
            input.ObjectId = testData.thisObject.Id;
            input.ObjectName = 'Account';
            input.TemplateId = testData.thisTemplate.Id;
            List<Id> jobIds = CreateProcessFlowController.CreateProcess(new List<CreateProcessFlowController.ProcessInput> {input});
    
            PageReference pageRef = Page.VisualCaseTracker;
            pageRef.getParameters().put('id', testData.thisTemplate.Id);
            Test.setCurrentPage(pageRef);
    
            Test.stopTest();
    
            Assert.isNotNull(pageRef.getUrl(), 'Page URL should have been set.');
            TaskTrackerController ctrl = new TaskTrackerController();
            String mermaidSyntax = ctrl.getMermaidForTemplate(testData.thisTemplate.Id);
            Assert.isNotNull(mermaidSyntax, 'Mermaid syntax should not be null.');
        }
    
    }
}