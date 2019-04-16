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
 * A description of a member that is being overridden.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class ParameterInfo {

  public static final ParameterInfo[] EMPTY_ARRAY = new ParameterInfo[0];

  public static final List<ParameterInfo> EMPTY_LIST = Lists.newArrayList();

  /**
   * The kind of the parameter.
   */
  private final String kind;

  /**
   * The name of the parameter.
   */
  private final String name;

  /**
   * The type of the parameter.
   */
  private final String type;

  /**
   * The default value for this parameter. This value will be omitted if the parameter does not have
   * a default value.
   */
  private final String defaultValue;

  /**
   * Constructor for {@link ParameterInfo}.
   */
  public ParameterInfo(String kind, String name, String type, String defaultValue) {
    this.kind = kind;
    this.name = name;
    this.type = type;
    this.defaultValue = defaultValue;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof ParameterInfo) {
      ParameterInfo other = (ParameterInfo) obj;
      return
        ObjectUtilities.equals(other.kind, kind) &&
        ObjectUtilities.equals(other.name, name) &&
        ObjectUtilities.equals(other.type, type) &&
        ObjectUtilities.equals(other.defaultValue, defaultValue);
    }
    return false;
  }

  public static ParameterInfo fromJson(JsonObject jsonObject) {
    String kind = jsonObject.get("kind").getAsString();
    String name = jsonObject.get("name").getAsString();
    String type = jsonObject.get("type").getAsString();
    String defaultValue = jsonObject.get("defaultValue") == null ? null : jsonObject.get("defaultValue").getAsString();
    return new ParameterInfo(kind, name, type, defaultValue);
  }

  public static List<ParameterInfo> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<ParameterInfo> list = new ArrayList<ParameterInfo>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * The default value for this parameter. This value will be omitted if the parameter does not have
   * a default value.
   */
  public String getDefaultValue() {
    return defaultValue;
  }

  /**
   * The kind of the parameter.
   */
  public String getKind() {
    return kind;
  }

  /**
   * The name of the parameter.
   */
  public String getName() {
    return name;
  }

  /**
   * The type of the parameter.
   */
  public String getType() {
    return type;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(kind);
    builder.append(name);
    builder.append(type);
    builder.append(defaultValue);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("kind", kind);
    jsonObject.addProperty("name", name);
    jsonObject.addProperty("type", type);
    if (defaultValue != null) {
      jsonObject.addProperty("defaultValue", defaultValue);
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
    builder.append("type=");
    builder.append(type + ", ");
    builder.append("defaultValue=");
    builder.append(defaultValue);
    builder.append("]");
    return builder.toString();
  }

}
