/**
 * @description       : Used to assign and retrieve information about record assignments
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 08-12-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
public with sharing class AssignRecordOwnerController {

    private static final String DEFAULT_ASSIGN_TYPE_FIELD = 'Assigned_Type__c';
    private static final String DEFAULT_ASSIGN_OWNER_FIELD = 'Assignee_Id__c';
    private static final String DEFAULT_ASSIGN_OWNER_NAME_FIELD = 'Assigned_To_Name__c';

    /**
    * @description Gets the options for how an owner can be assigned (using picklist lookup)
    * @author Brian Ezell (Simply EZ) | 10-03-2024 
    * @param request 
    * @return String 
    **/
    @AuraEnabled
    public static String getAssignedOwnerOptions(String request) {
        try {

            if(String.isEmpty(request)) {
                throw new AuraHandledException('The assigned owner options could not be retrieved.');
            }

            AssignRequest assignRequest = (AssignRequest) JSON.deserialize(request, AssignRequest.class);
            AssignResponse response = new AssignResponse();
            String assignTypeLowerCase = assignRequest.assignType.toLowerCase();

            switch on assignTypeLowerCase {
                when 'queue' {
                    response = getQueueOptions(assignRequest.selectedId);
                }
                when 'specific user' {
                    response = getUserOptions(assignRequest.selectedId);
                }
                when else {
                    response.showCombo = false;
                }
            }
            return JSON.serialize(response);
        } catch (Exception e) {
            throw new AuraHandledException(CommonFunctions.getExceptionError(e));
        }
    }

    /**
    * @description Updates the assgined owner for the template/template step.
    * @author Brian Ezell (Simply EZ) | 05-19-2024 
    * @param request 
    **/
    @AuraEnabled
    public static void updateAssignedOwner(String request) {
        try {
            if(String.isEmpty(request)) {
                throw new AuraHandledException('The assigned owner could not be set.');
            }
            updateObjectOwner(request);
        } catch (Exception ex) {
            throw new AuraHandledException(CommonFunctions.getExceptionError(ex));
        }
    }

    
    /**
    * @description Gets the currently assigned owner and type of the template.
    * @author Brian Ezell (Simply EZ) | 10-03-2024 
    * @param recordId 
    * @return String 
    **/
    @AuraEnabled
    public static String getAssignedOwner(String recordId) {
        try {

            if(String.isBlank(recordId)) {
                throw new AuraHandledException('Record id cannot be blank.');
            }

            GetAssignOwnerResponse response = new GetAssignOwnerResponse();
            if(recordId != null) {
                List<Task_Template__c> templates = 
                    [
                        SELECT Id, Assigned_Type__c, Assignee_Id__c
                        FROM Task_Template__c
                        WHERE Id = :recordId
                        WITH USER_MODE
                    ];

                if(templates.size() > 0) {
                    response.assignType = templates[0].Assigned_Type__c;
                    response.ownerId = templates[0].Assignee_Id__c;
                }
            }
            
            return JSON.serialize(response);
        } catch (Exception e) {
            throw new AuraHandledException(CommonFunctions.getExceptionError(e));
        }
    }


    /**
    * @description 
    * @author Brian Ezell (Simply EZ) | 10-03-2024 
    * @param request 
    **/
    private static void updateObjectOwner(String request) {
        UpdateAssignedOwnerRequest updateRequest = (UpdateAssignedOwnerRequest) JSON.deserialize(request, UpdateAssignedOwnerRequest.class);
        if(String.isNotBlank(updateRequest.recordId)){
            Id recordId = Id.valueOf(String.escapeSingleQuotes(updateRequest.recordId));
            if(updateRequest.recordId == null) {
                return;
            }
            SObject updateObject = recordId.getSobjectType().newSObject(recordId);


            String assignOwnerField = coalesce(updateRequest.assignOwnerField, DEFAULT_ASSIGN_OWNER_FIELD);
            String assignTypeField = coalesce(updateRequest.assignTypeField, DEFAULT_ASSIGN_TYPE_FIELD);
            String assignedOwnerNameField = coalesce(updateRequest.assignedOwnerNameField, DEFAULT_ASSIGN_OWNER_NAME_FIELD);

            Id assignedId = Id.valueOf(String.escapeSingleQuotes(updateRequest.assignedId));

            String ownerName = '';
            //Get the name of the assigned owner

            String assignedTypeLowerCase = String.escapeSingleQuotes(updateRequest.assignedType).toLowerCase();

            switch on assignedTypeLowerCase {
                when 'queue' {
                    Group queue = 
                        [
                            SELECT Id, Name
                            FROM Group
                            WHERE Id = :updateRequest.assignedId
                            WITH USER_MODE
                        ];
                    ownerName = queue.Name + '(Queue)';
                }
                when 'specific user' {
                    User user = 
                        [
                            SELECT Id, Name
                            FROM User
                            WHERE Id = :updateRequest.assignedId
                            WITH USER_MODE
                        ];
                    ownerName = user.Name + '(User)';
                } 
                when else {
                    ownerName = updateRequest.assignedType;
                }
            }

            updateObject.put(assignedOwnerNameField, ownerName);

            if(String.isNotBlank(updateRequest.assignedId)) {
                Id assignId = Id.valueOf(updateRequest.assignedId);
                updateObject.put(assignOwnerField, assignId);
            }
            if(String.isNotBlank(assignedOwnerNameField) && String.isNotBlank(updateRequest.assignedOwnerName)) {
                String ownerValue = String.format('{0} ({1})',
                    new List<String> {
                        updateRequest.assignedOwnerName,
                        updateRequest.assignedType
                    });

                updateObject.put(assignedOwnerNameField, ownerValue);
            }

            updateObject.put(assignTypeField, updateRequest.assignedType);

            update as user updateObject;
        }
    }


    /**
    * @description  Gets a list of options for the Queue selection.
    * @author Brian Ezell (Simply EZ) | 10-03-2024 
    * @param selectId 
    * @return AssignResponse 
    **/
    private static AssignResponse getQueueOptions(String selectId) {

        AssignResponse response = new AssignResponse();
        response.showCombo = true;
        response.optionsName = 'Queue';
        response.options = new List<Option>();
        List<Group> queues = 
            [
                SELECT 
                    Id, Name
                FROM Group 
                WHERE Type = 'Queue'
                WITH USER_MODE
                ORDER BY Name
            ];

        for(Group q : queues) {
            Option o = new Option(
                q.Name,
                q.Id
            );
            if(String.isNotBlank(selectId) && q.Id == selectId) {
                o.isSelected = true;
            }
            response.options.add(o);
        }

        return response;
    }

    /**
    * @description Gets a list of user options.  Passing in the selected id
    *   allows the value that is selected to be returned as such.
    * @author Brian Ezell (Simply EZ) | 10-03-2024 
    * @param selectId 
    * @return AssignResponse 
    **/
    private static AssignResponse getUserOptions(String selectId) {
        AssignResponse response = new AssignResponse();
        response.showCombo = true;
        response.optionsName = 'Users';
        response.options = new List<Option>();
        List<User> usrs = 
            [
                SELECT 
                    Id, FirstName, LastName
                FROM User 
                WHERE IsActive = true
                    AND Profile.Name != NULL
                WITH USER_MODE
                ORDER BY Name
            ];

        for(User u : usrs) {
            Option o = new Option(
                u.LastName + ', ' + u.FirstName,
                u.Id
            );
            if(String.isNotBlank(selectId) && u.Id == selectId) {
                o.isSelected = true;
            }
            response.options.add(o);
        }

        return response;
    }

    private static String coalesce(String val1, String val2) {
        return String.isBlank(val1) ? val2 : String.escapeSingleQuotes(val1);
    }


    /**
    * @description This class represents an owner assignment request
    * @author Brian Ezell (Simply EZ) | 10-03-2024 
    **/
    public class AssignRequest {
        public String assignType;
        public String selectedId;
        public String objectApiName;
    }


    /**
    * @description This class represents an assignment response
    * @author Brian Ezell (Simply EZ) | 10-03-2024 
    **/
    public class AssignResponse {
        public Boolean showCombo = true;
        public List<Option> options = new List<Option>();
        public String optionsName = '';

    }

    /**
    * @description This class represents an owner assignment response
    * @author Brian Ezell (Simply EZ) | 10-03-2024 
    **/
    public class GetAssignOwnerResponse {

        public String assignType = '';
        public String ownerId = '';
    }

        /**
    * @description This class represents an option in a picklist.
    * @author Brian Ezell (Simply EZ) | 10-03-2024 
    **/
    public class Option {

        public String label;
        public String value;
        public Boolean isSelected;

        /**
        * @description Initalizes the picklist option
        * @author Brian Ezell (Simply EZ) | 10-03-2024 
        * @param label 
        * @param value 
        **/
        public Option(String label, String value) {
            this.label = label;
            this.value = value;
            this.isSelected = false;
        }
    }

    /**
    * @description This class represents an owner assignment request
    * @author Brian Ezell (Simply EZ) | 10-03-2024 
    **/
    public class UpdateAssignedOwnerRequest {
        public String recordId = '';
        public String assignedId = '';
        public String assignedType = '';
        public String assignedOwnerName = '';
        public String assignTypeField = '';
        public String assignOwnerField = '';
        public String assignedOwnerNameField = '';
    }

}