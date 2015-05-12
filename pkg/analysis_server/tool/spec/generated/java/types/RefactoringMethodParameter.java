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
 * A description of a parameter in a method refactoring.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class RefactoringMethodParameter {

  public static final RefactoringMethodParameter[] EMPTY_ARRAY = new RefactoringMethodParameter[0];

  public static final List<RefactoringMethodParameter> EMPTY_LIST = Lists.newArrayList();

  /**
   * The unique identifier of the parameter. Clients may omit this field for the parameters they want
   * to add.
   */
  private String id;

  /**
   * The kind of the parameter.
   */
  private String kind;

  /**
   * The type that should be given to the parameter, or the return type of the parameter's function
   * type.
   */
  private String type;

  /**
   * The name that should be given to the parameter.
   */
  private String name;

  /**
   * The parameter list of the parameter's function type. If the parameter is not of a function type,
   * this field will not be defined. If the function type has zero parameters, this field will have a
   * value of "()".
   */
  private String parameters;

  /**
   * Constructor for {@link RefactoringMethodParameter}.
   */
  public RefactoringMethodParameter(String id, String kind, String type, String name, String parameters) {
    this.id = id;
    this.kind = kind;
    this.type = type;
    this.name = name;
    this.parameters = parameters;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof RefactoringMethodParameter) {
      RefactoringMethodParameter other = (RefactoringMethodParameter) obj;
      return
        ObjectUtilities.equals(other.id, id) &&
        ObjectUtilities.equals(other.kind, kind) &&
        ObjectUtilities.equals(other.type, type) &&
        ObjectUtilities.equals(other.name, name) &&
        ObjectUtilities.equals(other.parameters, parameters);
    }
    return false;
  }

  public static RefactoringMethodParameter fromJson(JsonObject jsonObject) {
    String id = jsonObject.get("id") == null ? null : jsonObject.get("id").getAsString();
    String kind = jsonObject.get("kind").getAsString();
    String type = jsonObject.get("type").getAsString();
    String name = jsonObject.get("name").getAsString();
    String parameters = jsonObject.get("parameters") == null ? null : jsonObject.get("parameters").getAsString();
    return new RefactoringMethodParameter(id, kind, type, name, parameters);
  }

  public static List<RefactoringMethodParameter> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<RefactoringMethodParameter> list = new ArrayList<RefactoringMethodParameter>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * The unique identifier of the parameter. Clients may omit this field for the parameters they want
   * to add.
   */
  public String getId() {
    return id;
  }

  /**
   * The kind of the parameter.
   */
  public String getKind() {
    return kind;
  }

  /**
   * The name that should be given to the parameter.
   */
  public String getName() {
    return name;
  }

  /**
   * The parameter list of the parameter's function type. If the parameter is not of a function type,
   * this field will not be defined. If the function type has zero parameters, this field will have a
   * value of "()".
   */
  public String getParameters() {
    return parameters;
  }

  /**
   * The type that should be given to the parameter, or the return type of the parameter's function
   * type.
   */
  public String getType() {
    return type;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(id);
    builder.append(kind);
    builder.append(type);
    builder.append(name);
    builder.append(parameters);
    return builder.toHashCode();
  }

  /**
   * The unique identifier of the parameter. Clients may omit this field for the parameters they want
   * to add.
   */
  public void setId(String id) {
    this.id = id;
  }

  /**
   * The kind of the parameter.
   */
  public void setKind(String kind) {
    this.kind = kind;
  }

  /**
   * The name that should be given to the parameter.
   */
  public void setName(String name) {
    this.name = name;
  }

  /**
   * The parameter list of the parameter's function type. If the parameter is not of a function type,
   * this field will not be defined. If the function type has zero parameters, this field will have a
   * value of "()".
   */
  public void setParameters(String parameters) {
    this.parameters = parameters;
  }

  /**
   * The type that should be given to the parameter, or the return type of the parameter's function
   * type.
   */
  public void setType(String type) {
    this.type = type;
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    if (id != null) {
      jsonObject.addProperty("id", id);
    }
    jsonObject.addProperty("kind", kind);
    jsonObject.addProperty("type", type);
    jsonObject.addProperty("name", name);
    if (parameters != null) {
      jsonObject.addProperty("parameters", parameters);
    }
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("id=");
    builder.append(id + ", ");
    builder.append("kind=");
    builder.append(kind + ", ");
    builder.append("type=");
    builder.append(type + ", ");
    builder.append("name=");
    builder.append(name + ", ");
    builder.append("parameters=");
    builder.append(parameters);
    builder.append("]");
    return builder.toString();
  }

}
