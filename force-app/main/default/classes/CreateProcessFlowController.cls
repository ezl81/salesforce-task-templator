/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 09-21-2024
 * @last modified by  : Brian Ezell (Simply EZ)
**/
global with sharing class CreateProcessFlowController {

    @InvocableMethod
    public static List<Id> createProcess(List<ProcessInput> inputs) {
        try {
            List<Id> returnProcessIds = new List<Id>();
            if(!inputs.isEmpty()) {

                CreateProcessHelper.CreateCaseRequest request = new CreateProcessHelper.CreateCaseRequest();
                request.objectId = inputs[0].ObjectId;
                request.objectApiName = inputs[0].ObjectName;
                request.templateId = inputs[0].TemplateId;
                CreateProcessHelper processHelper = new CreateProcessHelper(request);
                processHelper.createCases();
                
                returnProcessIds.add(processHelper.getTopLevelCaseId());
            }

            return returnProcessIds;
        } catch (Exception ex) {
            String msg = CommonFunctions.getExceptionError(ex);
            throw new AuraHandledException(msg);
        }
    }

	public class ProcessInput {

		@InvocableVariable
		public String objectId;

        @InvocableVariable
        public String objectName;

		@InvocableVariable
		public String templateId;
	}

}