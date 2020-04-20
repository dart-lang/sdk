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
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class InlineLocalVariableFeedback extends RefactoringFeedback {

  public static final InlineLocalVariableFeedback[] EMPTY_ARRAY = new InlineLocalVariableFeedback[0];

  public static final List<InlineLocalVariableFeedback> EMPTY_LIST = Lists.newArrayList();

  /**
   * The name of the variable being inlined.
   */
  private final String name;

  /**
   * The number of times the variable occurs.
   */
  private final int occurrences;

  /**
   * Constructor for {@link InlineLocalVariableFeedback}.
   */
  public InlineLocalVariableFeedback(String name, int occurrences) {
    this.name = name;
    this.occurrences = occurrences;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof InlineLocalVariableFeedback) {
      InlineLocalVariableFeedback other = (InlineLocalVariableFeedback) obj;
      return
        ObjectUtilities.equals(other.name, name) &&
        other.occurrences == occurrences;
    }
    return false;
  }

  public static InlineLocalVariableFeedback fromJson(JsonObject jsonObject) {
    String name = jsonObject.get("name").getAsString();
    int occurrences = jsonObject.get("occurrences").getAsInt();
    return new InlineLocalVariableFeedback(name, occurrences);
  }

  public static List<InlineLocalVariableFeedback> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<InlineLocalVariableFeedback> list = new ArrayList<InlineLocalVariableFeedback>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * The name of the variable being inlined.
   */
  public String getName() {
    return name;
  }

  /**
   * The number of times the variable occurs.
   */
  public int getOccurrences() {
    return occurrences;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(name);
    builder.append(occurrences);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("name", name);
    jsonObject.addProperty("occurrences", occurrences);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("name=");
    builder.append(name + ", ");
    builder.append("occurrences=");
    builder.append(occurrences);
    builder.append("]");
    return builder.toString();
  }

}
