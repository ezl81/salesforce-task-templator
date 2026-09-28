/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 08-01-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
({
    runImport : function(component) {
        component.set("v.isLoading", true);
        var importRequestId = component.get("v.recordId");

        var action = component.get("c.importTemplate");
        let request = {
            importRequestId: importRequestId
        };

        action.setParams({ request: JSON.stringify(request) });

        action.setCallback(this, function (response) {
            if (response.getState() == "SUCCESS") {
                var templateId = JSON.parse(response.getReturnValue()).masterTemplateId;
                component.set("v.masterTemplateUrl", '/' + templateId);
            } else {
                this.showErrorMessage(response.getError()[0].message);
            }
            component.set("v.isLoading", false);
        });
        $A.enqueueAction(action);
    },

    showSuccessMessage: function (msg) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Sccess!",
            "message": msg,
            "type": "success"
        });
        toastEvent.fire();
    },

    showErrorMessage: function (msg) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Error",
            "message": msg,
            "type": "error"
        });
        toastEvent.fire();
    },

})