import ballerina/io;
import ballerina/http;
import ballerina/sql;
import ballerina/jwt;
import ballerina/constraint;
import ballerinax/postgresql;
import ballerinax/postgresql.driver as _;
import ballerina/regex;

type Person record {|
    @constraint:String{
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

function generateCustomResponse(int statusCode, string message) returns http:Response {
    http:Response response = new;
    response.statusCode = statusCode;
    response.setPayload({"Error": message});
    return response;
}


public service class RequestInterceptor {
    *http:RequestInterceptor;

    // default resource function, which will be executed for all the requests. 
    // `RequestContext` is used to share data between the interceptors.
    resource function 'default [string... path](
            http:RequestContext ctx,
            http:Request req)
        returns http:NextService|http:Response|error? {
        
        if req.hasHeader("Authorization"){
            string token = check req.getHeader("Authorization");
            string regexPattern = "[\\s]+"; // Regex pattern for one or more whitespace characters

            string[] partsStream = regex:split(token, regexPattern);

            // Process the stream and collect the split parts
            string[] parts = [];
            foreach string part in partsStream {
                parts.push(part);
            }
            token = parts.pop();
            [jwt:Header, jwt:Payload] [_, payload] = check jwt:decode(token);

            if payload.toJson().role != "general-user"{
                return generateCustomResponse(401,"Unauthorized Access Point for a General User.");
            }
        }
        else{
            // Handle missing token
            return generateCustomResponse(401,"Invalid Token.");
        }
        
        return ctx.next();
    }
}



service http:InterceptableService / on new http:Listener(8080) {

    private final postgresql:Client db;

    function init() returns error? {
        self.db = check new ("localhost", "postgres", "abcd123","test", 5432);

        io:println("Postgres Database is connected and running successfully...");
    }

    public function createInterceptors() returns RequestInterceptor {
        return new RequestInterceptor();
    }

    resource function get all_records() returns Person[]|error {

        // Define the SQL query to retrieve all records from the 'person' table
        sql:ParameterizedQuery query = `SELECT * FROM person`;

        // Execute the query using the established Postgres connection
        stream<Person, sql:Error?> personStream = self.db->query(query);

        
        return from Person person in personStream
            select person;
        
    }


    resource function get personal_record(string nic) returns Person|error? {
        sql:ParameterizedQuery query = `SELECT * FROM person WHERE nic_number = ${nic}`;
        Person person = check self.db->queryRow(query);
        return person;

    }

    resource function post add_personal_record(Person newUser) returns sql:ExecutionResult|sql:Error {
        sql:ParameterizedQuery query = `INSERT INTO person VALUES (${newUser.nic_number}, ${newUser.f_name}, ${newUser.mid_name}, ${newUser.l_name}, ${newUser.address}, ${newUser.gender})`;
        sql:ExecutionResult|sql:Error result = self.db->execute(query);

        return result;
    }

}
