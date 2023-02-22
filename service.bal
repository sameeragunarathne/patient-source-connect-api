import ballerina/http;
service / on new http:Listener(9090) {
    resource function get read/[string id]() returns json|error {

     return {};
    }

    resource function get search(http:Request req) returns json|error {

        return {};
    }
}
