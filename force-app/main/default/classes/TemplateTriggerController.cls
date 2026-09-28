/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 07-25-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
public with sharing class TemplateTriggerController {

    /**
    * @description Determines if the parent template has changed.  If it has
    *   the task template counts need to update.
    * @author Brian Ezell (Simply EZ) | 05-24-2024 
    * @param newTemplates 
    * @param oldTemplates 
    **/
    public void updateParentTemplateIfNeeded(List<Task_Template__c> newTemplates, Map<Id, Task_Template__c> oldTemplates) {

        //This is an insert.  If there is no master template filled in, 
        //one needs to get created and assoicated with the template.

        if(oldTemplates == null) {
            onCreateAddMaster(newTemplates);
        }

        Set<Id> changedTemplateIds = new Set<Id>();
        if(oldTemplates == null) {
            changedTemplateIds = new Map<Id, Task_Template__c>(newTemplates).keySet();
        } else {
            for(Task_Template__c t : newTemplates) {
                Task_Template__c oldTemplate = oldTemplates.get(t.Id);
                if(t.Parent_Template__c != oldTemplate.Parent_Template__c && t.Parent_Template__c != null) {
                    changedTemplateIds.add(t.Id);
                }
            }
        }

        if(changedTemplateIds.size() > 0) {
            TemplateHelper tempHelper = new TemplateHelper(changedTemplateIds);
            tempHelper.updateTemplateLevelCounts();
        }
    }
    

    /**
    * @description Adds a master template record to the template if it doesn't exist already.
    * @author Brian Ezell (Simply EZ) | 05-28-2024
    * @param newTemplates 
    **/
    
    private void onCreateAddMaster(List<Task_Template__c> newTemplates) {

        Map<Id, Master_Task_Template__c> mapPostitionIndexToMasterTemplate = new Map<Id, Master_Task_Template__c>();
        for(Task_Template__c t : newTemplates) {
            if(t.Master_Task_Template__c == null) {
                Master_Task_Template__c newMaster = new Master_Task_Template__c (
                    Task_Template__c = t.Id
                );
                mapPostitionIndexToMasterTemplate.put(t.Id, newMaster);
            }
        }

        insert as user mapPostitionIndexToMasterTemplate.values();
    
        List<Task_Template__c> updateTemplates = new List<Task_Template__c>();
        for(Task_Template__c t : newTemplates) {
            if(mapPostitionIndexToMasterTemplate.get(t.Id) != null) {
                Task_Template__c updateTemp = new Task_Template__c (
                    Master_Task_Template__c = mapPostitionIndexToMasterTemplate.get(t.Id).Id,
                    Id = t.Id
                );
                updateTemplates.add(updateTemp);
            }
        }
        update as user updateTemplates;
    }

}