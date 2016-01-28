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
public class ExtractMethodFeedback extends RefactoringFeedback {

  public static final ExtractMethodFeedback[] EMPTY_ARRAY = new ExtractMethodFeedback[0];

  public static final List<ExtractMethodFeedback> EMPTY_LIST = Lists.newArrayList();

  /**
   * The offset to the beginning of the expression or statements that will be extracted.
   */
  private final int offset;

  /**
   * The length of the expression or statements that will be extracted.
   */
  private final int length;

  /**
   * The proposed return type for the method. If the returned element does not have a declared return
   * type, this field will contain an empty string.
   */
  private final String returnType;

  /**
   * The proposed names for the method.
   */
  private final List<String> names;

  /**
   * True if a getter could be created rather than a method.
   */
  private final boolean canCreateGetter;

  /**
   * The proposed parameters for the method.
   */
  private final List<RefactoringMethodParameter> parameters;

  /**
   * The offsets of the expressions or statements that would be replaced by an invocation of the
   * method.
   */
  private final int[] offsets;

  /**
   * The lengths of the expressions or statements that would be replaced by an invocation of the
   * method. The lengths correspond to the offsets. In other words, for a given expression (or block
   * of statements), if the offset of that expression is offsets[i], then the length of that
   * expression is lengths[i].
   */
  private final int[] lengths;

  /**
   * Constructor for {@link ExtractMethodFeedback}.
   */
  public ExtractMethodFeedback(int offset, int length, String returnType, List<String> names, boolean canCreateGetter, List<RefactoringMethodParameter> parameters, int[] offsets, int[] lengths) {
    this.offset = offset;
    this.length = length;
    this.returnType = returnType;
    this.names = names;
    this.canCreateGetter = canCreateGetter;
    this.parameters = parameters;
    this.offsets = offsets;
    this.lengths = lengths;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof ExtractMethodFeedback) {
      ExtractMethodFeedback other = (ExtractMethodFeedback) obj;
      return
        other.offset == offset &&
        other.length == length &&
        ObjectUtilities.equals(other.returnType, returnType) &&
        ObjectUtilities.equals(other.names, names) &&
        other.canCreateGetter == canCreateGetter &&
        ObjectUtilities.equals(other.parameters, parameters) &&
        Arrays.equals(other.offsets, offsets) &&
        Arrays.equals(other.lengths, lengths);
    }
    return false;
  }

  public static ExtractMethodFeedback fromJson(JsonObject jsonObject) {
    int offset = jsonObject.get("offset").getAsInt();
    int length = jsonObject.get("length").getAsInt();
    String returnType = jsonObject.get("returnType").getAsString();
    List<String> names = JsonUtilities.decodeStringList(jsonObject.get("names").getAsJsonArray());
    boolean canCreateGetter = jsonObject.get("canCreateGetter").getAsBoolean();
    List<RefactoringMethodParameter> parameters = RefactoringMethodParameter.fromJsonArray(jsonObject.get("parameters").getAsJsonArray());
    int[] offsets = JsonUtilities.decodeIntArray(jsonObject.get("offsets").getAsJsonArray());
    int[] lengths = JsonUtilities.decodeIntArray(jsonObject.get("lengths").getAsJsonArray());
    return new ExtractMethodFeedback(offset, length, returnType, names, canCreateGetter, parameters, offsets, lengths);
  }

  public static List<ExtractMethodFeedback> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<ExtractMethodFeedback> list = new ArrayList<ExtractMethodFeedback>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * True if a getter could be created rather than a method.
   */
  public boolean canCreateGetter() {
    return canCreateGetter;
  }

  /**
   * The length of the expression or statements that will be extracted.
   */
  public int getLength() {
    return length;
  }

  /**
   * The lengths of the expressions or statements that would be replaced by an invocation of the
   * method. The lengths correspond to the offsets. In other words, for a given expression (or block
   * of statements), if the offset of that expression is offsets[i], then the length of that
   * expression is lengths[i].
   */
  public int[] getLengths() {
    return lengths;
  }

  /**
   * The proposed names for the method.
   */
  public List<String> getNames() {
    return names;
  }

  /**
   * The offset to the beginning of the expression or statements that will be extracted.
   */
  public int getOffset() {
    return offset;
  }

  /**
   * The offsets of the expressions or statements that would be replaced by an invocation of the
   * method.
   */
  public int[] getOffsets() {
    return offsets;
  }

  /**
   * The proposed parameters for the method.
   */
  public List<RefactoringMethodParameter> getParameters() {
    return parameters;
  }

  /**
   * The proposed return type for the method. If the returned element does not have a declared return
   * type, this field will contain an empty string.
   */
  public String getReturnType() {
    return returnType;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(offset);
    builder.append(length);
    builder.append(returnType);
    builder.append(names);
    builder.append(canCreateGetter);
    builder.append(parameters);
    builder.append(offsets);
    builder.append(lengths);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("offset", offset);
    jsonObject.addProperty("length", length);
    jsonObject.addProperty("returnType", returnType);
    JsonArray jsonArrayNames = new JsonArray();
    for (String elt : names) {
      jsonArrayNames.add(new JsonPrimitive(elt));
    }
    jsonObject.add("names", jsonArrayNames);
    jsonObject.addProperty("canCreateGetter", canCreateGetter);
    JsonArray jsonArrayParameters = new JsonArray();
    for (RefactoringMethodParameter elt : parameters) {
      jsonArrayParameters.add(elt.toJson());
    }
    jsonObject.add("parameters", jsonArrayParameters);
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
    builder.append("offset=");
    builder.append(offset + ", ");
    builder.append("length=");
    builder.append(length + ", ");
    builder.append("returnType=");
    builder.append(returnType + ", ");
    builder.append("names=");
    builder.append(StringUtils.join(names, ", ") + ", ");
    builder.append("canCreateGetter=");
    builder.append(canCreateGetter + ", ");
    builder.append("parameters=");
    builder.append(StringUtils.join(parameters, ", ") + ", ");
    builder.append("offsets=");
    builder.append(StringUtils.join(offsets, ", ") + ", ");
    builder.append("lengths=");
    builder.append(StringUtils.join(lengths, ", "));
    builder.append("]");
    return builder.toString();
  }

}
