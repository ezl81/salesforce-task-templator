public with sharing class CreateCaseFromTemplateTierController {
    
   @AuraEnabled
    public static String getCategories(String request) {
        try {
            ObjectCategoryRequest objRequest = (ObjectCategoryRequest)JSON.deserialize(request, ObjectCategoryRequest.class);
            Id objectId = Id.valueOf(objRequest.objectId);
            String objectName = objectId.getSObjectType().getDescribe().getName();
        
            ObjectAndHierarchyHelper helper = new ObjectAndHierarchyHelper(objectName);
            ObjectAndHierarchyHelper.ObjectTemplateCollection objectCollection = helper.getObjectTemplateHierarchy();
            return JSON.serialize(objectCollection);

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class ObjectCategoryRequest {
        public String objectId;
    }


    @AuraEnabled
    public static String createCaseFromTemplateWithHierarchy(String request) {
        try {
            CreateCaseRequest createRequest = (CreateCaseRequest)JSON.deserialize(request, CreateCaseRequest.class);
            Id objectId = Id.valueOf(createRequest.objectId);
            String objectName = objectId.getSObjectType().getDescribe().getName();

            Object__c obj = getObjectByName(objectName);

            //Create the request that includes the template ids selected.
            CreateProcessHelper.CreateCaseWithHierarchyRequest processRequest = new CreateProcessHelper.CreateCaseWithHierarchyRequest();
            processRequest.objectId = objectId;
            processRequest.objectApiName = objectName; 
            processRequest.selectedTemplateIds = createRequest.selectedRows;

            //Run the process
            CreateProcessHelper processHelper = new CreateProcessHelper(processRequest);
            processHelper.createCases();

            //Return the new top-level case Id
            return JSON.serialize(processHelper.getTopLevelCaseId());
        } catch (Exception e) {

            CommonFunctions.printFullException(e);

            throw new AuraHandledException(e.getMessage());
        }
    }

    public class CreateCaseRequest {
        public String objectId;
        public List<String> selectedRows;
    }

    private static Object__c getObjectByName(String objectName) {
        return 
            [
                SELECT Id, Name 
                FROM Object__c 
                WHERE API_Name__c = :objectName 
                WITH USER_MODE
                LIMIT 1
            ];
    }
    
}