/*
 * Copyright (c) 2015, the Dart project authors.
 *
 * Licensed under the Eclipse Public License v1.0 (the "License"); you may not use this file except
 * in compliance with the License. You may obtain a copy of the License at
 *
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License
 * is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
 * or implied. See the License for the specific language governing permissions and limitations under
 * the License.
 *
 * This file has been automatically generated.  Please do not edit it manually.
 * To regenerate the file, use the script "pkg/analysis_server/tool/spec/generate_files".
 */
package org.dartlang.analysis.server.protocol;

import java.util.Arrays;
import java.util.List;
import java.util.Map;
import com.google.common.collect.Lists;
import com.google.dart.server.utilities.general.JsonUtilities;
import com.google.dart.server.utilities.general.ObjectUtilities;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonPrimitive;
import org.apache.commons.lang3.builder.HashCodeBuilder;
import java.util.ArrayList;
import java.util.Iterator;
import org.apache.commons.lang3.StringUtils;

/**
 * An indication of a problem with the execution of the server, typically in response to a request.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class RequestError {

  public static final RequestError[] EMPTY_ARRAY = new RequestError[0];

  public static final List<RequestError> EMPTY_LIST = Lists.newArrayList();

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
        ObjectUtilities.equals(other.code, code) &&
        ObjectUtilities.equals(other.message, message) &&
        ObjectUtilities.equals(other.stackTrace, stackTrace);
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
    ArrayList<RequestError> list = new ArrayList<RequestError>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
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
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(code);
    builder.append(message);
    builder.append(stackTrace);
    return builder.toHashCode();
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
