package com.wisetack.samples;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import java.util.HashMap;
import java.util.Map;

public class LambdaRequestHandler implements RequestHandler<Map<String, Object>, ApiResponse> {
    Gson gson = new GsonBuilder().setPrettyPrinting().create();

    public ApiResponse handleRequest(Map<String, Object> event, Context context) {
        LambdaLogger logger = context.getLogger();
        logger.log("EVENT: " + gson.toJson(event));
        testException(event); // to test exception provide request body like {httpStatus: 400}
        ApiResponse response = new ApiResponse();
        Map<String, Object> responseBody = new HashMap<>();
        responseBody.put("event", event);
        responseBody.put("context", context);
        responseBody.put("env", System.getenv());
        response.setResponseBody(responseBody);
        response.setStatusCode(202);
        return response;
    }

    private Map<String, Object> getApiEventBody(Map<String, Object> event) {
        Object body = event.get("body");
        if (body == null) {
            return null;
        }
        if (body instanceof Map) {
            return (Map<String, Object>) body;
        }
        return null;
    }

    private void testException(Map<String, Object> event) {
        Map<String, Object> apiEventBody = getApiEventBody(event);
        String errorMessage = "Test exception";
        if (apiEventBody != null && apiEventBody.get("httpStatus") != null) {
            int httpStatus = (int) apiEventBody.get("httpStatus");
            if (httpStatus >= 400) {
                if (apiEventBody.get("errorMessage") != null) {
                    errorMessage = (String) apiEventBody.get("errorMessage");
                }
                throwApiException(httpStatus, errorMessage);
            }
        }
    }

    private void throwApiException(int httpStatus, String errorMessage) {
        throw new RuntimeException(String.format("{\"httpStatus\": %d, \"errorMessage\": \"%s\"}",
                httpStatus, errorMessage));
    }

}
