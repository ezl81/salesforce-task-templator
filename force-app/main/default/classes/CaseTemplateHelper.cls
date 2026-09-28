/**
 * @description       : Used to bulkify some of the case/task progression counts.
 * @author            : Brian Ezell (SimplyEZ)
 * @group             : 
 * @last modified on  : 08-12-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
public with sharing class CaseTemplateHelper {

    /**
    * @description Updates the case counts for completed tasks/events 
    * @author Brian Ezell (SimplyEZ) | 08-16-2024 
    **/
    public static void updateCaseCounts(Set<Id> caseIds) {
        CaseTemplateHelper helper = new CaseTemplateHelper(caseIds);
        helper.runCounts();
    }

    public CaseTemplateHelper(Set<Id> caseIds) {
        this.caseIds = caseIds;
    }

    private Set<Id> caseIds;
    private Map<Id, CaseTally> mapCaseIdToActivityTally = new Map<Id, CaseTally>();
    private Map<Id, Case> mapCaseIdToUpdateCase = new Map<Id, Case>();

    private void runCounts() {
        List<Master_Case__c> masterCases = loadAllCasesFromCaseIds(this.caseIds);
        populateCaseTallies(masterCases);
        updateCaseCountsInternal(masterCases);
    }

    /**
    * @description Updates the activities/completed activities on cases
    * @author Brian Ezell (SimplyEZ) | 08-19-2024 
    * @param masterCases 
    **/
    private void updateCaseCountsInternal(List<Master_Case__c> masterCases) {

        List<Case> casesToUpdate = new List<Case>();
        for(Master_Case__c masterCase : masterCases) {
            updateTallyFromMasterCase(masterCase);
        }
        update as user this.mapCaseIdToUpdateCase.values();

    }

    private void updateTallyFromMasterCase(Master_Case__c masterCase) {

        for(Case c : masterCase.Cases__r) {
            
            CaseTally caseTally = this.mapCaseIdToActivityTally.get(c.Id);

            //If this case has child cases, we need to start accumulating the 
            //tallies on the child cases
            if(c.Cases.size() > 0) {

                for(Case childCase : c.Cases) {
                    //Add the child tallies into this one so we have a complete picture for the next
                    //level when rolled up.
                    CaseTally childTally = this.mapCaseIdToActivityTally.get(childCase.Id);
                    if(childTally != null) {
                        caseTally.addTally(childTally);
                    }
                }
                this.mapCaseIdToActivityTally.put(c.Id, caseTally);
                this.mapCaseIdToUpdateCase.put(c.Id, new Case (
                    Id = c.Id,
                    Number_of_Tasks_Completed__c = caseTally.TasksCompleted,
                    Number_of_Tasks_To_Complete__c = caseTally.TasksToComplete
                ));
            } else {
                this.mapCaseIdToUpdateCase.put(c.Id, new Case (
                    Id = c.Id,
                    Number_of_Tasks_Completed__c = caseTally?.TasksCompleted ?? 0,
                    Number_of_Tasks_To_Complete__c = caseTally?.TasksToComplete ?? 0
                ));
            }
        }
    }


    /**
    * @description Gets the task/event tallies for each case.
    * @author Brian Ezell (Simply EZ) | 07-16-2025 
    * @param masterCases 
    * @return Map<Id, CaseTally> 
    **/
    private void populateCaseTallies(List<Master_Case__c> masterCases) {
        Map<Id, CaseTally> caseTally = new Map<Id, CaseTally>();

        for(Master_Case__c masterCase : masterCases) {

            for(Case c : masterCase.Cases__r) {
                CaseTally tally = new CaseTally();
                for(Task t : c.Tasks) {
                    tally.TasksToComplete++;
                    if(t.Is_Task_Completed__c) {
                        tally.TasksCompleted++;
                    }
                }
                caseTally.put(c.Id, tally);
            }
        }

        this.mapCaseIdToActivityTally = caseTally;
    }

    public static List<Master_Case__c> loadAllCasesFromCaseIds(Set<Id> caseIds) {
        List<Case> startCase =
        [
            SELECT Id, Master_Case__c
            FROM Case
            WHERE Id IN :caseIds
            WITH USER_MODE
        ];

        Set<Id> masterCaseIds = new Set<Id>();
        for(Case c : startCase) {
            masterCaseIds.add(c.Master_Case__c);
        }

        System.debug('Getting all cases.');
        List<Master_Case__c> allCases = 
            [
                SELECT Id, Name,
                    (
                        SELECT Id, Subject, Number_of_Tasks_Completed__c, Status, 
                            Number_of_Tasks_To_Complete__c, ParentId, Master_Case__c,
                            Master_Case__r.Case__c,
                            (
                                SELECT Id, Subject, Number_of_Tasks_Completed__c, Status, 
                                    Number_of_Tasks_To_Complete__c, ParentId, Master_Case__c,
                                    Master_Case__r.Case__c
                                FROM Cases
                                ORDER BY Level__c DESC, Subject
                            ),

                            (
                                SELECT Id, Status, Subject, Task_Template_Step__c, 
                                    Is_Task_Completed__c
                                FROM Tasks
                                ORDER BY Subject
                            ),
                            (
                                SELECT Id, Subject, ActivityDate, Task_Template_Step__c, 
                                    Is_Task_Completed__c
                                FROM Events
                                ORDER BY Subject
                            ),
                            (
                                SELECT Id, Name, Task_Depends_On_Id__c, Task_Id__c
                                FROM Task_Dependencies__r
                            )
                        FROM Cases__r
                        WHERE Is_Simply_Tasks_Case__c = true
                        ORDER BY Level__c DESC, Subject
                    )

                FROM Master_Case__c
                WHERE Id IN :masterCaseIds
                WITH USER_MODE
            ];
        return allCases;
    }

}