import wso2healthcare/healthcare.fhir.r4;
import wso2healthcare/healthcare.hl7v23;

public function HL7v2ToFHIRr4Helper_GetHumanNameUse(hl7v23:ID id) returns r4:HumanNameUse => id is r4:HumanNameUse ? id: "usual";

public function HL7v2ToFHIRr4Helper_GetAddressType(hl7v23:ID id) returns r4:AddressType => id is r4:AddressType ? id: "postal";

public function HL7v2ToFHIRr4Helper_GetAddressUse(hl7v23:ID id) returns r4:AddressUse => id is r4:AddressUse ? id: "home";

public function HL7v2ToFHIRr4Helper_GetContactPointUse(hl7v23:ID id) returns r4:ContactPointUse => id is r4:ContactPointUse ? id: "home";

public function HL7v2ToFHIRr4Helper_GetContactPointSystem(hl7v23:ID id) returns r4:ContactPointSystem => id is r4:ContactPointSystem ? id: "phone";

// Enums
public enum ComparisonOperator {
    EQ,     // Matches values that are equal to a specified value.
    GT,     // Matches values that are greater than a specified value.
    GTE,    // Matches values that are greater than or equal to a specified value.
    IN,     // Matches any of the values specified in an array.
    LT,     // Matches values that are less than a specified value.
    LTE,    // Matches values that are less than or equal to a specified value.
    NE,     // Matches all values that are not equal to a specified value.
    NIN     // Matches none of the values specified in an array.
}

public enum LogicalOperator {
    AND,
    NOT,
    NOR,
    OR
}

# Standard ANTLR Record Definition
#
# + identifier - HL7 v2 Identifier(ID)
# + comparisonOperator - [EQ, GT, GTE, IN, LT, LTE, NE, NIN] - Comparison logic
# + valueList - Values to be applied with the logic to compare identifier
public type ANTLR record {|
    string identifier;
    ComparisonOperator comparisonOperator;
    string[] valueList;
|};


# Computable ANTLR checker
# 
# Parameter list: (identifier, comparisonOperator, value list)
# + antlrList - ANTLR expressions list
# + return - Return Value Description# 
public function CheckComputableANTLR(ANTLR[] antlrList) returns boolean {
    boolean finalResult = true;

    foreach ANTLR antlr in antlrList {
        match antlr.comparisonOperator {
            EQ => {
                finalResult = finalResult && ComparisononOp_IN(antlr.identifier, antlr.valueList);
            }    
            IN => {
                finalResult = finalResult &&  ComparisononOp_IN(antlr.identifier, antlr.valueList);
            }
            NE => {
                finalResult = finalResult &&  !ComparisononOp_IN(antlr.identifier, antlr.valueList);
            }
            NIN => {
                finalResult = finalResult &&  !ComparisononOp_IN(antlr.identifier, antlr.valueList);
            }
        }
    }

    return finalResult;
}

// Comparison Operaions
public function ComparisononOp_IN(string x, string[] valueList) returns boolean {
    foreach string item in valueList {
        if(item == x){
            return true;
        }
    }

    return false;
}
