@isTest
public class CustomerNumberUnpackaged {
    @isTest
    public static void insertAccount_ProvideCustomerNumberAndTechnicalIdWhitelistedSystem_RejectsInput() {
        // Act
        Account acc = new Account();
        acc.Name = 'Test Customer GmbH';
        acc.MasterSystem__c = 'TEST_WHITELISTED';
        acc.GlobalCustomerNumber__c = '10001';
        acc.OriginalTechnicalId__c = '20001';
        Database.SaveResult sr = Database.insert(acc, false);

        // Assert
        System.Assert.isFalse(sr.isSuccess(), 'dml failed');
        List<AutoCustomerNumber__c> cnRecords = [SELECT Id, Name FROM AutoCustomerNumber__c];
        System.Assert.areEqual(0, cnRecords.size(), 'inserted customer number records');
        System.Assert.areEqual(System.StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, sr.getErrors()[0].getStatusCode(), 'status code');
        System.Assert.areEqual(new List<String>{ 'OriginalTechnicalId__c' }, sr.getErrors()[0].getFields(), 'error fields');
    }

    @isTest
    public static void insertAccount_ProvideTechnicalIdNonWhitelistedSystem_GeneratesNumber() {
        // Act
        Account acc = new Account();
        acc.Name = 'Test Customer GmbH';
        acc.MasterSystem__c = 'TEST_NON_WHITELISTED';
        acc.GlobalCustomerNumber__c = null;
        acc.OriginalTechnicalId__c = 'c7e7f66f-ba76-4944-a73a-c95b9adf5500';
        insert acc;

        // Assert
        acc = [SELECT GlobalCustomerNumber__c, OriginalTechnicalId__c FROM Account WHERE Id = :acc.Id];
        List<AutoCustomerNumber__c> cnRecords = [SELECT Id, Name FROM AutoCustomerNumber__c];
        System.Assert.areEqual(1, cnRecords.size(), 'inserted customer number records');
        System.Assert.areEqual(cnRecords[0].Name, acc.GlobalCustomerNumber__c, 'new global number was generated');
        List<ExternalSystemIdentifier__c> systemIdentifierRecords = [SELECT Id, TechnicalId__c FROM ExternalSystemIdentifier__c];
        System.Assert.areEqual(1, systemIdentifierRecords.size(), 'inserted records for mapping');
        System.Assert.areEqual(systemIdentifierRecords[0].TechnicalId__c, acc.OriginalTechnicalId__c, 'mapping created successfully');
    }

    @isTest
    public static void insertAccount_ProvideCustomerNumberNonWhitelistedSystem_RejectsInput() {
        // Act
        Account acc = new Account();
        acc.Name = 'Test Customer GmbH';
        acc.MasterSystem__c = 'TEST_NON_WHITELISTED';
        acc.GlobalCustomerNumber__c = '10000';
        acc.OriginalTechnicalId__c = '10001';
        Database.SaveResult sr = Database.insert(acc, false);

        // Assert
        System.Assert.isFalse(sr.isSuccess(), 'dml failed');
        System.Assert.areEqual(
            System.StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION,
            sr.getErrors()[0].getStatusCode(),
            'status code of first error'
        );
        System.Assert.areEqual(new List<String>{ 'GlobalCustomerNumber__c' }, sr.getErrors()[0].getFields(), 'error fields');
    }

    @isTest
    public static void insertAccount_NoTechnicalIdNonWhitelistedSystem_RejectsInput() {
        // Act
        Account acc = new Account();
        acc.Name = 'Test Customer GmbH';
        acc.MasterSystem__c = 'TEST_NON_WHITELISTED';
        acc.GlobalCustomerNumber__c = null;
        acc.OriginalTechnicalId__c = null;
        Database.SaveResult sr = Database.insert(acc, false);

        // Assert
        System.Assert.isFalse(sr.isSuccess(), 'dml failed');
        System.Assert.areEqual(
            System.StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION,
            sr.getErrors()[0].getStatusCode(),
            'status code of first error'
        );
        System.Assert.areEqual(new List<String>{ 'OriginalTechnicalId__c' }, sr.getErrors()[0].getFields(), 'error fields');
    }

    @isTest
    public static void insertAccount_DuplicateTechnicalIdNonWhitelistedSystem_RejectsInput() {
        // Arrange
        Account acc = new Account(
            Name = 'Test Customer GmbH',
            MasterSystem__c = 'TEST_NON_WHITELISTED',
            OriginalTechnicalId__c = 'c7e7f66f-ba76-4944-a73a-c95b9adf5501'
        );
        insert acc;

        // Act
        Account duplicateAcc = new Account();
        duplicateAcc.Name = 'Test Customer GmbH';
        duplicateAcc.MasterSystem__c = 'TEST_NON_WHITELISTED';
        duplicateAcc.OriginalTechnicalId__c = 'c7e7f66f-ba76-4944-a73a-c95b9adf5501';
        Database.SaveResult sr = Database.insert(duplicateAcc, false);

        // Assert
        System.Assert.isFalse(sr.isSuccess(), 'dml failed');
        List<AutoCustomerNumber__c> cnRecords = [SELECT Id, Name FROM AutoCustomerNumber__c];
        System.Assert.areEqual(1, cnRecords.size(), 'inserted customer number records');
        System.Assert.areEqual(System.StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, sr.getErrors()[0].getStatusCode(), 'status code');
        System.Assert.areEqual(new List<String>{ 'OriginalTechnicalId__c' }, sr.getErrors()[0].getFields(), 'error fields');
    }

    @isTest
    public static void updateAccount_UpdateCustomerNumber_ValidationError() {
        // Arrange
        Account acc = new Account(Name = 'Test Customer GmbH', MasterSystem__c = 'SALESFORCE', GlobalCustomerNumber__c = '10000');
        insert acc;

        // Act
        Account updateAcc = new Account(Id = acc.Id);
        updateAcc.GlobalCustomerNumber__c = '10001';
        Database.SaveResult sr = Database.update(updateAcc, false);

        // Assert
        System.Assert.isFalse(sr.isSuccess(), 'dml failed');
        System.Assert.areEqual(new List<String>{ 'GlobalCustomerNumber__c' }, sr.getErrors()[0].getFields(), 'error fields');
        System.Assert.areEqual(System.StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, sr.getErrors()[0].getStatusCode(), 'status code');
    }

    @isTest
    public static void updateAccount_UpdateCustomerNumberFromBlankToValidValue_AcceptsInput() {
        // Arrange
        Account acc = new Account(Name = 'Test Customer GmbH', MasterSystem__c = 'SALESFORCE', GlobalCustomerNumber__c = null);
        Triggers.disableFeature('Account_Set_Customer_Number');
        Triggers.disableFeature('Account_Set_External_System_Identifier');
        insert acc;
        Triggers.enableFeature('Account_Set_Customer_Number');
        Triggers.enableFeature('Account_Set_External_System_Identifier');

        // Act
        Account updateAcc = new Account(Id = acc.Id);
        updateAcc.GlobalCustomerNumber__c = '10001';
        update updateAcc;

        // Assert
        updateAcc = [SELECT GlobalCustomerNumber__c FROM Account WHERE Id = :acc.Id];
        System.Assert.areEqual('10001', updateAcc.GlobalCustomerNumber__c, ' updated global number accepted');
    }
}
