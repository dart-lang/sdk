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
 * A type at runtime.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class RuntimeCompletionExpressionType {

  public static final RuntimeCompletionExpressionType[] EMPTY_ARRAY = new RuntimeCompletionExpressionType[0];

  public static final List<RuntimeCompletionExpressionType> EMPTY_LIST = Lists.newArrayList();

  /**
   * The path of the library that has this type. Omitted if the type is not declared in any library,
   * e.g. "dynamic", or "void".
   */
  private final String libraryPath;

  /**
   * The kind of the type.
   */
  private final String kind;

  /**
   * The name of the type. Omitted if the type does not have a name, e.g. an inline function type.
   */
  private final String name;

  /**
   * The type arguments of the type. Omitted if the type does not have type parameters.
   */
  private final List<RuntimeCompletionExpressionType> typeArguments;

  /**
   * If the type is a function type, the return type of the function. Omitted if the type is not a
   * function type.
   */
  private final RuntimeCompletionExpressionType returnType;

  /**
   * If the type is a function type, the types of the function parameters of all kinds - required,
   * optional positional, and optional named. Omitted if the type is not a function type.
   */
  private final List<RuntimeCompletionExpressionType> parameterTypes;

  /**
   * If the type is a function type, the names of the function parameters of all kinds - required,
   * optional positional, and optional named. The names of positional parameters are empty strings.
   * Omitted if the type is not a function type.
   */
  private final List<String> parameterNames;

  /**
   * Constructor for {@link RuntimeCompletionExpressionType}.
   */
  public RuntimeCompletionExpressionType(String libraryPath, String kind, String name, List<RuntimeCompletionExpressionType> typeArguments, RuntimeCompletionExpressionType returnType, List<RuntimeCompletionExpressionType> parameterTypes, List<String> parameterNames) {
    this.libraryPath = libraryPath;
    this.kind = kind;
    this.name = name;
    this.typeArguments = typeArguments;
    this.returnType = returnType;
    this.parameterTypes = parameterTypes;
    this.parameterNames = parameterNames;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof RuntimeCompletionExpressionType) {
      RuntimeCompletionExpressionType other = (RuntimeCompletionExpressionType) obj;
      return
        ObjectUtilities.equals(other.libraryPath, libraryPath) &&
        ObjectUtilities.equals(other.kind, kind) &&
        ObjectUtilities.equals(other.name, name) &&
        ObjectUtilities.equals(other.typeArguments, typeArguments) &&
        ObjectUtilities.equals(other.returnType, returnType) &&
        ObjectUtilities.equals(other.parameterTypes, parameterTypes) &&
        ObjectUtilities.equals(other.parameterNames, parameterNames);
    }
    return false;
  }

  public static RuntimeCompletionExpressionType fromJson(JsonObject jsonObject) {
    String libraryPath = jsonObject.get("libraryPath") == null ? null : jsonObject.get("libraryPath").getAsString();
    String kind = jsonObject.get("kind").getAsString();
    String name = jsonObject.get("name") == null ? null : jsonObject.get("name").getAsString();
    List<RuntimeCompletionExpressionType> typeArguments = jsonObject.get("typeArguments") == null ? null : RuntimeCompletionExpressionType.fromJsonArray(jsonObject.get("typeArguments").getAsJsonArray());
    RuntimeCompletionExpressionType returnType = jsonObject.get("returnType") == null ? null : RuntimeCompletionExpressionType.fromJson(jsonObject.get("returnType").getAsJsonObject());
    List<RuntimeCompletionExpressionType> parameterTypes = jsonObject.get("parameterTypes") == null ? null : RuntimeCompletionExpressionType.fromJsonArray(jsonObject.get("parameterTypes").getAsJsonArray());
    List<String> parameterNames = jsonObject.get("parameterNames") == null ? null : JsonUtilities.decodeStringList(jsonObject.get("parameterNames").getAsJsonArray());
    return new RuntimeCompletionExpressionType(libraryPath, kind, name, typeArguments, returnType, parameterTypes, parameterNames);
  }

  public static List<RuntimeCompletionExpressionType> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<RuntimeCompletionExpressionType> list = new ArrayList<RuntimeCompletionExpressionType>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * The kind of the type.
   */
  public String getKind() {
    return kind;
  }

  /**
   * The path of the library that has this type. Omitted if the type is not declared in any library,
   * e.g. "dynamic", or "void".
   */
  public String getLibraryPath() {
    return libraryPath;
  }

  /**
   * The name of the type. Omitted if the type does not have a name, e.g. an inline function type.
   */
  public String getName() {
    return name;
  }

  /**
   * If the type is a function type, the names of the function parameters of all kinds - required,
   * optional positional, and optional named. The names of positional parameters are empty strings.
   * Omitted if the type is not a function type.
   */
  public List<String> getParameterNames() {
    return parameterNames;
  }

  /**
   * If the type is a function type, the types of the function parameters of all kinds - required,
   * optional positional, and optional named. Omitted if the type is not a function type.
   */
  public List<RuntimeCompletionExpressionType> getParameterTypes() {
    return parameterTypes;
  }

  /**
   * If the type is a function type, the return type of the function. Omitted if the type is not a
   * function type.
   */
  public RuntimeCompletionExpressionType getReturnType() {
    return returnType;
  }

  /**
   * The type arguments of the type. Omitted if the type does not have type parameters.
   */
  public List<RuntimeCompletionExpressionType> getTypeArguments() {
    return typeArguments;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(libraryPath);
    builder.append(kind);
    builder.append(name);
    builder.append(typeArguments);
    builder.append(returnType);
    builder.append(parameterTypes);
    builder.append(parameterNames);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    if (libraryPath != null) {
      jsonObject.addProperty("libraryPath", libraryPath);
    }
    jsonObject.addProperty("kind", kind);
    if (name != null) {
      jsonObject.addProperty("name", name);
    }
    if (typeArguments != null) {
      JsonArray jsonArrayTypeArguments = new JsonArray();
      for (RuntimeCompletionExpressionType elt : typeArguments) {
        jsonArrayTypeArguments.add(elt.toJson());
      }
      jsonObject.add("typeArguments", jsonArrayTypeArguments);
    }
    if (returnType != null) {
      jsonObject.add("returnType", returnType.toJson());
    }
    if (parameterTypes != null) {
      JsonArray jsonArrayParameterTypes = new JsonArray();
      for (RuntimeCompletionExpressionType elt : parameterTypes) {
        jsonArrayParameterTypes.add(elt.toJson());
      }
      jsonObject.add("parameterTypes", jsonArrayParameterTypes);
    }
    if (parameterNames != null) {
      JsonArray jsonArrayParameterNames = new JsonArray();
      for (String elt : parameterNames) {
        jsonArrayParameterNames.add(new JsonPrimitive(elt));
      }
      jsonObject.add("parameterNames", jsonArrayParameterNames);
    }
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("libraryPath=");
    builder.append(libraryPath + ", ");
    builder.append("kind=");
    builder.append(kind + ", ");
    builder.append("name=");
    builder.append(name + ", ");
    builder.append("typeArguments=");
    builder.append(StringUtils.join(typeArguments, ", ") + ", ");
    builder.append("returnType=");
    builder.append(returnType + ", ");
    builder.append("parameterTypes=");
    builder.append(StringUtils.join(parameterTypes, ", ") + ", ");
    builder.append("parameterNames=");
    builder.append(StringUtils.join(parameterNames, ", "));
    builder.append("]");
    return builder.toString();
  }

}
