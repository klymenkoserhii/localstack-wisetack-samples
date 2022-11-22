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
        ApiResponse response = new ApiResponse();
        Map<String, Object> responseBody = new HashMap<>();
        responseBody.put("event", event);
        responseBody.put("context", context);
        responseBody.put("env", System.getenv());
        response.setResponseBody(responseBody);
        response.setStatusCode(202);
        return response;
    }
}
