/**
 * @description       : This will populate the Assign Id
 * column of the object once the user decides who/what they want to 
 * assigne the template step to.
 * @author            : Brian Ezell (Simply EZ)
 * @group             : 
 * @last modified on  : 10-08-2024
 * @last modified by  : Brian Ezell (Simply EZ)
**/
import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getAssignedOwnerOptions from '@salesforce/apex/AssignRecordOwnerController.getAssignedOwnerOptions';
import getAssignedOwner from '@salesforce/apex/AssignRecordOwnerController.getAssignedOwner';
import updateAssignedOwner from '@salesforce/apex/AssignRecordOwnerController.updateAssignedOwner';

export default class AssignRecordOwner extends LightningElement {

    @api recordId;
    @api objectApiName;
    @api isReadOnly;

    optionsAssignType = [];
    
    optionsForSelection = [];
    optionsLabel = '';

    selectedAssignType = '';
    selectedOwnerId = '';
    showSelectionCombo = false;

    hasSetup = false;
    hasOptions = false;

    error = null;
    message = '';

    get showSaveButton() {
        let showSave = !this.isReadOnly;
        if (showSave && this.showSelectionCombo) {
            showSave = this.optionsForSelection.length > 0;
        }

        return showSave;
    }

    connectedCallback() {
        this.optionsAssignType = [];
        if (this.objectApiName != 'Case') {
            this.optionsAssignType.push({
                label: 'Case Owner',
                value: 'Case Owner'
            });
        }

        this.optionsAssignType.push({
            label: 'Person Creating',
            value: 'Person Creating'
        });

        this.optionsAssignType.push({
            label: 'Queue',
            value: 'Queue'
        });

        this.optionsAssignType.push({
            label: 'Specific User',
            value: 'Specific User'
        });

        this.callGetAssignedOwner();
    }

    callGetAssignedOwner() {
        getAssignedOwner({ recordId: this.recordId })
            .then(result => {
                let response = JSON.parse(result);
                this.selectedAssignType = response.assignType;
                this.selectedOwnerId = response.ownerId;
                this.callGetAssignedOwnerOptions();
            })
            .catch(error => {
                console.log(error);
                this.error = error;
                this.showErrorMessage();
            });
    }

    callGetAssignedOwnerOptions() {

        if (this.selectedAssignType == null) {
            return;
        }

        let request = {
            recordId: this.recordId,
            assignType: this.selectedAssignType,
            assignedId: this.selectedOwnerId,
        };

        getAssignedOwnerOptions({ request: JSON.stringify(request) })
            .then(result => {
                let response = JSON.parse(result);
                this.comboBoxHasOptions = response.options.length > 0;
                this.showSelectionCombo = response.showCombo;
                this.optionsForSelection = response.options;
                this.optionsLabel = response.optionsName;
            })
            .catch(error => {
                console.log(error);
                this.error = error;
                this.showErrorMessage();
            });
    }

    callUpdateAssignedOwner() {
        let request = {
            recordId: this.recordId,
            assignedId: this.selectedOwnerId,
            assignedType: this.selectedAssignType,
        };

        updateAssignedOwner({ request: JSON.stringify(request) })
            .then(result => {
                if (result) {
                    this.message = 'Successfully updated the default owner.';
                    this.showSuccessMessage();
                }
            })
            .catch(error => {
                console.log(error);
                this.error = error;
                this.showErrorMessage();
            });
    }
    

    /**************************/
    /*       EVENT HANDLERS   */
    /**************************/

    onChangeAssignType(event) {
        this.selectedAssignType = event.currentTarget.value;
        this.callGetAssignedOwnerOptions();
    }

    onChangeSelectedOwner(event) {
        this.selectedOwnerId = event.currentTarget.value;
    }

    onClickUpdateOwner() {
        this.callUpdateAssignedOwner();
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
        });
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

    //Shows error message
    showErrorMessage() {
        let errorMsg = '';
        this.isLoading = false;

        if (Array.isArray(this.error.body)) {
            errorMsg = this.error.body.map(e => e.message).join(', ');
        } else if (this.error && this.error.body && typeof this.error.body.message == 'string') {
            errorMsg = this.error.body.message;
        } else {
            errorMsg = JSON.stringify(this.error);
        }
        let toastEvent = new ShowToastEvent({
            title: 'Error',
            message: errorMsg,
            variant: "error",
        });
        this.dispatchEvent(toastEvent);
    }

    //handles any error coming back from Apex calls
    handleError(error) {
        this.error = error;
        this.showErrorMessage();
        this.isLoading = false;
    }

}