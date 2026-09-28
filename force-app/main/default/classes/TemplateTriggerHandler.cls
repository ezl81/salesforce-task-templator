/**
 * @description       : 
 * @author            : Brian Ezell (SimplyEZ)
 * @group             : 
 * @last modified on  : 07-25-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
public without sharing class TemplateTriggerHandler implements TriggerHandler {
    
    private boolean triggerIsExecuting;
    private integer triggerSize;
    public TemplateTriggerController ctrl;
    public TemplateTriggerHandler(boolean triggerIsExecuting, integer triggerSize) {
        this.triggerIsExecuting = triggerIsExecuting;
        this.triggerSize = triggerSize;
        this.ctrl = new TemplateTriggerController();
    }

    public void beforeInsert(List<SObject> newList) {
    }

    public void beforeUpdate(List<SObject> oldList, List<SObject> newList, Map<ID, SObject> oldMap, Map<ID, SObject> newMap) {
    }

    public void beforeDelete(List<SObject> oldList, Map<ID, SObject> oldMap) {
    }
    public void afterInsert(List<SObject> newList, Map<ID, SObject> newMap) {
        List<Task_Template__c> newTemplateList = newList;
        ctrl.updateParentTemplateIfNeeded(newTemplateList, null); 
    }

    public void afterUpdate(List<SObject> oldList, List<SObject> newList, Map<ID, SObject> oldMap, Map<ID, SObject> newMap) {
        List<Task_Template__c> newTemplateList = newList;
        Map<Id, Task_Template__c> templateMap = (Map<Id, Task_Template__c>)oldMap;
        ctrl.updateParentTemplateIfNeeded(newTemplateList, templateMap); 
    }

    public void afterDelete(List<SObject> oldList, Map<ID, SObject> oldMap) {
    }
    
    public void afterUndelete(List<SObject> newList, Map<ID, SObject> newMap) {
    }

}