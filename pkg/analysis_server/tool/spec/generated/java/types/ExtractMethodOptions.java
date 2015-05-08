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
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class ExtractMethodOptions extends RefactoringOptions {

  public static final ExtractMethodOptions[] EMPTY_ARRAY = new ExtractMethodOptions[0];

  public static final List<ExtractMethodOptions> EMPTY_LIST = Lists.newArrayList();

  /**
   * The return type that should be defined for the method.
   */
  private String returnType;

  /**
   * True if a getter should be created rather than a method. It is an error if this field is true
   * and the list of parameters is non-empty.
   */
  private boolean createGetter;

  /**
   * The name that the method should be given.
   */
  private String name;

  /**
   * The parameters that should be defined for the method.
   *
   * It is an error if a REQUIRED or NAMED parameter follows a POSITIONAL parameter. It is an error
   * if a REQUIRED or POSITIONAL parameter follows a NAMED parameter.
   *
   * - To change the order and/or update proposed parameters, add parameters with the same
   *   identifiers as proposed.
   * - To add new parameters, omit their identifier.
   * - To remove some parameters, omit them in this list.
   */
  private List<RefactoringMethodParameter> parameters;

  /**
   * True if all occurrences of the expression or statements should be replaced by an invocation of
   * the method. The expression or statements used to initiate the refactoring will always be
   * replaced.
   */
  private boolean extractAll;

  /**
   * Constructor for {@link ExtractMethodOptions}.
   */
  public ExtractMethodOptions(String returnType, boolean createGetter, String name, List<RefactoringMethodParameter> parameters, boolean extractAll) {
    this.returnType = returnType;
    this.createGetter = createGetter;
    this.name = name;
    this.parameters = parameters;
    this.extractAll = extractAll;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof ExtractMethodOptions) {
      ExtractMethodOptions other = (ExtractMethodOptions) obj;
      return
        ObjectUtilities.equals(other.returnType, returnType) &&
        other.createGetter == createGetter &&
        ObjectUtilities.equals(other.name, name) &&
        ObjectUtilities.equals(other.parameters, parameters) &&
        other.extractAll == extractAll;
    }
    return false;
  }

  public static ExtractMethodOptions fromJson(JsonObject jsonObject) {
    String returnType = jsonObject.get("returnType").getAsString();
    boolean createGetter = jsonObject.get("createGetter").getAsBoolean();
    String name = jsonObject.get("name").getAsString();
    List<RefactoringMethodParameter> parameters = RefactoringMethodParameter.fromJsonArray(jsonObject.get("parameters").getAsJsonArray());
    boolean extractAll = jsonObject.get("extractAll").getAsBoolean();
    return new ExtractMethodOptions(returnType, createGetter, name, parameters, extractAll);
  }

  public static List<ExtractMethodOptions> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<ExtractMethodOptions> list = new ArrayList<ExtractMethodOptions>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * True if a getter should be created rather than a method. It is an error if this field is true
   * and the list of parameters is non-empty.
   */
  public boolean createGetter() {
    return createGetter;
  }

  /**
   * True if all occurrences of the expression or statements should be replaced by an invocation of
   * the method. The expression or statements used to initiate the refactoring will always be
   * replaced.
   */
  public boolean extractAll() {
    return extractAll;
  }

  /**
   * The name that the method should be given.
   */
  public String getName() {
    return name;
  }

  /**
   * The parameters that should be defined for the method.
   *
   * It is an error if a REQUIRED or NAMED parameter follows a POSITIONAL parameter. It is an error
   * if a REQUIRED or POSITIONAL parameter follows a NAMED parameter.
   *
   * - To change the order and/or update proposed parameters, add parameters with the same
   *   identifiers as proposed.
   * - To add new parameters, omit their identifier.
   * - To remove some parameters, omit them in this list.
   */
  public List<RefactoringMethodParameter> getParameters() {
    return parameters;
  }

  /**
   * The return type that should be defined for the method.
   */
  public String getReturnType() {
    return returnType;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(returnType);
    builder.append(createGetter);
    builder.append(name);
    builder.append(parameters);
    builder.append(extractAll);
    return builder.toHashCode();
  }

  /**
   * True if a getter should be created rather than a method. It is an error if this field is true
   * and the list of parameters is non-empty.
   */
  public void setCreateGetter(boolean createGetter) {
    this.createGetter = createGetter;
  }

  /**
   * True if all occurrences of the expression or statements should be replaced by an invocation of
   * the method. The expression or statements used to initiate the refactoring will always be
   * replaced.
   */
  public void setExtractAll(boolean extractAll) {
    this.extractAll = extractAll;
  }

  /**
   * The name that the method should be given.
   */
  public void setName(String name) {
    this.name = name;
  }

  /**
   * The parameters that should be defined for the method.
   *
   * It is an error if a REQUIRED or NAMED parameter follows a POSITIONAL parameter. It is an error
   * if a REQUIRED or POSITIONAL parameter follows a NAMED parameter.
   *
   * - To change the order and/or update proposed parameters, add parameters with the same
   *   identifiers as proposed.
   * - To add new parameters, omit their identifier.
   * - To remove some parameters, omit them in this list.
   */
  public void setParameters(List<RefactoringMethodParameter> parameters) {
    this.parameters = parameters;
  }

  /**
   * The return type that should be defined for the method.
   */
  public void setReturnType(String returnType) {
    this.returnType = returnType;
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("returnType", returnType);
    jsonObject.addProperty("createGetter", createGetter);
    jsonObject.addProperty("name", name);
    JsonArray jsonArrayParameters = new JsonArray();
    for (RefactoringMethodParameter elt : parameters) {
      jsonArrayParameters.add(elt.toJson());
    }
    jsonObject.add("parameters", jsonArrayParameters);
    jsonObject.addProperty("extractAll", extractAll);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("returnType=");
    builder.append(returnType + ", ");
    builder.append("createGetter=");
    builder.append(createGetter + ", ");
    builder.append("name=");
    builder.append(name + ", ");
    builder.append("parameters=");
    builder.append(StringUtils.join(parameters, ", ") + ", ");
    builder.append("extractAll=");
    builder.append(extractAll);
    builder.append("]");
    return builder.toString();
  }

}
