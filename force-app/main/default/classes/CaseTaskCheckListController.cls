/**
     * @description       : Handles requests related to task checklist items.
     * @author            : Brian Ezell (Simply EZ)
     * @group             : 
     * @last modified on  : 08-13-2025
     * @last modified by  : Brian Ezell (Simply EZ)
    **/
    public with sharing class CaseTaskCheckListController {

    /**
    * @description Gets a list of tasks for this case.  Includes whether or not the task has been marked completed.
    * @author Brian Ezell (Simply EZ) | 05-22-2024 
    * @param caseId 
    * @return String 
    **/
    @AuraEnabled
    public static String getTaskList(String caseId) {

        try {
            if(String.isBlank(caseId)) {
                throw new AuraHandledException('The case id cannot be blank.');
            }
            TaskListResponse response = getTaskListResponse(caseId);
            return JSON.serialize(response);
        } catch(Exception ex) {
            throw new AuraHandledException(CommonFunctions.getExceptionError(ex));
        }
    }

    /**
    * @description 
    * @author Brian Ezell (Simply EZ) | 05-22-2024 
    * @param caseId 
    * @param jsonTaskList 
    * @return String 
    **/
    @AuraEnabled
    public static String updateTaskList(String caseId, String jsonTaskList) {

        System.debug('***JSON TASK LIST***');
        System.debug(jsonTaskList);

        try {
            if(String.isBlank(caseId)) {
                throw new AuraHandledException('The case id cannot be blank.');
            }

            if(String.isBlank(jsonTaskList)) {
                throw new AuraHandledException('The task list cannot be blank.');
            }

            TaskListResponse response = new TaskListResponse();
            List<String> completedList = (List<String>) JSON.deserialize(jsonTaskList, List<String>.class);
            
            updateTasksCompleted(caseId, completedList);
            response = getTaskListResponse(caseId);

            return JSON.serialize(response);
        } catch (Exception ex) {
            throw new AuraHandledException(CommonFunctions.getExceptionError(ex));
        }
    }


    /**
    * @description Gets list of tasks on the case
    * @author Brian Ezell (Simply EZ) | 2/5/2020
    * @param caseId
    * @return TaskListResponse
    **/
    private static TaskListResponse getTaskListResponse(String caseId) {

        TaskListResponse response = new TaskListResponse();
        if(caseId != null) {
            List<Task> tasks =
                [
                    SELECT Id, Subject, Status
                    FROM Task
                    WHERE WhatId = :caseId
                    WITH USER_MODE
                ];

        List<Task_Dependency__c> dependencies =
            [
                SELECT Id, Task_Id__c, Task_Depends_On_Id__c
                FROM Task_Dependency__c
                WHERE Case__c = :caseId
                WITH USER_MODE
            ];

            Map<Id, List<String>> mapTaskDependencies = getMapTaskDependencies(tasks, dependencies);
            List<String> completedTaskNames = getCompletedTaskNames(tasks);

            //Get a list of all tasks with completed status to return
            for(Task t : tasks) {
                response.TaskItems.add(new TaskItem(
                    t.Id,
                    t.Subject,
                    completedTaskNames.contains(t.Subject),
                    mapTaskDependencies.containsKey(t.Id) ? mapTaskDependencies.get(t.Id) : new List<String>()
                ));
            }
        }
        return response;
    }

    /**
    * @description Gets a Map of Task Ids to a list of dependency names
    * @author Brian Ezell (Simply EZ) | 10-03-2024 
    * @param tasks 
    * @return Map<String, List<String>> 
    **/
    private static Map<Id, List<String>> getMapTaskDependencies(List<Task> tasks, List<Task_Dependency__c> dependencies) {
        Map<Id, Task> mapTasks = new Map<Id, Task>(tasks);
        Map<Id, List<String>> mapTaskDependencies = new Map<Id, List<String>>();

        for(Task t : tasks) {
            for(Task_Dependency__c d : dependencies) {
                if(d.Task_Id__c == t.Id) {
                    if(!mapTaskDependencies.containsKey(t.Id)) {
                        mapTaskDependencies.put(t.Id, new List<String>());
                    }
                    String subject = mapTasks.get(t.Id).Subject;
                    mapTaskDependencies.get(t.Id).add(subject);
                }
            }
        }
        return mapTaskDependencies;
    }

    /**
    * @description Gets a Map of Task Ids to a list of dependency names
    * @author Brian Ezell (Simply EZ) | 10-03-2024 
    * @param tasks 
    * @return Map<String, List<String>> 
    **/
    private static List<String> getCompletedTaskNames(List<Task> tasks) {
        //Get a list of completed tasks first
        List<String> completedTasks = new List<String>();
        for(Task t : tasks) {
            if(t.Status == Constants.TASK_COMPLETED_STATUS) {
                completedTasks.add(t.Subject);
            }
        }
        return completedTasks;
    }

    /**
    * @description Updates tasks to completed or not completed
    * @author Revolution Group (Brian Ezell) | 2/5/2020
    * @param caseId
    * @param completedList
    **/
    private static void updateTasksCompleted(String caseId, List<String> completedList) {

        if(String.isBlank(caseId)) {
            return;
        }

        List<Task> tasks =
            [
                SELECT Id, Status, Subject
                FROM Task
                WHERE WhatId = :caseId
                WITH USER_MODE
            ];
            
        List<Task> updateTasks = new List<Task>();
        for(Task t : tasks) {
            if(completedList.contains(t.Id)) {
                if(t.Status != Constants.TASK_COMPLETED_STATUS) {
                    updateTasks.add(new Task(
                        Id = t.Id,
                        Status = Constants.TASK_COMPLETED_STATUS
                    ));
                }
            } else if(t.Status == Constants.TASK_COMPLETED_STATUS) {
                updateTasks.add(new Task(
                    Id = t.Id,
                    Status = Constants.TASK_START_STATUS
                ));
            }
        }

        update as user updateTasks;
    }

    /**
    * @description Represents a list of tasks
    * @author Brian Ezell (Simply EZ) | 2/5/2020
    **/
    public class TaskListResponse {
        /**
        * @description Init for task list response
        * @author Brian Ezell (Simply EZ) | 10-03-2024 
        **/
        public TaskListResponse() {
            Messages = new List<String>();
            TaskItems = new List<TaskItem>();
        }

        public List<String> Messages {get;set;}
        public List<TaskItem> TaskItems{get;set;}

        /**
        * @description Determins if the response (update) was successful
        * @author Brian Ezell (Simply EZ) | 10-03-2024 
        **/
        public Boolean IsSuccessful {
            get {
                return Messages.size() == 0;
            }
        }
    }

    /**
    * @description Represents a task item
    * @author Brian Ezell (Simply EZ) | 2/5/2020
    **/
    public class TaskItem{

        public String Id {get;set;}
        public String Name {get;set;}
        public Boolean IsComplete {get;set;}
        public List<String> Dependencies {get;set;}

        public TaskItem() {
            Id = '';
            Name = '';
            IsComplete = false;
            Dependencies = new List<String>();
        }
        
        public TaskItem(String i, String nm, Boolean comp, List<String> dep) {
            Id = i;
            Name = nm;
            IsComplete = comp;
            Dependencies = dep;
        }

    }
}