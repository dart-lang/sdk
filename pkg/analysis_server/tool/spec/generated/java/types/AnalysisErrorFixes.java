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
 * A list of fixes associated with a specific error
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class AnalysisErrorFixes {

  public static final AnalysisErrorFixes[] EMPTY_ARRAY = new AnalysisErrorFixes[0];

  public static final List<AnalysisErrorFixes> EMPTY_LIST = Lists.newArrayList();

  /**
   * The error with which the fixes are associated.
   */
  private final AnalysisError error;

  /**
   * The fixes associated with the error.
   */
  private final List<SourceChange> fixes;

  /**
   * Constructor for {@link AnalysisErrorFixes}.
   */
  public AnalysisErrorFixes(AnalysisError error, List<SourceChange> fixes) {
    this.error = error;
    this.fixes = fixes;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof AnalysisErrorFixes) {
      AnalysisErrorFixes other = (AnalysisErrorFixes) obj;
      return
        ObjectUtilities.equals(other.error, error) &&
        ObjectUtilities.equals(other.fixes, fixes);
    }
    return false;
  }

  public static AnalysisErrorFixes fromJson(JsonObject jsonObject) {
    AnalysisError error = AnalysisError.fromJson(jsonObject.get("error").getAsJsonObject());
    List<SourceChange> fixes = SourceChange.fromJsonArray(jsonObject.get("fixes").getAsJsonArray());
    return new AnalysisErrorFixes(error, fixes);
  }

  public static List<AnalysisErrorFixes> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<AnalysisErrorFixes> list = new ArrayList<AnalysisErrorFixes>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * The error with which the fixes are associated.
   */
  public AnalysisError getError() {
    return error;
  }

  /**
   * The fixes associated with the error.
   */
  public List<SourceChange> getFixes() {
    return fixes;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(error);
    builder.append(fixes);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.add("error", error.toJson());
    JsonArray jsonArrayFixes = new JsonArray();
    for (SourceChange elt : fixes) {
      jsonArrayFixes.add(elt.toJson());
    }
    jsonObject.add("fixes", jsonArrayFixes);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("error=");
    builder.append(error + ", ");
    builder.append("fixes=");
    builder.append(StringUtils.join(fixes, ", "));
    builder.append("]");
    return builder.toString();
  }

}
