/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 07-10-2025
 * @last modified by  : Brian Ezell (Simply EZ)
**/
import { LightningElement, api, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import deleteTemplate from '@salesforce/apex/TemplateDeleteController.deleteTemplate';

export default class TemplateDelete extends LightningElement {

    @api recordId;
    @api objectApiName;

    callDeleteTemplate() {
        
        let request = {
            templateId: this.recordId
        };

        deleteTemplate({ request: JSON.stringify(request) })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Template deleted successfully',
                        variant: 'success'
                    })
                );
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error deleting template',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
                this.dispatchEvent(new CloseActionScreenEvent());
            });
    }

    /***********************/
    /*      Events         */
    /***********************/

    onClickDelete(event) {
        this.callDeleteTemplate();
    }

    onClickCancel(event) {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    
}