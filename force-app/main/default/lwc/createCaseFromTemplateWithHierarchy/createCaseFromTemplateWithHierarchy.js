import { LightningElement, api, track } from 'lwc';
import getCategories from '@salesforce/apex/CreateCaseFromTemplateTierController.getCategories';
import createCaseFromTemplateWithHierarchy from '@salesforce/apex/CreateCaseFromTemplateTierController.createCaseFromTemplateWithHierarchy';

export default class CreateCaseFromTemplateWithHierarchy extends LightningElement {

    @api recordId;
    selectedTemplateId;

    @track templateData = [];
    columns = [
        { label: 'Template', fieldName: 'name', type: 'text' },
    ];
    isLoading = false;

    //Tree Grid variables
    currentlyExpandedRows = [];
    selectedRows = [];
    topLevelRows = [];

    currentTopLevelParentId = '';

    error = '';
    message = '';

    newCaseId = '';
    
    get isCreateButtonDisabled() {
        return this.selectedRows.length === 0 || this.isLoading;
    }

    get newCaseLink() {
        if(this.newCaseId) {
            return '/' + this.newCaseId;
        }
        return '';
    }

    get hasError() {
        return this.error !== '';
    }

    get hasMessage() {
        return this.message !== '';
    }

    connectedCallback() {
        this.callGetCategories();
    }   

    //APEX CALLS

    callGetCategories() {

        let request = { objectId: this.recordId };
        this.isLoading = true;
        this.message = '';
        this.error = '';

        let strRequest = JSON.stringify(request);
        getCategories({ request: strRequest})
            .then(result => {
                let templateResults = JSON.parse(result);
                
                //The results will come in with the children attached to the parent nodes.
                this.setupGrid(templateResults.templates);
                this.error = '';
            })
            .catch(error => {
                this.error = this.getErrorText(error);
                this.message = '';
            }).finally(() => {
                this.currentTopLevelParentId = '';
                this.isLoading = false;
            });
    }   

    callCreateCaseFromTemplateWithHierarchy() {

        let request = { objectId: this.recordId, selectedRows: this.selectedRows };
        this.isLoading = true;
        let strRequest = JSON.stringify(request);

        createCaseFromTemplateWithHierarchy({ request: strRequest }) 
            .then(result => {
                this.newCaseId = JSON.parse(result);
                this.message = 'Case created successfully from template hierarchy.';
                this.error = '';
            })
            .catch(error => {
                this.error = this.getErrorText(error);
                this.message = '';
                console.error('Error creating case from template:', error);
            }).finally(() => {
                this.isLoading = false;
            });
    }

    setupGrid(templates) {
        let data = [];

        //Cycle through the top-level templates
        for(let i = 0; i < templates.length; i++) {
            if(!this.topLevelRows.includes(templates[i].id)) {
                //Add the top level templates to the top level row ids
                this.topLevelRows.push(templates[i].id);

                //Set the parent currently being examined.  This allows the children, etc 
                //to set the topLevelParentId later on.
                this.currentTopLevelParentId = templates[i].id;
            }
            let parentCategory = this.getCategory(templates[i]); 
            this.topLevelRows.push(parentCategory.id);
            data.push(parentCategory);
        }

        this.templateData = data;
    }

    getCategory(template) {
        let category = {
            id: template.id,
            name: template.name,
            parentId: template.parentId,
            topLevelParentId: this.currentTopLevelParentId,
            _children: [],
        };
        if(template && template.childTemplates && template.childTemplates.length > 0) {
            for(let x = 0; x < template.childTemplates.length; x++) {
                let temp = template.childTemplates[x];
                let childCategory = this.getCategory(temp);
                category._children.push(childCategory);
            }
        }

        return category;
    }


    /***EVENTS***/

    handleChangeTopLevelCategory(event) {
        this.selectedTopLevelCategoryId = event.detail.value;
        this.callGetSubategoriesByObjectAndParent(this.selectedTopLevelCategoryId);
    }

    //Handles the clicking of a checkbox next to a row
    handleRowSelection(event) {
        this.selectedRows = event.detail.selectedRows.map(row => row.id);
        this.selectedRows.push(...event.detail.selectedRows.map(row => row.parentId));
    }

    handleCategoryToggle(event) {
        let rowName = event.detail.name;
        let isExpanded = event.detail.isExpanded;

        if(isExpanded) {
            //Add to expanded rows
            if(!this.currentlyExpandedRows.includes(rowName)) {
                this.currentlyExpandedRows.push(rowName);
            }
        } else {
            //Remove from expanded rows
            this.currentlyExpandedRows = this.currentlyExpandedRows.filter(item => item !== rowName);
        }
    }

    onClickCreateCase(event) {
        this.callCreateCaseFromTemplateWithHierarchy();
    }

    getErrorText(err) {
        return err && err.body && err.body.message ? err.body.message : 'Unknown error';
    }

}