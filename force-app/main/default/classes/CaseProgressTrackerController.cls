/**
 * @description        : Shows the master case progress and child cases under it
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 06-16-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
public with sharing class CaseProgressTrackerController {

	/**
	* @description Gets a hierarchy summary of the cases (tasks/events vs. tasks/events completed) to be 
	*   used for the progress tracker screens.
	* @author Brian Ezell (Simply EZ) | 10-03-2024 
	* @param caseId 
	* @return String 
	**/
	@AuraEnabled
	public static String getChildTasksSummary(String caseId)
	{
		try {

			if(String.isBlank(caseId)) {
				throw new AuraHandledException('The case id cannot be blank.');
			}

			List<Case> currentCase =
				[
					SELECT Id, Master_Case__c, Master_Case__r.Case__c
					FROM Case
					WHERE Id = :caseId
					WITH USER_MODE
				];

			List<Case> cases = new List<Case>();
			if(currentCase.size() > 0) {
				cases =
				[
					SELECT Id, Subject, Number_of_Tasks_Completed__c, 
						Number_of_Tasks_To_Complete__c, ParentId,
						(
							SELECT Id, Subject, Number_of_Tasks_Completed__c, 
								Number_of_Tasks_To_Complete__c, ParentId
							FROM Cases
							ORDER BY Subject
						),
						(
							SELECT Id, Status
							FROM Tasks
							ORDER BY Subject
						),
						(
							SELECT Id, Subject, ActivityDate
							FROM Events
							ORDER BY Subject
						)
					FROM Case
					WHERE Master_Case__c = :currentCase[0].Master_Case__c
					WITH USER_MODE
					ORDER BY Subject
				];
			}

			//Get the top level case
			Case masterCase = null;
			for(Case c : cases) {
				if(c.ParentId == null) {
					masterCase = c;
					break;
				}
			}

			Map<Id, Summary> caseSummaries = getParentAndChildSummaries(cases, masterCase, 0);

			return JSON.serialize(caseSummaries.values());
		} catch(Exception ex) {
			throw new AuraHandledException(CommonFunctions.getExceptionError(ex));
		}
	}

	/**
	* @description Gets the parent and child summaries of the passed in case.
	* @author Brian Ezell (Simply EZ) | 10-03-2024 
	* @param allCases 
	* @param parentCase 
	* @param level 
	* @return Map<Id, Summary> 
	**/
	private static Map<Id, Summary> getParentAndChildSummaries(List<Case> allCases, Case parentCase, Integer level) {

		Map<Id, Summary> summaries = new Map<Id, Summary>();

		//We only want to get information on child cases,
		//but we'll need to iterate over all cases to ensure
		for(Case c : allCases) {
			if(c.Id == parentCase.Id) {
				Summary s = getSummaryFromCase(c, level);
				summaries.put(c.Id, s);

				for(Case childCase : c.Cases) {
					Map<Id, Summary> childSummaries = getParentAndChildSummaries(allCases, childCase, level+1);
					addToSummary(childSummaries.values(), s);
					summaries.putAll(childSummaries);
				}
			}
		}
		return summaries;
	}

	/**
	* @description Adds a list of summaries to a summary type.
	*	This is used just to lessen the congnative complexity of the getParentAndChildSummaries.
	* @author Brian Ezell (Simply EZ) | 10-03-2024 
	* @param summaries 
	* @param s 
	* @return Summary 
	**/
	private static Summary addToSummary(List<Summary> childSummaries, Summary s) {
		for(Summary childSummary : childSummaries) {
			s.ChildTasks += childSummary.TotalTasks;
			s.ChildTasksCompleted += childSummary.CompleteTasks;
		}
		return s;
	}

	/**
	* @description Gets a summary tally from the case passed in
	* @author Brian Ezell (Simply EZ) | 10-03-2024 
	* @param c 
	* @param level 
	* @return Summary 
	**/
	private static Summary getSummaryFromCase(Case c, Integer level) {
		Summary s = new Summary();
		s.CaseId = c.Id;
		s.CaseName = c.Subject;

		Integer tasksToComplete = 0;
		Integer tasksCompleted = 0;

		for(Task t : c.Tasks) {
			tasksToComplete++;
			tasksCompleted += t.Status == Constants.TASK_COMPLETED_STATUS ? 1 : 0;
		}

		Date thisDate = Date.today();
		for(Event e : c.Events) {
			tasksToComplete++;
			if(e.ActivityDate <= thisDate) {
				tasksCompleted += 1;
			}
		}

		s.totalTasks = tasksToComplete;
		s.completeTasks = tasksCompleted;
		s.isCompleted = tasksToComplete == tasksCompleted;
		s.isParent = c.ParentId == null;
		s.level = level;

		return s;
	}

	/**
	* @description Summarizes a case with the tallies of its children and tasks/events.
	* @author Brian Ezell (Simply EZ) | 10-03-2024 
	**/

	public class Summary
	{
		public String caseName = '';
		public String caseId = '';
		public Integer totalTasks = 0;
		public Integer completeTasks = 0;
		public Boolean isParent = false;
		public Integer level = 0;
		public Boolean isCompleted = false;
		public Integer childTasks = 0;
		public Integer childTasksCompleted = 0;
	}
}