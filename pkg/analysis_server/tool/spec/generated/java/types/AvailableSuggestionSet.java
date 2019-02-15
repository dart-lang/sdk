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
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class AvailableSuggestionSet {

  public static final AvailableSuggestionSet[] EMPTY_ARRAY = new AvailableSuggestionSet[0];

  public static final List<AvailableSuggestionSet> EMPTY_LIST = Lists.newArrayList();

  /**
   * The id associated with the library.
   */
  private final int id;

  /**
   * The URI of the library.
   */
  private final String uri;

  private final List<AvailableSuggestion> items;

  /**
   * Constructor for {@link AvailableSuggestionSet}.
   */
  public AvailableSuggestionSet(int id, String uri, List<AvailableSuggestion> items) {
    this.id = id;
    this.uri = uri;
    this.items = items;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof AvailableSuggestionSet) {
      AvailableSuggestionSet other = (AvailableSuggestionSet) obj;
      return
        other.id == id &&
        ObjectUtilities.equals(other.uri, uri) &&
        ObjectUtilities.equals(other.items, items);
    }
    return false;
  }

  public static AvailableSuggestionSet fromJson(JsonObject jsonObject) {
    int id = jsonObject.get("id").getAsInt();
    String uri = jsonObject.get("uri").getAsString();
    List<AvailableSuggestion> items = AvailableSuggestion.fromJsonArray(jsonObject.get("items").getAsJsonArray());
    return new AvailableSuggestionSet(id, uri, items);
  }

  public static List<AvailableSuggestionSet> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<AvailableSuggestionSet> list = new ArrayList<AvailableSuggestionSet>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * The id associated with the library.
   */
  public int getId() {
    return id;
  }

  public List<AvailableSuggestion> getItems() {
    return items;
  }

  /**
   * The URI of the library.
   */
  public String getUri() {
    return uri;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(id);
    builder.append(uri);
    builder.append(items);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("id", id);
    jsonObject.addProperty("uri", uri);
    JsonArray jsonArrayItems = new JsonArray();
    for (AvailableSuggestion elt : items) {
      jsonArrayItems.add(elt.toJson());
    }
    jsonObject.add("items", jsonArrayItems);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("id=");
    builder.append(id + ", ");
    builder.append("uri=");
    builder.append(uri + ", ");
    builder.append("items=");
    builder.append(StringUtils.join(items, ", "));
    builder.append("]");
    return builder.toString();
  }

}
