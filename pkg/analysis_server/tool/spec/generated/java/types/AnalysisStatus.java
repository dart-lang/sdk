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
 * An indication of the current state of analysis.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class AnalysisStatus {

  public static final AnalysisStatus[] EMPTY_ARRAY = new AnalysisStatus[0];

  public static final List<AnalysisStatus> EMPTY_LIST = Lists.newArrayList();

  /**
   * True if analysis is currently being performed.
   */
  private final boolean isAnalyzing;

  /**
   * The name of the current target of analysis. This field is omitted if analyzing is false.
   */
  private final String analysisTarget;

  /**
   * Constructor for {@link AnalysisStatus}.
   */
  public AnalysisStatus(boolean isAnalyzing, String analysisTarget) {
    this.isAnalyzing = isAnalyzing;
    this.analysisTarget = analysisTarget;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof AnalysisStatus) {
      AnalysisStatus other = (AnalysisStatus) obj;
      return
        other.isAnalyzing == isAnalyzing &&
        ObjectUtilities.equals(other.analysisTarget, analysisTarget);
    }
    return false;
  }

  public static AnalysisStatus fromJson(JsonObject jsonObject) {
    boolean isAnalyzing = jsonObject.get("isAnalyzing").getAsBoolean();
    String analysisTarget = jsonObject.get("analysisTarget") == null ? null : jsonObject.get("analysisTarget").getAsString();
    return new AnalysisStatus(isAnalyzing, analysisTarget);
  }

  public static List<AnalysisStatus> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<AnalysisStatus> list = new ArrayList<AnalysisStatus>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * The name of the current target of analysis. This field is omitted if analyzing is false.
   */
  public String getAnalysisTarget() {
    return analysisTarget;
  }

  /**
   * True if analysis is currently being performed.
   */
  public boolean isAnalyzing() {
    return isAnalyzing;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(isAnalyzing);
    builder.append(analysisTarget);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("isAnalyzing", isAnalyzing);
    if (analysisTarget != null) {
      jsonObject.addProperty("analysisTarget", analysisTarget);
    }
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("isAnalyzing=");
    builder.append(isAnalyzing + ", ");
    builder.append("analysisTarget=");
    builder.append(analysisTarget);
    builder.append("]");
    return builder.toString();
  }

}
