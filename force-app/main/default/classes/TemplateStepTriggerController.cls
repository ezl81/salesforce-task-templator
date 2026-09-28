/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 07-25-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
public with sharing class TemplateStepTriggerController {

   /**
    * @description Update count of steps on templates. Because its allowing
    *   multiple level of roll-ups, where templates can have child templates
    *   and steps off the template need to keep track of total number of tasks.
    * @author Brian Ezell (Simply EZ)
    * @param newSteps
    * @param oldSteps
    * @return void
    **/
    public void updateTemplateStepCount(List<Task_Template_Step__c> newSteps) {

        Set<Id> parentTemplateIds = new Set<Id>();
        for(Task_Template_Step__c s : newSteps) {
            parentTemplateIds.add(s.Parent_Task_Template__c);
        }

        TemplateHelper tempHelper = new TemplateHelper(parentTemplateIds);
        tempHelper.updateTemplateLevelCounts();
    }
}