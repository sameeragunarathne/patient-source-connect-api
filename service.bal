import ballerina/http;

final http:Client sourceEp = check new ("https://run.mocky.io/v3");

service /patient on new http:Listener(9091) {

    resource function get read/[string id]() returns json|error {

        http:Response|http:ClientError res = sourceEp->get("/8a58266a-d8b3-4f0d-b506-3397df2516f8/" + id);
        if (res is http:Response) {
            json patient = check res.getJsonPayload();
            jsonPatient jp = check patient.cloneWithType(jsonPatient);
            Patient p = convertPatient(jp);
            return p;
        } else {
            return res;
        }
    }

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
        http:Response|http:ClientError res = sourceEp->get("/8f3b6d14-c535-496d-826c-4cdf9594b542" + queryString);
        if (res is http:Response) {
            json payload = check res.getJsonPayload();
            //cast payload to json[]
            json[] payloadArray = <json[]>payload;
            //create patient array from payload
            Patient[] patients = [];
            foreach var p in payloadArray {
                jsonPatient jp = check p.cloneWithType(jsonPatient);
                Patient patient = convertPatient(jp);
                patients.push(patient);
            }
            return patients;
        } else {
            return res;
        }
    }
}
