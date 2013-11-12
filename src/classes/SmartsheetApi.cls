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
public with sharing class SmartsheetApi {
	private static final String GRANT_TYPE_AUTH = 'authorization_code';
	private static final String GRANT_TYPE_REFRESH = 'refresh_token';
	
	private static final Integer SERVICE_UNAVAILABLE_CODE = 503;
	private static final Integer MAX_RETRIES = 5;
	private static final Integer WAIT_INTERVAL_SECS = 5;
	
	private static final String TOKEN_PATH = '/token';
	private static final String SHEETS_PATH = '/sheets';
	
	private Smartsheet_Config__c config;
	private String accessToken;
	private String refreshToken;
	private Datetime tokenExpires;
	private HttpClient httpClient;
	private Boolean retryOnRateLimit = true;
	
	/*
	 * constructor with org default config
	 */
	public SmartsheetApi() {
		this.config = Smartsheet_Config__c.getOrgDefaults();
		
		// get authToken from User object
		getAccessToken();
		httpClient = new HttpClient(config.API_Base_URL__c + '/' + config.API_Version__c);
	}
	
	/*
	 * constructor with config name
	 */
	public SmartsheetApi(String configName) {
		this.config = Smartsheet_Config__c.getInstance(configName);

		// get authToken from User object
		getAccessToken();
		httpClient = new HttpClient(config.API_Base_URL__c + '/' + config.API_Version__c);
	}
	
	/*
	 * set retry on rate limit
	 */
	public void setRetryOnRateLimit(Boolean retry) {
		this.retryOnRateLimit = retry;
	}
	
	public Boolean getRetryOnRateLimit() {
		return this.retryOnRateLimit;
	}

	/*
	 * get the sheet list
	 */
	public List<Smartsheet.Sheet> getSheets() {
		List<Smartsheet.Sheet> sheets = (List<Smartsheet.Sheet>)callSmartsheetApi(SHEETS_PATH, 'GET', null, List<Smartsheet.Sheet>.class);
		return sheets;
	}
	
	/*
	 * get the sheet of sheetId
	 */
	public Smartsheet.Sheet getSheet(Long sheetId) {
		String path = '/sheet/' + sheetId;
		Smartsheet.Sheet sheet = (Smartsheet.Sheet)callSmartsheetApi(path, 'GET', null, Smartsheet.Sheet.class);
		return sheet;
	}
	
	/*
	 * create a sheet with provided sheet object
	 */
	public Smartsheet.SheetResult createSheet(Smartsheet.Sheet sheet) {
		/* get JSON string of sheet */
		String sheetStr = getJsonForNewSheet(sheet);

		Smartsheet.SheetResult sheetResult = (Smartsheet.SheetResult)callSmartsheetApi(SHEETS_PATH, 'POST', sheetStr, Smartsheet.SheetResult.class);
		return sheetResult;
	}
	
	/*
	 * insert rows to the sheet of sheetId
	 */
	public Smartsheet.RowsResult insertRows(Long sheetId, Smartsheet.InsertRows insertRows) {
		String path = '/sheet/' + sheetId + '/rows';
		/* get JSON string of InsertRows object */
		String insertRowsStr = getJsonForInsertRows(insertRows);

		Smartsheet.RowsResult rowsResult = (Smartsheet.RowsResult)callSmartsheetApi(path, 'POST', insertRowsStr, Smartsheet.RowsResult.class);
		return rowsResult;
	}
	
	/*
	 * The second leg of OAuth flow to get accessToken
	 */
	public Smartsheet.AccessToken getAccessToken(String code) {
		
		String doHash = config.Client_Secret__c + '|' + code;
		Blob digest = Crypto.generateDigest('SHA-256', Blob.valueOf(doHash));
        String hex = EncodingUtil.convertToHex(digest);

		// build request query parameters for getting access token
		Map<String, String> params = new Map<String, String>();
		params.put('client_id', config.Client_Id__c);
		params.put('hash', hex);
		params.put('redirect_uri', config.Redirect_URL__c);
		params.put('grant_type', GRANT_TYPE_AUTH);
		params.put('code', code);
		
		// send a request to get access token
		HttpResponse response = httpClient.sendRequest(TOKEN_PATH, 'POST', params, null);
		Smartsheet.AccessToken accessToken = (Smartsheet.AccessToken)JSON.deserialize(response.getBody(), Smartsheet.AccessToken.class);
		
		// update accessToken in User object
		saveAccessToken(accessToken);
		return accessToken;
	}
	
	/*
	 * refresh the access token
	 */
	public Smartsheet.AccessToken refreshAccessToken() {
		String doHash = config.Client_Secret__c + '|' + this.refreshToken;
		Blob digest = Crypto.generateDigest('SHA-256', Blob.valueOf(doHash));
        String hex = EncodingUtil.convertToHex(digest);

		// build request query parameters for refresh access token
		Map<String, String> params = new Map<String, String>();
		params.put('client_id', config.Client_Id__c);
		params.put('hash', hex);
		params.put('redirect_uri', config.Redirect_URL__c);
		params.put('grant_type', GRANT_TYPE_REFRESH);
		params.put('refresh_token', this.refreshToken);

		// send a request to refresh token
		HttpResponse response = httpClient.sendRequest(TOKEN_PATH, 'POST', params, null);
		Smartsheet.AccessToken accessToken = (Smartsheet.AccessToken)JSON.deserialize(response.getBody(), Smartsheet.AccessToken.class);
		
		// update accessToken in User object
		saveAccessToken(accessToken);
		return accessToken;
	}
	

	/*
	 * The method is called to request authorization code to authorization url, which is a start of OAuth flow.
	 */
	public String getRequestAuthCodeUrl(String state) {
		String params = 'response_type=code&client_id=' + config.Client_Id__c + '&redirect_uri=' + config.Redirect_URL__c +
			'&scope=' + config.Scope__c + '&state=' + state;
		String url = config.Authorize_URL__c + '?' + params;
		return url;
	}
	
	/*
	 * get the JSON string of sheet object.
	 * JSON.serialize() method produces null value, so need to use a custom generator.
	 */
	private String getJsonForNewSheet(Smartsheet.Sheet s) {
		JSONGenerator gen = JSON.createGenerator(false);
		gen.writeStartObject();
		gen.writeStringField('name', s.name);
		gen.writeFieldName('columns');
			gen.writeStartArray();
			
			for (Integer i=0; i < s.columns.size(); i++) {
				Smartsheet.Column column = s.columns.get(i);
			
				if (column.title != null && !column.title.equals('')) {
					gen.writeStartObject();
					gen.writeStringField('title', column.title);
			
					if (column.primary != null && column.primary) {
						gen.writeBooleanField('primary', true);
					}
					gen.writeStringField('type', column.type);
					
					if(column.type.equals('PICKLIST') && column.options != null) {
						gen.writeFieldName('options');
						gen.writeStartArray();

						for(Integer x=0; x < column.options.size(); x++) {
							gen.writeString(column.options.get(x));
						}
						gen.writeEndArray();
					}
					
					gen.writeEndObject();
				}
			}
			gen.writeEndArray();
		gen.writeEndObject();
		String jsonStr = gen.getAsString();
		return jsonStr;
	}
	
	/*
	 * get the JSON string of insertRow object
	 * JSON.serialize() method produces null value, so need to use a custom generator.
	 */
	private String getJsonForInsertRows(Smartsheet.InsertRows insertRows) {
		JSONGenerator gen = JSON.createGenerator(false);
		gen.writeStartObject();
	
		if (insertRows.toTop != null && insertRows.toTop) {
			gen.writeBooleanField('toTop', true);
		} else if (insertRows.toBottom != null && insertRows.toBottom) {
			gen.writeBooleanField('toBottom', true);
		} else if (insertRows.parentId != null) {
			gen.writeNumberField('parentId', insertRows.parentId);
		} else if (insertRows.siblingId != null) {
			gen.writeNumberField('siblingId', insertRows.siblingId);
		} else {
			System.debug('No insert position is specified, using toTop by default');
			gen.writeBooleanField('toTop', true);
		}
		
		gen.writeFieldName('rows');
			gen.writeStartArray();
			for (Integer i=0; i < insertRows.rows.size(); i++) {
				Smartsheet.Row row = insertRows.rows.get(i);
				gen.writeStartObject();
				gen.writeFieldName('cells');
				gen.writeStartArray();
				
				for (Integer j=0; j < row.cells.size(); j++) {
					Smartsheet.Cell cell = row.cells.get(j);
					
					// changing nulls to blank string for the writeStringField()
					if(cell.value == null){
						cell.value = '';
					}
			
					gen.writeStartObject();
					gen.writeNumberField('columnId', cell.columnId);
					gen.writeStringField('value', cell.value);
					if(cell.strict != null) {
						gen.writeBooleanField('strict', cell.strict);
					}
					gen.writeEndObject();
				}
				gen.writeEndArray();
				gen.writeEndObject();
			}
			gen.writeEndArray();
		gen.writeEndObject();
		String jsonStr = gen.getAsString();
		return jsonStr;
	}
	
	/* 
	 * callout to Smartsheet api with the provided path, method and object data
	 */
	private Object callSmartsheetApi(String path, String method, Object obj, Type returnType) {
		if (this.accessToken == null) {
			// todo: redirect to OAuth flow to login
			throw new SmartsheetException('Api is called without access token, please login to Smartsheet');
		}
		// refresh token if expired
		if (this.tokenExpires != null) {
			Datetime now = System.now();
			if (this.tokenExpires.getTime() < now.getTime()) {	// expired, refresh it
				refreshAccessToken();
			}
		}
		
		String body = null;
		if (obj != null) {
			if  (obj instanceof String) {
				body = (String)obj;
			} else {
				body = JSON.serialize(obj);
			}
		}
		
		// retry on rate limit
		for (Integer i=0; i < MAX_RETRIES; i++) {
			HttpResponse response = httpClient.sendRequest(path, method, body, this.accessToken);

			// handle error and rate limit
			if (response.getStatusCode() == 200) {	// no error						
				Object returnObject = JSON.deserialize(response.getBody(), returnType);
				return returnObject;
			} else {
				Smartsheet.RestError restError = (Smartsheet.RestError)JSON.deserialize(response.getBody(), Smartsheet.RestError.class);
				if (restError.errorCode == 1003) {	// token is expired, refresh token
					refreshAccessToken();
				} else if (this.retryOnRateLimit && response.getStatusCode() == SERVICE_UNAVAILABLE_CODE) {
					if (i < MAX_RETRIES) {
						sleepForDefinedInterval(i+1);
					}
				} else {
					throw new SmartsheetException('Error on Smartsheet API call, ' + restError.message);
				}
			}
		}
		
		return null;
	}
	
	/*
	 * retrieve access token from User object
	 */
	private void getAccessToken() {
		// get authToken from User object
		User u = [SELECT Access_Token__c, Refresh_Token__c, Token_Expires__c FROM User WHERE Id = :UserInfo.getUserId()];
		this.accessToken = u.Access_Token__c;
		this.refreshToken = u.Refresh_Token__c;
		if (u.Token_Expires__c != null) {
			this.tokenExpires = u.Token_Expires__c;
		}
		
	}
	
	/*
	 * save an access token to User object
	 */
	private void saveAccessToken(Smartsheet.AccessToken accessToken) {
		if (accessToken != null) {
			User u = [SELECT Id, Access_Token__c, Refresh_Token__c, Token_Expires__c FROM User WHERE Id = :UserInfo.getUserId()];
			u.Access_Token__c = accessToken.access_token;
			u.Refresh_Token__c = accessToken.refresh_token;
			Datetime now = System.now();
			Datetime expires = now.addSeconds(accessToken.expires_in);
			u.Token_Expires__c = expires;
			try {
				update u;
			} catch (DmlException e) {
				System.debug('Error on saving access token to User, ' + e.getMessage());
				throw new SmartsheetException('Error on saving access token to User');
			}
			
			this.accessToken = accessToken.access_token;
			this.refreshToken = accessToken.refresh_token;
			this.tokenExpires = expires;
		}
	}

	/*
	 * fake sleep method.
	 * There seems no way to sleep in APEX, I just put the fake sleep with looping.
	 * I think the retry should be implemented outside the toolkit by using @future
	 */
	private static void sleepForDefinedInterval(Integer retryNumber) {
		Integer sleepSecs = retryNumber * WAIT_INTERVAL_SECS;
		System.debug('503 (Service Unavailable) received - sleep ' + sleepSecs + ' secs before retry...');
		try {
			String looping = 'looping';
			for (Integer i=0; i<10; i++) {
				looping = looping + i;
			}
		} catch (Exception e) {
			System.debug('Threas.sleep got Exception ' + e.getMessage());
		}
	}
}