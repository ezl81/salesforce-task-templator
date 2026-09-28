/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 05-30-2024
 * @last modified by  : Brian Ezell (Simply EZ)
**/
@IsTest
private class SObjectDataTest {

    @IsTest
    private static void testMakeObject() {

        SObject obj = SObjectData.makeObject('Account');
        Assert.isNotNull(obj, 'Expected object to not be null');

    }

}