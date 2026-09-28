/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 08-01-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
({
    exportTemplate: function (component) {
        
        component.set("v.isLoading", true);
        var templateId = component.get("v.recordId");

        var action = component.get("c.exportTemplate");
        let request = {
            templateId: templateId
        };

        action.setParams({ request: JSON.stringify(request)});

        action.setCallback(this, function (response) {
            if (response.getState() == "SUCCESS") {
                var exportTemplateId = JSON.parse(response.getReturnValue()).exportTemplateId;
                component.set("v.exportTemplateUrl", '/' + exportTemplateId);
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