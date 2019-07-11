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
 * A value of a property of a Flutter widget.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class FlutterWidgetPropertyValue {

  public static final FlutterWidgetPropertyValue[] EMPTY_ARRAY = new FlutterWidgetPropertyValue[0];

  public static final List<FlutterWidgetPropertyValue> EMPTY_LIST = Lists.newArrayList();

  private final Boolean boolValue;

  private final Double doubleValue;

  private final Integer intValue;

  private final String stringValue;

  private final FlutterWidgetPropertyValueEnumItem enumValue;

  /**
   * Constructor for {@link FlutterWidgetPropertyValue}.
   */
  public FlutterWidgetPropertyValue(Boolean boolValue, Double doubleValue, Integer intValue, String stringValue, FlutterWidgetPropertyValueEnumItem enumValue) {
    this.boolValue = boolValue;
    this.doubleValue = doubleValue;
    this.intValue = intValue;
    this.stringValue = stringValue;
    this.enumValue = enumValue;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof FlutterWidgetPropertyValue) {
      FlutterWidgetPropertyValue other = (FlutterWidgetPropertyValue) obj;
      return
        ObjectUtilities.equals(other.boolValue, boolValue) &&
        ObjectUtilities.equals(other.doubleValue, doubleValue) &&
        ObjectUtilities.equals(other.intValue, intValue) &&
        ObjectUtilities.equals(other.stringValue, stringValue) &&
        ObjectUtilities.equals(other.enumValue, enumValue);
    }
    return false;
  }

  public static FlutterWidgetPropertyValue fromJson(JsonObject jsonObject) {
    Boolean boolValue = jsonObject.get("boolValue") == null ? null : jsonObject.get("boolValue").getAsBoolean();
    Double doubleValue = jsonObject.get("doubleValue") == null ? null : jsonObject.get("doubleValue").getAsDouble();
    Integer intValue = jsonObject.get("intValue") == null ? null : jsonObject.get("intValue").getAsInt();
    String stringValue = jsonObject.get("stringValue") == null ? null : jsonObject.get("stringValue").getAsString();
    FlutterWidgetPropertyValueEnumItem enumValue = jsonObject.get("enumValue") == null ? null : FlutterWidgetPropertyValueEnumItem.fromJson(jsonObject.get("enumValue").getAsJsonObject());
    return new FlutterWidgetPropertyValue(boolValue, doubleValue, intValue, stringValue, enumValue);
  }

  public static List<FlutterWidgetPropertyValue> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<FlutterWidgetPropertyValue> list = new ArrayList<FlutterWidgetPropertyValue>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  public Boolean getBoolValue() {
    return boolValue;
  }

  public Double getDoubleValue() {
    return doubleValue;
  }

  public FlutterWidgetPropertyValueEnumItem getEnumValue() {
    return enumValue;
  }

  public Integer getIntValue() {
    return intValue;
  }

  public String getStringValue() {
    return stringValue;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(boolValue);
    builder.append(doubleValue);
    builder.append(intValue);
    builder.append(stringValue);
    builder.append(enumValue);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    if (boolValue != null) {
      jsonObject.addProperty("boolValue", boolValue);
    }
    if (doubleValue != null) {
      jsonObject.addProperty("doubleValue", doubleValue);
    }
    if (intValue != null) {
      jsonObject.addProperty("intValue", intValue);
    }
    if (stringValue != null) {
      jsonObject.addProperty("stringValue", stringValue);
    }
    if (enumValue != null) {
      jsonObject.add("enumValue", enumValue.toJson());
    }
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("boolValue=");
    builder.append(boolValue + ", ");
    builder.append("doubleValue=");
    builder.append(doubleValue + ", ");
    builder.append("intValue=");
    builder.append(intValue + ", ");
    builder.append("stringValue=");
    builder.append(stringValue + ", ");
    builder.append("enumValue=");
    builder.append(enumValue);
    builder.append("]");
    return builder.toString();
  }

}
