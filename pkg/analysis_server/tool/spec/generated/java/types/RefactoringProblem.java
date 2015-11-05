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
 * A description of a problem related to a refactoring.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class RefactoringProblem {

  public static final RefactoringProblem[] EMPTY_ARRAY = new RefactoringProblem[0];

  public static final List<RefactoringProblem> EMPTY_LIST = Lists.newArrayList();

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
        ObjectUtilities.equals(other.severity, severity) &&
        ObjectUtilities.equals(other.message, message) &&
        ObjectUtilities.equals(other.location, location);
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
    ArrayList<RefactoringProblem> list = new ArrayList<RefactoringProblem>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
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
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(severity);
    builder.append(message);
    builder.append(location);
    return builder.toHashCode();
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
