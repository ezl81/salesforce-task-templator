/**
 * @description       : 
 * @author            : Brian Ezell (SimplyEZ)
 * @group             : 
 * @last modified on  : 08-12-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
public with sharing class TemplateHelper {

    private Map<Id, Master_Task_Template__c> mapMasterTemplateIdToMasterTemplates = new Map<Id, Master_Task_Template__c>();
    private Map<Id, Integer> mapTemplateIdToLevel = new Map<Id, Integer>();
    private Map<Id, Integer> mapTemplateIdToActivityCount = new Map<id, Integer>();
    private Integer totalNumberOfCases = 0;
    Map<Id, Set<Id>> mapTemplateIdToChildTemplateIdList = new Map<Id, Set<Id>>();
    List<Task_Template__c> newTemplates = new List<Task_Template__c>();

    /**
     * @description Constructor for TemplateHelper that takes a list of Templates.
     * @param templates List of task templates to initialize the helper with.
     **/
    public TemplateHelper(Set<Id> templateIds) {
        this.newTemplates = 
            [
                SELECT Id, 
                    Number_Of_Child_Template_Steps__c, 
                    Is_Master_Template__c, 
                    Total_Number_Of_Steps__c, 
                    Number_of_Child_Steps__c,
                    Parent_Template__c,
                    Level__c,
                    Master_Task_Template__c
                FROM Task_Template__c
                WHERE Id IN :templateIds
                WITH USER_MODE
            ];
        this.mapMasterTemplateIdToMasterTemplates = getMasterLevelTemplatesMap();
    }


    //TODO: REDO HELPER TO HANDLE CREATES/UPDATES TO BOTH TEMPLATES AND STESP
    //SUCH THAT IT CAN KEEP TRACK OF MASTERS, LEVELS, AND NUMBER OF STEPS IN ONE PLACE.

    public void updateTemplateLevelCounts() {

        if(mapMasterTemplateIdToMasterTemplates.size() == 0) {
            return;
        }

        getNextLevelTemplates(0);
        
        List<Task_Template__c> updateTemplates = new List<Task_Template__c>();
        for(Id tempId : mapTemplateIdToLevel.keySet()) {
            updateTemplates.add (
                new Task_Template__c(
                    Id = tempId,
                    Level__c = mapTemplateIdToLevel.get(tempId),
                    Number_of_Child_Steps__c = mapTemplateIdToActivityCount.get(tempId),
                    Number_Of_Child_Template_Steps__c = getNumberOfChildTemplateSteps(tempId)
                )
            );
        }

        update as user updateTemplates;   
        
    }

    /**
    * @description Counts the number of steps on the child templates
    * @author Brian Ezell (SimplyEZ) | 08-26-2024 
    * @param templateId 
    * @return Integer 
    **/
    private Integer getNumberOfChildTemplateSteps(Id templateId) {
        Integer childTemplateTasks = 0;
        for(Id childTemplateId : mapTemplateIdToChildTemplateIdList.get(templateId)) {
            childTemplateTasks += mapTemplateIdToActivityCount.get(childTemplateId);
            if(mapTemplateIdToChildTemplateIdList.containsKey(childTemplateId)) {
                childTemplateTasks += getNumberOfChildTemplateSteps(childTemplateId);
            }
        }
        return childTemplateTasks;
    }

    /**
    * @description Takes in all of the master templates and the level and 
    *   adds the current level templates to the level mapping
    * @author Brian Ezell (SImplyEZ) | 08-16-2024 
    * @param mapTemplateIdToTopLevelTemplates 
    * @param currentLevel 
    * @return Boolean 
    **/
    private void getNextLevelTemplates(Integer currentLevel) {

        Integer previousLevel = currentLevel - 1;
        Boolean isThisDone = true;
        Set<Id> thisLevelParentIds = new Set<Id>();

        //This is the top level template
        if(currentLevel > 0) {
            for(Id tempId : mapTemplateIdToLevel.keySet()) {
                if(mapTemplateIdToLevel.get(tempId) == previousLevel) {
                    thisLevelParentIds.add(tempId);
                }
            }
        }

        for(Master_Task_Template__c masterTemp : this.mapMasterTemplateIdToMasterTemplates.values()) {
            if(masterTemp.Task_Templates__r.size() > 0) {
                for(Task_Template__c temp : masterTemp.Task_Templates__r) {

                    //This is the first level so just look for templates without a parent - these are the top level ones.
                    if(currentLevel == 0 && temp.Parent_Template__c == null) {
                        mapTemplateIdToLevel.put(temp.Id, currentLevel);
                        isThisDone = false;
                    } else if(thisLevelParentIds.contains(temp.Parent_Template__c)) {
                        mapTemplateIdToLevel.put(temp.Id, currentLevel);
                        isThisDone = false;
                    }
                    mapTemplateIdToActivityCount.put(temp.Id, temp.Parent_Task_Template_Steps__r.size());

                    //Map the child templates to this template
                    Set<Id> childTemplateIds = new Set<Id>();
                    for(Task_Template__c childTemp : temp.Task_Templates__r) {
                        childTemplateIds.add(childTemp.Id);
                    }
                    mapTemplateIdToChildTemplateIdList.put(temp.Id, childTemplateIds);
                }
            }
        }

        //If we didn't find any more templates at this level, then we're done and need to exit the recursion.
        if(isThisDone) {
            return;
        } else {
            getNextLevelTemplates(currentLevel+1);
        }
    }

    /**
     * @description Returns a map of master templates keyed by their Id in relation to their templates.
     * @author Brian Ezell (SimplyEZ) | 08-16-2024
     * @return Map<Id, Master_Task_Template__c>
     **/
    private Map<Id, Master_Task_Template__c> getMasterLevelTemplatesMap() {
        Set<Id> masterTemplateIds = new Set<Id>();

        for(Task_Template__c t : this.newTemplates) {
            masterTemplateIds.add(t.Master_Task_Template__c);
        }

        //Start with counting at this level.
        //We'll start rolling up from here.
        Map<Id, Master_Task_Template__c> masterTemplates = new Map<Id, Master_Task_Template__c> (
        [
            SELECT Id, Name,
                (
                    SELECT 
                        Id, 
                        Number_Of_Child_Template_Steps__c, 
                        Is_Master_Template__c, 
                        Total_Number_Of_Steps__c, 
                        Number_of_Child_Steps__c,
                        Parent_Template__c,
                        Level__c,
                        (
                            SELECT
                                Id,
                                Name,
                                Assigned_To_Name__c
                            FROM
                                Parent_Task_Template_Steps__r
                            ORDER BY
                                Name
                        ),
                        (
                            SELECT 
                                Id, 
                                Number_Of_Child_Template_Steps__c, 
                                Is_Master_Template__c, 
                                Total_Number_Of_Steps__c, 
                                Number_of_Child_Steps__c,
                                Parent_Template__c,
                                Level__c
                            FROM
                                Task_Templates__r
                        )
                    FROM Task_Templates__r
                    WHERE Is_Active__c = true
                )
            FROM Master_Task_Template__c
            WHERE Id = :masterTemplateIds
            WITH SYSTEM_MODE
        ]);

        return masterTemplates;
    }
}