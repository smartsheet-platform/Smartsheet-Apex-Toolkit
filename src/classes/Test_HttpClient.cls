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
private class Test_HttpClient {

    static testMethod void testSendRequestGetMethod() {

		HttpClient.testResponse = TestHelper.getTemplatesResponse(true);
		
		String endpoint = 'https://api.smartsheet.com/1.1';
		HttpClient client = new HttpClient(endpoint);
		String body = null;
		
		// test starts here
		Test.startTest();
		
			HttpResponse response = client.sendRequest('/sheets', 'GET', body, 'token');

			System.assertEquals(200, response.getStatusCode());
			System.assertEquals('Accepted', response.getStatus());
			
		Test.stopTest();
    }
    
	static testMethod void testSendRequestPostWithStringBody() {

		HttpClient.testResponse = TestHelper.getTemplatesResponse(true);
		
		String endpoint = 'https://api.smartsheet.com/1.1';
		HttpClient client = new HttpClient(endpoint);
		String body = 'this is body string';
		
		// test starts here
		Test.startTest();
		
			HttpResponse response = client.sendRequest('/sheets', 'POST', body, 'token');

			System.assertEquals(200, response.getStatusCode());
			System.assertEquals('Accepted', response.getStatus());
			
		Test.stopTest();
    }
 
	static testMethod void testSendRequestPostWithParameterMap() {

		HttpClient.testResponse = TestHelper.getTemplatesResponse(true);
		
		String endpoint = 'https://api.smartsheet.com/1.1';
		HttpClient client = new HttpClient(endpoint);
		Map<String, String> params = new Map<String, String>();
		params.put('key1', 'value1');
		
		// test starts here
		Test.startTest();
		
			HttpResponse response = client.sendRequest('/sheets', 'POST', params, 'token');

			System.assertEquals(200, response.getStatusCode());
			System.assertEquals('Accepted', response.getStatus());
			
		Test.stopTest();
    }
    
	static testMethod void testSendRequestPutWithStringBody() {

		HttpClient.testResponse = TestHelper.getTemplatesResponse(true);
		
		String endpoint = 'https://api.smartsheet.com/1.1';
		HttpClient client = new HttpClient(endpoint);
		String body = 'this is body string';
		
		// test starts here
		Test.startTest();
		
			HttpResponse response = client.sendRequest('/sheets', 'PUT', body, 'token');

			System.assertEquals(200, response.getStatusCode());
			System.assertEquals('Accepted', response.getStatus());
			
		Test.stopTest();
    }

    static testMethod void testSendRequestDeleteMethod() {

		HttpClient.testResponse = TestHelper.getTemplatesResponse(true);
	
		String endpoint = 'https://api.smartsheet.com/1.1';
		HttpClient client = new HttpClient(endpoint);
		String body = null;
		
		// test starts here
		Test.startTest();
		
			HttpResponse response = client.sendRequest('/sheets', 'DELETE', body, 'token');

			System.assertEquals(200, response.getStatusCode());
			System.assertEquals('Accepted', response.getStatus());
			
		Test.stopTest();
    }
}