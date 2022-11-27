package com.wisetack.samples;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;

import java.util.Map;

public class ApiExceptionThrower {
    public ApiExceptionThrower(Map<String, Object> apiEventBody) {
        String errorMessage = "Test exception";
        if (apiEventBody != null && apiEventBody.get("httpStatus") != null) {
            int httpStatus = Integer.parseInt(apiEventBody.get("httpStatus").toString());
            if (httpStatus >= 400) {
                if (apiEventBody.get("errorMessage") != null) {
                    errorMessage = (String) apiEventBody.get("errorMessage");
                }
                throwApiException(httpStatus, errorMessage);
            }
        }
    }

    public ApiExceptionThrower(String body) {
        Map<String, Object> apiEventBody = new Gson().fromJson(body, new TypeToken<Map<String, Object>>() {}.getType());
        new ApiExceptionThrower(apiEventBody);
    }

    public ApiExceptionThrower() {
        throwApiException(400, "Bad Request Test");
    }

    private void throwApiException(int httpStatus, String errorMessage) {
        throw new RuntimeException(String.format("{\"httpStatus\":%d, \"errorMessage\":\"%s\"}",
                httpStatus, errorMessage));
    }
}
