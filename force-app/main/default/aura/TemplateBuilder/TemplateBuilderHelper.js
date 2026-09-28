/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 08-01-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
({
    loadAndShowTemplateNodes: function (component, helper) {
        component.set("v.isLoading", true);
        var templateId = component.get("v.recordId");
        var action = component.get("c.getTemplateNodes");
        action.setParams({
            templateId: templateId
        });

        action.setCallback(this, function (response) {
            if (response.getState() == "SUCCESS") {
                var templates = JSON.parse(response.getReturnValue());
                var tree = helper.setupGrid(component, helper, templates);
            } else {
                helper.showErrorMessage(response.getError()[0].message);
            }
            component.set("v.isLoading", false);
        });
        $A.enqueueAction(action);
    },

    setupGrid: function (component, helper, templates) {
        var data = [];
        for (var i = 0; i < templates.length; i++) {
            data.push(
                helper.getTemplateRows(component, helper, templates[i])
            );
        }
        component.set("v.gridData", data);
    },

    getTemplateRows: function (component, helper, template) {

        let allRowsForExpansion = [];
        let allRowsForCheckbox = [];

        var templateData = {
            name: template.name,
            objectId: template.objectId,
            tasks: template.numberOfChildSteps,
            childTasks: template.numberOfChildTemplateSteps,
            id: template.id,
            expanded: true,
            topLevelId: template.topLevelId,
            parentId: template.parentId,
            type: "Template",
            link: "/" + template.id,
            assignedName: template.assignedName,
            _children: [],
        };
        allRowsForExpansion.push(template.id);

        
        for (var i = 0; i < template.childTemplateList.length; i++) {
            var t = template.childTemplateList[i];
            templateData._children.push(
                helper.getTemplateRows(component, helper, t)
            );
            allRowsForExpansion.push(t.id);
        }

        for (var i = 0; i < template.childStepList.length; i++) {
            var task = template.childStepList[i];
            templateData._children.push({
                name: task.name,
                tasks: null,
                childTasks: null,
                id: task.id,
                type: "Task",
                link: "/" + task.id,
                expanded: true,
                assignedName: task.assignedName,
                parentId: template.id,
            });
        }
        component.set("v.allRowsForExpansion", allRowsForExpansion);
        return templateData;
    },

    getRowActions: function (component, row, doneCallback) {
        var actions = [];

        if (row.type == "Template") {
            actions.push({
                "label": "Add Task",
                "iconName": "utility:task",
                "name": "add_task",
            });
            actions.push({
                "label": "Add Event",
                "iconName": "utility:event",
                "name": "add_event",
            });
            actions.push({
                "label": "Add Template",
                "iconName": "utility:text_template",
                "name": "add_template",
            });
            actions.push({
                "label": "Edit",
                "iconName": "utility:edit",
                "name": "edit_template",
            });
            actions.push({
                "label": "Delete Template",
                "iconName": "utility:delete",
                "name": "delete_template",
            });
        } else {
            actions.push({
                "label": "Add Dependency",
                "iconName": "utility:zoom",
                "name": "add_dependency",
            });
            actions.push({
                "label": "Edit",
                "iconName": "utility:edit",
                "name": "edit_task",
            });
            actions.push({
                "label": "Delete Task",
                "iconName": "utility:delete",
                "name": "delete_task",
            });
        }

        doneCallback(actions);
    },

    deleteRecord: function (component, helper) {
        var deleteRecordType = component.get("v.deleteRecordConfirmationRecordType");
        var deleteRecordId = component.get("v.deleteRecordConfirmationRecordId");

        var action;

        if (deleteRecordType == "template") {
            action = component.get("c.deleteTemplateRecord");
        } else {
            action = component.get("c.deleteTaskRecord");
        }

        action.setParams({
            recordId: deleteRecordId
        });

        action.setCallback(this, function (response) {
            if (response.getState() == "SUCCESS") {
                helper.showSuccessMessage(helper, "Deleted");
                helper.loadAndShowTemplateNodes(component, helper);
            } else {
                showErrorMessage("An error occurred");
            }
        });
        $A.enqueueAction(action);
    },

    toggleAllNodes: function (component) {
        let allNodes = component.get("v.allRowsForExpansion");
        let isChecked = component.get("v.areAllNodesChecked");

        if (isChecked) {
            component.set('v.currentlyExpandedRows', allNodes);
        } else {
            component.set('v.currentlyExpandedRows', []);
        }
        component.set("v.areAllNodesChecked", !isChecked);
    },
    
    //Toast message functions
    showSuccessMessage: function (helper, msg) {
        helper.showToast(helper, msg, "success");
    },

    showErrorArray: function (helper, msgAry) {
        var msg = msgAry.join("\n");
        helper.showErrorMessage(msg);
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

    showToast: function (msg) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Success!",
            "message": msg,
            "type": "success"
        });
        toastEvent.fire();
    }

})