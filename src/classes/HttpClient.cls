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

public with sharing class HttpClient {
	
	public static HttpResponse testResponse; // use it for testing
	private String endpoint;

	// constructor
	public HttpClient(String endpoint) {
		this.endpoint = endpoint;
	}
	
	/**
	 * sendRequst Sends a HTTP Request with body content to the endpoint.
	 * 
	 * @param path
	 *            the endpoint URL
	 * @param method
	 *            the HTTP method to use, defaults to GET
	 * @param body
	 *	          the request body content for POST or PUT method.
	 * @param token
	 *	          the access token to access API service
	 * 
	 * @return the HTTP rest response
	 */
	public HttpResponse sendRequest(String path, String method, String body, String token) {
			HttpRequest request = setupRequest(path, method, body, null);
			if (token != null) {
				request.setHeader('Authorization','Bearer ' + token);
				request.setHeader('Accept', 'application/json');
				request.setHeader('Content-Type', 'application/json');
			}
			return send(request);
	}
	
	/**
	 * sendRequst Sends a HTTP Request with querystring parameters to the endpoint.
	 * 
	 * @param path
	 *            the endpoint URL
	 * @param method
	 *            the HTTP method to use, defaults to GET
	 * @param vars
	 *            for POST or PUT, a map of data to send, for GET will be
	 *            appended to the URL as querystring params
	 * @param token
	 *	          the access token to access API service
	 * 
	 * @return the HTTP response
	 */
	public HttpResponse sendRequest(String path, String method, Map<String, String> vars, String token) {
			HttpRequest request = setupRequest(path, method, null, vars);
			if (token != null) {
				request.setHeader('Authorization','Bearer ' + token);
				request.setHeader('Accept', 'application/json');
				request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
			}
			return send(request);
	}

	/**
	 * send Sends a HTTP Request to the endpoint.
	 * 
	 * @param request
	 *            the HttpRequest to send
	 * @return the HTTP response
	 */
	private HttpResponse send(HttpRequest request) {

		String responseBody;
		Integer statusCode;
		String contentType;
		HttpResponse response = null;
		if (Test.isRunningTest()) {
			// can't execute HTTP requests during test execution
			return testResponse;
		} else {
			// execute HTTP request
			response = (new Http()).send(request);
			responseBody = (response.getBody() == null) ? '' : response.getBody();
			System.debug(responseBody + '------------------' + response);
		}
			
		return response;
	}
	
	/**
	 * Builds the method.
	 * 
	 * @param method
	 *            the method
	 * @param path
	 *            the path
	 * @param body
	 *	          the request body content
	 * @param params
	 *            the params
	 * @return the http uri request
	 */
	private HttpRequest buildMethod(String method, String path, String body,
			Map<String,String> params) {
		if (method.equalsIgnoreCase('GET')) {
			return generateGetRequest(path, params);
		} else if (method.equalsIgnoreCase('POST')) {
			return generatePostRequest(path, body, params);
		} else if (method.equalsIgnoreCase('PUT')) {
			return generatePutRequest(path, body, params);
		} else if (method.equalsIgnoreCase('DELETE')) {
			return generateDeleteRequest(path, params);
		} else {
			throw new SmartsheetException('Unknown Method: ' + method);
		}
	}

	/**
	 * Generate get request.
	 * 
	 * @param path
	 *            the path
	 * @param params
	 *            the params
	 * @return the http get
	 */
	private HttpRequest generateGetRequest(String path, Map<String,String> params) {

		URL uri = buildUri(path, params);
		HttpRequest req = new HttpRequest();
		req.setEndpoint(uri.toExternalForm());
		req.setMethod('GET');
		return req;
	}

	/**
	 * Generate post request.
	 * 
	 * @param path
	 *            the path
	 * @param body
	 *            the body content
	 * @param params
	 *            the params
	 * @return the http post
	 */
	private HttpRequest generatePostRequest(String path, String body, Map<String,String> params) {
		URL uri = buildUri(path);
		
		// if body exists, then use body
		String entity = null;
		if (body != null) {
			entity = body;
		} else {
			entity = buildEntityBody(params);
		}
		
		HttpRequest req = new HttpRequest();
		req.setEndpoint(uri.toExternalForm());
		req.setMethod('POST');
		req.setBody(entity);
		return req;
	}

	/**
	 * Generate put request.
	 * 
	 * @param path
	 *            the path
	 * @param params
	 *            the params
	 * @return the http put
	 */
	private HttpRequest generatePutRequest(String path, String body, Map<String,String> params) {
		URL uri = buildUri(path);

		// if body exists, then use body
		String entity = null;
		if (body != null) {
			entity = body;
		} else {
			entity = buildEntityBody(params);
		}
		
		HttpRequest req = new HttpRequest();
		req.setEndpoint(uri.toExternalForm());
		req.setMethod('PUT');
		req.setBody(entity);

		return req;
	}

	/**
	 * Generate delete request.
	 * 
	 * @param path
	 *            the path
	 * @param params
	 *            the params
	 * @return the http delete
	 */
	private HttpRequest generateDeleteRequest(String path,
			Map<String,String> params) {
		URL uri = buildUri(path);

		HttpRequest req = new HttpRequest();
		req.setEndpoint(uri.toExternalForm());
		req.setMethod('DELETE');
		return req;
	}

	/*
	 * 
	 * Helper functions for building methods
	 */
	/**
	 * Builds the entity body.
	 * 
	 * @param params
	 *            the params
	 * @return the url encoded form entity
	 */
	private String buildEntityBody(Map<String,String> params) {
		String entityBody='';
		if (params != null) {
			for (String key : params.keySet()) {
				try {
					entityBody += (entityBody=='' ? '' : '&')
									+ key + '=' + EncodingUtil.urlEncode(params.get(key), 'UTF-8');
				} catch (Exception e) {
					System.debug('ERROR: ' + e);
				}
			}
		}
		return entityBody;
	}

	/**
	 * Builds the uri.
	 * 
	 * @param path
	 *            the path
	 * @return the uRI
	 */
	private URL buildUri(String path) {
		return buildUri(path, null);
	}

	/**
	 * Builds the uri.
	 * 
	 * @param path
	 *            the path
	 * @param queryStringParams
	 *            the query string params
	 * @return the uRI
	 */
	private URL buildUri(String path, Map<String,String> queryStringParams) {
		String sb = path;
		
		if (queryStringParams != null && queryStringParams.size() > 0) {
			sb += '?';
			sb += buildEntityBody(queryStringParams);
		}

		URL uri;
		try {
			uri = new URL(sb);
		} catch (Exception e) {
			throw new SmartsheetException('Invalid uri: ' + sb, e);
		}

		return uri;
	}

	/**
	 * Setup request.
	 * 
	 * @param path
	 *            the path
	 * @param method
	 *            the method
	 * @param body
	 *	          the request body content. The body has preference over params.
	 * @param params
	 *            the params
	 * @return the http uri request
	 */
	private HttpRequest setupRequest(String path, String method, String body,
			Map<String, String> params) {
		
		String normalizedPath = path.toLowerCase();
		String sb = '';

		// If we've given a fully qualified uri then skip building the endpoint
		if (normalizedPath.startsWith('http://') || normalizedPath.startsWith('https://')) {
			sb += path;
		} else {
			sb += this.endpoint;

			if (!normalizedPath.startsWith('/')) {
				sb += '/';
			}
			sb += path;
		}

		path = sb;

		HttpRequest request = buildMethod(method, path, body, params);
		
		return request;
	}
}