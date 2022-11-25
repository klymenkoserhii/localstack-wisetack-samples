package com.wisetack.samples;

import java.util.HashMap;
import java.util.Map;

public class ParameterMapContainer {
    private Map<String, String> parameterMap = new HashMap<>();

    public Map<String, String> getParameterMap() {
        return parameterMap;
    }

    public void setParameterMap(Map<String, String> parameterMap) {
        this.parameterMap = parameterMap;
    }
}
