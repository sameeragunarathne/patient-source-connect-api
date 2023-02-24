import ballerina/http;
import wso2healthcare/healthcare.hl7;
import wso2healthcare/healthcare.hl7v23;
import wso2healthcare/healthcare.fhir.r4;
import ballerina/log;

//HL7 parser and encoder which are used to parse and encode HL7 messages.
final hl7:HL7Parser hl7Parser = new ();
final hl7:HL7Encoder hl7Encoder = new ();

configurable string hl7ServerIP = "localhost";
configurable int hl7ServerPort = 9988;

// You don't have to change the following service declaration
service / on new http:Listener(9091) {

    # This API operation will be called by the WSO2 Healthcare Accelerator to get a FHIR resource by `id` 
    # path parameter. 
    # You are required to implement this API operation to connect to the source system and return the
    # FHIR resource as a json payload.
    # If the source system is non-FHIR, you can use Choreo visual data mapper to convert the source
    # system payload to a FHIR resource. see v2tofhir_transformations.bal for an example.
    #
    # + id - Patient id
    # + return - Return FHIR patient resource as a json or an error.
    resource function get read/[string id]() returns json|error {

        hl7:Message|hl7v23:GenericMessage?|hl7:HL7Error responseMsg = triggerHL7QueryMessageAndResponse(id);
        if responseMsg is hl7v23:ADR_A19 {
            // This utility function is used to convert ADR_A19 message into FHIR Patient resources. This has pre-build mapping done from the
            // Implementation guide: https://build.fhir.org/ig/HL7/v2-to-fhir/branches/master/index.html.
            // In upcoming releases these utility functions will be provided as inbuilt mapping functions by WSO2 Healthcare Accelerator packages.
            r4:Patient[] patients = ADR_A19ToPatient(responseMsg);
            if patients.length() > 0 {
                return patients[0].toJson();
            }
        } else if responseMsg is hl7:HL7Error {
            log:printError(responseMsg.message());
            return responseMsg;
        }
        return {};
    }

    # This API operation will be called by the WSO2 Healthcare Accelerator to search FHIR resources based 
    # on the query parameters.
    # You are required to implement this API operation to connect to the source system and return the
    # FHIR resource as a json payload.
    # If the source system is non-FHIR, you can use Choreo visual data mapper to convert the source
    # system payload to a FHIR resource. see patient_data_mapper.bal for an example.
    #
    # + req - The HTTP request
    # + return - Returns FHIR resource Bundle as a json or FHIR resource array as json array or an error.
    resource function get search(http:Request req) returns json|error {

        map<string|string[]> queryParams = req.getQueryParams();
        // Only _id query parameter is supported in this demo for patient search,and the id is used to query the patient 
        // demographics from the HL7 server.
        if queryParams.hasKey("_id") {
            string|string[] idVal = queryParams.get("_id");
            if idVal is string[] {
                hl7:Message|hl7v23:GenericMessage?|hl7:HL7Error responseMsg = triggerHL7QueryMessageAndResponse(idVal[0]);
                if responseMsg is hl7v23:ADR_A19 {
                    // This utility function is used to convert ADR_A19 message into FHIR Patient resources. This has pre-build mapping done from the
                    // Implementation guide: https://build.fhir.org/ig/HL7/v2-to-fhir/branches/master/index.html.
                    // In upcoming releases these utility functions will be provided as inbuilt mapping functions by WSO2 Healthcare Accelerator packages.
                    r4:Patient[] patients = ADR_A19ToPatient(responseMsg);
                    return patients;
                } else if responseMsg is hl7:HL7Error {
                    log:printError(responseMsg.message());
                    return responseMsg;
                }
            }
        }

        return {};
    }

}

# This function is used to construct a patient query message and send it to the HL7 server and receive the response message
# from the HL7 server. The success response message is parsed to a patient query response message and returned otherwise
# an error is returned.
#
# + id - Patient ID
# + return - Returns a patient query response message(ADR^A19) or generic message or an error.
function triggerHL7QueryMessageAndResponse(string id) returns hl7:Message|hl7v23:GenericMessage?|hl7:HL7Error {
    //building patient query message
    hl7v23:QRY_A19 qry_a19 = {
        msh: {
            msh3: {hd1: "ADT1"},
            msh4: {hd1: "MCM"},
            msh5: {hd1: "LABADT"},
            msh6: {hd1: "MCM"},
            msh8: "SECURITY",
            msh9: {cm_msg1: "QRY", cm_msg2: "A19"},
            msh10: "MSG00001",
            msh11: {pt1: "P"},
            msh12: "2.3"
        },
        qrd: {
            qrd1: {ts1: "20220828104856+0000"},
            qrd2: "R",
            qrd3: "I",
            qrd4: "QueryID01",
            qrd8: [{xcn1: id}]
        }
    };

    //encoding query message to HL7 wire format.
    byte[] encodedQRYA19 = check hl7Encoder.encode(hl7v23:VERSION, qry_a19);

    do {
        //sending query message to HL7 server
        hl7:HL7Client hl7Client = check new (hl7ServerIP, hl7ServerPort);
        byte[]|hl7:HL7Error response = hl7Client.sendMessage(encodedQRYA19);

        if response is byte[] {
            //parsing response message from the HL7 server 
            hl7:Message|hl7v23:GenericMessage?|hl7:HL7Error responseMsg = hl7Parser.parse(response);
            return responseMsg;
        } else {
            log:printError(response.message());
            return response;
        }
    } on fail var e {
        log:printError(e.message());
        hl7:HL7Error sendMsgError = error(hl7:HL7_V2_CLIENT_ERROR, message = "Error while sending message to the HL7 server.");
        return sendMsgError;
    }
}
