import { LightningElement, track, api } from 'lwc';
import getAccountData from '@salesforce/apex/AccountDataService.getAccountData';

export default class ListViewSection extends LightningElement {
    @track columns = [];
    @track rows = [];
    @track searchTerm = '';
    @api country;
    @api state;

    connectedCallback() {
        this.fetchAccountData();
    }

    fetchAccountData() {
        // Fetch account data in wrapper format
        getAccountData({
            searchTerm: this.searchTerm,
            countyCode: this.country,
            stateCode: this.state
        })
            .then(data => {
                if (data.length > 0) {
                    // Extract columns (field labels) from the first record
                    this.columns = data[0].fieldData.map(field => field.fieldLabel);

                    // Process each account record to add unique keys
                    this.rows = data.map(account => {
                        const rowData = { accountId: account.accountId, fieldValues: [] };
                        account.fieldData.forEach((field, index) => {
                            // Add unique key to each field value
                            rowData.fieldValues.push({
                                value: field.fieldValue,
                                key: `${account.accountId}-${index}`  // Unique key for each cell
                            });
                        });
                        return rowData;
                    });
                }
            })
            .catch(error => {
                console.error('Error fetching account data:', error);
            });
    }

    handleSearch(event) {
        this.searchTerm = event.target.value;  // Update the search term as the user types
        this.fetchAccountData();
    }
}