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
  private final String tag;

  /**
   * The boost to the relevance of the completion suggestions that match this tag, which is added to
   * the relevance of the containing IncludedSuggestionSet.
   */
  private final int relevanceBoost;

  /**
   * Constructor for {@link IncludedSuggestionRelevanceTag}.
   */
  public IncludedSuggestionRelevanceTag(String tag, int relevanceBoost) {
    this.tag = tag;
    this.relevanceBoost = relevanceBoost;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof IncludedSuggestionRelevanceTag) {
      IncludedSuggestionRelevanceTag other = (IncludedSuggestionRelevanceTag) obj;
      return
        ObjectUtilities.equals(other.tag, tag) &&
        other.relevanceBoost == relevanceBoost;
    }
    return false;
  }

  public static IncludedSuggestionRelevanceTag fromJson(JsonObject jsonObject) {
    String tag = jsonObject.get("tag").getAsString();
    int relevanceBoost = jsonObject.get("relevanceBoost").getAsInt();
    return new IncludedSuggestionRelevanceTag(tag, relevanceBoost);
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
   * The boost to the relevance of the completion suggestions that match this tag, which is added to
   * the relevance of the containing IncludedSuggestionSet.
   */
  public int getRelevanceBoost() {
    return relevanceBoost;
  }

  /**
   * The opaque value of the tag.
   */
  public String getTag() {
    return tag;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(tag);
    builder.append(relevanceBoost);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("tag", tag);
    jsonObject.addProperty("relevanceBoost", relevanceBoost);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("tag=");
    builder.append(tag + ", ");
    builder.append("relevanceBoost=");
    builder.append(relevanceBoost);
    builder.append("]");
    return builder.toString();
  }

}
