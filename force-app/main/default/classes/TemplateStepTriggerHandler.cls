/**
 * @description       : 
 * @author            : Brian Ezell (SimplyEZ)
 * @group             : 
 * @last modified on  : 07-11-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
public without sharing class TemplateStepTriggerHandler implements TriggerHandler {
    private boolean triggerIsExecuting;
    private integer triggerSize;
    public TemplateStepTriggerController ctrl;
    public TemplateStepTriggerHandler(boolean triggerIsExecuting, integer triggerSize) {
        this.triggerIsExecuting = triggerIsExecuting;
        this.triggerSize = triggerSize;
        this.ctrl = new TemplateStepTriggerController();
    }

    public void beforeInsert(List<SObject> newList) {
    }
    public void beforeUpdate(List<SObject> oldList, List<SObject> newList, Map<ID, SObject> oldMap, Map<ID, SObject> newMap) {
    }
    public void beforeDelete(List<SObject> oldCases, Map<ID, SObject> oldMap) {
    }
    public void afterInsert(List<SObject> newList, Map<ID, SObject> newMap) {
        List<Task_Template_Step__c> newStepList = newList;
        ctrl.updateTemplateStepCount(newStepList);
    }
    public void afterUpdate(List<SObject> oldList, List<SObject> newList, Map<ID, SObject> oldMap, Map<ID, SObject> newMap) {
    }
    public void afterDelete(List<SObject> oldList, Map<ID, SObject> oldMap) {
        List<Task_Template_Step__c> oldStepList = oldList;
        ctrl.updateTemplateStepCount(oldStepList);
    }
    public void afterUndelete(List<SObject> newList, Map<ID, SObject> newMap) {
    }
}