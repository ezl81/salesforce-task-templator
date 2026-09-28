/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 08-13-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
({
    loadTaskList: function (component) {

        try {
            var caseId = component.get("v.recordId");
            var action = component.get("c.getTaskList");
            action.setParams({
                caseId: caseId
            });

            action.setCallback(this, function (response) {
                if (response.getState() == "SUCCESS") {
                    var rObj = JSON.parse(response.getReturnValue());
                    if (rObj.IsSuccessful) {
                        var taskItems = rObj.TaskItems;
                        var selectItems = this.getSelectedItemsFromTaskList(taskItems);
                        var optionItems = this.getOptionItemsFromTaskList(taskItems);

                        console.log('***OPTIONS***');
                        console.log(JSON.stringify(optionItems));

                        component.set("v.TaskList", optionItems);
                        component.set("v.CompletedTasks", selectItems);
                    }
                    else {
                        this.showErrorMessageAry(rObj.Messages);
                    }
                }
            });
            $A.enqueueAction(action);
        } catch (e) {
            this.showErrorMessage('Error occurred.');
        }
    },

    saveTaskList: function (component) {

        try {
            var action = component.get("c.updateTaskList");
            var caseId = component.get("v.recordId");
            var optionList = component.get("v.TaskList");
            var selectedList = component.get("v.CompletedTasks");
            //var taskList = this.getTaskListFromOptionItems(selectedList, optionList);
            var jsonTaskList = JSON.stringify(selectedList);
            action.setParams({
                'caseId': caseId,
                'jsonTaskList': jsonTaskList
            });

            action.setCallback(this, function (response) {
                if (response.getState() == "SUCCESS") {
                    var responseStr = response.getReturnValue();
                    if (typeof (responseStr) == 'undefined') {
                        this.showErrorMessage("Response was undefined - error occurred.");
                    }
                    else {
                        var rObj = JSON.parse(responseStr);
                        if (rObj.IsSuccessful) {
                            var taskItems = rObj.TaskItems;
                            var selectItems = this.getSelectedItemsFromTaskList(component, taskItems);
                            var optionItems = this.getOptionItemsFromTaskList(component, taskItems);

                            component.set("v.TaskList", optionItems);
                            component.set("v.CompletedTasks", selectItems);
                            this.showSuccessMessage('Case tasks updated.');

                            $A.get('e.force:refreshView').fire();
                        } else {
                            this.showErrorArray(rObj.Messages);
                        }
                    }
                    $A.get("e.force:refreshView").fire();
                } else {
                    this.showErrorArrayFromResponse(response);
                    this.loadTaskList(component);
                }
            });
            $A.enqueueAction(action);
        } catch (e) {
            this.showErrorMessage('Error occurred.');
        }
    },

    getSelectedItemsFromTaskList: function (taskItems) {
        var selectedItems = [];
        for (var i in taskItems) {
            var item = taskItems[i];
            if (item.IsComplete) {
                selectedItems.push(item.Id);
            }
        }
        return selectedItems;
    },

    getOptionItemsFromTaskList: function (taskItems) {
        var optionItems = [];
        for (var i in taskItems) {
            var item = taskItems[i];
            optionItems.push({
                "label": item.Name,
                "value": item.Id
            });
        }
        return optionItems;
    },

    getTaskListFromOptionItems: function (selectedItems, optionItems) {
        var taskList = [];
        for (var i in optionItems) {
            var item = optionItems[i];
            taskList.push({
                "Name": item.Name,
                "IsComplete": this.isItemInSelectedList(item, selectedItems)
            });
        }
        return taskList;
    },

    isItemInSelectedList: function (item, selectedItems) {
        for (var i in selectedItems) {
            var currentSelected = selectedItems[i];
            if (item.value == currentSelected) {
                return true;
            }
        }
        return false;
    },

    toggleLoading: function (component, isLoading) {
        component.set("v.IsLoading", isLoading);
    },

    //Toast message functions
    showSuccessMessage: function (msg) {
        this.showToast(msg, "success");
    },

    showErrorArray: function (msgAry) {
        this.showErrorMessage(msgAry);
    },

    showErrorArrayFromResponse: function (response) {
        var errors = response.getError();
        var msgs = [];
        for (var x = 0; x < errors.length; x++) {
            var errorMsg = errors[x].message;
            if (errorMsg.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION') > -1) {
                errorMsg = errorMsg.split('FIELD_CUSTOM_VALIDATION_EXCEPTION, ')[1].split(':')[0];
                msgs.push(errorMsg);
            } else {
                msgs.push(errors[x].message);
            }
        }
        this.showErrorMessage(msgs.join());
    },

    showErrorMessage: function (msg) {
        this.showToast(msg, "error");
    },

    showToast: function (msg, msgType) {
        var toastEvent = $A.get("e.force:showToast");
        var toastMode = (msgType == "success" ? "dismissible" : "sticky");
        var toastTitle = (msgType == "success" ? "Success" : "Error");
        var toastIcon = (msgType == "success" ? "check" : "error");
        toastEvent.setParams({
            "title": toastTitle,
            "message": msg,
            "mode": toastMode,
            "type": msgType,
            "key": toastIcon
        });
        toastEvent.fire();
    }
})