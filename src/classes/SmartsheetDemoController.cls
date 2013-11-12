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
public with sharing class SmartsheetDemoController {

	private static List<SelectOption> AUTH_TYPE_LIST = new SelectOption[] {
		new SelectOption('OAuth2.0', 'OAuth 2.0'),
		new SelectOption('UserGeneratedToken', 'User Generated Token')
	};

	private static List<SelectOption> API_METHOD_LIST = new SelectOption[] {
		new SelectOption('ListSheets', 'List Sheets'),
		new SelectOption('CreateSheet', 'Create Sheet'),
		new SelectOption('InsertRows', 'Insert Rows')
	};
	
	private static List<SelectOption> COLUMN_TYPE_LIST = new SelectOption[] {
		new SelectOption('TEXT_NUMBER', 'TEXT NUMBER'),
		new SelectOption('DATE', 'DATE'),
		new SelectOption('DATETIME', 'DATETIME'),
		new SelectOption('CONTACT_LIST', 'CONTACT LIST'),
		new SelectOption('CHECKBOX', 'CHECKBOX'),
		new SelectOption('PICKLIST', 'PICKLIST')
	};
	
	private String oauthState;
	private SmartsheetApi api;
	
	public SmartsheetDemoController() {
		api = new SmartsheetApi();
		User u = [SELECT Access_Token__c FROM User WHERE Id = :UserInfo.getUserId()];
		token = u.Access_Token__c;
		
		/*
		 * new sheet object
		 */
		createNewSheetObject();
		createNewInsertRowsObject();
	}
	
	public String token {
		get {
			if (token == null) {
				return 'No Access Token Found.';
			} else {
				return 'Token Saved';
			}
			return token;
		}
		set; 
	}
	public String authType { get; set; }
	public String generatedToken { get; set; }
	public Smartsheet.Sheet sheet { get; set; }	// currently selected sheet
	public Smartsheet.Sheet newSheet { get; set; }	// used for creating new sheet
	public Smartsheet.InsertRows insertRows { get; set; }	// used for inserting rows to the currently selected sheet
	public List<Smartsheet.Sheet> sheets { get; set; } // list of sheets
	
	public String apiMethod { get; set; }
	public Long sheetId { get; set; }
	
	public List<SelectOption> getAuthTypeList() {
		return AUTH_TYPE_LIST;
	}
	
	public List<SelectOption> getApiMethodList() {
		return API_METHOD_LIST;
	}
	
	public List<SelectOption> getColumnTypeList() {
		return COLUMN_TYPE_LIST;
	}
	
	/* 
	 * Smartsheet OAuth redirect_url is set to the VF page. When Smartsheet makes callback,
	 * this oauthTarget() method is get called.
	 */
	public PageReference oauthTarget() {
		/* 
		 * retrieve oauth state from User object
		 */
		User u = [SELECT Id, OAuth_State__c FROM User WHERE Id = :UserInfo.getUserId()];
		oauthState = u.OAuth_State__c;
		
		String code = ApexPages.currentPage().getParameters().get('code');
		String state = ApexPages.currentPage().getParameters().get('state');
		String error = ApexPages.currentPage().getParameters().get('error');
		
		if (code == null && state == null && error == null) {
			/* 
			 * Regular VF visit, not OAuth callback
			 */
			return null;
		}
		
		/* 
		 * check state
		 */
		if (error != null) {
			System.debug('oauthTarget: non-null error returned ' + error);
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,
					'Smartsheet API error returned: ' + error));		} else if (state == null || !state.equals(oauthState)) {
			System.debug('oauthTarget: state is null or does not match, ' + state);
			throw new SmartsheetException('oauthTarget: state is null or does not match, ' + state);
		} else {
			/*
			 * requesting authroization code is successful
 			 *
			 * request access token
			 */
			Smartsheet.AccessToken accessToken = api.getAccessToken(code);
			token = accessToken.access_token;
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,
					'Logged in to Smartsheet successfully'));
			
		}
		return null;
	}
	
	/* 
	 * start OAuth flow by redirecting user to Smartsheet authorization URL 
	 */
	public PageReference authorize() {
		
		if (authType.equals('UserGeneratedToken')) {
			if (generatedToken != null && !generatedToken.equals(''))
				updateToken(generatedToken);
			else {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,
						'Generated Token is empty, please set the user generated token in the Generated Token field'));
			}
		} else {	
			/*
			 * OAuth
			 * 
			 * create random, save it to User object
			 */
			oauthState = '' + Crypto.getRandomLong();
			User u = [SELECT Id, OAuth_State__c FROM User WHERE Id = :UserInfo.getUserId()];
			u.OAuth_State__c = oauthState;
			
			try {
				update u;
			} catch (DmlException e) {
				System.debug('Failed to update User, ' + e.getMessage());
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,
						'Failed to update User object, please try again'));
			}
			
			String authUrl = api.getRequestAuthCodeUrl(oauthState);
			PageReference authPage = new PageReference(authUrl);
			authPage.setRedirect(true);
			return authPage;
		}
		return null;
	}
	
	/* 
	 * action method to delete current token
	 */
	public PageReference deleteToken() {
		updateToken(null);
		ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,
				'Deleted access token, please login again to use Smartsheet API'));
		return null;
	}

	/* 
	 * action method for Execute API button
	 */
	public PageReference invokeApi() {
		/*
		 * apiMethod = 'ListSheets';
		 */
		if (apiMethod == 'ListSheets') {
			sheets = api.getSheets();
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,
			'Retrieved ' + sheets.size() + ' sheets from Smartsheet'));
		/*
		 * apiMethod = 'CreateSheets';
		 */
		} else if (apiMethod == 'CreateSheet') {
			System.debug('New sheet name: ' + newSheet.name);
			newSheet.rows = null;
			api.createSheet(newSheet);
	
			/* 
			 * get the updated sheet list
			 */
			sheets = api.getSheets();
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,
					'Created new sheet '+ newSheet.name +' successfully'));
			
			/* 
			 * clear the existing newSheet object
			 */
			createNewSheetObject();
			
		/*
		 * apiMethod = 'InsertRows';
		 */
		} else if (apiMethod == 'InsertRows') {
			Smartsheet.RowsResult rowsResult = api.insertRows(sheet.id, insertRows);
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,
					'Inserted rows to the sheet ' + sheet.name));
			/*
			 * get the updated sheet
			 */
			sheet = api.getSheet(sheet.id);
			createNewInsertRowsObject();		// clear insertRows object
			apiMethod = 'GetSheet';
		/*
		 * apiMethod = 'GetSheet';
		 */
		} else if (apiMethod == 'GetSheet') {
			sheet = api.getSheet(sheetId);
			createNewSheetObject();			// clear newSheet object
			createNewInsertRowsObject();	// clear insertRows object
		}
		return null;
	}
		
	private void updateToken(String newToken) {
		User u = [SELECT Access_Token__c, Refresh_Token__c, Token_Expires__c FROM User WHERE Id = :UserInfo.getUserId()];
		u.Access_Token__c = newToken;
		u.Refresh_Token__c = null;
		u.Token_Expires__c = null;
		try {
			update u;
		} catch (DmlException e) {
			System.debug('Failed to update User, '+ e.getMessage());
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,
				'Failed to update User object, please try again'));
		}
		token = newToken;
		api = new SmartsheetApi();
	}
	
	private void createNewSheetObject() {
		newSheet = new Smartsheet.Sheet();
		List<Smartsheet.Column> columns = new List<Smartsheet.Column>();
		for (Integer i=0; i<4; i++) {
			Smartsheet.Column column = new Smartsheet.Column();
			if (i==0)
				column.primary = true;
			columns.add(column);
		}
		newSheet.columns = columns;
		
	}
	
	private void createNewInsertRowsObject() {
		if (sheet != null) {
			insertRows = new Smartsheet.InsertRows();
			insertRows.toTop = true;
			List<Smartsheet.Row> rows = new List<Smartsheet.Row>();
			for (Integer i=0; i<2; i++) {
				Smartsheet.Row row = new Smartsheet.Row();
				List<Smartsheet.Cell> cells = new List<Smartsheet.Cell>();
				for (Integer j=0; j<sheet.columns.size(); j++) {
					Smartsheet.Column column = sheet.columns.get(j);
					Smartsheet.Cell cell = new Smartsheet.Cell();
					cell.columnId = column.getId();
					cells.add(cell);
				}
				row.cells = cells;
				rows.add(row);
			}
			insertRows.rows = rows;
		}
	}
}