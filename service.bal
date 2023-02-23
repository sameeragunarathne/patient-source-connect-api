import ballerina/http;

// Endpoint URL of the source system you want to connect to
// Refer https://ballerina.io/learn/by-example/#http-client 
// for more information on how to configure http:Client
final http:Client sourceEp = check new ("https://run.mocky.io/v3");

// You don't have to change the following service declaration
service / on new http:Listener(9091) {

    // This API operation will be called by the WSO2 Healthcare Accelerator to get a FHIR resource by `id` 
    // path parameter. 
    // You are required to implement this API operation to connect to the source system and return the
    // FHIR resource as a json payload.
    // If the source system is non-FHIR, you can use Choreo visual data mapper to convert the source
    // system payload to a FHIR resource. see patient_data_mapper.bal for an example.
    resource function get read/[string id]() returns json|error {

        // This is only a sample implementation. You are required to implement this based on your source system/s.
        http:Response res = check sourceEp->get("/8a58266a-d8b3-4f0d-b506-3397df2516f8/" + id);

        json payload = check res.getJsonPayload();
        jsonPatient jp = check payload.cloneWithType(jsonPatient);
        Patient patient = convertPatient(jp);
        return patient;
    }

    // This API operation will be called by the WSO2 Healthcare Accelerator to search FHIR resources based 
    // on the query parameters.
    // You are required to implement this API operation to connect to the source system and return the
    // FHIR resource as a json payload.
    // If the source system is non-FHIR, you can use Choreo visual data mapper to convert the source
    // system payload to a FHIR resource. see patient_data_mapper.bal for an example.
    resource function get search(http:Request req) returns json|error {

        map<string|string[]> queryParams = req.getQueryParams();
        // convert queryParams to query string
        string queryString = "";
        foreach var [key, value] in queryParams.entries() {
            //check if value is an array
            if (value is string[]) {
                foreach var item in value {
                    queryString += key + "=" + item + "&";
                }
            } else {
                queryString += key + "=" + value + "&";
            }
        }
        // remove the last ampersand if querryString is not empty
        if (queryString != "") {
            queryString = "?" + queryString.substring(0, queryString.length() - 1);
        }

        // connect to the source system and get the response
        http:Response res = check sourceEp->get("/8f3b6d14-c535-496d-826c-4cdf9594b542" + queryString);
        json payload = check res.getJsonPayload();

        // transform the payload to a fhir json array or a fhir json object
        if payload is json[] {
            //create patient array from payload
            Patient[] patients = [];
            foreach var p in payload {
                jsonPatient jp = check p.cloneWithType(jsonPatient);
                Patient patient = convertPatient(jp);
                patients.push(patient);
            }
            return patients;
        } else {
            //create patient from payload
            jsonPatient jp = check payload.cloneWithType(jsonPatient);
            Patient patient = convertPatient(jp);
            return patient;
        }
    }
}
