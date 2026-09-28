/**
 * @description       : The controller used for building out templates on the Aura component
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 08-12-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
@RestResource(urlMapping='/Flow/*')
global with sharing class TemplateBuilderController {

    @HttpPost
    global static String flowDependencies(String id) {
        return getTemplateNodes(id);
    }

    @AuraEnabled
    public static string getTemplateNodes(String templateId) {

        try {
            if(String.isBlank(templateId)) {
                throw new TemplateBuilderControllerException('Template id cannot be blank.');
            }

            Set<Id> templateIdList = new Set<Id>();
            templateIdList.add(templateId);

            Map<Id, Task_Template__c> mapTemplateIdToTemplate = getAlltemplates(templateId);
            List<TaskTemplateNode> templateNodes = getTemplateNodesInternal(mapTemplateIdToTemplate, templateIdList);
            return Json.serialize(templateNodes);
        } catch (Exception ex) {
            throw new AuraHandledException(CommonFunctions.getExceptionError(ex));
        }
    }

    @AuraEnabled
    public static void deleteTaskRecord(String recordId) {
        try {

            if(String.isBlank(recordId)) {
                throw new TemplateBuilderControllerException('Record id cannot be blank.');
            }

            List<Task_Template_Step__c> taskTemplateSteps =
            [
                SELECT Id
                FROM Task_Template_Step__c
                WHERE Id = :recordId
                WITH USER_MODE
            ];

            delete as user taskTemplateSteps;

        } catch (Exception e) {
            throw new AuraHandledException(CommonFunctions.getExceptionError(e));
        }
    }

    @AuraEnabled
    public static void deleteTemplateRecord(String recordId) {
        try {

            if(String.isBlank(recordId)) {
                throw new TemplateBuilderControllerException('Record id cannot be blank.');
            }

            List<Task_Template__c> taskTemplate =
            [
                SELECT Id
                FROM Task_Template__c
                WHERE Id = :recordId
                WITH USER_MODE
            ];
            
            delete as user taskTemplate;
        } catch (Exception e) {
            throw new AuraHandledException(CommonFunctions.getExceptionError(e));
        }
    }


    /**
    * @description Gets a complete map of all templates involved
    * @author Brian Ezell (Simply EZ) | 08-12-2024
    * @param templateId 
    * @return Map<Id, Task_Template__c> 
    **/
    private static Map<Id, Task_Template__c> getAlltemplates(String templateId) {

        Map<Id, Task_Template__c> templates = new Map<Id, Task_Template__c> (
            CommonFunctions.getAllTemplates(templateId)
        );

        return templates;
    }


    /**
    * @description Gets the template nodes
    * @author Brian Ezell (Simply EZ) | 05-31-2024 
    * @param templateIds 
    * @return List<TaskTemplateNode> 
    **/
    private static List<TaskTemplateNode> getTemplateNodesInternal(Map<Id, Task_Template__c> allTemplates, Set<Id> templateIds) {
        Map<Id, TaskTemplateNode> newTemplates = new Map<Id, TaskTemplateNode>();

        List<Task_Template__c> templates = new List<Task_Template__c>();

        for(Id tId : templateIds) {
            templates.add(allTemplates.get(tId));
        }

        Set<Id> templateStepIds = new Set<Id>();
        for(Task_Template__c t : templates) {
            TaskTemplateNode templateNode = new TaskTemplateNode();
            templateNode.id = t.Id;
            templateNode.objectId = t.Templated_Object__c;
            templateNode.name = t.Name;
            templateNode.assignedName = t.Assigned_To_Name__c;
            templateNode.parentId = t.Parent_Template__c;
            templateNode.topLevelId = t.Master_Task_Template__c;
            templateNode.numberOfChildSteps = t.Number_of_Child_Steps__c;
            templateNode.numberOfChildTemplateSteps = t.Number_Of_Child_Template_Steps__c;

            Map<Id, Task_Template__c> childTemplates = new Map<Id, Task_Template__c>(t.Task_Templates__r);

            templateNode.childTemplateList = getTemplateNodesInternal(allTemplates, childTemplates.keySet());
            templateNode.childStepList = getTemplateStepNodes(t.Parent_Task_Template_Steps__r);

            newTemplates.put(t.Id, templateNode);
        }

        return newTemplates.values();
    }

    /**
    * @description Gets a usable list of steps for the template builder
    * @author Brian Ezell (Simply EZ) | 08-12-2024 
    * @param steps 
    * @return List<TaskTemplateStepNode> 
    **/
    private static List<TaskTemplateStepNode> getTemplateStepNodes(List<Task_Template_Step__c> steps) {

        List<TaskTemplateStepNode> stepNodes = new List<TaskTemplateStepNode>();

        //Add each step to the return list
        for(Task_Template_Step__c s : steps) {
            TaskTemplateStepNode stepNode = new TaskTemplateStepNode();
            stepNode.Id = s.Id;
            stepNode.Name = s.Name;
            stepNode.assignedName = s.Assigned_To_Name__c;

            //Add each dependency to the step dependency list
            for(Task_Template_Step_Dependency__c d : s.Task_Template_Step_Dependencies__r) {
                TaskTemplateStepDependencyNode depNode = new TaskTemplateStepDependencyNode();
                depNode.stepName = d.Task_Template__r.Name;
                depNode.dependsOnName = d.Depends_On_Step__r.Name;
                depNode.description = d.Description__c;
                stepNode.dependencyList.add(depNode);
            }

            stepNodes.add(stepNode);
        }

        return stepNodes;
    }

    public class TaskTemplateNode {
        public TaskTemplateNode() {
            childTemplateList = new List<TaskTemplateNode>();
            childStepList = new List<TaskTemplateStepNode>();
            numberOfChildSteps = 0;
            numberOfChildTemplateSteps = 0;
        }

        public String id;
        public String name;
        public String objectId;
        public String parentId;
        public String topLevelId;
        public Decimal numberOfChildSteps;
        public Decimal numberOfChildTemplateSteps;
        public String assignedName;
        public List<TaskTemplateNode> childTemplateList;
        public List<TaskTemplateStepNode> childStepList;
    }

    public class TaskTemplateStepNode {

        public TaskTemplateStepNode() {
            DependencyList = new LIst<TaskTemplateStepDependencyNode>();
        }

        public String id;
        public String name;
        public String assignedName;
        public String objectId;
        public List<TaskTemplateStepDependencyNode> dependencyList;
    }

    public class TaskTemplateStepDependencyNode {
        public String stepName;
        public string dependsOnName;
        public String description;
    }

    public class TemplateBuilderControllerException extends Exception {}
}