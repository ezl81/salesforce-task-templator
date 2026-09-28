/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 09-22-2024
 * @last modified by  : Brian Ezell (Simply EZ)
**/
({
    doInit: function (component, event, helper) {
        helper.loadMasterTemplate(component);
    },

    onClickCloneTemplate: function (component, event, helper) {
        helper.cloneTemplate(component);
    },

    clickCancel: function (component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },

    clickClone: function(component, event, helper) {
        helper.cloneTemplate(component);
    }

})