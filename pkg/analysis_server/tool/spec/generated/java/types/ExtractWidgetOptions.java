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
import com.google.common.collect.Lists;
import com.google.dart.server.utilities.general.JsonUtilities;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonPrimitive;
import org.apache.commons.lang3.StringUtils;

/**
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class ExtractWidgetOptions extends RefactoringOptions {

  public static final ExtractWidgetOptions[] EMPTY_ARRAY = new ExtractWidgetOptions[0];

  public static final List<ExtractWidgetOptions> EMPTY_LIST = List.of();

  /**
   * The name that the widget class should be given.
   */
  private String name;

  /**
   * Constructor for {@link ExtractWidgetOptions}.
   */
  public ExtractWidgetOptions(String name) {
    this.name = name;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof ExtractWidgetOptions) {
      ExtractWidgetOptions other = (ExtractWidgetOptions) obj;
      return
        Objects.equals(other.name, name);
    }
    return false;
  }

  public static ExtractWidgetOptions fromJson(JsonObject jsonObject) {
    String name = jsonObject.get("name").getAsString();
    return new ExtractWidgetOptions(name);
  }

  public static List<ExtractWidgetOptions> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    List<ExtractWidgetOptions> list = new ArrayList<>(jsonArray.size());
    for (final JsonElement element : jsonArray) {
      list.add(fromJson(element.getAsJsonObject()));
    }
    return list;
  }

  /**
   * The name that the widget class should be given.
   */
  public String getName() {
    return name;
  }

  @Override
  public int hashCode() {
    return Objects.hash(
      name
    );
  }

  /**
   * The name that the widget class should be given.
   */
  public void setName(String name) {
    this.name = name;
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("name", name);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("name=");
    builder.append(name);
    builder.append("]");
    return builder.toString();
  }

}
