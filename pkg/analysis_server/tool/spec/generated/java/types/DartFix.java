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
 * A "fix" that can be specified in an edit.dartfix request.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class DartFix {

  public static final DartFix[] EMPTY_ARRAY = new DartFix[0];

  public static final List<DartFix> EMPTY_LIST = Lists.newArrayList();

  /**
   * The name of the fix.
   */
  private final String name;

  /**
   * A human readable description of the fix.
   */
  private final String description;

  /**
   * Constructor for {@link DartFix}.
   */
  public DartFix(String name, String description) {
    this.name = name;
    this.description = description;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof DartFix) {
      DartFix other = (DartFix) obj;
      return
        ObjectUtilities.equals(other.name, name) &&
        ObjectUtilities.equals(other.description, description);
    }
    return false;
  }

  public static DartFix fromJson(JsonObject jsonObject) {
    String name = jsonObject.get("name").getAsString();
    String description = jsonObject.get("description") == null ? null : jsonObject.get("description").getAsString();
    return new DartFix(name, description);
  }

  public static List<DartFix> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<DartFix> list = new ArrayList<DartFix>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * A human readable description of the fix.
   */
  public String getDescription() {
    return description;
  }

  /**
   * The name of the fix.
   */
  public String getName() {
    return name;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(name);
    builder.append(description);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("name", name);
    if (description != null) {
      jsonObject.addProperty("description", description);
    }
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("name=");
    builder.append(name + ", ");
    builder.append("description=");
    builder.append(description);
    builder.append("]");
    return builder.toString();
  }

}
