/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 09-03-2024
 * @last modified by  : Brian Ezell (Simply EZ)
**/
({
    invoke: function (component) {
        var redirect = $A.get("e.force:navigateToURL");
        let objectApiName = component.get("v.objectApiName");
        let url = '/lightning/o/' + objectApiName + '/home';
        redirect.setParams({
            "url" : url
        });
        redirect.fire();
    }
})