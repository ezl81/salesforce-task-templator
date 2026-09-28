/**
 * @description       : 
 * @author            : Brian Ezell (SimplyEZ)
 * @group             : 
 * @last modified on  : 07-29-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
public without sharing class TaskTriggerHandler implements TriggerHandler {

   private boolean triggerIsExecuting;
    private integer triggerSize;
    public TaskTriggerController ctrl;
    public TaskTriggerHandler(boolean triggerIsExecuting, integer triggerSize) {
        this.triggerIsExecuting = triggerIsExecuting;
        this.triggerSize = triggerSize;
        this.ctrl = new TaskTriggerController();
    }

    public void beforeInsert(List<SObject> newList) {
    }
    public void beforeUpdate(List<SObject> oldList, List<SObject> newList, Map<ID, SObject> oldMap, Map<ID, SObject> newMap) {
    }
    public void beforeDelete(List<SObject> oldList, Map<ID, SObject> oldMap) {
    }
    public void afterInsert(List<SObject> newList, Map<ID, SObject> newMap) {
        List<Task> newTaskList = newList;
        Map<Id, Task> oldTaskMap = new Map<Id, Task>();
        ctrl.onAfterUpdate(newTaskList, oldTaskMap);
    }
    public void afterUpdate(List<SObject> oldList, List<SObject> newList, Map<ID, SObject> oldMap, Map<ID, SObject> newMap) {
        List<Task> newTaskList = newList;
        Map<Id, Task> oldTaskMap = (Map<Id, Task>)oldMap;
        ctrl.onAfterUpdate(newTaskList, oldTaskMap);
    }
    public void afterDelete(List<SObject> oldList, Map<ID, SObject> oldMap) {
    }
    public void afterUndelete(List<SObject> newList, Map<ID, SObject> newMap) {
    }

}