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
 * A declaration - top-level (class, field, etc) or a class member (method, field, etc).
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class ElementDeclaration {

  public static final ElementDeclaration[] EMPTY_ARRAY = new ElementDeclaration[0];

  public static final List<ElementDeclaration> EMPTY_LIST = Lists.newArrayList();

  /**
   * The name of the declaration.
   */
  private final String name;

  /**
   * The kind of the element that corresponds to the declaration.
   */
  private final String kind;

  /**
   * The index of the file (in the enclosing response).
   */
  private final int fileIndex;

  /**
   * The offset of the declaration name in the file.
   */
  private final int offset;

  /**
   * The one-based index of the line containing the declaration name.
   */
  private final int line;

  /**
   * The one-based index of the column containing the declaration name.
   */
  private final int column;

  /**
   * The offset of the first character of the declaration code in the file.
   */
  private final int codeOffset;

  /**
   * The length of the declaration code in the file.
   */
  private final int codeLength;

  /**
   * The name of the class enclosing this declaration. If the declaration is not a class member, this
   * field will be absent.
   */
  private final String className;

  /**
   * The name of the mixin enclosing this declaration. If the declaration is not a mixin member, this
   * field will be absent.
   */
  private final String mixinName;

  /**
   * The parameter list for the element. If the element is not a method or function this field will
   * not be defined. If the element doesn't have parameters (e.g. getter), this field will not be
   * defined. If the element has zero parameters, this field will have a value of "()". The value
   * should not be treated as exact presentation of parameters, it is just approximation of
   * parameters to give the user general idea.
   */
  private final String parameters;

  /**
   * Constructor for {@link ElementDeclaration}.
   */
  public ElementDeclaration(String name, String kind, int fileIndex, int offset, int line, int column, int codeOffset, int codeLength, String className, String mixinName, String parameters) {
    this.name = name;
    this.kind = kind;
    this.fileIndex = fileIndex;
    this.offset = offset;
    this.line = line;
    this.column = column;
    this.codeOffset = codeOffset;
    this.codeLength = codeLength;
    this.className = className;
    this.mixinName = mixinName;
    this.parameters = parameters;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof ElementDeclaration) {
      ElementDeclaration other = (ElementDeclaration) obj;
      return
        ObjectUtilities.equals(other.name, name) &&
        ObjectUtilities.equals(other.kind, kind) &&
        other.fileIndex == fileIndex &&
        other.offset == offset &&
        other.line == line &&
        other.column == column &&
        other.codeOffset == codeOffset &&
        other.codeLength == codeLength &&
        ObjectUtilities.equals(other.className, className) &&
        ObjectUtilities.equals(other.mixinName, mixinName) &&
        ObjectUtilities.equals(other.parameters, parameters);
    }
    return false;
  }

  public static ElementDeclaration fromJson(JsonObject jsonObject) {
    String name = jsonObject.get("name").getAsString();
    String kind = jsonObject.get("kind").getAsString();
    int fileIndex = jsonObject.get("fileIndex").getAsInt();
    int offset = jsonObject.get("offset").getAsInt();
    int line = jsonObject.get("line").getAsInt();
    int column = jsonObject.get("column").getAsInt();
    int codeOffset = jsonObject.get("codeOffset").getAsInt();
    int codeLength = jsonObject.get("codeLength").getAsInt();
    String className = jsonObject.get("className") == null ? null : jsonObject.get("className").getAsString();
    String mixinName = jsonObject.get("mixinName") == null ? null : jsonObject.get("mixinName").getAsString();
    String parameters = jsonObject.get("parameters") == null ? null : jsonObject.get("parameters").getAsString();
    return new ElementDeclaration(name, kind, fileIndex, offset, line, column, codeOffset, codeLength, className, mixinName, parameters);
  }

  public static List<ElementDeclaration> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<ElementDeclaration> list = new ArrayList<ElementDeclaration>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * The name of the class enclosing this declaration. If the declaration is not a class member, this
   * field will be absent.
   */
  public String getClassName() {
    return className;
  }

  /**
   * The length of the declaration code in the file.
   */
  public int getCodeLength() {
    return codeLength;
  }

  /**
   * The offset of the first character of the declaration code in the file.
   */
  public int getCodeOffset() {
    return codeOffset;
  }

  /**
   * The one-based index of the column containing the declaration name.
   */
  public int getColumn() {
    return column;
  }

  /**
   * The index of the file (in the enclosing response).
   */
  public int getFileIndex() {
    return fileIndex;
  }

  /**
   * The kind of the element that corresponds to the declaration.
   */
  public String getKind() {
    return kind;
  }

  /**
   * The one-based index of the line containing the declaration name.
   */
  public int getLine() {
    return line;
  }

  /**
   * The name of the mixin enclosing this declaration. If the declaration is not a mixin member, this
   * field will be absent.
   */
  public String getMixinName() {
    return mixinName;
  }

  /**
   * The name of the declaration.
   */
  public String getName() {
    return name;
  }

  /**
   * The offset of the declaration name in the file.
   */
  public int getOffset() {
    return offset;
  }

  /**
   * The parameter list for the element. If the element is not a method or function this field will
   * not be defined. If the element doesn't have parameters (e.g. getter), this field will not be
   * defined. If the element has zero parameters, this field will have a value of "()". The value
   * should not be treated as exact presentation of parameters, it is just approximation of
   * parameters to give the user general idea.
   */
  public String getParameters() {
    return parameters;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(name);
    builder.append(kind);
    builder.append(fileIndex);
    builder.append(offset);
    builder.append(line);
    builder.append(column);
    builder.append(codeOffset);
    builder.append(codeLength);
    builder.append(className);
    builder.append(mixinName);
    builder.append(parameters);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("name", name);
    jsonObject.addProperty("kind", kind);
    jsonObject.addProperty("fileIndex", fileIndex);
    jsonObject.addProperty("offset", offset);
    jsonObject.addProperty("line", line);
    jsonObject.addProperty("column", column);
    jsonObject.addProperty("codeOffset", codeOffset);
    jsonObject.addProperty("codeLength", codeLength);
    if (className != null) {
      jsonObject.addProperty("className", className);
    }
    if (mixinName != null) {
      jsonObject.addProperty("mixinName", mixinName);
    }
    if (parameters != null) {
      jsonObject.addProperty("parameters", parameters);
    }
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("name=");
    builder.append(name + ", ");
    builder.append("kind=");
    builder.append(kind + ", ");
    builder.append("fileIndex=");
    builder.append(fileIndex + ", ");
    builder.append("offset=");
    builder.append(offset + ", ");
    builder.append("line=");
    builder.append(line + ", ");
    builder.append("column=");
    builder.append(column + ", ");
    builder.append("codeOffset=");
    builder.append(codeOffset + ", ");
    builder.append("codeLength=");
    builder.append(codeLength + ", ");
    builder.append("className=");
    builder.append(className + ", ");
    builder.append("mixinName=");
    builder.append(mixinName + ", ");
    builder.append("parameters=");
    builder.append(parameters);
    builder.append("]");
    return builder.toString();
  }

}
