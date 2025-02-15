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
import java.util.stream.Collectors;
import com.google.dart.server.utilities.general.JsonUtilities;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonPrimitive;

/**
 * Information about an element (something that can be declared in code).
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class Element {

  public static final List<Element> EMPTY_LIST = List.of();

  private static final int ABSTRACT = 0x01;

  private static final int CONST = 0x02;

  private static final int FINAL = 0x04;

  private static final int TOP_LEVEL_STATIC = 0x08;

  private static final int PRIVATE = 0x10;

  private static final int DEPRECATED = 0x20;

  /**
   * The kind of the element.
   */
  private final String kind;

  /**
   * The name of the element. This is typically used as the label in the outline.
   */
  private final String name;

  /**
   * The location of the name in the declaration of the element.
   */
  private final Location location;

  /**
   * A bit-map containing the following flags:
   *
   * - 0x01 - set if the element is explicitly or implicitly abstract
   * - 0x02 - set if the element was declared to be 'const'
   * - 0x04 - set if the element was declared to be 'final'
   * - 0x08 - set if the element is a static member of a class or is a top-level function or field
   * - 0x10 - set if the element is private
   * - 0x20 - set if the element is deprecated
   */
  private final int flags;

  /**
   * The parameter list for the element. If the element is not a method or function this field will
   * not be defined. If the element doesn't have parameters (e.g. getter), this field will not be
   * defined. If the element has zero parameters, this field will have a value of "()".
   */
  private final String parameters;

  /**
   * The return type of the element. If the element is not a method or function this field will not
   * be defined. If the element does not have a declared return type, this field will contain an
   * empty string.
   */
  private final String returnType;

  /**
   * The type parameter list for the element. If the element doesn't have type parameters, this field
   * will not be defined.
   */
  private final String typeParameters;

  /**
   * If the element is a type alias, this field is the aliased type. Otherwise this field will not be
   * defined.
   */
  private final String aliasedType;

  /**
   * Constructor for {@link Element}.
   */
  public Element(String kind, String name, Location location, int flags, String parameters, String returnType, String typeParameters, String aliasedType) {
    this.kind = kind;
    this.name = name;
    this.location = location;
    this.flags = flags;
    this.parameters = parameters;
    this.returnType = returnType;
    this.typeParameters = typeParameters;
    this.aliasedType = aliasedType;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof Element other) {
      return
        Objects.equals(other.kind, kind) &&
        Objects.equals(other.name, name) &&
        Objects.equals(other.location, location) &&
        other.flags == flags &&
        Objects.equals(other.parameters, parameters) &&
        Objects.equals(other.returnType, returnType) &&
        Objects.equals(other.typeParameters, typeParameters) &&
        Objects.equals(other.aliasedType, aliasedType);
    }
    return false;
  }

  public static Element fromJson(JsonObject jsonObject) {
    String kind = jsonObject.get("kind").getAsString();
    String name = jsonObject.get("name").getAsString();
    Location location = jsonObject.get("location") == null ? null : Location.fromJson(jsonObject.get("location").getAsJsonObject());
    int flags = jsonObject.get("flags").getAsInt();
    String parameters = jsonObject.get("parameters") == null ? null : jsonObject.get("parameters").getAsString();
    String returnType = jsonObject.get("returnType") == null ? null : jsonObject.get("returnType").getAsString();
    String typeParameters = jsonObject.get("typeParameters") == null ? null : jsonObject.get("typeParameters").getAsString();
    String aliasedType = jsonObject.get("aliasedType") == null ? null : jsonObject.get("aliasedType").getAsString();
    return new Element(kind, name, location, flags, parameters, returnType, typeParameters, aliasedType);
  }

  public static List<Element> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    List<Element> list = new ArrayList<>(jsonArray.size());
    for (final JsonElement element : jsonArray) {
      list.add(fromJson(element.getAsJsonObject()));
    }
    return list;
  }

  /**
   * If the element is a type alias, this field is the aliased type. Otherwise this field will not be
   * defined.
   */
  public String getAliasedType() {
    return aliasedType;
  }

  /**
   * A bit-map containing the following flags:
   *
   * - 0x01 - set if the element is explicitly or implicitly abstract
   * - 0x02 - set if the element was declared to be 'const'
   * - 0x04 - set if the element was declared to be 'final'
   * - 0x08 - set if the element is a static member of a class or is a top-level function or field
   * - 0x10 - set if the element is private
   * - 0x20 - set if the element is deprecated
   */
  public int getFlags() {
    return flags;
  }

  /**
   * The kind of the element.
   */
  public String getKind() {
    return kind;
  }

  /**
   * The location of the name in the declaration of the element.
   */
  public Location getLocation() {
    return location;
  }

  /**
   * The name of the element. This is typically used as the label in the outline.
   */
  public String getName() {
    return name;
  }

  /**
   * The parameter list for the element. If the element is not a method or function this field will
   * not be defined. If the element doesn't have parameters (e.g. getter), this field will not be
   * defined. If the element has zero parameters, this field will have a value of "()".
   */
  public String getParameters() {
    return parameters;
  }

  /**
   * The return type of the element. If the element is not a method or function this field will not
   * be defined. If the element does not have a declared return type, this field will contain an
   * empty string.
   */
  public String getReturnType() {
    return returnType;
  }

  /**
   * The type parameter list for the element. If the element doesn't have type parameters, this field
   * will not be defined.
   */
  public String getTypeParameters() {
    return typeParameters;
  }

  @Override
  public int hashCode() {
    return Objects.hash(
      kind,
      name,
      location,
      flags,
      parameters,
      returnType,
      typeParameters,
      aliasedType
    );
  }

  public boolean isAbstract() {
    return (flags & ABSTRACT) != 0;
  }

  public boolean isConst() {
    return (flags & CONST) != 0;
  }

  public boolean isDeprecated() {
    return (flags & DEPRECATED) != 0;
  }

  public boolean isFinal() {
    return (flags & FINAL) != 0;
  }

  public boolean isPrivate() {
    return (flags & PRIVATE) != 0;
  }

  public boolean isTopLevelOrStatic() {
    return (flags & TOP_LEVEL_STATIC) != 0;
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("kind", kind);
    jsonObject.addProperty("name", name);
    if (location != null) {
      jsonObject.add("location", location.toJson());
    }
    jsonObject.addProperty("flags", flags);
    if (parameters != null) {
      jsonObject.addProperty("parameters", parameters);
    }
    if (returnType != null) {
      jsonObject.addProperty("returnType", returnType);
    }
    if (typeParameters != null) {
      jsonObject.addProperty("typeParameters", typeParameters);
    }
    if (aliasedType != null) {
      jsonObject.addProperty("aliasedType", aliasedType);
    }
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("kind=");
    builder.append(kind);
    builder.append(", ");
    builder.append("name=");
    builder.append(name);
    builder.append(", ");
    builder.append("location=");
    builder.append(location);
    builder.append(", ");
    builder.append("flags=");
    builder.append(flags);
    builder.append(", ");
    builder.append("parameters=");
    builder.append(parameters);
    builder.append(", ");
    builder.append("returnType=");
    builder.append(returnType);
    builder.append(", ");
    builder.append("typeParameters=");
    builder.append(typeParameters);
    builder.append(", ");
    builder.append("aliasedType=");
    builder.append(aliasedType);
    builder.append("]");
    return builder.toString();
  }

}
