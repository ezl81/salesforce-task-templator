/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 09-18-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
public with sharing class CaseTrackerController {

    public String mermaidFlow {get;set;}

    public String completedStyles {get;set;}

    private Set<String> completedTasksAndEvents;
    private String currentId;
    private Set<String> allIds = new Set<String>();

    public CaseTrackerController() {
        currentId = ApexPages.currentPage().getParameters().get('id');
        completedTasksAndEvents = new Set<String>();
        mermaidFlow  = '---\n' + 
            'config:\n' +
            ' layout: elk\n' +
            '---\n' +
            'graph TB\n' + getMermaidForTemplate(currentId);
    }

    public String getThisUrl() {
        return String.format('{0}&fullPages={1}&id={2}', new List<String>{
            ApexPages.currentPage().getUrl().escapeHtml4(),
            ApexPages.currentPage()?.getParameters()?.get('fullPages') == 'true' ? 'false' : 'true',
            currentId
        });   }

    public String getFullPageCss() {
        return String.format('{0}&fullPages={1}&id={2}', new List<String>{
            ApexPages.currentPage().getUrl().escapeHtml4(),
            ApexPages.currentPage()?.getParameters()?.get('fullPages') == 'true' ? 'true' : 'hidden',
            currentId
        });    
    }

    public Boolean getFullScreen() {
        Boolean fullScreenCheck = ApexPages.currentPage()?.getParameters()?.get('fullPages') == 'true';
        return fullScreenCheck;
    }

    public String getMermaidForTemplate(String id) {

        completedStyles = 'completed';
        Set<Id> caseIds = new Set<Id> {
            id
        };

        List<Case> allCases = CommonFunctions.getAssociatedCases(caseIds);

        //Determine which tasks/events are completed.
        //This changes some display options

        if(allCases == null) {
            return 'No Cases Found';
        }

        allIds.addAll(getAllIds(allCases));

        //Get the top level master template, then work
        //downwards
        Case masterCase = getMasterCase(allCases);

        if(masterCase.Status != Constants.TASK_COMPLETED_STATUS) {
            completedStyles += ' hidden';
        }

        List<String> flowList = new List<String>();
        flowList.addAll(getCaseFlow(allCases, masterCase));

        /*
        for(String thisId : allIds) {
            //Add a click link to each task/event
            flowList.add(String.format('click {0} "{1}" "Open in New Window" _blank', new List<String>{
                thisId,
                '../' + thisId
            }));
        }
        */

        //If we don't add dependencies last, if a dependency is referenced
        //before it is defined, it will show up in the dependency case
        //rather than the correct case
        for(Case c : allCases) {
            for(Task_Dependency__c d : c.Task_Dependencies__r) {
                flowList.add(d.Task_Depends_On_Id__c + '-.->' + d.Task_Id__c);
            }
        }

        //Add the class/colors
        for(String color : Constants.MERMAID_COLORS) {
            flowList.add(color);
        }

        return String.join(flowList, '\n\r');
    }

    private Set<String> getAllIds(List<Case> allCases) {
        Set<String> allIds = new Set<String>();
        for(Case c : allCases) {
            allIds.add(c.Id);
            if(c?.Tasks != null) {
                for(Task t : c.Tasks) {
                    allIds.add(t.Id);
                }
            }

            if(c?.Events != null) {
                for(Event e : c.Events) {
                    allIds.add(e.Id);
                }
            }
        }
        return allIds;
    }

    private Case getMasterCase(List<Case> allCases) {
        for(Case c : allCases) {
            if(c?.Master_Case__r.Case__c == c.Id) {
                return c;
            }
        }
        return null;
    }

    private List<String> getCaseFlow(List<Case> allCases, Case currentCase) {
        List<String> flowSteps = new List<String>();

        List<Case> childCases = new List<Case>();
        for(Case c : allCases) {
            if(c.ParentId == currentCase.Id) {
                childCases.add(c);
            }
        }

        String currentCaseName = CommonFunctions.makeMermaidSafe(currentCase.Subject);
        flowSteps.add(currentCase.Id + ':::' + Constants.MERMAID_MAIN_COLOR);
        flowSteps.add('subgraph ' + currentCase.Id + '["' + currentCaseName + '"]');

        flowSteps.addAll(getCaseStepsTasks(currentCase));
        flowSteps.addAll(getCaseStepsEvents(currentCase));
        for(Case c : childCases) {
            flowSteps.addAll(getCaseFlow(allCases, c));
        }

        flowSteps.add('end');
        return flowSteps;
    }

    private List<String> getCaseStepsTasks(Case currentCase) {
        List<String> flowSteps = new List<String>();
        for(Task t : currentCase.Tasks) {

            String imageHtml = '';
            if(Constants.USE_ICONS) {
                if(t.Is_Task_Completed__c) {
                    imageHtml = CommonFunctions.getImageTag(Constants.TASK_DONE_ICON_URL);
                } else {
                    imageHtml = CommonFunctions.getImageTag(Constants.TASK_ICON_URL);
                }
            }
            flowSteps.add(t.Id + ':::' + Constants.MERMAID_TASK_COLOR);
            flowSteps.add(t.Id + '("' + CommonFunctions.makeMermaidSafe(t.Subject) + imageHtml + '")');
        }
        return flowSteps;
    }

    private List<String> getCaseStepsEvents(Case currentCase) {
        List<String> flowSteps = new List<String>();
        for(Event e : currentCase.Events) {

            //if the event took place already, put an asterisk
            //next to it.
            String imageHtml = '';
            if(Constants.USE_ICONS) {
                if(e.Is_Task_Completed__c) {
                    imageHtml = CommonFunctions.getImageTag(Constants.EVENT_DONE_ICON_URL);
                } else {
                    imageHtml = CommonFunctions.getImageTag(Constants.EVENT_ICON_URL);
                }
            }
            flowSteps.add(e.Id + ':::' + Constants.MERMAID_EVENT_COLOR);
            flowSteps.add(e.Id + '(' + CommonFunctions.makeMermaidSafe(e.Subject) + imageHtml + ')');
        }
        return flowSteps;
    }
}