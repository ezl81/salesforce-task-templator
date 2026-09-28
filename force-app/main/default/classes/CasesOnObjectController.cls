/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 06-16-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
public with sharing class CasesOnObjectController {

	@AuraEnabled
	public static String getCaseSummaries(String objectId, String caseLinkedField) {

        try {


        //Make sure this column exists on the Case object
            if(!CommonFunctions.isColumnInSObject('Case', caseLinkedField)) {
                throw new DmlException(String.format('The field {0} does not exist on the Case object.',
                new List<String> {
                    caseLinkedField
                }));
            }

            String sql = 'SELECT Id FROM Case WHERE ' + String.escapeSingleQuotes(caseLinkedField) + ' = :objectId AND Is_Simply_Tasks_Case__c = true AND Is_Parent_Case__c = true ORDER BY Subject';
            List<Case> cases = Database.query(sql, AccessLevel.USER_MODE);

            List<ObjectSummaryByCases> listOfMapSummaries = new List<ObjectSummaryByCases>();

            for(Case c : cases) {
                String jsonResult = CaseProgressTrackerController.getChildTasksSummary(c.Id);
                if(jsonResult != null) {
                    List<CaseProgressTrackerController.Summary> caseSummaries = (List<CaseProgressTrackerController.Summary>)JSON.deserialize(jsonResult, List<CaseProgressTrackerController.Summary>.class);

                    ObjectSummaryByCases objSummary = new ObjectSummaryByCases();
                    objSummary.parentCaseName = caseSummaries[0].caseName;
                    objSummary.summaries = caseSummaries;
                    listOfMapSummaries.add(objSummary);
                }
            }
            return JSON.serialize(listOfMapSummaries);

        } catch(Exception ex) {
            throw new AuraHandledException(CommonFunctions.getExceptionError(ex));
        }

    }

	/**
	* @description Represents the parent case name and a list of summaries under it.
	* @author Brian Ezell (Simply EZ) | 10-03-2024 
	**/
    public class ObjectSummaryByCases {
        public String parentCaseName;
        public List<CaseProgressTrackerController.Summary> summaries;
    }
}