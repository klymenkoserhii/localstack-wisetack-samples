package com.wisetack.samples;

import java.util.HashMap;
import java.util.Map;

public class ApiResponse {
    private Map<String, Object> responseBody;
    private int statusCode;
    private String errorMessage;
    private String errorType;
    private Map<String, String> headers = new HashMap<>();

    public Map<String, Object> getResponseBody() {
        return responseBody;
    }

    public void setResponseBody(Map<String, Object> responseBody) {
        this.responseBody = responseBody;
    }

    public int getStatusCode() {
        return statusCode;
    }

    public void setStatusCode(int statusCode) {
        this.statusCode = statusCode;
    }

    public String getErrorMessage() {
        return errorMessage;
    }

    public void setErrorMessage(String errorMessage) {
        this.errorMessage = errorMessage;
    }

    public String getErrorType() {
        return errorType;
    }

    public void setErrorType(String errorType) {
        this.errorType = errorType;
    }

    public Map<String, String> getHeaders() {
        return headers;
    }

    public void setHeaders(Map<String, String> headers) {
        this.headers = headers;
    }
}
