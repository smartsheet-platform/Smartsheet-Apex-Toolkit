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
private class Test_SmartsheetApi {

	static testMethod void testGetRequestAuthCodeUrl() {
		Smartsheet_Config__c config = TestHelper.createTestConfig('testConfig');
		
		SmartsheetApi api = new SmartsheetApi('testConfig');
		
		String state = 'test-state';
		String expectedUrl = config.Authorize_URL__c+'?'+'response_type=code&client_id='+config.Client_Id__c+'&redirect_uri='+
					config.Redirect_URL__c+'&scope='+config.Scope__c+'&state='+state;
		
		Test.startTest();
			String authUrl = api.getRequestAuthCodeUrl(state);
			System.assertEquals(expectedUrl, authUrl);
		Test.stopTest();
	}

    static testMethod void testGetAccessToken() {

		TestHelper.createTestConfig('testConfig');
		TestHelper.createTestAccessToken();
		HttpClient.testResponse = TestHelper.getTokenResponse(true);
		
		SmartsheetApi api = new SmartsheetApi('testConfig');
		
		// test starts here
		Test.startTest();
		
			Smartsheet.AccessToken accessToken = api.getAccessToken('code1');
			
			System.assertEquals('access_token-1', accessToken.access_token);
			System.assertEquals('refresh-token-1', accessToken.refresh_token);
			System.assertEquals(1234, accessToken.expires_in);
			System.assertEquals('bearer', accessToken.token_type);

		Test.stopTest();
    }

    static testMethod void testGetFreshToken() {

		TestHelper.createTestConfig('testConfig');
		TestHelper.createTestAccessToken();
		HttpClient.testResponse = TestHelper.getTokenResponse(true);
		
		SmartsheetApi api = new SmartsheetApi('testConfig');
		
		// test starts here
		Test.startTest();
		
			Smartsheet.AccessToken accessToken = api.refreshAccessToken();
			
			System.assertEquals('access_token-1', accessToken.access_token);
			System.assertEquals('refresh-token-1', accessToken.refresh_token);
			System.assertEquals(1234, accessToken.expires_in);
			System.assertEquals('bearer', accessToken.token_type);

		Test.stopTest();
    }

    static testMethod void testGetSheetsWithoutToken() {

		TestHelper.createTestConfig('testConfig');
		TestHelper.clearTestAccessToken();
		HttpClient.testResponse = TestHelper.getSheetsResponse(true);
		
		SmartsheetApi api = new SmartsheetApi('testConfig');
		
		// test starts here
		Test.startTest();
		
			try {
				List<Smartsheet.Sheet> sheets = api.getSheets();
				System.assertEquals(1, 2);	// assert fail
			} catch (SmartsheetException e) {
				System.assertEquals('Api is called without access token, please login to Smartsheet', e.getMessage());
			}

		Test.stopTest();
    }
    
    static testMethod void testGetSheets() {

		TestHelper.createTestConfig('testConfig');
		TestHelper.createTestAccessToken();
		HttpClient.testResponse = TestHelper.getSheetsResponse(true);
		
		SmartsheetApi api = new SmartsheetApi('testConfig');
		
		// test starts here
		Test.startTest();
		
			List<Smartsheet.Sheet> sheets = api.getSheets();
			
			System.assertEquals(3, sheets.size());
			Smartsheet.Sheet sheet1 = sheets.get(0);
			System.assertEquals(1111, sheet1.id);
			System.assertEquals('Test Sheet1', sheet1.name);
			System.assertEquals('OWNER', sheet1.accessLevel);

		Test.stopTest();
    }
    
    static testMethod void testGetSheet() {

		TestHelper.createTestConfig('testConfig');
		TestHelper.createTestAccessToken();
		HttpClient.testResponse = TestHelper.getSheetResponse(true);
		
		SmartsheetApi api = new SmartsheetApi('testConfig');
		
		// test starts here
		Test.startTest();
			
			Smartsheet.Sheet sheet = api.getSheet(1111L);
			
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
    
    static testMethod void testCreateSheet() {

		TestHelper.createTestConfig('testConfig');
		TestHelper.createTestAccessToken();
		HttpClient.testResponse = TestHelper.getNewSheetResponse(true);
		
		SmartsheetApi api = new SmartsheetApi('testConfig');
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
			
		// test starts here
		Test.startTest();
			
			Smartsheet.SheetResult sheetResult = api.createSheet(sheet);
			
			Smartsheet.Sheet newSheet = sheetResult.result;
			System.assertEquals(1111L, newSheet.id);
			System.assertEquals('Test Sheet1', newSheet.name);
			System.assertEquals('OWNER', newSheet.accessLevel);

		Test.stopTest();
    }
    
    static testMethod void testInsertRows() {

		TestHelper.createTestConfig('testConfig');
		TestHelper.createTestAccessToken();
		HttpClient.testResponse = TestHelper.getInsertRowsResponse(true);
		
		SmartsheetApi api = new SmartsheetApi('testConfig');
		
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
		
		// test starts here
		Test.startTest();
			
			Smartsheet.RowsResult rowsResult = api.insertRows(1111L, insertRows);
			
			List<Smartsheet.Row> rows2 = rowsResult.result;
			System.assertEquals(0, rowsResult.resultCode);
			System.assertEquals('SUCCESS', rowsResult.message);
			System.assertEquals(1, rows2.size());

		Test.stopTest();
    }
    
    static testMethod void testSmartsheetModels() {
    	Smartsheet.Sheet sheet = new Smartsheet.Sheet();
    	sheet.setId(1111L);
    	sheet.setName('Sheet-1');
    	
    	Smartsheet.Column column = new Smartsheet.Column();
    	column.id = 1;
    	System.assertEquals(1, column.getId());
    	column.index = 1;
    	System.assertEquals(1, column.getIndex());
    	column.setTitle('title-1');
    	System.assertEquals('title-1', column.getTitle());
    	column.setType('type-1');
    	System.assertEquals('type-1', column.getType());
    	column.primary = true;
    	System.assertEquals(true, column.getPrimary());
    	
    	Smartsheet.Cell cell = new Smartsheet.Cell();
    	cell.setValue('value-1');
    	System.assertEquals('value-1', cell.getValue());
    	cell.displayValue = 'value-1';
    	System.assertEquals('value-1', cell.getDisplayValue());
    	cell.setColumnId(1111);
    	System.assertEquals(1111, cell.getColumnId());
    	cell.setType('type-1');
    	System.assertEquals('type-1', cell.getType());
    	
    	List<Smartsheet.Cell> cells = new List<Smartsheet.Cell>();
    	cells.add(cell);
    	
    	List<Smartsheet.Column> columns = new List<Smartsheet.Column>();
    	sheet.setColumns(columns);
    	List<Smartsheet.Row> rows = new List<Smartsheet.Row>();
    	sheet.setRows(rows);
    	List<Smartsheet.Row> rows2 = sheet.getRows();
    	
    	Smartsheet.Row row = new Smartsheet.Row();
    	row.id = 1;
    	System.assertEquals(1, row.getId());
    	row.getSheetId();
    	row.getRowNumber();
    	row.cells = cells;
    	System.assertEquals(1, row.getCells().size());
    	
    	Smartsheet.AccessToken token = new Smartsheet.AccessToken();
    	token.access_token = 'token-1';
    	System.assertEquals('token-1', token.getAccessToken());
    	
    	Smartsheet.RestError restError = new Smartsheet.RestError();
    	restError.error = 'error-1';
    	restError.message = 'message-1';

    	
    }
}