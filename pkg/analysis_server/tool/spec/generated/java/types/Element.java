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
 * Information about an element (something that can be declared in code).
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class Element {

  public static final Element[] EMPTY_ARRAY = new Element[0];

  public static final List<Element> EMPTY_LIST = Lists.newArrayList();

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
   * - 0x02 - set if the element was declared to be ‘const’
   * - 0x04 - set if the element was declared to be ‘final’
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
   * Constructor for {@link Element}.
   */
  public Element(String kind, String name, Location location, int flags, String parameters, String returnType, String typeParameters) {
    this.kind = kind;
    this.name = name;
    this.location = location;
    this.flags = flags;
    this.parameters = parameters;
    this.returnType = returnType;
    this.typeParameters = typeParameters;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof Element) {
      Element other = (Element) obj;
      return
        ObjectUtilities.equals(other.kind, kind) &&
        ObjectUtilities.equals(other.name, name) &&
        ObjectUtilities.equals(other.location, location) &&
        other.flags == flags &&
        ObjectUtilities.equals(other.parameters, parameters) &&
        ObjectUtilities.equals(other.returnType, returnType) &&
        ObjectUtilities.equals(other.typeParameters, typeParameters);
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
    return new Element(kind, name, location, flags, parameters, returnType, typeParameters);
  }

  public static List<Element> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<Element> list = new ArrayList<Element>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * A bit-map containing the following flags:
   *
   * - 0x01 - set if the element is explicitly or implicitly abstract
   * - 0x02 - set if the element was declared to be ‘const’
   * - 0x04 - set if the element was declared to be ‘final’
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
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(kind);
    builder.append(name);
    builder.append(location);
    builder.append(flags);
    builder.append(parameters);
    builder.append(returnType);
    builder.append(typeParameters);
    return builder.toHashCode();
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
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("kind=");
    builder.append(kind + ", ");
    builder.append("name=");
    builder.append(name + ", ");
    builder.append("location=");
    builder.append(location + ", ");
    builder.append("flags=");
    builder.append(flags + ", ");
    builder.append("parameters=");
    builder.append(parameters + ", ");
    builder.append("returnType=");
    builder.append(returnType + ", ");
    builder.append("typeParameters=");
    builder.append(typeParameters);
    builder.append("]");
    return builder.toString();
  }

}
