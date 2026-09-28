/**
 * @description       : Gets around the required fields by applying defaults
 *  where needed for fields that don't have defaults.
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 05-30-2024
 * @last modified by  : Brian Ezell (Simply EZ)
**/
public with sharing class SObjectData {

//TEST SCRIPT:
/*
    SObject newObject = SObjectData.makeObject('Account');
    insert newObject;
    System.debug('New Object = ' + newObject);
*/

    private static final DateTime DATE_TIME_VALUE = Datetime.now();
    private static final Date DATE_VALUE = Date.today();
    private static final Map<String, Object> MAP_FIELD_TYPE_TO_DEFAULT_REQUIRED_VALUE = new Map<String, Object> {
        'STRING' => 'Test Text',
        'TEXTAREA' => 'Test Text',
        'DOUBLE' => (Double)5.2,
        'PHONE' => '123.456.7890',
        'INTEGER' => (Integer)10,
        'DATETIME' => DATE_TIME_VALUE,
        'DATE' => DATE_VALUE
    };
    
    /**
    * @description Creates a new object of type api name with the 
    *   required fields on the object along with any additional values
    *   that get passed in.
    * @author Brian Ezell (Simply EZ) | 05-27-2024 
    * @param objectApiName 
    * @param mapFieldsToValues 
    * @return SObject 
    **/
    public static SObject makeObject(String objectApiName) {

        //Create the object
        SObject so =  Schema.getGlobalDescribe().get(objectApiName).newSObject(null, true);

        //Get the fields
        Map<String, Schema.sObjectField> fieldMap = so.getSObjectType().getDescribe().fields.getMap();

        //Populate the requried fields

        for(String key : fieldMap.keySet()) {
            Schema.DescribeFieldResult fieldDescribe = fieldMap.get(key).getDescribe();
            //Requried:
            //  Is not able to be null
            //  No default on create
            //  Is createable
            //Then add a default value so it doesn't throw an error.
            if(!fieldDescribe.isNillable() && 
                !fieldDescribe.isDefaultedOnCreate() &&
                fieldDescribe.isCreateable()) {
                Object value = makeValue(fieldMap.get(key));
                so.put(key, value);
            }
        }
        return so;
    }

    private static Object makeValue(Schema.sObjectField field) {
        return MAP_FIELD_TYPE_TO_DEFAULT_REQUIRED_VALUE.get(field.getDescribe().getType().name());
    }
    
}