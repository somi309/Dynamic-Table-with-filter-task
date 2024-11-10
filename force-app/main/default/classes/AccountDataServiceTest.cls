/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @description
* Test Class for AccountDataService class
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @author               Mousomi Sen
* @group          
* @class                AccountDataServiceTest
* @created Date         Nov 10, 2024
* @Last Modified on     Nov 10, 2024
* @Last Modified by     Mousomi Sen
* @version              1.0
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
* Change History :
  --------------------------------------------------------------------------------------------------
    SR#         Description                                                     Updated By          Updated On
**/


@IsTest
public class AccountDataServiceTest {

    @TestSetup
    static void setupTestData() {
        // Insert test Account records
        List<Account> accounts = new List<Account>{
            new Account(Name = 'Test Account 1', BillingCountryCode = 'US', BillingStateCode = 'CA', Phone = '1234567890'),
            new Account(Name = 'Sample Account 2', BillingCountryCode = 'US', BillingStateCode = 'NY', Phone = '0987654321'),
            new Account(Name = 'Example Account 3', BillingCountryCode = 'CA', BillingStateCode = 'ON', Phone = '1112223333')
        };
        insert accounts;
    }

    @IsTest
    static void testGetAccountDataWithMockedMetadata() {
        // Mocking metadata by manually simulating it in the method
        Test.startTest();
        List<AccountDataService.AccountRecordWrapper> results = AccountDataService.getAccountData('Test', 'US', 'CA');
        Test.stopTest();

        // Add assertions as per your tests above
        System.assertEquals(1, results.size(), 'Only one account should match the search term "Test" and countyCode "US".');
    }
}