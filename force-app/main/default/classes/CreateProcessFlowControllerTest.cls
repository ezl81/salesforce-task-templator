/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 07-31-2024
 * @last modified by  : Brian Ezell (Simply EZ)
**/
@IsTest
public class CreateProcessFlowControllerTest {

    @TestVisible
    private static void createCasesFromTemplateAndContact(Id masterTemplateId, Id contactId) {
        User u = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_ADMIN_PERMISSION_SET, Constants.SYSTEM_ADMIN_PROFILE_NAME);

        System.runAs(u) {
            CreateProcessFlowController.ProcessInput input = new CreateProcessFlowController.ProcessInput();
            input.ObjectId = contactId;
            input.TemplateId = masterTemplateId;
            input.ObjectName = 'Contact'; //Not used currently, but maybe later

            List<CreateProcessFlowController.ProcessInput> inputList = new List<CreateProcessFlowController.ProcessInput>();
            inputList.add(input);
            CreateProcessFlowController.CreateProcess(inputList);
        }
        
    }
}