/**
 * @description       : 
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 09-03-2024
 * @last modified by  : Brian Ezell (Simply EZ)
**/
import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Welcome extends LightningElement {

    statusIcon = 'utility:chevronright';
    templateIcon = 'utility:chevronright';
    objectLayoutIcon = 'utility:chevronright';

    error = null;

    objectList = [];

    connectedCallback() {
    }

    doesContainClass(element, className) {
        return element.classList.contains(className);
    }

    onClickToggleStatues() {
        this.refs.setupCaseTaskDetails.classList.toggle('hidden');
        this.statusIcon = this.doesContainClass(this.refs.setupCaseTaskDetails, 'hidden') ?
            'utility:chevronright' :
            'utility:chevrondown';
    }

    onClickToggleCreateTemplates() {
        this.refs.setupCreateTemplates.classList.toggle('hidden');
        this.templateIcon = this.doesContainClass(this.refs.setupCreateTemplates, 'hidden') ?
            'utility:chevronright' :
            'utility:chevrondown';
    }

    onClickToggleObjectLayouts() {
        this.refs.setupObjectLayouts.classList.toggle('hidden');
        this.objectLayoutIcon = this.doesContainClass(this.refs.setupObjectLayouts, 'hidden') ?
            'utility:chevronright' :
            'utility:chevrondown';
    }

    showErrorMessage() {
        let errorMsg = '';
        this.isLoading = false;
        errorMsg = JSON.stringify(this.error);
        let toastEvent = new ShowToastEvent({
            title: 'Error',
            message: errorMsg,
            variant: "error",
        });
        this.dispatchEvent(toastEvent);
    }


}