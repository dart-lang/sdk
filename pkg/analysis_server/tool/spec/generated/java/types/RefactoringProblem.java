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
 * A description of a problem related to a refactoring.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class RefactoringProblem {

  public static final RefactoringProblem[] EMPTY_ARRAY = new RefactoringProblem[0];

  public static final List<RefactoringProblem> EMPTY_LIST = List.of();

  /**
   * The severity of the problem being represented.
   */
  private final String severity;

  /**
   * A human-readable description of the problem being represented.
   */
  private final String message;

  /**
   * The location of the problem being represented. This field is omitted unless there is a specific
   * location associated with the problem (such as a location where an element being renamed will be
   * shadowed).
   */
  private final Location location;

  /**
   * Constructor for {@link RefactoringProblem}.
   */
  public RefactoringProblem(String severity, String message, Location location) {
    this.severity = severity;
    this.message = message;
    this.location = location;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof RefactoringProblem) {
      RefactoringProblem other = (RefactoringProblem) obj;
      return
        Objects.equals(other.severity, severity) &&
        Objects.equals(other.message, message) &&
        Objects.equals(other.location, location);
    }
    return false;
  }

  public static RefactoringProblem fromJson(JsonObject jsonObject) {
    String severity = jsonObject.get("severity").getAsString();
    String message = jsonObject.get("message").getAsString();
    Location location = jsonObject.get("location") == null ? null : Location.fromJson(jsonObject.get("location").getAsJsonObject());
    return new RefactoringProblem(severity, message, location);
  }

  public static List<RefactoringProblem> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    List<RefactoringProblem> list = new ArrayList<>(jsonArray.size());
    for (final JsonElement element : jsonArray) {
      list.add(fromJson(element.getAsJsonObject()));
    }
    return list;
  }

  /**
   * The location of the problem being represented. This field is omitted unless there is a specific
   * location associated with the problem (such as a location where an element being renamed will be
   * shadowed).
   */
  public Location getLocation() {
    return location;
  }

  /**
   * A human-readable description of the problem being represented.
   */
  public String getMessage() {
    return message;
  }

  /**
   * The severity of the problem being represented.
   */
  public String getSeverity() {
    return severity;
  }

  @Override
  public int hashCode() {
    return Objects.hash(
      severity,
      message,
      location
    );
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("severity", severity);
    jsonObject.addProperty("message", message);
    if (location != null) {
      jsonObject.add("location", location.toJson());
    }
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("severity=");
    builder.append(severity + ", ");
    builder.append("message=");
    builder.append(message + ", ");
    builder.append("location=");
    builder.append(location);
    builder.append("]");
    return builder.toString();
  }

}
