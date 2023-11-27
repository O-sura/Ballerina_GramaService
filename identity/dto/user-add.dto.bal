import ballerina/constraint;

public type Person record {|
    @constraint:String {
        maxLength: 12,
        minLength: 10
    }
    string nic_number;
    string f_name;
    string mid_name;
    string l_name;
    string address;
    string gender;
|};