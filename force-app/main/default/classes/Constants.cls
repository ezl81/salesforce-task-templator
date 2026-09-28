/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 09-18-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
public with sharing class Constants {

    public static final String APP_VERSION = '1.0';
    public static final String APP_LANGUAGE = 'en_US';
    public static final String APP_COUNTRY = 'US';
    public static final String APP_STATUS = 'Active';

    //Task statuses
    public static final String TASK_PENDING_STATUS = 
        [
            SELECT Id, Value__c
            FROM Simply_Task_Setting__mdt 
            WHERE Area__c = 'Task'
                AND Name__c = 'Pending Status'
            WITH USER_MODE
        ].Value__c;

    public static final String TASK_START_STATUS =         
        [
            SELECT Id, Value__c
            FROM Simply_Task_Setting__mdt 
            WHERE Area__c = 'Task'
                AND Name__c = 'Start Status'
            WITH USER_MODE
        ].Value__c;

    public static final String TASK_COMPLETED_STATUS =         
        [
            SELECT Id, Value__c
            FROM Simply_Task_Setting__mdt 
            WHERE Area__c = 'Task'
                AND Name__c = 'Completed Status'
            WITH USER_MODE
        ].Value__c;

    //Case Statuses
    //Task statuses
    public static final String CASE_WORKING_STATUS = 
        [
            SELECT Id, Value__c
            FROM Simply_Task_Setting__mdt 
            WHERE Area__c = 'Case'
                AND Name__c = 'Working Status'
            WITH USER_MODE
        ].Value__c;

    public static final String CASE_START_STATUS =         
        [
            SELECT Id, Value__c
            FROM Simply_Task_Setting__mdt 
            WHERE Area__c = 'Case'
                AND Name__c = 'Start Status'
            WITH USER_MODE
        ].Value__c;

    public static final String CASE_CLOSED_STATUS =         
        [
            SELECT Id, Value__c
            FROM Simply_Task_Setting__mdt 
            WHERE Area__c = 'Case'
                AND Name__c = 'Completed Status'
            WITH USER_MODE
        ].Value__c;

    public static final Id SIMPLY_TASK_CASE_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Simply Tasks Case').getRecordTypeId();

    //Used mainly for test data
    public static final String SYSTEM_ADMIN_PROFILE_NAME = 'System Administrator';
    public static final String STANDARD_USER_PROFILE_NAME = 'Standard User';

    public static final Boolean USE_ICONS = true;
    public static final String TASK_ICON_URL = CommonFunctions.getStaticResourceUrl('task');
    public static final String EVENT_ICON_URL = CommonFunctions.getStaticResourceUrl('event');
    public static final String TASK_DONE_ICON_URL = CommonFunctions.getStaticResourceUrl('taskdone');
    public static final String EVENT_DONE_ICON_URL = CommonFunctions.getStaticResourceUrl('eventdone');

    public static final String MERMAID_MAIN_COLOR = 'white';
    public static final String MERMAID_TASK_COLOR = 'blue';
    public static final String MERMAID_EVENT_COLOR = 'green';

    public static final List<String> MERMAID_COLORS = new List<String>{
        'classDef green fill:lightgreen,stroke:#333,stroke-width:2px',
        'classDef blue fill:lightblue,stroke:#333,stroke-width:2px',
        'classDef white fill:white,stroke:#333,stroke-width:2px'
    };

}