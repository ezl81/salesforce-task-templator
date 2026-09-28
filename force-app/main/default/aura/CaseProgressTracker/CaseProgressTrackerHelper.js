/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 08-28-2024
 * @last modified by  : Brian Ezell (Simply EZ)
**/
({
    loadSummary: function (component, helper) {
        var caseId = component.get("v.recordId");
        var action = component.get("c.getChildTasksSummary");
        action.setParams({
            caseId: caseId
        });

        action.setCallback(this, function (response) {
            if (response.getState() == "SUCCESS") {
                var caseSummaries = JSON.parse(response.getReturnValue());
                var totalTasks = 0;
                var completeTasks = 0;

                var maximumIndent = 11;

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
                    caseSummaries[i].isCurrentCase = caseId == caseSummaries[i].caseId;
                    caseSummaries[i].indent = maximumIndent - (maximumIndent - caseSummaries[i].level);
                    caseSummaries[i].childLabel = "(" + caseSummaries[i].childTasksCompleted + " / " + caseSummaries[i].childTasks + ")";
                    caseSummaries[i].childValue = childPct;
                    caseSummaries[i].compositePct = compositePct;
                    caseSummaries[i].compositeLabel = caseSummaries[i].caseName + ' (' + compositeCompletedTasks + " / " + compositeTotalTasks + ')';

                }
                component.set("v.CaseSummaryList", caseSummaries);
                component.set("v.OverallPercentComplete", 100 * (completeTasks / totalTasks));
                component.set("v.OverallTitle", (100 * (completeTasks / totalTasks)).toFixed(2) + "%");
            }
            else {
                helper.showErrorMessageAry(helper, response.getError());
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

    showToast: function (msg) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Success!",
            "message": msg,
            "type": "success"
        });
        toastEvent.fire();
    },
})