package com.wisetack.samples;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import java.util.HashMap;
import java.util.Map;

public class LambdaRequestProxyHandler implements RequestHandler<ApiProxyRequest, ApiProxyResponse> {
    Gson gson = new GsonBuilder().setPrettyPrinting().create();

    @Override
    public ApiProxyResponse handleRequest(ApiProxyRequest event, Context context) {
        LambdaLogger logger = context.getLogger();
        logger.log("EVENT: " + gson.toJson(event));
        testException(event);
        ApiProxyResponse response = new ApiProxyResponse();
        Map<String, Object> responseBody = new HashMap<>();
        responseBody.put("event", event);
        responseBody.put("context", context);
        responseBody.put("env", System.getenv());
        response.setBody(gson.toJson(responseBody));
        response.getHeaders().put("X-Wisetack-Token", "Test-Wisetack-Token");
        response.setStatusCode(202);
        response.setBase64Encoded(false);
        return response;
    }

    private void testException(ApiProxyRequest event) {
        // Mapping status codes to static values on exception (with regular expression) doesn't work
        // in case of "aws-proxy" integration type (for both, AWS Cloud and LocalStack)
        new ApiExceptionThrower(event.getBody());
    }

}
