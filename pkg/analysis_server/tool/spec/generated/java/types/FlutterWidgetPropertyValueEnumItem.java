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
 * An item of an enumeration in a general sense - actual enum value, or a static field in a class.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class FlutterWidgetPropertyValueEnumItem {

  public static final FlutterWidgetPropertyValueEnumItem[] EMPTY_ARRAY = new FlutterWidgetPropertyValueEnumItem[0];

  public static final List<FlutterWidgetPropertyValueEnumItem> EMPTY_LIST = Lists.newArrayList();

  /**
   * The URI of the library containing the className. When the enum item is passed back, this will
   * allow the server to import the corresponding library if necessary.
   */
  private final String libraryUri;

  /**
   * The name of the class or enum.
   */
  private final String className;

  /**
   * The name of the field in the enumeration, or the static field in the class.
   */
  private final String name;

  /**
   * The documentation to show to the user. Omitted if the server does not know the documentation,
   * e.g. because the corresponding field is not documented.
   */
  private final String documentation;

  /**
   * Constructor for {@link FlutterWidgetPropertyValueEnumItem}.
   */
  public FlutterWidgetPropertyValueEnumItem(String libraryUri, String className, String name, String documentation) {
    this.libraryUri = libraryUri;
    this.className = className;
    this.name = name;
    this.documentation = documentation;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof FlutterWidgetPropertyValueEnumItem) {
      FlutterWidgetPropertyValueEnumItem other = (FlutterWidgetPropertyValueEnumItem) obj;
      return
        ObjectUtilities.equals(other.libraryUri, libraryUri) &&
        ObjectUtilities.equals(other.className, className) &&
        ObjectUtilities.equals(other.name, name) &&
        ObjectUtilities.equals(other.documentation, documentation);
    }
    return false;
  }

  public static FlutterWidgetPropertyValueEnumItem fromJson(JsonObject jsonObject) {
    String libraryUri = jsonObject.get("libraryUri").getAsString();
    String className = jsonObject.get("className").getAsString();
    String name = jsonObject.get("name").getAsString();
    String documentation = jsonObject.get("documentation") == null ? null : jsonObject.get("documentation").getAsString();
    return new FlutterWidgetPropertyValueEnumItem(libraryUri, className, name, documentation);
  }

  public static List<FlutterWidgetPropertyValueEnumItem> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<FlutterWidgetPropertyValueEnumItem> list = new ArrayList<FlutterWidgetPropertyValueEnumItem>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * The name of the class or enum.
   */
  public String getClassName() {
    return className;
  }

  /**
   * The documentation to show to the user. Omitted if the server does not know the documentation,
   * e.g. because the corresponding field is not documented.
   */
  public String getDocumentation() {
    return documentation;
  }

  /**
   * The URI of the library containing the className. When the enum item is passed back, this will
   * allow the server to import the corresponding library if necessary.
   */
  public String getLibraryUri() {
    return libraryUri;
  }

  /**
   * The name of the field in the enumeration, or the static field in the class.
   */
  public String getName() {
    return name;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(libraryUri);
    builder.append(className);
    builder.append(name);
    builder.append(documentation);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("libraryUri", libraryUri);
    jsonObject.addProperty("className", className);
    jsonObject.addProperty("name", name);
    if (documentation != null) {
      jsonObject.addProperty("documentation", documentation);
    }
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("libraryUri=");
    builder.append(libraryUri + ", ");
    builder.append("className=");
    builder.append(className + ", ");
    builder.append("name=");
    builder.append(name + ", ");
    builder.append("documentation=");
    builder.append(documentation);
    builder.append("]");
    return builder.toString();
  }

}
