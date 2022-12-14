package com.wisetack.samples;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import java.util.HashMap;
import java.util.Map;

public class LambdaRequestHandler implements RequestHandler<ApiRequest, ApiResponse> {
    Gson gson = new GsonBuilder().setPrettyPrinting().create();

    public ApiResponse handleRequest(ApiRequest event, Context context) {
        LambdaLogger logger = context.getLogger();
        logger.log("EVENT: " + gson.toJson(event));
        testException(event); // to test exception provide request body like {httpStatus: 400}
        ApiResponse response = new ApiResponse();
        Map<String, Object> responseBody = new HashMap<>();
        responseBody.put("event", event);
        responseBody.put("context", context);
        responseBody.put("env", System.getenv());
        response.setResponseBody(responseBody);
        response.getHeaders().put("X-Wisetack-Token", "Test-Wisetack-Token");
        response.setStatusCode(202);
        return response;
    }

    private void testException(ApiRequest event) {
        new ApiExceptionThrower(event.getBody());
    }

}
