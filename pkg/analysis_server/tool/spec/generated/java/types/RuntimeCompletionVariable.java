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
 * A variable in a runtime context.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class RuntimeCompletionVariable {

  public static final RuntimeCompletionVariable[] EMPTY_ARRAY = new RuntimeCompletionVariable[0];

  public static final List<RuntimeCompletionVariable> EMPTY_LIST = Lists.newArrayList();

  /**
   * The name of the variable. The name "this" has a special meaning and is used as an implicit
   * target for runtime completion, and in explicit "this" references.
   */
  private final String name;

  /**
   * The type of the variable.
   */
  private final RuntimeCompletionExpressionType type;

  /**
   * Constructor for {@link RuntimeCompletionVariable}.
   */
  public RuntimeCompletionVariable(String name, RuntimeCompletionExpressionType type) {
    this.name = name;
    this.type = type;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof RuntimeCompletionVariable) {
      RuntimeCompletionVariable other = (RuntimeCompletionVariable) obj;
      return
        ObjectUtilities.equals(other.name, name) &&
        ObjectUtilities.equals(other.type, type);
    }
    return false;
  }

  public static RuntimeCompletionVariable fromJson(JsonObject jsonObject) {
    String name = jsonObject.get("name").getAsString();
    RuntimeCompletionExpressionType type = RuntimeCompletionExpressionType.fromJson(jsonObject.get("type").getAsJsonObject());
    return new RuntimeCompletionVariable(name, type);
  }

  public static List<RuntimeCompletionVariable> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<RuntimeCompletionVariable> list = new ArrayList<RuntimeCompletionVariable>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * The name of the variable. The name "this" has a special meaning and is used as an implicit
   * target for runtime completion, and in explicit "this" references.
   */
  public String getName() {
    return name;
  }

  /**
   * The type of the variable.
   */
  public RuntimeCompletionExpressionType getType() {
    return type;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(name);
    builder.append(type);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("name", name);
    jsonObject.add("type", type.toJson());
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("name=");
    builder.append(name + ", ");
    builder.append("type=");
    builder.append(type);
    builder.append("]");
    return builder.toString();
  }

}
