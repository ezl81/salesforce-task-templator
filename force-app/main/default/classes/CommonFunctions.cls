/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 09-18-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
public with sharing class CommonFunctions {

    private static final Integer MAX_LIST_OBJECTS_TO_PRINT = 10;

    /**
    * @description Prints a debug message and returns a 
    *   more readable/consistent message for showing the user.
    * @author Brian Ezell (Simply EZ) | 05-15-2024 
    * @param e 
    * @return String 
    **/
    public static String getExceptionError(Exception e)
    {
        String msg = '';
        
        if(e.getCause() != null) {
            msg = getExceptionError(e.getCause()) + '\n';
        }

        msg += 'Error: [' + e.getMessage() +']';
        msg += '\nStack Trace: ' + e.getStackTraceString();

        return msg;
    }

   /**
   * @description Gets all case information related to the case passed in.
   * @author Brian Ezell (Simply EZ) | 05-15-2024 
   * @param caseId 
   * @return List<Case> 
   **/
   public static List<Case> getAssociatedCases(Set<Id> caseIds) {
        //Shouldn't happen, but there could be multiple master cases associated with these cases.
        //Since that's the case need to iterate over the master cases to ensure we get them all.
        List<Master_Case__c> masterCases = CaseTemplateHelper.loadAllCasesFromCaseIds(caseIds);
        List<Case> allCases = new List<Case>();

        for(Master_Case__c masterCase : masterCases) {
            allCases.addAll(masterCase.Cases__r);
        }
        return allCases;
    }


    /**
    * @description Gets a list of picklist values given the object name and field name
    * @author Brian Ezell (Simply EZ) | 09-03-2024 
    * @param objectName 
    * @param fieldName 
    * @return List<Schema.PicklistEntry> 
    **/
    public static List<Schema.PicklistEntry> getPicklistValues(String objectName, String fieldName) {
        Schema.SObjectType objSobjectType = Schema.getGlobalDescribe().get(objectName) ;
        Schema.DescribeSObjectResult objDescribeSobject = objSobjectType.getDescribe() ;
        Map<String,Schema.SObjectField> fields = objDescribeSobject.fields.getMap() ;
        Schema.DescribeFieldResult fieldResult = fields.get(fieldName).getDescribe();
        return fieldResult.getPicklistValues();
    }

    /**
    * @description Determins if the field is in the SObject ignoring case on name.
    * @author Brian Ezell (Simply EZ) | 05-23-2024 
    * @param sObjectApiName 
    * @param field 
    * @return Boolean 
    **/
    public static Boolean isColumnInSObject(String sObjectApiName, String field) {
        SObjectType accountType = Schema.getGlobalDescribe().get(sObjectApiName);
        Map<String,Schema.SObjectField> mfields = accountType.getDescribe().fields.getMap();
        for(String key : mfields.keySet()) {
            if(key.equalsIgnoreCase(field)) {
                return true;
            }
        }
        return false;
    }

    /**
    * @description Makes a string safe for displaying in Mermaid for the flow charts.
    * @author Brian Ezell (Simply EZ) | 06-04-2024 
    * @param str 
    * @return String 
    **/
    public static String makeMermaidSafe(String str) {
        return '"' + str.replaceAll('"', '') + '"';
    }
    
    /**
    * @description Used for printing out SObject Lists
    *   Mainly for debugging purposes
    * @author Brian Ezell (Simply EZ) | 07-30-2024 
    * @param soList 
    **/
    public static void printSObjectList(List<SObject> soList) {
        Integer i = 0;
        for(SObject so : soList) {
            printSObject(so);
            i++;
            if(i > MAX_LIST_OBJECTS_TO_PRINT) {
                break;
            }
        }
    }

    /**
    * @description Loads a static resource body from a resource name
    * @author Brian Ezell (SimplyEZ) | 08-27-2024 
    * @param resourceName 
    * @return String 
    **/
    public static String loadStaticResource(String resourceName) {
        StaticResource sr = 
            [
                SELECT Id, SystemModStamp, Name, Body
                FROM StaticResource 
                WHERE Name = :resourceName
                WITH USER_MODE
                LIMIT 1
            ];
        return sr.Body.toString();
    }

    public static String getStaticResourceUrl(String resourceName) {
        return '/resource/' + resourceName;
    }

    public static List<Task_Template__c> getAllTemplates(String templateId) {
      Task_Template__c thisTemplate = 
            [
                SELECT 
                    Id, 
                    Name, 
                    Master_Task_Template__c
                FROM Task_Template__c
                WHERE Id = :templateId
                WITH USER_MODE
            ];

        List<Task_Template__c> templates = 
            [
                SELECT
                    Id,
                    Name,
                    Number_of_Child_Steps__c,
                    Number_Of_Child_Template_Steps__c,
                    Parent_Template__c,
                    Master_Task_Template__c,
                    Master_Task_Template__r.Task_Template__c,
                    Assigned_To_Name__c,
                    Templated_Object__c,
                    Level__c,
                    (
                        SELECT
                            Id,
                            Depends_On_Step__c,
                            Task_Template__r.Name,
                            Depends_On_Step__r.Name,
                            Step__c,
                            Description__c,
                            Task_Template__c,
                            Step__r.Activity_Type__c
                        FROM
                            Task_Template_Step_Dependencies__r
                    ),
                    (
                        SELECT
                            Id,
                            Name,
                            Assigned_To_Name__c,
                            Activity_Type__c,
                            Order__c,
                            (
                                SELECT
                                    Id,
                                    Depends_On_Step__c,
                                    Task_Template__r.Name,
                                    Depends_On_Step__r.Name,
                                    Step__c,
                                    Description__c,
                                    Task_Template__c
                                FROM
                                    Task_Template_Step_Dependencies__r
                            )
                        FROM
                            Parent_Task_Template_Steps__r
                        ORDER BY
                            Order__c,
                            Name
                    ),
                    (
                        SELECT
                            Id,
                            Name,
                            Number_of_Child_Steps__c,
                            Assigned_To_Name__c,
                            Number_Of_Child_Template_Steps__c,
                            Parent_Template__c,
                            Templated_Object__c,
                            Master_Task_Template__c,
                            (
                                SELECT
                                    Id,
                                    Name,
                                    Assigned_To_Name__c,
                                    Activity_Type__c,
                                    Order__c,
                                    (
                                        SELECT
                                            Id,
                                            Depends_On_Step__c,
                                            Task_Template__r.Name,
                                            Depends_On_Step__r.Name,
                                            Step__c,
                                            Description__c,
                                            Task_Template__c,
                                            Step__r.Activity_Type__c
                                        FROM
                                            Task_Template_Step_Dependencies__r
                                    )
                                FROM
                                    Parent_Task_Template_Steps__r
                                ORDER BY
                                    Order__c,
                                    Name
                            )
                        FROM
                            Task_Templates__r
                        ORDER BY
                            Level__c,
                            Name
                    )
                FROM Task_Template__c
                WHERE Master_Task_Template__c = :thisTemplate.Master_Task_Template__c
                WITH USER_MODE
                ORDER BY 
                    Level__c, 
                    Name
            ];
        return templates;
    }

    /**
    * @description Creates the content version and attaches it to the object
    * @author Brian Ezell (Simply EZ) | 09-08-2024 
    * @param objectId 
    * @param fileName 
    * @param fileContent 
    **/
    public static void createObjectDocument(Id objectId, String fileName, Blob fileBlob) {
        ContentVersion cv = createContentVersion(fileName, fileBlob);

        insert as user cv;

        cv = 
            [
                SELECT Id, ContentDocumentId 
                FROM ContentVersion 
                WHERE Id = :cv.Id
                WITH USER_MODE
                LIMIT 1
            ];
        ContentDocumentLink cdl = createContentDocumentLink(cv.ContentDocumentId, objectId);

        insert as user cdl;
    }

    /**
    * @description Create a link between a document and an object
    * @author Brian Ezell (Slalom) | 04-29-2024 
    * @param contentDocumentId 
    * @param parentId 
    * @return ContentDocumentLink 
    **/
    public static ContentDocumentLink createContentDocumentLink(Id contentDocumentId, Id parentId) {
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
        contentDocumentLink.ContentDocumentId = contentDocumentId;
        contentDocumentLink.LinkedEntityId = parentId;
        return contentDocumentLink;
    }

    /**
    * @description Creates a document in Salesforce with the name and content
    *   passed in.
    * @author Brian Ezell (Slalom) | 04-29-2024 
    * @param name 
    * @param body 
    * @return ContentVersion 
    **/
    public static ContentVersion createContentVersion(String name, Blob body) {
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.ContentLocation = 'S'; // S = Stored in Salesforce
        contentVersion.PathOnClient = name;
        contentVersion.Title = name;
        contentVersion.VersionData = body;
        return contentVersion;
    }

    /**
    * @description Gets the formatted tag for the image shown on the tracker pages.
    * @author Brian Ezell (Simply EZ) | 09-18-2025 
    * @param iconUrl 
    * @return String 
    **/
    public static String getImageTag(String iconUrl) {
        return Constants.USE_ICONS ? ' <img src=\'' + iconUrl + '\' class=\'simply-ez-icon\'/> ' : '';
    }

    public static List<String> getObjectMainFieldList(String objectApiName) {

        String mainFieldName = CommonFunctions.getObjectMainField(objectApiName);
        List<String> fields = new List<String>();

        switch on objectApiName.toLowerCase() {
            when 'opportunity' {
                fields.addAll(new List<String> {'Id', mainFieldName, 'AccountId', 'OwnerId'});
            }
            when 'case' {
                fields.addAll(new List<String> {'Id', mainFieldName, 'OwnerId'});
            }
            when else {
                fields.addAll(new List<String> {'Id', mainFieldName, 'OwnerId'});
            }
        }
        return fields;
    }


    public static String getObjectMainField(String objectApiName) {
        if(objectApiName == null) {
            throw new AuraHandledException('Object Api Name not set.');
        }
        switch on objectApiName.toLowerCase() {
            when 'opportunity' {
                return 'Subject';
            }
            when 'case' {
                return 'Subject';
            }
            when else {
                return 'Name';
            }
        }
    }

    public static void printFullException (Exception ex) {

        if(ex.getCause() != null) {
            printFullException(ex.getCause());
        }

        System.debug('Error: ' + ex.getMessage());
        System.debug('Stack: ' + ex.getStackTraceString());
    }

    /**
    * @description Used for print out SObjects
    *   Mainly for debugging purposes
    * @author Brian Ezell (Simply EZ) | 07-30-2024 
    * @param so 
    **/
    private static void printSObject(SObject so) {
        Map<String, Object> soFieldMap = so.getPopulatedFieldsAsMap();
        System.debug('***OBJECT ' + so.getSObjectType().getDescribe().getName() + ' ***');
        for(String fieldName : soFieldMap.keySet()) {
            System.debug('  ' +fieldName + ' = ' + so.get(fieldName));
        }
    }

}