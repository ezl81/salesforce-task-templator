/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 08-01-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
({
    doInit: function (component, event, helper) {

        var rowActions = helper.getRowActions.bind(this, component);

        var columns = [
            {
                type: "url",
                fieldName: "link",
                label: "Name",
                typeAttributes: {
                    label: { fieldName: "name" }
                },
            },
            {
                type: "number",
                fieldName: "tasks",
                label: "Tasks"
            },
            {
                type: "number",
                fieldName: "childTasks",
                label: "Child Template Tasks"
            },
            {
                type: "string",
                fieldName: "assignedName",
                label: "Assigned To"
            },
            {
                type: "action",
                typeAttributes: { rowActions: rowActions }
            }
        ];
        component.set("v.columns", columns);
        helper.loadAndShowTemplateNodes(component, helper);
    },

    handleRowAction: function (component, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');

        switch (action.name) {
            case 'add_event':
                var createRecordEvent = $A.get("e.force:createRecord");
                createRecordEvent.setParams({
                    "entityApiName": "Task_Template_Step__c",
                    "defaultFieldValues": {
                        "Parent_Task_Template__c": row.id,
                        "Activity_Type__c": "Event",
                        "Order__c": row.tasks + 1,
                    },
                    "panelOnDestroyCallback": function () {
                        $A.get('e.force:refreshView').fire();
                        helper.loadAndShowTemplateNodes(component, helper);
                    },
                    "navigationLocation": "LOOKUP",
                });
                createRecordEvent.fire();

                break;

            case 'add_task':
                var createRecordEvent = $A.get("e.force:createRecord");
                createRecordEvent.setParams({
                    "entityApiName": "Task_Template_Step__c",
                    "defaultFieldValues": {
                        "Parent_Task_Template__c": row.id,
                        "Activity_Type__c": "Task",
                        "Order__c": row.tasks + 1,
                    },
                    "panelOnDestroyCallback": function (event) {
                        $A.get('e.force:refreshView').fire();
                        helper.loadAndShowTemplateNodes(component, helper);
                    },
                    "navigationLocation": "LOOKUP",
                });
                createRecordEvent.fire();

                break;

            case 'add_template':
                var createRecordEvent = $A.get("e.force:createRecord");
                createRecordEvent.setParams({
                    "entityApiName": "Task_Template__c",
                    "defaultFieldValues": {
                        "Parent_Template__c": row.id,
                        "Master_Task_Template__c": row.topLevelId,
                        "Templated_Object__c": row.objectId,
                        "Assigned_Type__c": "Person Creating"
                    },
                    "panelOnDestroyCallback": function () {
                        $A.get('e.force:refreshView').fire();
                        helper.loadAndShowTemplateNodes(component, helper);
                    },
                    "navigationLocation": "LOOKUP",
                });
                createRecordEvent.fire();

                break;

            case "add_dependency":
                var createRecordEvent = $A.get("e.force:createRecord");
                createRecordEvent.setParams({
                    "entityApiName": "Task_Template_Step_Dependency__c",
                    "defaultFieldValues": {
                        "Task_Template__c": row.parentId,
                        "Step__c": row.id,
                    },
                    "panelOnDestroyCallback": function (event) {
                        $A.get('e.force:refreshView').fire();
                        helper.loadAndShowTemplateNodes(component, helper);
                    },
                    "navigationLocation": "LOOKUP",
                });
                createRecordEvent.fire();
                break;

            case "edit_task": 
            case "edit_template":
                var editRecordEvent = $A.get("e.force:editRecord");
                editRecordEvent.setParams({
                    "recordId": row.id,
                });
                editRecordEvent.fire();                
                break;
            
            case "delete_template":
                component.set("v.deleteRecordConfirmationRecordType", "template");
                component.set("v.deleteRecordConfirmationRecordId", row.id);
                helper.showDeleteConfirmationDialog(component, helper);
                break;

            case "delete_task":
                component.set("v.deleteRecordConfirmationRecordType", "task");
                component.set("v.deleteRecordConfirmationRecordId", row.id);
                helper.showDeleteConfirmationDialog(component, helper);
                break;
        }
    },

    handleToggleAllNodes: function (component, event, helper) {
        helper.toggleAllNodes(component);
    }
})