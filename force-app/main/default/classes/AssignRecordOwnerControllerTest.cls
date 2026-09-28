/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 06-23-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
@IsTest 
private class AssignRecordOwnerControllerTest {

    @IsTest
    private static void testGetAssignedOwnerOptionsQueue() {

        User u = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_ADMIN_PERMISSION_SET, Constants.SYSTEM_ADMIN_PROFILE_NAME);

        Group queue = new Group (
            Name = 'Test Queue', 
            Type = 'Queue'
        );
        insert queue;

        System.runAs(u) {

            AssignRecordOwnerController.AssignRequest request = new AssignRecordOwnerController.AssignRequest();
            
            request.selectedId = queue.Id;
            request.assignType = 'Queue';


            String strRequest = JSON.serialize(request);

            String strResponse = AssignRecordOwnerController.getAssignedOwnerOptions(strRequest);
            AssignRecordOwnerController.AssignResponse response = (AssignRecordOwnerController.AssignResponse) JSON.deserialize(strResponse, AssignRecordOwnerController.AssignResponse.class);

            Assert.isNotNull(response, 'Expected response to not be null');
            Assert.isTrue(response.options.size() > 0, 'There should be options returned.');
        }
    }

    @IsTest
    private static void testGetAssignedOwnerOptionsSpecificUser() {

        User u = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_ADMIN_PERMISSION_SET, Constants.STANDARD_USER_PROFILE_NAME);

        AssignRecordOwnerController.AssignRequest request = new AssignRecordOwnerController.AssignRequest();

        request.selectedId = u.Id;
        request.assignType = 'Specific User';

        System.runAs(u) {

            String strRequest = JSON.serialize(request);

            String strResponse = AssignRecordOwnerController.getAssignedOwnerOptions(strRequest);
            AssignRecordOwnerController.AssignResponse response = (AssignRecordOwnerController.AssignResponse) JSON.deserialize(strResponse, AssignRecordOwnerController.AssignResponse.class);
 
            Assert.isNotNull(response, 'Expected response to not be null');
            Assert.isTrue(response.options.size() > 0, 'There should be options returned.');
        }

    }

    @IsTest
    private static void testGetAssignedOwnerOptionsOther() {

        AssignRecordOwnerController.AssignRequest request = new AssignRecordOwnerController.AssignRequest();

        request.assignType = 'Case Owner';

        String strRequest = JSON.serialize(request);

        User u = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_ADMIN_PERMISSION_SET, Constants.STANDARD_USER_PROFILE_NAME);

        System.runAs(u) {
            String strResponse = AssignRecordOwnerController.getAssignedOwnerOptions(strRequest);
            AssignRecordOwnerController.AssignResponse response = (AssignRecordOwnerController.AssignResponse) JSON.deserialize(strResponse, AssignRecordOwnerController.AssignResponse.class);

            Assert.isNotNull(response, 'Expected response to not be null');
            Assert.isTrue(response.options.size() == 0, 'There should be no options returned.');
        }
    }

    @IsTest
    private static void testUpdateObjectOwner() {

        User u = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_ADMIN_PERMISSION_SET, Constants.SYSTEM_ADMIN_PROFILE_NAME);
        System.runAs(u) {

            TestDataFactory.TestDataFactoryData testData = TestDataFactory.createAllTestData('Contact');
            Group queue = new Group (
                Name = 'Test Queue', 
                Type = 'Queue'
            );
            insert queue;

            //Verify the Queue options
            AssignRecordOwnerController.UpdateAssignedOwnerRequest request = new AssignRecordOwnerController.UpdateAssignedOwnerRequest();
            request.recordId = testData.thisTemplate.Id;
            request.assignedType = 'Queue';
            request.assignedId = queue.Id;
            request.assignedOwnerName = queue.Name;

            String strRequest = JSON.serialize(request);    
            AssignRecordOwnerController.updateAssignedOwner(strRequest);

            Task_Template__c template = 
                [
                    SELECT Id, Assigned_Type__c, Assignee_Id__c, Assigned_To_Name__c
                    FROM Task_Template__c
                    WHERE Id = :testData.thisTemplate.Id
                ];

            Assert.isTrue(template.Assigned_Type__c.equalsIgnoreCase('Queue'), 'Assigned_Type__c should be marked as "queue".');
            Assert.isTrue(template.Assignee_Id__c.equalsIgnoreCase(queue.Id), 'Assignee_Id__c should be marked as the queue id.');
            Assert.isNotNull(template.Assigned_To_Name__c, 'Assigned_To_Name__c should be marked as the queue name.');
        }
    }

    @IsTest
    private static void testGetAssignedOwner() {
     
        User u = TestDataFactory.createUserWithPermissionSets(TestDataFactory.SIMPLY_TASKS_ADMIN_PERMISSION_SET, Constants.SYSTEM_ADMIN_PROFILE_NAME);

        System.runAs(u) {
            TestDataFactory.TestDataFactoryData testData = TestDataFactory.createAllTestData('Account');
            String strResponse = AssignRecordOwnerController.getAssignedOwner(testData.thisTemplate.Id);
            AssignRecordOwnerController.GetAssignOwnerResponse response = (AssignRecordOwnerController.GetAssignOwnerResponse) JSON.deserialize(strResponse, AssignRecordOwnerController.GetAssignOwnerResponse.class);
            
            Assert.isNotNull(response, 'Expected response to not be null');
        }

    }

}