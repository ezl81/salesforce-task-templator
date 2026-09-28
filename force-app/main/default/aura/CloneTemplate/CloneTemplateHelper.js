/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 08-01-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
({
    loadMasterTemplate : function(component) {
        component.set("v.isLoading", true);
        var templateId = component.get("v.recordId");

        var action = component.get("c.getTemplate");
        action.setParams({
            templateId: templateId
        });

        action.setCallback(this, function (response) {
            if (response.getState() == "SUCCESS") {
                var thisTemplate = JSON.parse(response.getReturnValue());
                component.set("v.thisTemplate", thisTemplate);
                component.set("v.newTemplateName", thisTemplate.Name + " (Clone)");
            }
            else {
                this.showErrorMessage(response.getError()[0].message);
            }
            component.set("v.isLoading", false);
        });
        $A.enqueueAction(action);
    },
    
    cloneTemplate: function (component) {
        component.set("v.isLoading", true);
        var templateId = component.get("v.recordId");
        var newName = component.get("v.newTemplateName");

        var action = component.get("c.cloneTemplate");
        var request = {
            templateId: templateId,
            newName: newName
        };
        action.setParams({
            request: JSON.stringify(request)
        });

        action.setCallback(this, function (response) {
            if (response.getState() == "SUCCESS") {
                var response = JSON.parse(response.getReturnValue());
                this.showSuccessMessage('Template cloned successfully');

                //Navigate to newTemplateId page
                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                    "url": "/" + response.newTemplateId
                });
                urlEvent.fire();
            }
            else {
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

    showErrorMessage: function ( msg) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Error",
            "message": msg,
            "type": "error"
        });
        toastEvent.fire();
    },

})