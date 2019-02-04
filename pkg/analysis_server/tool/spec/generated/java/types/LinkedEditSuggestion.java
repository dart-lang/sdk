/*
 * Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
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
 * A suggestion of a value that could be used to replace all of the linked edit regions in a
 * LinkedEditGroup.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class LinkedEditSuggestion {

  public static final LinkedEditSuggestion[] EMPTY_ARRAY = new LinkedEditSuggestion[0];

  public static final List<LinkedEditSuggestion> EMPTY_LIST = Lists.newArrayList();

  /**
   * The value that could be used to replace all of the linked edit regions.
   */
  private final String value;

  /**
   * The kind of value being proposed.
   */
  private final String kind;

  /**
   * Constructor for {@link LinkedEditSuggestion}.
   */
  public LinkedEditSuggestion(String value, String kind) {
    this.value = value;
    this.kind = kind;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof LinkedEditSuggestion) {
      LinkedEditSuggestion other = (LinkedEditSuggestion) obj;
      return
        ObjectUtilities.equals(other.value, value) &&
        ObjectUtilities.equals(other.kind, kind);
    }
    return false;
  }

  public static LinkedEditSuggestion fromJson(JsonObject jsonObject) {
    String value = jsonObject.get("value").getAsString();
    String kind = jsonObject.get("kind").getAsString();
    return new LinkedEditSuggestion(value, kind);
  }

  public static List<LinkedEditSuggestion> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<LinkedEditSuggestion> list = new ArrayList<LinkedEditSuggestion>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * The kind of value being proposed.
   */
  public String getKind() {
    return kind;
  }

  /**
   * The value that could be used to replace all of the linked edit regions.
   */
  public String getValue() {
    return value;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(value);
    builder.append(kind);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("value", value);
    jsonObject.addProperty("kind", kind);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("value=");
    builder.append(value + ", ");
    builder.append("kind=");
    builder.append(kind);
    builder.append("]");
    return builder.toString();
  }

}
