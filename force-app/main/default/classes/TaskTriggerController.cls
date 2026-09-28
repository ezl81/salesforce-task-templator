/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 08-12-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
public with sharing class TaskTriggerController {

    private static Boolean isRunning;

    private static Set<String> closedStatuses = new Set<String> {
        Constants.TASK_COMPLETED_STATUS
    };

    public void onAfterUpdate(List<Task> newTasks, Map<Id, Task> oldTaskMap) {
        checkTaskDependencies(newTasks, oldTaskMap);
        updateCasesFromTasks(newTasks, oldTaskMap);
    }

    /**
    * @description: Before any tasks can be marked complete, there needs
    *   to be a check to see if dependencies exist to other tasks
    *   and those tasks are not completed already.
    * @author Brian Ezell (Simply EZ)
    * @param newTasks
    * @param oldTaskMap
    * @return void
    **/
    private void checkTaskDependencies(List<Task> newTasks, Map<Id, Task> oldTaskMap) {

        List<Task> tasksMarkedComplete = new List<Task>();
        List<Task> tasksMarkedUncomplete = new List<Task>();

        for(Task t : newTasks) {
            if(t.Is_Simply_Tasks_Created__c) {
                Task oldTask = oldTaskMap.get(t.Id);
                if(oldTask != null && t.IsClosed && !oldTask.IsClosed) {
                    tasksMarkedComplete.add(t);
                } else if(oldTask == null || (!t.IsClosed && oldTask.isClosed)) {
                    tasksMarkedUncomplete.add(t);
                }
            }
        }

        if(tasksMarkedUncomplete.size() > 0) {
            checkTasksCantBeStartedNow(tasksMarkedUncomplete);
        }

        if(tasksMarkedComplete.size() > 0) {
            checkTasksWithOutstandingDependencies(tasksMarkedComplete);
            checkTasksCanBeStartedNow(tasksMarkedComplete);
        }
    }

    /**
    * @description If tasks are unmarked as completed,
    *   back out any dependencies that may have been able
    *   to be started.
    * @author Brian Ezell (Simply EZ)
    * @param tasksMarkedUncompleted
    * @return void
    **/
    private void checkTasksCantBeStartedNow(List<Task> tasksMarkedUncompleted) {

        Set<String> taskIds = new Set<String>();
        for(Task t : tasksMarkedUncompleted) {
            taskIds.add(t.Id);
        }

        //Look up the dependencies
        //First lookup the task ids.  Since this
        //is a string field, will have to do a secondary

        List<Task_Dependency__c> dependencies =
            [
                SELECT Id, Task_Id__c
                FROM Task_Dependency__c
                WHERE Task_Depends_On_Id__c = :taskIds
                WITH SYSTEM_MODE
            ];
        Set<String> dependentTaskIds = new Set<String>();
        for(Task_Dependency__c d : dependencies) {
            dependentTaskIds.add(d.Task_Id__c);
        }
        Map<Id, Task> dependentTasks = new Map<Id, Task>(
            [
                SELECT Id, Status, Dependent_Tasks_To_Complete__c
                FROM Task
                WHERE Id = :dependentTaskIds
                WITH SYSTEM_MODE
            ]);

        if(!dependentTasks.isEmpty()) {
            List<Task> updateTasks = new List<Task>();
            for(Task t : dependentTasks.values()) {
                Decimal countTasksToComplete = t?.Dependent_Tasks_To_Complete__c == null ? 0 : t.Dependent_Tasks_To_Complete__c + 1;
                updateTasks.add(new Task(
                    Id = t.Id,
                    Dependent_Tasks_To_Complete__c = countTasksToComplete,
                    Status = Constants.TASK_PENDING_STATUS,
                    ActivityDate = null
                ));
            }

            if(updateTasks.size() > 0) {
                update as user updateTasks;
            }

        }
    }

    /**
    * @description Determine if any tasks can be started now
    *   if any of their dependencies have been completed.
    * @author Brian Ezell (Simply EZ)
    * @param tasksMarkedComplete
    * @return void
    **/
    private void checkTasksCanBeStartedNow(List<Task> tasksMarkedComplete) {

        Set<String> taskIds = new Set<String>();
        for(Task t : tasksMarkedComplete) {
            taskIds.add(t.Id);
        }

        //Look up the dependencies
        //First lookup the task ids.  Since this
        //is a string field, will have to do a secondary
        List<Task_Dependency__c> dependencies =
            [
                SELECT Id, Task_Id__c
                FROM Task_Dependency__c
                WHERE Task_Depends_On_Id__c = :taskIds
                WITH SYSTEM_MODE
            ];
        Set<String> dependentTaskIds = new Set<String>();
        for(Task_Dependency__c d : dependencies) {
            dependentTaskIds.add(d.Task_Id__c);
        }
        Map<Id, Task> dependentTasks = new Map<Id, Task>(
            [
                SELECT Id, Status, Dependent_Tasks_To_Complete__c
                FROM Task
                WHERE Id = :dependentTaskIds
                    AND Status = :Constants.TASK_PENDING_STATUS
                WITH SYSTEM_MODE
            ]);

        if(dependentTasks.size() > 0) {

            //We need to look up the task template steps so we know
            //How long the task should take.  Then we add from today.

            Map<Id, Task> mapTasksToDuration = new Map<Id, Task>(
                [
                    SELECT Id, Task_Template_Step__r.Duration_In_Days__c
                    FROM Task
                    WHERE Id = :dependentTaskIds
                    WITH SYSTEM_MODE
                ]);

            List<Task> updateTasks = new List<Task>();
            Date thisDate = date.today();
            for(Task t : dependentTasks.values()) {

                //Figure out how many days out this task is due.
                Decimal countTasksToComplete = t?.Dependent_Tasks_To_Complete__c == null ? 0 : t.Dependent_Tasks_To_Complete__c - 1;
                Task lookupTask = mapTasksToDuration.get(t.Id);
                Integer daysOut = lookupTask != null && lookupTask.Task_Template_Step__r.Duration_In_Days__c != null ?
                    Integer.valueOf(lookupTask.Task_Template_Step__r.Duration_In_Days__c) : null;
                Date dueDate = date.today();
                if(daysOut != null) {
                    dueDate.addDays(daysOut);
                }

                updateTasks.add(new Task(
                    Id = t.Id,
                    Dependent_Tasks_To_Complete__c = countTasksToComplete,
                    Status = countTasksToComplete > 0 ? 
                        t.Status : 
                        Constants.TASK_START_STATUS,
                    ActivityDate = daysOut == null ? null : dueDate
                ));
            }

            if(updateTasks.size() > 0) {
                update as user updateTasks;
            }
            
        }
    }

    /**
    * @description Check if tasks are marked as completed and there
    *   are other tasks that need to be completed first.
    * @author Brian Ezell (Simply EZ)
    * @param tasksMarkedComplete
    * @return void
    **/
    private void checkTasksWithOutstandingDependencies(List<Task> tasksMarkedComplete) {
        List<String> tasksMarkedCompleteIds = new List<String>();
        for(Task t : tasksMarkedComplete) {
            tasksMarkedCompleteIds.add(t.Id);
        }

        //Look up the dependencies
        List<Task_Dependency__c> dependencies =
            [
                SELECT Id, Task_Depends_On_Id__c
                FROM Task_Dependency__c
                WHERE Task_Id__c = :tasksMarkedCompleteIds
                WITH SYSTEM_MODE
            ];

        List<Id> dependTaskIds = new List<Id>();
        for(Task_Dependency__c d : dependencies) {
            dependTaskIds.add(d.Task_Depends_On_Id__c);
        }

        List<Task> dependentTasks =
            [
                SELECT Id, Subject
                FROM Task
                WHERE Id = :dependTaskIds
                    AND IsClosed = false
                WITH SYSTEM_MODE
            ];

        for(Task t : dependentTasks) {
            tasksMarkedComplete[0].addError(string.format(
                'Task {0} needs to be completed before you can close out these task(s).',
                new List<String>{ t.Subject }
            ));
        }
    }

    /**
    * @description updates cases based on a list of tasks
    * @author Brian Ezell (Simply EZ)
    * @param newTasks
    * @param oldTasks
    * @return void
    **/
    private void updateCasesFromTasks(List<Task> newTasks, Map<Id, Task> oldTasks) {
        Set<Id> caseIds = new Set<Id>();

        for(Task t : newTasks) {
            //Only look at task tracker created tasks
            if(t.Is_Simply_Tasks_Created__c) {

                Task oldTask = oldTasks.get(t.Id);
                Boolean oldStatusClosed = oldTask != null && closedStatuses.contains(oldTask.Status);
                Boolean newStatusClosed = closedStatuses.contains(t.Status);

                //Only look at tasks where the status has changed
                //from or to a status of closed.  If so,
                //we'll update the case's progress
                if (oldStatusClosed != newStatusClosed && t.WhatId != null) {
                    caseIds.add(t.WhatId);
                }
            }
        }

        if(caseIds.size() > 0) {
            CaseTemplateHelper.updateCaseCounts(caseIds);
        }
        
    }

}