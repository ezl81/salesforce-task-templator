/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 09-22-2024
 * @last modified by  : Brian Ezell (Simply EZ)
**/
import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';

import getTemplates from '@salesforce/apex/CreateObjectTemplateController.getTemplates';
import createTemplate from '@salesforce/apex/CreateObjectTemplateController.createTemplate';

export default class CreateObjectTemplate extends LightningElement {

    @api objectApiName;
    @api recordId;

    templateList = [];
    selectedTemplateId = '';

    isLoading = false;

    message = '';

    get isCreateButtonDisabled() {
        return this.selectedTemplateId == '';
    }

    connectedCallback() {
        this.callGetTemplates();
    }

    callGetTemplates() {
        this.isLoading = true;
        getTemplates({ objectApiName: this.objectApiName })
            .then(result => {
                let response = JSON.parse(result);
                this.templateList = [];
                for (let i = 0; i < response.length; i++) {
                    this.templateList.push({
                        label: response[i].Name,
                        value: response[i].Id,
                    });
                }
                this.isLoading = false;
            })
            .catch(error => {
                this.isLoading = false;
                console.log(error);
                this.message = error.body.message;
                this.showErrorMessage();
            });
    }

    callCreateTemplate() {
        this.isLoading = true;
        let request = {
            objectId: this.recordId,
            objectName: this.objectApiName,
            templateId: this.selectedTemplateId,
        };
        createTemplate({ request: JSON.stringify(request) })
            .then(result => {
                let response = JSON.parse(result);
                let caseId = response.caseId;

                const event = new ShowToastEvent({
                    title: 'Success!',
                    message: 'Successfully created the caes.  Click {0} to view.',
                    messageData: [
                        {
                            url: '/' + caseId,
                            label: 'here'
                        },
                    ],
                });
                this.dispatchEvent(event);
                this.isLoading = false;
                //Refresh page
                updateRecord({ fields: { Id: this.recordId } })
            })
            .catch(error => {
                console.log(error);
                this.message = error.body.message;
                this.isLoading = false;
                this.showErrorMessage();
            });
    }
    
    /**************************/
    /*       EVENT HANDLERS   */
    /**************************/
    onClickCreateCase(event) {
        this.callCreateTemplate();
    }

    onChangeSelectedTemplate(event) {
        this.selectedTemplateId = event.currentTarget.value;
    }

    /***************************************/
    /***      TOASTS (popup messages)   ***/
    /*************************************/

    //Shows successful message
    showSuccessMessage() {
        let toastEvent = new ShowToastEvent({
            title: 'Success',
            message: this.message,
            variant: "success",
            messageData: this.messageData
        });
        this.messageData = [];
        this.dispatchEvent(toastEvent);
    }

    showWarningMessage() {
        let toastEvent = new ShowToastEvent({
            title: 'Warning',
            message: this.message,
            variant: "warning",
        });
        this.dispatchEvent(toastEvent);
    }

    showErrorMessage() {
        let toastEvent = new ShowToastEvent({
            title: 'Error',
            message: this.message,
            variant: "error",
        });
        this.dispatchEvent(toastEvent);
    }


}