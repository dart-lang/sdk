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
 * A suggestion from an edit.dartfix request.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class DartFixSuggestion {

  public static final DartFixSuggestion[] EMPTY_ARRAY = new DartFixSuggestion[0];

  public static final List<DartFixSuggestion> EMPTY_LIST = Lists.newArrayList();

  /**
   * A human readable description of the suggested change.
   */
  private final String description;

  /**
   * The location of the suggested change.
   */
  private final Location location;

  /**
   * Constructor for {@link DartFixSuggestion}.
   */
  public DartFixSuggestion(String description, Location location) {
    this.description = description;
    this.location = location;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof DartFixSuggestion) {
      DartFixSuggestion other = (DartFixSuggestion) obj;
      return
        ObjectUtilities.equals(other.description, description) &&
        ObjectUtilities.equals(other.location, location);
    }
    return false;
  }

  public static DartFixSuggestion fromJson(JsonObject jsonObject) {
    String description = jsonObject.get("description").getAsString();
    Location location = jsonObject.get("location") == null ? null : Location.fromJson(jsonObject.get("location").getAsJsonObject());
    return new DartFixSuggestion(description, location);
  }

  public static List<DartFixSuggestion> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<DartFixSuggestion> list = new ArrayList<DartFixSuggestion>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * A human readable description of the suggested change.
   */
  public String getDescription() {
    return description;
  }

  /**
   * The location of the suggested change.
   */
  public Location getLocation() {
    return location;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(description);
    builder.append(location);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("description", description);
    if (location != null) {
      jsonObject.add("location", location.toJson());
    }
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("description=");
    builder.append(description + ", ");
    builder.append("location=");
    builder.append(location);
    builder.append("]");
    return builder.toString();
  }

}
