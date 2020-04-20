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
 * An editor for a property of a Flutter widget.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class FlutterWidgetPropertyEditor {

  public static final FlutterWidgetPropertyEditor[] EMPTY_ARRAY = new FlutterWidgetPropertyEditor[0];

  public static final List<FlutterWidgetPropertyEditor> EMPTY_LIST = Lists.newArrayList();

  private final String kind;

  private final List<FlutterWidgetPropertyValueEnumItem> enumItems;

  /**
   * Constructor for {@link FlutterWidgetPropertyEditor}.
   */
  public FlutterWidgetPropertyEditor(String kind, List<FlutterWidgetPropertyValueEnumItem> enumItems) {
    this.kind = kind;
    this.enumItems = enumItems;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof FlutterWidgetPropertyEditor) {
      FlutterWidgetPropertyEditor other = (FlutterWidgetPropertyEditor) obj;
      return
        ObjectUtilities.equals(other.kind, kind) &&
        ObjectUtilities.equals(other.enumItems, enumItems);
    }
    return false;
  }

  public static FlutterWidgetPropertyEditor fromJson(JsonObject jsonObject) {
    String kind = jsonObject.get("kind").getAsString();
    List<FlutterWidgetPropertyValueEnumItem> enumItems = jsonObject.get("enumItems") == null ? null : FlutterWidgetPropertyValueEnumItem.fromJsonArray(jsonObject.get("enumItems").getAsJsonArray());
    return new FlutterWidgetPropertyEditor(kind, enumItems);
  }

  public static List<FlutterWidgetPropertyEditor> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<FlutterWidgetPropertyEditor> list = new ArrayList<FlutterWidgetPropertyEditor>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  public List<FlutterWidgetPropertyValueEnumItem> getEnumItems() {
    return enumItems;
  }

  public String getKind() {
    return kind;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(kind);
    builder.append(enumItems);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("kind", kind);
    if (enumItems != null) {
      JsonArray jsonArrayEnumItems = new JsonArray();
      for (FlutterWidgetPropertyValueEnumItem elt : enumItems) {
        jsonArrayEnumItems.add(elt.toJson());
      }
      jsonObject.add("enumItems", jsonArrayEnumItems);
    }
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("kind=");
    builder.append(kind + ", ");
    builder.append("enumItems=");
    builder.append(StringUtils.join(enumItems, ", "));
    builder.append("]");
    return builder.toString();
  }

}
