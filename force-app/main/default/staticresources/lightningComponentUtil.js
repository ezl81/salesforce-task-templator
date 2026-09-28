/**
 * @description   This resource contains a set of JavaScript functions commonly used across
 *                several lightning components.
 * @author        Revolution Group (Kirk Lampert)
 */
window.util = (function () {
    return {  // public API. NOTE: The { bracket to the left must stay on this line!

        //========================================================================================/
        // The following validation functions are the result of having to use ui:inputDate until
        // Salesforce fixes the locale bug in lightning:input (see: https://bit.ly/2t5w4aM and
        // https://sforce.co/2I0Tfx0) and because lightning:select doesn't support setting custom
        // validity yet (see https://sforce.co/2Sw6aY6).  These functions simplify the process of
        // validating these types of inputs by providing a common set of functions they can use.
        //========================================================================================/

        /**
         * @description   An alias for validateField
         * @param         component   the Salesforce lightning component
         * @param         fieldName   the name of the field to validate
         * @return        true if the field is valid, else false
         */
        fieldIsValid: function (component, fieldName) {
            return this.validateField(component, fieldName);
        },

        /**
         * @description   Validates either lightning:input or ui:inputDate components.  If valid
         *                then it resets the field validity.
         * @param         component   The Salesforce lightning component
         * @param         fieldName   The name of the field to validate
         * @return        true if the field is valid, else false
         */
        validateField: function (component, fieldName) {
            // Verify we have all required fields
            let field = component.find(fieldName);
            let validity = field.get("v.validity");

            if (typeof validity !== "undefined") {
                // lightning:input supports validity checks
                field.showHelpMessageIfInvalid();
                if (!validity.valid) {
                    // console.log(" [X] " + fieldName + " value of '" + field.get("v.value") + "' NOT valid");
                    return false;
                }
            }
            else // ui:inputDate doesn't support validity checks
            {
                // Validate date fields
                if (fieldName.indexOf("Date") !== -1) {
                    // Date.parse lets MMM d, YYYY through so that won't work here.  The control always
                    // returns YYYY-MM-DD so the regex must check for that instead of MM/DD/YYYY.
                    let dateReg = /^\d{4}-\d{1,2}-\d{1,2}$/;
                    let value = field.get("v.value");
                    if (value === null || !value.match(dateReg)) {
                        this.setFieldValidity(component, fieldName, "Please enter a date with the format MM/DD/YYYY");
                        // console.log(" [X] " + fieldName + " value of '" + value + "' NOT valid");
                        return false;
                    }
                }
            }

            // console.log(" -> " + fieldName + " value of '" + field.get("v.value") + "' IS valid");
            this.resetFieldValidity(component, fieldName);
            return true;
        },

        /**
         * @description   Sets the validity of both lightning:input and ui: components
         * @param         component   The Salesforce lightning component
         * @param         fieldName   The name of the field to set the validity for
         * @param         error       The error message to display
         */
        setFieldValidity: function (component, fieldName, error) {
            let field = component.find(fieldName);

            // "Validity" is a lightning:input feature.  It's not supported by lightning:select or
            // ui:inputDate.  We must use ui:inputDate until Salesforce fixes the locale bug with
            // lightning:input (see: https://bit.ly/2t5w4aM and https://sforce.co/2I0Tfx0). This
            // function checks to see if the field object has the setCustomValidity function
            // before calling it. If it doesn't then assume it's an older ui date control.
            if (typeof field.setCustomValidity === "function") {
                field.setCustomValidity(error);
                field.reportValidity();
            }
            else {
                if (fieldName.indexOf("Date") !== -1) {
                    field.set("v.errors", [{ message: error }]);
                }
            }

            return field;
        },

        /**
         * @description   Clears a field's content and resets its validity
         * @param         component   The Salesforce lightning component
         * @param         fieldName   The name of the field to reset
         * @param         tempValue   The temporary value to use when resetting the field's validity.
         *                            This is a workaround for a bug Salesforce needs to fix.
         */
        resetField: function (component, fieldName, tempValue) {
            // Salesforce's validity reset doesn't quite work yet, so this is a workaround
            component.set("v." + fieldName, tempValue);
            this.resetFieldValidity(component, fieldName);
            component.set("v." + fieldName, "");
        },

        /**
         * @description   Clears a field's content and resets its validity
         * @param         component   The Salesforce lightning component
         * @param         fieldName   The name of the field to reset
         * @param         tempValue   The temporary value to use when resetting the field's validity.
         *                            This is a workaround for a bug Salesforce needs to fix.
         */
        // NOT a working solution yet
        /*resetPicklistField : function(component, fieldName, picklistValuesName)
        {
            // Get the first value in the picklist list of values
            let tempValue = ".";
            let picklistValues = component.get("v." + picklistValuesName);
            if (picklistValues.length > 0)
            {
                tempValue = picklistValues[0];
            }

            // Salesforce's validity reset doesn't quite work yet, so this is a workaround
            component.set("v."+fieldName, tempValue);
            this.resetFieldValidity(component, fieldName);
            component.set("v."+fieldName, "");
        },*/

        /**
         * @description   Sets a field's content and resets its validity
         * @param         component   The Salesforce lightning component
         * @param         fieldName   The name of the field to reset
         * @param         value       The value to set
         */
        resetFieldWithValue: function (component, fieldName, value) {
            component.set("v." + fieldName, value);
            this.resetFieldValidity(component, fieldName);
        },

        resetFieldValidity: function (component, fieldName) {
            let field = component.find(fieldName);

            // "Validity" is a lightning:input feature.  It's not supported by lightning:select or
            // ui:inputDate.  We must use ui:inputDate until Salesforce fixes the locale bug with
            // lightning:input (see: https://bit.ly/2t5w4aM and https://sforce.co/2I0Tfx0). This
            // function checks to see if the field object has the setCustomValidity function
            // before calling it. If it doesn't then assume it's an older ui date control.
            if (typeof field.setCustomValidity === "function") {
                // console.log("Reseting validity for " + fieldName);
                field.setCustomValidity("");
                field.reportValidity();
            }
            else {
                // console.log("Reseting errors for " + fieldName);
                if (fieldName.indexOf("Date") !== -1) {
                    field.set("v.errors", []);
                }
                else if (typeof field.showHelpMessageIfInvalid === "function") {
                    // This should be a lightning:select control.  Not sure what can be done here
                    // yet.  lightning:select doesn't have a setCustomValidity function yet. You
                    // can set a custom "messageWhenValueMissing" but if you try to use an
                    // attribute variable OR just set it blank, Salesforce defaults to using the
                    // standard message, so that's no help.
                    // console.log("Can't reset validity of lightning:select control");
                }
            }

            return field;
        },
        //========================================================================================/
        // End of validation related functions.  See the note at the top of this block for info.
        //========================================================================================/

        dateStringToDate: function (dateString) {
            if ($A.util.isUndefinedOrNull(dateString)) return "";

            // console.log("dateStringToDate(" + dateString + ")");
            let parts = dateString.split("-");
            let theDate = new Date(parts[0], parts[1] - 1, parts[2]);
            // console.log("The date: " + theDate);
            return theDate;
        },

        dateStringToLocaleString: function (dateString) {
            if ($A.util.isUndefinedOrNull(dateString)) return "";
            dateString = dateString.replace("T00:00:00.000Z", "");
            let parts = dateString.split("-");
            let twoDigitYr = parts[0].substr(parts[0].length - 2);
            return parts[1] + "/" + parts[2] + "/" + twoDigitYr;
        },

        dateToLocaleString: function (theDate) {
            return (theDate.getMonth() + 1) + "/" + theDate.getDate() + "/" + theDate.getFullYear();
        },

        formatMoney: function (n, c, d, t) {
            var c = isNaN(c = Math.abs(c)) ? 2 : c,
                d = d == undefined ? "." : d,
                t = t == undefined ? "," : t,
                s = n < 0 ? "-" : "",
                i = String(parseInt(n = Math.abs(Number(n) || 0).toFixed(c))),
                j = (j = i.length) > 3 ? j % 3 : 0;

            return s + (j ? i.substr(0, j) + t : "") + i.substr(j).replace(/(\d{3})(?=\d)/g, "$1" + t) + (c ? d + Math.abs(n - i).toFixed(c).slice(2) : "");
        },

        round: function (value, decimals) {
            return Number(Math.round(value + 'e' + decimals) + 'e-' + decimals);
        },

        hideDiv: function (component, auraId) {
            let cmp = component.find(auraId);
            $A.util.removeClass(cmp, "slds-show");
            $A.util.addClass(cmp, "slds-hide");
        },

        showDiv: function (component, auraId) {
            let cmp = component.find(auraId);
            $A.util.removeClass(cmp, "slds-hide");
            $A.util.addClass(cmp, "slds-show");
        },

        showModalDialog: function (component, componentId, className) {
            let modalDialog = component.find(componentId);
            $A.util.removeClass(modalDialog, className + "hide");
            $A.util.addClass(modalDialog, className + "open");
        },

        hideModalDialog: function (component, componentId, className) {
            let modalDialog = component.find(componentId);
            $A.util.addClass(modalDialog, className + "hide");
            $A.util.removeClass(modalDialog, className + "open");
        },

        showError: function (response) {
            let errorMsg = "";
            if (response.getState() === "ERROR") {
                errorMsg = response.getError()[0].message;
            }
            else {
                errorMsg = "The remote server request timed out.";
            }

            // If an error occurred, show an error toast
            this.showErrorMsg(errorMsg);
        },

        showErrorMsg: function (errorMsg) {
            this.showMsg(errorMsg, "Error")
        },

        showSuccessMsg: function (successMsg) {
            this.showMsg(successMsg, "Success")
        },

        showMsg: function (message, type) {
            // Show an error toast
            let resultsToast = $A.get("e.force:showToast");
            resultsToast.setParams({
                "type": type,
                "title": type,
                "message": message,
                "mode": "dismissible"
            });
            resultsToast.fire();
        },

        sortBy: function (field, reverse) {
            let key = function (x) { return x[field] };

            // Checks if the two rows should switch places
            reverse = !reverse ? 1 : -1;
            return function (a, b) {
                return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
            }
        }
    };
}());
