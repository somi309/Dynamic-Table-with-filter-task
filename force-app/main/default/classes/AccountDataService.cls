public with sharing class AccountDataService {

    public class AccountWrapper {
        @AuraEnabled public String fieldLabel;
        @AuraEnabled public String fieldValue;
    }

    public class AccountRecordWrapper {
        @AuraEnabled public Id accountId;
        @AuraEnabled public List<AccountWrapper> fieldData;
    }

    @AuraEnabled(cacheable=true)
    public static List<AccountRecordWrapper> getAccountData(String searchTerm, String countyCode, String stateCode) {
        List<AccountRecordWrapper> wrapperList = new List<AccountRecordWrapper>();

        try {
            List<String> fieldApiNames = new List<String>();
            Map<String, String> fieldLabels = new Map<String, String>();
            List<String> searchableFields = new List<String>();
            Map<String, Schema.SObjectField> accountFields = Schema.SObjectType.Account.fields.getMap();

            // Retrieve fields marked as Active, ordered by Order__c
            for (Account_Field_Config__mdt fieldConfig : [
                SELECT Field_API_Name__c, Label__c, Search__c, Is_Active__c, Order__c
                FROM Account_Field_Config__mdt
                WHERE Is_Active__c = true
                ORDER BY Order__c
            ]) {
                fieldApiNames.add(fieldConfig.Field_API_Name__c);
                fieldLabels.put(fieldConfig.Field_API_Name__c, fieldConfig.Label__c);
            }

            // Retrieve fields for Search, ordered by Order__c
            for (Account_Field_Config__mdt fieldConfig : [
                SELECT Field_API_Name__c, Label__c, Search__c, Is_Active__c, Order__c
                FROM Account_Field_Config__mdt
                WHERE Search__c = true
                ORDER BY Order__c
            ]) {
                String fieldApi = fieldConfig.Field_API_Name__c;
                if (accountFields.containsKey(fieldApi) && accountFields.get(fieldApi).getDescribe().getType() == Schema.DisplayType.String) {
                    searchableFields.add(fieldApi);
                }
            }

            List<String> whereConditions = new List<String>();

            if (!String.isBlank(countyCode)) {
                whereConditions.add('BillingCountryCode = \'' + String.escapeSingleQuotes(countyCode) + '\'');
            }

            if (!String.isBlank(stateCode)) {
                whereConditions.add('BillingStateCode = \'' + String.escapeSingleQuotes(stateCode) + '\'');
            }

            if (!String.isBlank(searchTerm) && searchableFields.size() > 0) {
                List<String> searchConditions = new List<String>();
                for (String fieldApi : searchableFields) {
                    searchConditions.add(fieldApi + ' LIKE \'%' + String.escapeSingleQuotes(searchTerm) + '%\'');
                }
                whereConditions.add('(' + String.join(searchConditions, ' OR ') + ')');
            }

            String whereClause = whereConditions.size() > 0 ? 'WHERE ' + String.join(whereConditions, ' AND ') : '';

            // Build the final query, ensuring relationship fields are handled correctly
            List<String> queryFields = new List<String>();
            for (String field : fieldApiNames) {
                if (field.contains('.')) {
                    queryFields.add(field);
                } else if (accountFields.containsKey(field)) {
                    queryFields.add(field);
                }
            }

            String fields = String.join(queryFields, ',');
            String query = 'SELECT Id, ' + fields + ' FROM Account ' + whereClause + ' LIMIT 100';
            List<Account> accounts = Database.query(query);

            for (Account acc : accounts) {
                AccountRecordWrapper accWrapper = new AccountRecordWrapper();
                accWrapper.accountId = acc.Id;
                accWrapper.fieldData = new List<AccountWrapper>();

                for (String fieldApi : fieldApiNames) {
                    AccountWrapper fieldWrapper = new AccountWrapper();
                    fieldWrapper.fieldLabel = fieldLabels.get(fieldApi);

                    if (fieldApi.contains('.')) {
                        List<String> relationFields = fieldApi.split('\\.');
                        SObject relatedObject = acc.getSObject(relationFields[0]);
                        fieldWrapper.fieldValue = relatedObject != null ? String.valueOf(relatedObject.get(relationFields[1])) : '';
                    } else {
                        fieldWrapper.fieldValue = String.valueOf(acc.get(fieldApi));
                    }

                    accWrapper.fieldData.add(fieldWrapper);
                }
                wrapperList.add(accWrapper);
            }

        } catch (QueryException qe) {
            // You can handle a specific exception like QueryException here
            throw new AuraHandledException('An error occurred while retrieving data. Please try again later.');
        } catch (DmlException de) {
            // Handle DML specific errors if applicable
            throw new AuraHandledException('An error occurred while saving data. Please try again later.');
        } catch (Exception e) {
            // Generic catch block for all other exceptions
            throw new AuraHandledException('An unexpected error occurred. Please contact support.');
        }

        return wrapperList;
    }
}