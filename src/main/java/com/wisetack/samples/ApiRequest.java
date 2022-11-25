package com.wisetack.samples;

import java.util.Map;

public class ApiRequest {
    private Map<String, String> apiContext;
    private ParameterMapContainer header;
    private ParameterMapContainer path;
    private ParameterMapContainer querystring;
    private Map<String, Object> body;

    public Map<String, String> getApiContext() {
        return apiContext;
    }

    public void setApiContext(Map<String, String> apiContext) {
        this.apiContext = apiContext;
    }

    public ParameterMapContainer getHeader() {
        return header;
    }

    public void setHeader(ParameterMapContainer header) {
        this.header = header;
    }

    public ParameterMapContainer getPath() {
        return path;
    }

    public void setPath(ParameterMapContainer path) {
        this.path = path;
    }

    public ParameterMapContainer getQuerystring() {
        return querystring;
    }

    public void setQuerystring(ParameterMapContainer querystring) {
        this.querystring = querystring;
    }

    public Map<String, Object> getBody() {
        return body;
    }

    public void setBody(Map<String, Object> body) {
        this.body = body;
    }
}
