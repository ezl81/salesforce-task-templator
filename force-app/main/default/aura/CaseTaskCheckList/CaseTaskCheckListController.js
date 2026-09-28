/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 08-01-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
({
    doInit: function (component, event, helper) {
        helper.toggleLoading(component, true);
        helper.loadTaskList(component);
        helper.toggleLoading(component, false);
    },

    saveTaskList: function (component, event, helper) {
        helper.toggleLoading(component, true);
        helper.saveTaskList(component);
        helper.toggleLoading(component, false);
    },

    toggleTaskListItem: function (component, event, helper) {
        helper.toggleLoading(component, true);
        helper.saveTaskList(component);
        helper.toggleLoading(component, false);
    }
})