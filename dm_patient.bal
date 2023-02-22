import wso2healthcare/healthcare.fhir.r4;

type Patient r4:Patient;

type jsonPatient record {
    string id;
    record {
        string versionId;
        string[] profile;
    } meta;
    anydata[] identifier;
    string implicitRules;
    string language;
    string gender;
    string dob;
    string name;
};

function convertPatient(jsonPatient jsonPatient) returns Patient => {
    id: jsonPatient.id,
    meta: {
        versionId: jsonPatient.meta.versionId,
        profile: jsonPatient.meta.profile
    },
    implicitRules: jsonPatient.implicitRules,
    birthDate: jsonPatient.dob,
    name: [
        {
            text: jsonPatient.name
        }
    ]
};
