/*
 * Copyright (c) 2014, the Dart project authors.
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
package com.google.dart.server.generated.types;

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
 * An indication of an error, warning, or hint that was produced by the analysis.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class AnalysisError {

  public static final AnalysisError[] EMPTY_ARRAY = new AnalysisError[0];

  public static final List<AnalysisError> EMPTY_LIST = Lists.newArrayList();

  /**
   * The severity of the error.
   */
  private final String severity;

  /**
   * The type of the error.
   */
  private final String type;

  /**
   * The location associated with the error.
   */
  private final Location location;

  /**
   * The message to be displayed for this error. The message should indicate what is wrong with the
   * code and why it is wrong.
   */
  private final String message;

  /**
   * The correction message to be displayed for this error. The correction message should indicate
   * how the user can fix the error. The field is omitted if there is no correction message
   * associated with the error code.
   */
  private final String correction;

  /**
   * Constructor for {@link AnalysisError}.
   */
  public AnalysisError(String severity, String type, Location location, String message, String correction) {
    this.severity = severity;
    this.type = type;
    this.location = location;
    this.message = message;
    this.correction = correction;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof AnalysisError) {
      AnalysisError other = (AnalysisError) obj;
      return
        ObjectUtilities.equals(other.severity, severity) &&
        ObjectUtilities.equals(other.type, type) &&
        ObjectUtilities.equals(other.location, location) &&
        ObjectUtilities.equals(other.message, message) &&
        ObjectUtilities.equals(other.correction, correction);
    }
    return false;
  }

  public static AnalysisError fromJson(JsonObject jsonObject) {
    String severity = jsonObject.get("severity").getAsString();
    String type = jsonObject.get("type").getAsString();
    Location location = Location.fromJson(jsonObject.get("location").getAsJsonObject());
    String message = jsonObject.get("message").getAsString();
    String correction = jsonObject.get("correction") == null ? null : jsonObject.get("correction").getAsString();
    return new AnalysisError(severity, type, location, message, correction);
  }

  public static List<AnalysisError> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<AnalysisError> list = new ArrayList<AnalysisError>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * The correction message to be displayed for this error. The correction message should indicate
   * how the user can fix the error. The field is omitted if there is no correction message
   * associated with the error code.
   */
  public String getCorrection() {
    return correction;
  }

  /**
   * The location associated with the error.
   */
  public Location getLocation() {
    return location;
  }

  /**
   * The message to be displayed for this error. The message should indicate what is wrong with the
   * code and why it is wrong.
   */
  public String getMessage() {
    return message;
  }

  /**
   * The severity of the error.
   */
  public String getSeverity() {
    return severity;
  }

  /**
   * The type of the error.
   */
  public String getType() {
    return type;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(severity);
    builder.append(type);
    builder.append(location);
    builder.append(message);
    builder.append(correction);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("severity", severity);
    jsonObject.addProperty("type", type);
    jsonObject.add("location", location.toJson());
    jsonObject.addProperty("message", message);
    if (correction != null) {
      jsonObject.addProperty("correction", correction);
    }
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("severity=");
    builder.append(severity + ", ");
    builder.append("type=");
    builder.append(type + ", ");
    builder.append("location=");
    builder.append(location + ", ");
    builder.append("message=");
    builder.append(message + ", ");
    builder.append("correction=");
    builder.append(correction);
    builder.append("]");
    return builder.toString();
  }

}
