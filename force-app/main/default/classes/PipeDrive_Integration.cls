public class PipeDrive_Integration {

  // Define a method to create an organization in Pipedrive and store its ID in Salesforce
    @AuraEnabled
    public static void createOrganization(String  Id) {
        try {
        Account acc=[select id,Name,BillingStreet,BillingCity,BillingCountry,Phone,Email__c,Pipe_Drive_Organization__c FROM Account where id =: id];
        if(acc.Pipe_Drive_Organization__c !=null){
            // Construct the Pipedrive API endpoint
            String pipedriveEndpoint = System.label.PipeDrive_URL+System.label.Pipe_Drive_Api_Key;

            // Construct the JSON payload to send to Pipedrive
     String jsonPayload = '{"name": "' + acc.Name + '", "address": "' + acc.BillingStreet + ', ' + acc.BillingCity + ', ' + acc.BillingCountry + '", "phone": "' + acc.Phone + '", "email": "' + acc.Email__c + '"}';

            // Create an HTTP request
            HttpRequest req = new HttpRequest();
            req.setEndpoint(pipedriveEndpoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(jsonPayload);

            // Send the HTTP request
            Http http = new Http();
            HttpResponse res = http.send(req);

            // Check the response from Pipedrive
            if (res.getStatusCode() == 201) {
                try {
                    // Deserialize the JSON response into the wrapper class
                    PipedriveResponse responseObj = (PipedriveResponse) JSON.deserialize(res.getBody(), PipedriveResponse.class);

                    // Extract the organization ID from the response
                    if (responseObj != null && responseObj.success && responseObj.data != null) {
                        String pipedriveOrgId = String.valueOf(responseObj.data.id);

                       // update an Account  with the Pipedrive Org ID
                       
                        acc.Pipe_Drive_Organization__c= pipedriveOrgId;

                        // Update the Account in Salesforce
                        update acc;
                        
                        System.debug('Organization created and ID stored in Salesforce: ' + pipedriveOrgId);
                    } else {
                        System.debug('Error: Organization creation failed or invalid response data.');
                    }
                } catch (Exception deserializationEx) {
                    // Handle any exceptions during JSON deserialization
                    System.debug('Error during JSON deserialization: ' + deserializationEx.getMessage());
                }
            } else {
                System.debug('Failed to create organization: ' + res.getStatusCode() + ' ' + res.getBody());
            }
            }
        
        } catch (Exception e) {
            // Catch any unexpected exceptions during the HTTP request or Salesforce operations
            System.debug('An error occurred while processing the request: ' + e.getMessage());
            // Optionally, you can add more logging or send a notification for critical errors
        }
        List<Account> lstAccounts = [select id,Pipe_Drive_Organization__c,(select id,Name,Email,phone FROM Contacts where Pipe_Drive_Person__c!=null ) FROM account];

    for(Account eachAccount:lstAccounts){

    for(contact eachContact:eachAccount.contacts){

    createPerson(eachContact.Id,eachAccount.Pipe_Drive_Organization__c);

    }
    }
    

    }
    // Define a method to create a person in Pipedrive and update the Contact record in Salesforce with the Pipedrive Person ID
    @future(callout=true)
    public static Void createPerson(string Id,String OrganisationId) {
    contact returncontactWithPersonID;
    contact eachcontact = [select Id,Pipe_Drive_Person__c,Name,Email,phone FROM Contact WHERE id=: id And Pipe_Drive_Person__c!=null];
        try {
            // Pipedrive API Endpoint to create a person
            String pipedriveEndpoint =System.label.Pipe_Drive_Person+System.label.Pipe_Drive_Api_Key; 

            // Construct JSON payload to send to Pipedrive API
            String jsonPayload = '{"name": "' + eachContact.Name + '", ' +
                                 '"owner_id": ' +  + ', ' +
                                 '"org_id": ' + OrganisationId + ', ' +
                                 '"email": [' +
                                    '{"value": "' + eachContact.Email + '", "primary": true, "label": "work"}' +
                                 '], ' +
                                 '"phone": [' +
                                    '{"value": "' + eachContact.phone + '", "primary": true, "label": "mobile"}' +
                                 ']}';

            // Create an HTTP request
            HttpRequest req = new HttpRequest();
            req.setEndpoint(pipedriveEndpoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(jsonPayload);

            // Send the HTTP request to Pipedrive
            Http http = new Http();
            HttpResponse res = http.send(req);

            // Check for successful response
            if (res.getStatusCode() == 201) {
                // Deserialize the JSON response into PipedrivePersonResponse wrapper class
                PipedrivePersonResponse responseObj = (PipedrivePersonResponse) JSON.deserialize(res.getBody(), PipedrivePersonResponse.class);

                // Extract Pipedrive Person ID from response
                if (responseObj != null && responseObj.success && responseObj.data != null) {
                    String pipedrivePersonId = String.valueOf(responseObj.data.id);

                     
                        eachcontact.Pipe_Drive_Person__c= pipedrivePersonId;

                        
                        // Update the Account in Salesforce
                        update eachcontact;
                        System.debug('Updated Contact with Pipedrive Person ID: ' + pipedrivePersonId);
                    
                } else {
                    System.debug('Error: Person creation failed or invalid response data.');
                }
            } else {
                System.debug('Failed to create person: ' + res.getStatusCode() + ' ' + res.getBody());
            }
        } catch (Exception e) {
            // Catch any unexpected exceptions during the HTTP request or Salesforce operations
            System.debug('An error occurred while processing the request: ' + e.getMessage());
            // Optionally, you can add more logging or send a notification for critical errors
        }
        
      
    }

}