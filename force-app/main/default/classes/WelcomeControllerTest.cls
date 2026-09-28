/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 09-03-2024
 * @last modified by  : Brian Ezell (Simply EZ)
**/
@IsTest
private class WelcomeControllerTest {

    @IsTest
    private static void testGetPicklistObjects() {
        String results = WelcomeController.getPicklistObjects();
        Assert.isNotNull(results, 'Expected object to not be null');
        List<Schema.PicklistEntry> picklistValues = (List<Schema.PicklistEntry>) JSON.deserialize(results, List<Schema.PicklistEntry>.class);
        Assert.isNotNull(picklistValues, 'Expected picklist values to not be null');
    }

}