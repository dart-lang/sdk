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
 * A collection of positions that should be linked (edited simultaneously) for the purposes of
 * updating code after a source change. For example, if a set of edits introduced a new variable
 * name, the group would contain all of the positions of the variable name so that if the client
 * wanted to let the user edit the variable name after the operation, all occurrences of the name
 * could be edited simultaneously.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class LinkedEditGroup {

  public static final LinkedEditGroup[] EMPTY_ARRAY = new LinkedEditGroup[0];

  public static final List<LinkedEditGroup> EMPTY_LIST = Lists.newArrayList();

  /**
   * The positions of the regions (after applying the relevant edits) that should be edited
   * simultaneously.
   */
  private final List<Position> positions;

  /**
   * The length of the regions that should be edited simultaneously.
   */
  private final int length;

  /**
   * Pre-computed suggestions for what every region might want to be changed to.
   */
  private final List<LinkedEditSuggestion> suggestions;

  /**
   * Constructor for {@link LinkedEditGroup}.
   */
  public LinkedEditGroup(List<Position> positions, int length, List<LinkedEditSuggestion> suggestions) {
    this.positions = positions;
    this.length = length;
    this.suggestions = suggestions;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof LinkedEditGroup) {
      LinkedEditGroup other = (LinkedEditGroup) obj;
      return
        ObjectUtilities.equals(other.positions, positions) &&
        other.length == length &&
        ObjectUtilities.equals(other.suggestions, suggestions);
    }
    return false;
  }

  public static LinkedEditGroup fromJson(JsonObject jsonObject) {
    List<Position> positions = Position.fromJsonArray(jsonObject.get("positions").getAsJsonArray());
    int length = jsonObject.get("length").getAsInt();
    List<LinkedEditSuggestion> suggestions = LinkedEditSuggestion.fromJsonArray(jsonObject.get("suggestions").getAsJsonArray());
    return new LinkedEditGroup(positions, length, suggestions);
  }

  public static List<LinkedEditGroup> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<LinkedEditGroup> list = new ArrayList<LinkedEditGroup>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * The length of the regions that should be edited simultaneously.
   */
  public int getLength() {
    return length;
  }

  /**
   * The positions of the regions (after applying the relevant edits) that should be edited
   * simultaneously.
   */
  public List<Position> getPositions() {
    return positions;
  }

  /**
   * Pre-computed suggestions for what every region might want to be changed to.
   */
  public List<LinkedEditSuggestion> getSuggestions() {
    return suggestions;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(positions);
    builder.append(length);
    builder.append(suggestions);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    JsonArray jsonArrayPositions = new JsonArray();
    for (Position elt : positions) {
      jsonArrayPositions.add(elt.toJson());
    }
    jsonObject.add("positions", jsonArrayPositions);
    jsonObject.addProperty("length", length);
    JsonArray jsonArraySuggestions = new JsonArray();
    for (LinkedEditSuggestion elt : suggestions) {
      jsonArraySuggestions.add(elt.toJson());
    }
    jsonObject.add("suggestions", jsonArraySuggestions);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("positions=");
    builder.append(StringUtils.join(positions, ", ") + ", ");
    builder.append("length=");
    builder.append(length + ", ");
    builder.append("suggestions=");
    builder.append(StringUtils.join(suggestions, ", "));
    builder.append("]");
    return builder.toString();
  }

}
