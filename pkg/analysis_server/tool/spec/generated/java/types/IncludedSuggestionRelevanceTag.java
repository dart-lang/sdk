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
 * Each AvailableSuggestion can specify zero or more tags in the field relevanceTags, so that when
 * the included tag is equal to one of the relevanceTags, the suggestion is given higher relevance
 * than the whole IncludedSuggestionSet.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class IncludedSuggestionRelevanceTag {

  public static final IncludedSuggestionRelevanceTag[] EMPTY_ARRAY = new IncludedSuggestionRelevanceTag[0];

  public static final List<IncludedSuggestionRelevanceTag> EMPTY_LIST = Lists.newArrayList();

  /**
   * The opaque value of the tag.
   */
  private final AvailableSuggestionRelevanceTag tag;

  /**
   * The relevance of the completion suggestions that match this tag, where a higher number indicates
   * a higher relevance.
   */
  private final int relevance;

  /**
   * Constructor for {@link IncludedSuggestionRelevanceTag}.
   */
  public IncludedSuggestionRelevanceTag(AvailableSuggestionRelevanceTag tag, int relevance) {
    this.tag = tag;
    this.relevance = relevance;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof IncludedSuggestionRelevanceTag) {
      IncludedSuggestionRelevanceTag other = (IncludedSuggestionRelevanceTag) obj;
      return
        ObjectUtilities.equals(other.tag, tag) &&
        other.relevance == relevance;
    }
    return false;
  }

  public static IncludedSuggestionRelevanceTag fromJson(JsonObject jsonObject) {
    AvailableSuggestionRelevanceTag tag = AvailableSuggestionRelevanceTag.fromJson(jsonObject.get("tag").getAsJsonObject());
    int relevance = jsonObject.get("relevance").getAsInt();
    return new IncludedSuggestionRelevanceTag(tag, relevance);
  }

  public static List<IncludedSuggestionRelevanceTag> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<IncludedSuggestionRelevanceTag> list = new ArrayList<IncludedSuggestionRelevanceTag>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * The relevance of the completion suggestions that match this tag, where a higher number indicates
   * a higher relevance.
   */
  public int getRelevance() {
    return relevance;
  }

  /**
   * The opaque value of the tag.
   */
  public AvailableSuggestionRelevanceTag getTag() {
    return tag;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(tag);
    builder.append(relevance);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.add("tag", tag.toJson());
    jsonObject.addProperty("relevance", relevance);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("tag=");
    builder.append(tag + ", ");
    builder.append("relevance=");
    builder.append(relevance);
    builder.append("]");
    return builder.toString();
  }

}
