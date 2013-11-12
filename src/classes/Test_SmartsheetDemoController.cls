/****************************************************************************
	Copyright 2013 Smartsheet, Inc.
	
	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at
	
	http://www.apache.org/licenses/LICENSE-2.0
	
	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and       
	limitations under the License.             
*****************************************************************************/
@isTest
private class Test_SmartsheetDemoController {
    
    static testMethod void testAuthorizeActionOAuth() {

		Smartsheet_Config__c config = TestHelper.createTestConfig('testConfig');
		
		SmartsheetDemoController controller = new SmartsheetDemoController();
		controller.authType = 'OAuth2.0';
		
		// test starts here
		Test.startTest();
		
			PageReference pageRef = controller.authorize();
			
			User u = [SELECT Id, OAuth_State__c FROM User WHERE Id = :UserInfo.getUserId()];
			String state = u.OAuth_State__c;

			System.assertEquals(true, pageRef.getUrl().contains(config.Authorize_URL__c));


		Test.stopTest();
    }

    static testMethod void testAuthorizeActionGeneratedToken() {

		Smartsheet_Config__c config = TestHelper.createTestConfig('testConfig');
		
		SmartsheetDemoController controller = new SmartsheetDemoController();
		controller.authType = 'UserGeneratedToken';
		controller.generatedToken = 'generated-token-1';
		
		// test starts here
		Test.startTest();
		
			PageReference pageRef = controller.authorize();
			
			User u = [SELECT Id, Access_Token__c FROM User WHERE Id = :UserInfo.getUserId()];
			String state = u.Access_Token__c;

			System.assertEquals('generated-token-1', u.Access_Token__c);


		Test.stopTest();
    }

    static testMethod void testDeleteTokenAction() {

		TestHelper.createTestAccessToken();
		
		SmartsheetDemoController controller = new SmartsheetDemoController();
		
		// test starts here
		Test.startTest();
		
			PageReference pageRef = controller.deleteToken();
			
			User u = [SELECT Id, Access_Token__c FROM User WHERE Id = :UserInfo.getUserId()];

			System.assertEquals(null, u.Access_Token__c);


		Test.stopTest();
    }
    
    static testMethod void testGetSheetsApiMethod() {

		TestHelper.createTestConfig('testConfig');
		TestHelper.createTestAccessToken();
		HttpClient.testResponse = TestHelper.getSheetsResponse(true);
		
		SmartsheetDemoController controller = new SmartsheetDemoController();
		controller.apiMethod = 'ListSheets';
		
		// test starts here
		Test.startTest();
		
			PageReference pageRef = controller.invokeApi();
			
			System.assertEquals(3, controller.sheets.size());
			Smartsheet.Sheet sheet1 = controller.sheets.get(0);
			System.assertEquals(1111, sheet1.id);
			System.assertEquals('Test Sheet1', sheet1.name);
			System.assertEquals('OWNER', sheet1.accessLevel);

		Test.stopTest();
    }
    
    static testMethod void testGetSheetApiMethod() {

		TestHelper.createTestConfig('testConfig');
		TestHelper.createTestAccessToken();
		HttpClient.testResponse = TestHelper.getSheetResponse(true);
		
		SmartsheetDemoController controller = new SmartsheetDemoController();
		controller.apiMethod = 'GetSheet';
		controller.sheetId = 1111L;
		
		// test starts here
		Test.startTest();
			
			PageReference pageRef = controller.invokeApi();
			Smartsheet.Sheet sheet = controller.sheet;
			
			System.assertEquals(1111L, sheet.id);
			System.assertEquals('Test Sheet1', sheet.name);
			System.assertEquals('OWNER', sheet.accessLevel);
			System.assertEquals(3, sheet.columns.size());
			System.assertEquals(1111L, sheet.getId());
			System.assertEquals('Test Sheet1', sheet.getName());
			System.assertEquals('OWNER', sheet.getAccessLevel());
			System.assertEquals(3, sheet.getColumns().size());
			

		Test.stopTest();
    }
/*
    static testMethod void testCreateSheetApiMethod() {

		TestHelper.createTestConfig('testConfig');
		TestHelper.createTestAccessToken();
		HttpClient.testResponse = TestHelper.getNewSheetResponse(true);
		
		SmartsheetDemoController controller = new SmartsheetDemoController();
		controller.apiMethod = 'CreateSheet';
		controller.sheetId = 1111L;
		
		Smartsheet.Sheet sheet = new Smartsheet.Sheet();
		sheet.name = 'Test Sheet1';
		List<Smartsheet.Column> columns = new List<Smartsheet.Column>();
		sheet.columns = columns;
		for (Integer i=0; i<2; i++) {
			Smartsheet.Column column = new Smartsheet.Column();
			column.title = 'column'+i;
			column.type = 'TEXT+NUMBER';
			if (i==0)
				column.primary = true;
			columns.add(column);
		}
		controller.newSheet = sheet;
			
		// test starts here
		Test.startTest();
			
			PageReference pageRef = controller.invokeApi();
			
			System.assertEquals(3, controller.sheets.size());

		Test.stopTest();
    }

    static testMethod void testInsertRowsApiMethod() {

		TestHelper.createTestConfig('testConfig');
		TestHelper.createTestAccessToken();
		HttpClient.testResponse = TestHelper.getInsertRowsResponse(true);
		
		SmartsheetDemoController controller = new SmartsheetDemoController();
		controller.apiMethod = 'InsertRows';
		
		Smartsheet.Sheet sheet = new Smartsheet.Sheet();
		sheet.id = 1111L;
		sheet.columns = new List<Smartsheet.Column>();
		for (Integer i=0; i<2; i++) {
			Smartsheet.Column column = new Smartsheet.Column();
			column.title = 'column'+i;
			column.type = 'TEXT+NUMBER';
			if (i==0)
				column.primary = true;
			sheet.columns.add(column);
		}
		controller.sheet = sheet;
		
		Smartsheet.InsertRows insertRows = new Smartsheet.InsertRows();
		insertRows.toTop = true;
		List<Smartsheet.Row> rows = new List<Smartsheet.Row>();
		insertRows.rows = rows;
		Smartsheet.Row row = new Smartsheet.Row();
		rows.add(row);
		List<Smartsheet.Cell> cells = new List<Smartsheet.Cell>();
		row.cells = cells;
		Smartsheet.Cell cell = new Smartsheet.Cell();
		cell.columnId = 1234;
		cell.value = 'Cell1 Value';
		cells.add(cell);
		controller.insertRows = insertRows;
		
		// test starts here
		Test.startTest();
			
			PageReference pageRef = controller.invokeApi();
			
			System.assertEquals(1111L, controller.sheet.id);
			System.assertEquals('GetSheet', controller.apiMethod);

		Test.stopTest();
    }
*/
}