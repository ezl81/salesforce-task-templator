/**
 * @description       : 
 * @author            : Brian Ezell (SimplyEZ)
 * @group             : 
 * @last modified on  : 07-29-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
public with sharing class EventTriggerHandler implements TriggerHandler {

    private boolean triggerIsExecuting;
    private integer triggerSize;
    public EventTriggerController ctrl;
    public EventTriggerHandler(boolean triggerIsExecuting, integer triggerSize) {
        this.triggerIsExecuting = triggerIsExecuting;
        this.triggerSize = triggerSize;
        this.ctrl = new EventTriggerController();
    }

    public void beforeInsert(List<SObject> newList) {
    }
    public void beforeUpdate(List<SObject> oldList, List<SObject> newList, Map<ID, SObject> oldMap, Map<ID, SObject> newMap) {
    }
    public void beforeDelete(List<SObject> newList, Map<ID, SObject> oldMap) {
    }
    public void afterInsert(List<SObject> newList, Map<ID, SObject> newMap) {
        System.debug('Event After Insert');
        List<Event> newEventList = newList;
        Map<Id, Event> oldEventMap = (Map<Id, Event>)newMap;
        ctrl.refreshCases(newEventList, oldEventMap);
    }
    public void afterUpdate(List<SObject> oldList, List<SObject> newList, Map<ID, SObject> oldMap, Map<ID, SObject> newMap) {
        System.debug('Event After Update');
        List<Event> newEventList = newList;
        Map<Id, Event> oldEventMap = (Map<Id, Event>)oldMap;
        ctrl.refreshCases(newEventList, oldEventMap);
    }
    public void afterDelete(List<SObject> oldList, Map<ID, SObject> oldMap) {
    }
    public void afterUndelete(List<SObject> newList, Map<ID, SObject> newMap) {
    }

}