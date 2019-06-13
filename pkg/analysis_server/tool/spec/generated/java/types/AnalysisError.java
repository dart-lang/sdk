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
   * The name, as a string, of the error code associated with this error.
   */
  private final String code;

  /**
   * The URL of a page containing documentation associated with this error.
   */
  private final String url;

  /**
   * Additional messages associated with this diagnostic that provide context to help the user
   * understand the diagnostic.
   */
  private final List<DiagnosticMessage> contextMessages;

  /**
   * A hint to indicate to interested clients that this error has an associated fix (or fixes). The
   * absence of this field implies there are not known to be fixes. Note that since the operation to
   * calculate whether fixes apply needs to be performant it is possible that complicated tests will
   * be skipped and a false negative returned. For this reason, this attribute should be treated as a
   * "hint". Despite the possibility of false negatives, no false positives should be returned. If a
   * client sees this flag set they can proceed with the confidence that there are in fact associated
   * fixes.
   */
  private final Boolean hasFix;

  /**
   * Constructor for {@link AnalysisError}.
   */
  public AnalysisError(String severity, String type, Location location, String message, String correction, String code, String url, List<DiagnosticMessage> contextMessages, Boolean hasFix) {
    this.severity = severity;
    this.type = type;
    this.location = location;
    this.message = message;
    this.correction = correction;
    this.code = code;
    this.url = url;
    this.contextMessages = contextMessages;
    this.hasFix = hasFix;
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
        ObjectUtilities.equals(other.correction, correction) &&
        ObjectUtilities.equals(other.code, code) &&
        ObjectUtilities.equals(other.url, url) &&
        ObjectUtilities.equals(other.contextMessages, contextMessages) &&
        ObjectUtilities.equals(other.hasFix, hasFix);
    }
    return false;
  }

  public static AnalysisError fromJson(JsonObject jsonObject) {
    String severity = jsonObject.get("severity").getAsString();
    String type = jsonObject.get("type").getAsString();
    Location location = Location.fromJson(jsonObject.get("location").getAsJsonObject());
    String message = jsonObject.get("message").getAsString();
    String correction = jsonObject.get("correction") == null ? null : jsonObject.get("correction").getAsString();
    String code = jsonObject.get("code").getAsString();
    String url = jsonObject.get("url") == null ? null : jsonObject.get("url").getAsString();
    List<DiagnosticMessage> contextMessages = jsonObject.get("contextMessages") == null ? null : DiagnosticMessage.fromJsonArray(jsonObject.get("contextMessages").getAsJsonArray());
    Boolean hasFix = jsonObject.get("hasFix") == null ? null : jsonObject.get("hasFix").getAsBoolean();
    return new AnalysisError(severity, type, location, message, correction, code, url, contextMessages, hasFix);
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
   * The name, as a string, of the error code associated with this error.
   */
  public String getCode() {
    return code;
  }

  /**
   * Additional messages associated with this diagnostic that provide context to help the user
   * understand the diagnostic.
   */
  public List<DiagnosticMessage> getContextMessages() {
    return contextMessages;
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
   * A hint to indicate to interested clients that this error has an associated fix (or fixes). The
   * absence of this field implies there are not known to be fixes. Note that since the operation to
   * calculate whether fixes apply needs to be performant it is possible that complicated tests will
   * be skipped and a false negative returned. For this reason, this attribute should be treated as a
   * "hint". Despite the possibility of false negatives, no false positives should be returned. If a
   * client sees this flag set they can proceed with the confidence that there are in fact associated
   * fixes.
   */
  public Boolean getHasFix() {
    return hasFix;
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

  /**
   * The URL of a page containing documentation associated with this error.
   */
  public String getUrl() {
    return url;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(severity);
    builder.append(type);
    builder.append(location);
    builder.append(message);
    builder.append(correction);
    builder.append(code);
    builder.append(url);
    builder.append(contextMessages);
    builder.append(hasFix);
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
    jsonObject.addProperty("code", code);
    if (url != null) {
      jsonObject.addProperty("url", url);
    }
    if (contextMessages != null) {
      JsonArray jsonArrayContextMessages = new JsonArray();
      for (DiagnosticMessage elt : contextMessages) {
        jsonArrayContextMessages.add(elt.toJson());
      }
      jsonObject.add("contextMessages", jsonArrayContextMessages);
    }
    if (hasFix != null) {
      jsonObject.addProperty("hasFix", hasFix);
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
    builder.append(correction + ", ");
    builder.append("code=");
    builder.append(code + ", ");
    builder.append("url=");
    builder.append(url + ", ");
    builder.append("contextMessages=");
    builder.append(StringUtils.join(contextMessages, ", ") + ", ");
    builder.append("hasFix=");
    builder.append(hasFix);
    builder.append("]");
    return builder.toString();
  }

}
