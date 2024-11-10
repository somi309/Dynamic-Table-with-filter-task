import { LightningElement, wire, track,api } from 'lwc';

import { getPicklistValues } from 'lightning/uiObjectInfoApi';

import COUNTRY_CODE from '@salesforce/schema/Account.BillingCountryCode';
import BILLING_STATE_CODE from '@salesforce/schema/Account.BillingStateCode';
export default class FilterSection extends LightningElement {
     _countries = [];
    _countryToStates = {};
    @track selectedCountry;
    @track selectedState;

    selectedCountry = '';
    selectedState= '';

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: COUNTRY_CODE
    })
    wiredCountires({ data }) {
        this._countries = data?.values;
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: BILLING_STATE_CODE })
    wiredStates({ data }) {
        if (!data) {
            return;
        }

        const validForNumberToCountry = Object.fromEntries(Object.entries(data.controllerValues).map(([key, value]) => [value, key]));

        this._countryToStates = data.values.reduce((accumulatedStates, state) => {
            const countryIsoCode = validForNumberToCountry[state.validFor[0]];

            return { ...accumulatedStates, [countryIsoCode]: [...(accumulatedStates?.[countryIsoCode] || []), state] };
        }, {});
    }

    get countries() {
        return this._countries;
    }

    get states() {
        return this._countryToStates[this.selectedCountry] || [];
    }

    handleCountry(e) {
        this.selectedCountry = e.detail.value;
    }

    handleState(e) {
        this.selectedState = e.detail.value;
    }
    get shouldRenderChild() {
        // Render child component only when both selectedCountry and selectedState are defined
        return this.selectedCountry && this.selectedState;
    }

}