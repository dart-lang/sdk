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
 * A reference to an AvailableSuggestionSet noting that the library's members which match the kind
 * of this ref should be presented to the user.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class IncludedSuggestionSet {

  public static final IncludedSuggestionSet[] EMPTY_ARRAY = new IncludedSuggestionSet[0];

  public static final List<IncludedSuggestionSet> EMPTY_LIST = Lists.newArrayList();

  /**
   * Clients should use it to access the set of precomputed completions to be displayed to the user.
   */
  private final int id;

  /**
   * The relevance of completion suggestions from this library where a higher number indicates a
   * higher relevance.
   */
  private final int relevance;

  /**
   * The optional string that should be displayed instead of the uri of the referenced
   * AvailableSuggestionSet.
   *
   * For example libraries in the "test" directory of a package have only "file://" URIs, so are
   * usually long, and don't look nice, but actual import directives will use relative URIs, which
   * are short, so we probably want to display such relative URIs to the user.
   */
  private final String displayUri;

  /**
   * Constructor for {@link IncludedSuggestionSet}.
   */
  public IncludedSuggestionSet(int id, int relevance, String displayUri) {
    this.id = id;
    this.relevance = relevance;
    this.displayUri = displayUri;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof IncludedSuggestionSet) {
      IncludedSuggestionSet other = (IncludedSuggestionSet) obj;
      return
        other.id == id &&
        other.relevance == relevance &&
        ObjectUtilities.equals(other.displayUri, displayUri);
    }
    return false;
  }

  public static IncludedSuggestionSet fromJson(JsonObject jsonObject) {
    int id = jsonObject.get("id").getAsInt();
    int relevance = jsonObject.get("relevance").getAsInt();
    String displayUri = jsonObject.get("displayUri") == null ? null : jsonObject.get("displayUri").getAsString();
    return new IncludedSuggestionSet(id, relevance, displayUri);
  }

  public static List<IncludedSuggestionSet> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<IncludedSuggestionSet> list = new ArrayList<IncludedSuggestionSet>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * The optional string that should be displayed instead of the uri of the referenced
   * AvailableSuggestionSet.
   *
   * For example libraries in the "test" directory of a package have only "file://" URIs, so are
   * usually long, and don't look nice, but actual import directives will use relative URIs, which
   * are short, so we probably want to display such relative URIs to the user.
   */
  public String getDisplayUri() {
    return displayUri;
  }

  /**
   * Clients should use it to access the set of precomputed completions to be displayed to the user.
   */
  public int getId() {
    return id;
  }

  /**
   * The relevance of completion suggestions from this library where a higher number indicates a
   * higher relevance.
   */
  public int getRelevance() {
    return relevance;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(id);
    builder.append(relevance);
    builder.append(displayUri);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("id", id);
    jsonObject.addProperty("relevance", relevance);
    if (displayUri != null) {
      jsonObject.addProperty("displayUri", displayUri);
    }
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("id=");
    builder.append(id + ", ");
    builder.append("relevance=");
    builder.append(relevance + ", ");
    builder.append("displayUri=");
    builder.append(displayUri);
    builder.append("]");
    return builder.toString();
  }

}
