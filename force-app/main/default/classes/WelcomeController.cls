/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 06-16-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
public with sharing class WelcomeController {

    /**
    * @description Gets a list of picklist labels/values for the Templated_Objects__c field on Task_Template__c
    * @author Brian Ezell (Simply EZ) | 09-03-2024 
    * @return String 
    **/
    @AuraEnabled
    public static String getPicklistObjects() {
        try {
            List<Schema.PicklistEntry> picklistValues = CommonFunctions.getPicklistValues('Task_Template__c', 'Templated_Objects__c');
            return JSON.serialize(picklistValues);
        } catch (Exception e) {
            throw new AuraHandledException(CommonFunctions.getExceptionError(e));
        }
    }

}