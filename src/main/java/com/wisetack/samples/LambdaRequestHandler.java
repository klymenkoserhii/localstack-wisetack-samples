package com.wisetack.samples;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import java.util.Map;

public class LambdaRequestHandler implements RequestHandler<Map<String, Object>, Map<String, Object>> {
    Gson gson = new GsonBuilder().setPrettyPrinting().create();

    public Map<String, Object> handleRequest(Map<String, Object> event, Context context) {
        LambdaLogger logger = context.getLogger();
        // logger.log("ENVIRONMENT VARIABLES: " + gson.toJson(System.getenv()));
        logger.log("EVENT: " + gson.toJson(event));
        // logger.log("CONTEXT: " + gson.toJson(context));
        return event;
    }
}
