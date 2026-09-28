/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 08-28-2024
 * @last modified by  : Brian Ezell (Simply EZ)
**/
({
    loadCases: function (component, helper) {
        var recordId = component.get("v.recordId");
        var recordLinkedField = component.get("v.CaseLinkedField");
        var action = component.get("c.getCaseSummaries");
        action.setParams({
            objectId: recordId,
            caseLinkedField: recordLinkedField
        });

        action.setCallback(this, function (response) {
            if (response.getState() == "SUCCESS") {
                var objectCaseSummaries = JSON.parse(response.getReturnValue());

                for (var x = 0; x < objectCaseSummaries.length; x++) {

                    var totalTasks = 0;
                    var completeTasks = 0;
                    var caseSummaries = objectCaseSummaries[x].summaries;

                    for (var i = 0; i < caseSummaries.length; i++) {
                        totalTasks += caseSummaries[i].totalTasks;
                        completeTasks += caseSummaries[i].completeTasks;
                        var pct = (100 * (caseSummaries[i].completeTasks / caseSummaries[i].totalTasks)).toFixed(2);
                        if (isNaN(pct)) {
                            pct = 100;
                        }
                        var childPct = (100 * (caseSummaries[i].childTasksCompleted / caseSummaries[i].childTasks)).toFixed(2);
                        if (isNaN(childPct)) {
                            childPct = 100;
                        }
                        var compositeTotalTasks = caseSummaries[i].totalTasks + caseSummaries[i].childTasks;
                        var compositeCompletedTasks = caseSummaries[i].completeTasks + caseSummaries[i].childTasksCompleted;
                        var compositePct = (100 * (compositeCompletedTasks / compositeTotalTasks)).toFixed(2);

                        caseSummaries[i].label = caseSummaries[i].caseName + ' (' + pct + '%)';
                        caseSummaries[i].value = pct;
                        caseSummaries[i].display = "(" + caseSummaries[i].completeTasks + " / " + caseSummaries[i].totalTasks + ")";
                        caseSummaries[i].isCurrentCase = false;
                        caseSummaries[i].indent = 11 - (11 - caseSummaries[i].level);
                        caseSummaries[i].childLabel = "(" + caseSummaries[i].childTasksCompleted + " / " + caseSummaries[i].childTasks + ")";
                        caseSummaries[i].childValue = childPct;
                        caseSummaries[i].compositePct = compositePct;
                        caseSummaries[i].compositeLabel = caseSummaries[i].caseName + ' (' + compositeCompletedTasks + " / " + compositeTotalTasks + ')';
                        caseSummaries[i].caseUrl = '/' + caseSummaries[i].caseId;
                    }
                    objectCaseSummaries[x].overallPercentComplete = (100 * (completeTasks / totalTasks)).toFixed(2);
                    objectCaseSummaries[x].label = objectCaseSummaries[x].parentCaseName + ' (' + objectCaseSummaries[x].overallPercentComplete + '%)';
                }
                component.set("v.CaseListOfSummaries", objectCaseSummaries);
            }
            else {
                helper.showErrorMessage(helper, response.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },

    //Toast message functions
    showSuccessMessage: function (helper, msg) {
        helper.showToast(helper, msg, "success");
    },

    showErrorArray: function (helper, msgAry) {
        var msg = msgAry.join("\n");
        helper.showErrorMessage(helper, msg);
    },

    showErrorMessage: function (helper, msg) {
        helper.showToast(helper, msg, "error");
    },

    showToast: function (helper, msg, msgType) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Success!",
            "message": msg,
            "type": msgType
        });
        toastEvent.fire();
    },
})