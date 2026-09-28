/**
 * @description       : 
 * @author            : Brian Ezell (SimplyEZ)
 * @group             : 
 * @last modified on  : 09-21-2024
 * @last modified by  : Brian Ezell (Simply EZ)
**/
public without sharing class CaseTriggerHandler implements TriggerHandler {

    private boolean triggerIsExecuting;
    private integer triggerSize;
    public CaseTriggerController ctrl;
    public CaseTriggerHandler(boolean triggerIsExecuting, integer triggerSize) {
        this.triggerIsExecuting = triggerIsExecuting;
        this.triggerSize = triggerSize;
        this.ctrl = new CaseTriggerController();
    }

    public void beforeInsert(List<SObject> newList) {
    }
    public void beforeUpdate(List<SObject> oldList, List<SObject> newList, Map<ID, SObject> oldMap, Map<ID, SObject> newMap) {
    }
    public void beforeDelete(List<SObject> oldCases, Map<ID, SObject> oldMap) {
    }
    public void afterInsert(List<SObject> newCases, Map<ID, SObject> newMap) {
    }
    public void afterUpdate(List<SObject> oldList, List<SObject> newList, Map<ID, SObject> oldMap, Map<ID, SObject> newMap) {
    }
    public void afterDelete(List<SObject> oldList, Map<ID, SObject> oldMap) {
    }
    public void afterUndelete(List<SObject> newList, Map<ID, SObject> newMap) {
    }
       
}