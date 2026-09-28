/**
 * @description       : 
 * @author            : Brian Ezell (SimplyEZ)
 * @group             : 
 * @last modified on  : 08-28-2024
 * @last modified by  : Brian Ezell (Simply EZ)
**/
public interface TriggerHandler {
    void beforeInsert(List<SObject> newList);
    void beforeUpdate(List<SObject> oldList, List<SObject> newList, Map<ID, SObject> oldMap, Map<ID, SObject> newMap);
    void beforeDelete(List<SObject> oldList, Map<ID, SObject> oldMap);
    void afterInsert(List<SObject> newList, Map<ID, SObject> newMap);
    void afterUpdate(List<SObject> oldList, List<SObject> newList, Map<ID, SObject> oldMap, Map<ID, SObject> newMap);
    void afterDelete(List<SObject> oldList, Map<ID, SObject> oldMap);
    void afterUndelete(List<SObject> newList, Map<ID, SObject> newMap);
}