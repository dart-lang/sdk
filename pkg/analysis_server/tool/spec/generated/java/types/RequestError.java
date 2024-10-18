/*
 * Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
 *
 * This file has been automatically generated. Please do not edit it manually.
 * To regenerate the file, use the script "pkg/analysis_server/tool/spec/generate_files".
 */
package org.dartlang.analysis.server.protocol;

import java.util.Arrays;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import com.google.common.collect.Lists;
import com.google.dart.server.utilities.general.JsonUtilities;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonPrimitive;
import org.apache.commons.lang3.StringUtils;

/**
 * An indication of a problem with the execution of the server, typically in response to a request.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class RequestError {

  public static final RequestError[] EMPTY_ARRAY = new RequestError[0];

  public static final List<RequestError> EMPTY_LIST = List.of();

  /**
   * A code that uniquely identifies the error that occurred.
   */
  private final String code;

  /**
   * A short description of the error.
   */
  private final String message;

  /**
   * The stack trace associated with processing the request, used for debugging the server.
   */
  private final String stackTrace;

  /**
   * Constructor for {@link RequestError}.
   */
  public RequestError(String code, String message, String stackTrace) {
    this.code = code;
    this.message = message;
    this.stackTrace = stackTrace;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof RequestError) {
      RequestError other = (RequestError) obj;
      return
        Objects.equals(other.code, code) &&
        Objects.equals(other.message, message) &&
        Objects.equals(other.stackTrace, stackTrace);
    }
    return false;
  }

  public static RequestError fromJson(JsonObject jsonObject) {
    String code = jsonObject.get("code").getAsString();
    String message = jsonObject.get("message").getAsString();
    String stackTrace = jsonObject.get("stackTrace") == null ? null : jsonObject.get("stackTrace").getAsString();
    return new RequestError(code, message, stackTrace);
  }

  public static List<RequestError> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    List<RequestError> list = new ArrayList<>(jsonArray.size());
    for (final JsonElement element : jsonArray) {
      list.add(fromJson(element.getAsJsonObject()));
    }
    return list;
  }

  /**
   * A code that uniquely identifies the error that occurred.
   */
  public String getCode() {
    return code;
  }

  /**
   * A short description of the error.
   */
  public String getMessage() {
    return message;
  }

  /**
   * The stack trace associated with processing the request, used for debugging the server.
   */
  public String getStackTrace() {
    return stackTrace;
  }

  @Override
  public int hashCode() {
    return Objects.hash(
      code,
      message,
      stackTrace
    );
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("code", code);
    jsonObject.addProperty("message", message);
    if (stackTrace != null) {
      jsonObject.addProperty("stackTrace", stackTrace);
    }
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("code=");
    builder.append(code + ", ");
    builder.append("message=");
    builder.append(message + ", ");
    builder.append("stackTrace=");
    builder.append(stackTrace);
    builder.append("]");
    return builder.toString();
  }

}
