/*
 * Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
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
public class ExtractWidgetOptions extends RefactoringOptions {

  public static final ExtractWidgetOptions[] EMPTY_ARRAY = new ExtractWidgetOptions[0];

  public static final List<ExtractWidgetOptions> EMPTY_LIST = Lists.newArrayList();

  /**
   * The name that the widget class should be given.
   */
  private String name;

  /**
   * True if a StatefulWidget should be created.
   */
  private boolean stateful;

  /**
   * Constructor for {@link ExtractWidgetOptions}.
   */
  public ExtractWidgetOptions(String name, boolean stateful) {
    this.name = name;
    this.stateful = stateful;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof ExtractWidgetOptions) {
      ExtractWidgetOptions other = (ExtractWidgetOptions) obj;
      return
        ObjectUtilities.equals(other.name, name) &&
        other.stateful == stateful;
    }
    return false;
  }

  public static ExtractWidgetOptions fromJson(JsonObject jsonObject) {
    String name = jsonObject.get("name").getAsString();
    boolean stateful = jsonObject.get("stateful").getAsBoolean();
    return new ExtractWidgetOptions(name, stateful);
  }

  public static List<ExtractWidgetOptions> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<ExtractWidgetOptions> list = new ArrayList<ExtractWidgetOptions>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * The name that the widget class should be given.
   */
  public String getName() {
    return name;
  }

  /**
   * True if a StatefulWidget should be created.
   */
  public boolean stateful() {
    return stateful;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(name);
    builder.append(stateful);
    return builder.toHashCode();
  }

  /**
   * The name that the widget class should be given.
   */
  public void setName(String name) {
    this.name = name;
  }

  /**
   * True if a StatefulWidget should be created.
   */
  public void setStateful(boolean stateful) {
    this.stateful = stateful;
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("name", name);
    jsonObject.addProperty("stateful", stateful);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("name=");
    builder.append(name + ", ");
    builder.append("stateful=");
    builder.append(stateful);
    builder.append("]");
    return builder.toString();
  }

}
