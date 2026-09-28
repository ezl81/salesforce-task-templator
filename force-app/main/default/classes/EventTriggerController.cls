/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 06-16-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
public with sharing class EventTriggerController {

    /**
    * @description If events are updated, the only changes
    *   we need to worry about is if this is the last event
    *   closed on a case. Then mark the case closed.
    * @author Brian Ezell (Simply EZ)   
    * @param newEvents
    * @param oldEventMap
    * @return void
    **/
    public void refreshCases(List<Event> newEvents, Map<Id, Event> oldEventMap) {
        Set<Id> caseIds = new Set<Id>();
        Boolean isNew = oldEventMap == null;
        for(Event e : newEvents) {
            if(e.Is_Simply_Tasks_Created__c &&
                (isNew || e.Is_Task_Completed__c != !oldEventMap.get(e.Id).Is_Task_Completed__c)) {
                caseIds.add(e.WhatId);
            }
        }

        if(caseIds.size() > 0) {
            CaseTemplateHelper.updateCaseCounts(caseIds);
        }
    }

}