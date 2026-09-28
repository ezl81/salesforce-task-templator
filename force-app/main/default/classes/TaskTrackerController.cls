/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 09-18-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
public with sharing class TaskTrackerController {

    public String mermaidFlow {get;set;}

    private List<Task_Template__c> allTemplates;
    private Set<String> allIds = new Set<String>();
    private String currentId;
    //ApexPages.StandardController controller

    public TaskTrackerController() {
        currentId = ApexPages.currentPage()?.getParameters()?.get('id');
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
        });
    }

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

        //Get all assoicated templates
        allTemplates = CommonFunctions.getAllTemplates(id);

        //Get the top level master template, then work
        //downwards
        Task_Template__c masterTemplate;
        for(Task_Template__c t : allTemplates) {
            if(t.Parent_Template__c == null) {
                masterTemplate = t;
                allIds.add(t.Id);
                break;
            }
        }
        List<String> flowList = new List<String>();
        if(masterTemplate != null) {
            flowList.addAll(getTemplateFlow(masterTemplate));
        }
        
        for(Task_Template__c t : allTemplates) {
            for(Task_Template_Step_Dependency__c d : t.Task_Template_Step_Dependencies__r) {
                flowList.add(d.Depends_On_Step__c + '-.->' + d.Step__c);
            }
        }
        
        //Add the class/colors
        for(String color : Constants.MERMAID_COLORS) {
            flowList.add(color);
        }
        /*
        for(String thisId : allIds) {
            flowList.add(String.format('click {0} "{1}" "Open in New Window" _blank', new List<String>{
                thisId,
                '../' + thisId
            }));
        }
        */

        String returnString = String.join(flowList, '\n\r');
        return returnString;
    }

    private List<String> getTemplateFlow(Task_Template__c currentTemplate) {

        List<String> flowSteps = new List<String>();
     
        List<Task_Template__c> childTemplates = new List<Task_Template__c>();

        allIds.add(currentTemplate.Id);
        for(Task_Template__c t : allTemplates) {
            if(t?.Parent_Template__c == currentTemplate?.Id) {
                childTemplates.add(t);
                allIds.add(t.Id);
            }
        }

        String currentTemplateName = CommonFunctions.makeMermaidSafe(currentTemplate.Name);
        flowSteps.add(currentTemplate.Id + ':::' + Constants.MERMAID_MAIN_COLOR);
        flowSteps.add('subgraph ' +  currentTemplate.Id + '["' + currentTemplateName +'"]');

        for(Task_Template__c t : childTemplates) {
            flowSteps.addAll(getTemplateFlow(t));
        }

        flowSteps.addAll(getTemplateStepsFlow(currentTemplate));
        flowSteps.add('end');

        return flowSteps;
    }

    private List<String> getTemplateStepsFlow(Task_Template__c template) {
        List<String> flowSteps = new List<String>();
        for(Task_Template_Step__c step : template.Parent_Task_Template_Steps__r) {

            allIds.add(step.Id);
            String imageHtml = '';
            if(step.Activity_Type__c == 'Task') {
                imageHtml = CommonFunctions.getImageTag(Constants.TASK_ICON_URL);
                flowSteps.add(step.Id + ':::' + Constants.MERMAID_TASK_COLOR);
            } else {
                imageHtml = CommonFunctions.getImageTag(Constants.EVENT_ICON_URL);
                flowSteps.add(step.Id + ':::' + Constants.MERMAID_EVENT_COLOR);
            }
            flowSteps.add(step.Id + '(' + CommonFunctions.makeMermaidSafe(step.Name) + imageHtml +')');
        }
        return flowSteps;
    }
}