import ballerina/http;

public service class RequestInterceptor {
    *http:RequestInterceptor;

    // A default resource function, which will be executed for all the requests. 
    // A `RequestContext` is used to share data between the interceptors.
    // An accessor and a path can also be specified. In that case, the interceptor will be
    // executed only for the requests, which match the accessor and path.
    resource function 'default [string... path](
            http:RequestContext ctx,
            @http:Header {name: "x-api-version"} string xApiVersion)
        returns http:NotImplemented|http:NextService|error? {
        // Checks the API version header.
        if xApiVersion != "v1" {
            // Returns a `501 NotImplemented` response if the version is not supported.
            return http:NOT_IMPLEMENTED;
        }
        // Returns the next interceptor or the target service in the pipeline. 
        // An error is returned when the call fails.
        return ctx.next();
    }
}
