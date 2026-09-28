public with sharing class ObjectAndHierarchyHelper {

    private Id objectTypeId;

    public ObjectAndHierarchyHelper(String objectName) {
        System.debug('Object Name = ' + objectName);
        this.objectTypeId = 
            [
                SELECT Id
                FROM Object__c
                WHERE Api_Name__c = :objectName
                WITH USER_MODE
                LIMIT 1
            ].Id;
    }

    public ObjectTemplateCollection getObjectTemplateHierarchy() {

        List<Task_Template__c> allTemplates = getAllTemplates();

        ObjectTemplateCollection collection = new ObjectTemplateCollection();

        //First, load up the top-level templates
        for(Task_Template__c t : allTemplates) {
            if(t.Parent_Template__c == null) {
                ObjectTemplateNode parentNode = new ObjectTemplateNode(t.Name, t.Id, null);
                parentNode.childTemplates = getChildNodes(t.Id, allTemplates);
                collection.templates.add(parentNode);
            }
        }

        return collection;
    }
    
    private List<Task_Template__c> getAllTemplates() {
        return 
            [
                SELECT Id, Name, Templated_Object__c, Parent_Template__c
                FROM Task_Template__c
                WHERE Templated_Object__c = :this.objectTypeId
                ORDER BY Name,
                    Parent_Template__c NULLS FIRST
            ];
    }

    private List<ObjectTemplateNode> getChildNodes(Id parentId, List<Task_Template__c> allTemplates) {
        List<ObjectTemplateNode> childNodes = new List<ObjectTemplateNode>();
        for(Task_Template__c t : allTemplates) {
            if(t.Parent_Template__c == parentId) {
                ObjectTemplateNode childNode = new ObjectTemplateNode(t.Name, t.Id, parentId);
                childNode.childTemplates = getChildNodes(t.Id, allTemplates);
                childNodes.add(childNode);
            }
        }
        return childNodes;
    }

    public class ObjectTemplateCollection {
        
        public ObjectTemplateCollection() {
            this.templates = new List<ObjectTemplateNode>();
        }

        public List<ObjectTemplateNode> templates;
    }

    public class ObjectTemplateNode {

        public ObjectTemplateNode(String name, String id, String parentId) {
            this.name = name;
            this.id = id;
            this.parentId = parentId;
            this.childTemplates = new List<ObjectTemplateNode>();
        }

        public String name;
        public String id;
        public String parentId;
        public List<ObjectTemplateNode> childTemplates;
    }

}