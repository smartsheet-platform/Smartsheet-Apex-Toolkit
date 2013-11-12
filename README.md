 
# Smartsheet Apex Toolkit
## Overview
The Smartsheet Apex Toolkit provides an Apex class library that interacts with the Smartsheet API, including an Apex object model and convenience methods for calling the API.

The Smartsheet API provides a REST interface to Smartsheet features and data. The API enables Smartsheet customers to programmatically access and manage their data, and empowers application developers to build solutions on top of Smartsheet.

For more information about the Smartsheet API, please visit [http://www.smartsheet.com/developers](http://www.smartsheet.com/developers) for full [API Documentation](http://www.smartsheet.com/developers/api-documentation) and [sample applications](https://www.smartsheet.com/developers/apps).

####Revision History
1.0 - November 12, 2013 - Basic authentication and sheet actions coverage.

## Usage
You can create a Sheet as follows: 
	
	Smartsheet.Sheet sheet = new Smartsheet.Sheet()
	sheet.name = "My Sheet Name"


## Current API Coverage

####Authentication

* getAccessToken()
* refreshAccessToken()
* saveAccessToken()	
* getRequestAuthCodeUrl()
	
####Sheet Actions	
* getSheet()
* getSheets()
* createSheet()
* insertRows()
 
## Connecting to Smartsheet
To enable your Salesforce application access to the Smartsheet API you'll need to create register a third-party app with Smartsheet or generate an API Access token in Smartsheet.

#### Registering Smartsheet Third-Party App
See the Smartsheet API documentation section on creating [third-party applications](http://www.smartsheet.com/developers/api-documentation#h.opcwlo3avvxk).

#### Generate API Access Token
See the Smartsheet API documentation section on how to [generate a Smartsheet Access Token](http://www.smartsheet.com/developers/api-documentation#h.5osh0dl59e5m).


## Installation
To start using the Smartsheet Apex Toolkit in your Salesforce Org install the unmanaged package of the library with the following URL:
 
[https://login.salesforce.com/packaging/installPackage.apexp?p0=04ti00000004HZH](https://login.salesforce.com/packaging/installPackage.apexp?p0=04ti00000004HZH)

Click Continue -> Next -> Next -> Install

## Setup
Create a List custom setting for organizational defaults in the Setup->Develop->Custom Settings->Smartsheet Config->Manage. On the Smartsheet Config Custom Setting page click the New button, and use the configuration values below:

* Name = a descriptive name  
* API_Base_URL = https://api.smartsheet.com
* API_Version = 1.1
* Authorize_URL = https://www.smartsheet.com/b/authorize
* Scope = READ_SHEETS,WRITE_SHEETS,CREATE_SHEETS 
* Redirect_URL = your-redirect-url
* Client_Id = your-smartsheet-client-id
* Client_Secret = your-smartsheet-secret

#### Add Remote Site
Interacting with the Smartsheet API requires a new remote site setting.

- Add a remote site for Smartsheet API site in the `Administration Setup`->`Security Controls`->`Remote Site Setting`->`New Remote Site`. 
- Create new remote site and set `https://api.smartsheet.com` in the Remote Site URL.




## Toolkit Demo VF page
Included in the Toolkit is a VisualForce page, SmartsheetDemoPage, which implements a simple Smartsheet API demo. To use it and test the toolkit, go to `https://<your-salesforce-server>/apex/SmartsheetDemoPage`:

- First, select one of the two available authorization types in the Authorization Type dropdown.
- When `User Generated Token` is selected, please type the user-generated-token in to `Generated Token` input field. Then click `Login to Smartsheet` button.
- When OAuth 2.0 is selected, then just click the `Login to Smartsheet` button and follow the OAuth 2 flow.
- Once you have been authorized, you will see your your access token displayed in the Access Token field, and a dropdown with sample API methods you can try.


## Contact
If you have any questions or suggestions about this document, the toolkit, or about the Smartsheet API in general please contact us at api@smartsheet.com. Development questions can also be posted to [Stackoverflow](http://stackoverflow.com/) with the tag [smartsheet-api](http://stackoverflow.com/questions/tagged/smartsheet-api).

##Contributions
We encourage community development on this library, and welcome any high quality contributions. Please submit a pull request if you develop enhancements or new methods for additional API coverage.


The Smartsheet Platform team


[![githalytics.com alpha](https://cruel-carlota.pagodabox.com/7b122c2a7e23b4e0fda2ce7bcb2b5d07 "githalytics.com")](http://githalytics.com/smartsheet-platform/Smartsheet-Apex-Toolkit) 
