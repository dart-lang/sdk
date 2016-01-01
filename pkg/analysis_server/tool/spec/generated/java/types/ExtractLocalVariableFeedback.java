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
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class ExtractLocalVariableFeedback extends RefactoringFeedback {

  public static final ExtractLocalVariableFeedback[] EMPTY_ARRAY = new ExtractLocalVariableFeedback[0];

  public static final List<ExtractLocalVariableFeedback> EMPTY_LIST = Lists.newArrayList();

  /**
   * The offsets of the expressions that cover the specified selection, from the down most to the up
   * most.
   */
  private final int[] coveringExpressionOffsets;

  /**
   * The lengths of the expressions that cover the specified selection, from the down most to the up
   * most.
   */
  private final int[] coveringExpressionLengths;

  /**
   * The proposed names for the local variable.
   */
  private final List<String> names;

  /**
   * The offsets of the expressions that would be replaced by a reference to the variable.
   */
  private final int[] offsets;

  /**
   * The lengths of the expressions that would be replaced by a reference to the variable. The
   * lengths correspond to the offsets. In other words, for a given expression, if the offset of that
   * expression is offsets[i], then the length of that expression is lengths[i].
   */
  private final int[] lengths;

  /**
   * Constructor for {@link ExtractLocalVariableFeedback}.
   */
  public ExtractLocalVariableFeedback(int[] coveringExpressionOffsets, int[] coveringExpressionLengths, List<String> names, int[] offsets, int[] lengths) {
    this.coveringExpressionOffsets = coveringExpressionOffsets;
    this.coveringExpressionLengths = coveringExpressionLengths;
    this.names = names;
    this.offsets = offsets;
    this.lengths = lengths;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof ExtractLocalVariableFeedback) {
      ExtractLocalVariableFeedback other = (ExtractLocalVariableFeedback) obj;
      return
        Arrays.equals(other.coveringExpressionOffsets, coveringExpressionOffsets) &&
        Arrays.equals(other.coveringExpressionLengths, coveringExpressionLengths) &&
        ObjectUtilities.equals(other.names, names) &&
        Arrays.equals(other.offsets, offsets) &&
        Arrays.equals(other.lengths, lengths);
    }
    return false;
  }

  public static ExtractLocalVariableFeedback fromJson(JsonObject jsonObject) {
    int[] coveringExpressionOffsets = jsonObject.get("coveringExpressionOffsets") == null ? null : JsonUtilities.decodeIntArray(jsonObject.get("coveringExpressionOffsets").getAsJsonArray());
    int[] coveringExpressionLengths = jsonObject.get("coveringExpressionLengths") == null ? null : JsonUtilities.decodeIntArray(jsonObject.get("coveringExpressionLengths").getAsJsonArray());
    List<String> names = JsonUtilities.decodeStringList(jsonObject.get("names").getAsJsonArray());
    int[] offsets = JsonUtilities.decodeIntArray(jsonObject.get("offsets").getAsJsonArray());
    int[] lengths = JsonUtilities.decodeIntArray(jsonObject.get("lengths").getAsJsonArray());
    return new ExtractLocalVariableFeedback(coveringExpressionOffsets, coveringExpressionLengths, names, offsets, lengths);
  }

  public static List<ExtractLocalVariableFeedback> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<ExtractLocalVariableFeedback> list = new ArrayList<ExtractLocalVariableFeedback>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * The lengths of the expressions that cover the specified selection, from the down most to the up
   * most.
   */
  public int[] getCoveringExpressionLengths() {
    return coveringExpressionLengths;
  }

  /**
   * The offsets of the expressions that cover the specified selection, from the down most to the up
   * most.
   */
  public int[] getCoveringExpressionOffsets() {
    return coveringExpressionOffsets;
  }

  /**
   * The lengths of the expressions that would be replaced by a reference to the variable. The
   * lengths correspond to the offsets. In other words, for a given expression, if the offset of that
   * expression is offsets[i], then the length of that expression is lengths[i].
   */
  public int[] getLengths() {
    return lengths;
  }

  /**
   * The proposed names for the local variable.
   */
  public List<String> getNames() {
    return names;
  }

  /**
   * The offsets of the expressions that would be replaced by a reference to the variable.
   */
  public int[] getOffsets() {
    return offsets;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(coveringExpressionOffsets);
    builder.append(coveringExpressionLengths);
    builder.append(names);
    builder.append(offsets);
    builder.append(lengths);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    if (coveringExpressionOffsets != null) {
      JsonArray jsonArrayCoveringExpressionOffsets = new JsonArray();
      for (int elt : coveringExpressionOffsets) {
        jsonArrayCoveringExpressionOffsets.add(new JsonPrimitive(elt));
      }
      jsonObject.add("coveringExpressionOffsets", jsonArrayCoveringExpressionOffsets);
    }
    if (coveringExpressionLengths != null) {
      JsonArray jsonArrayCoveringExpressionLengths = new JsonArray();
      for (int elt : coveringExpressionLengths) {
        jsonArrayCoveringExpressionLengths.add(new JsonPrimitive(elt));
      }
      jsonObject.add("coveringExpressionLengths", jsonArrayCoveringExpressionLengths);
    }
    JsonArray jsonArrayNames = new JsonArray();
    for (String elt : names) {
      jsonArrayNames.add(new JsonPrimitive(elt));
    }
    jsonObject.add("names", jsonArrayNames);
    JsonArray jsonArrayOffsets = new JsonArray();
    for (int elt : offsets) {
      jsonArrayOffsets.add(new JsonPrimitive(elt));
    }
    jsonObject.add("offsets", jsonArrayOffsets);
    JsonArray jsonArrayLengths = new JsonArray();
    for (int elt : lengths) {
      jsonArrayLengths.add(new JsonPrimitive(elt));
    }
    jsonObject.add("lengths", jsonArrayLengths);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("coveringExpressionOffsets=");
    builder.append(StringUtils.join(coveringExpressionOffsets, ", ") + ", ");
    builder.append("coveringExpressionLengths=");
    builder.append(StringUtils.join(coveringExpressionLengths, ", ") + ", ");
    builder.append("names=");
    builder.append(StringUtils.join(names, ", ") + ", ");
    builder.append("offsets=");
    builder.append(StringUtils.join(offsets, ", ") + ", ");
    builder.append("lengths=");
    builder.append(StringUtils.join(lengths, ", "));
    builder.append("]");
    return builder.toString();
  }

}
