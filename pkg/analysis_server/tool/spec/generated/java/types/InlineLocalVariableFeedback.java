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
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;
import com.google.dart.server.utilities.general.JsonUtilities;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonPrimitive;

/**
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class InlineLocalVariableFeedback extends RefactoringFeedback {

  public static final List<InlineLocalVariableFeedback> EMPTY_LIST = List.of();

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
    if (obj instanceof InlineLocalVariableFeedback other) {
      return
        Objects.equals(other.name, name) &&
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
    List<InlineLocalVariableFeedback> list = new ArrayList<>(jsonArray.size());
    for (final JsonElement element : jsonArray) {
      list.add(fromJson(element.getAsJsonObject()));
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
    return Objects.hash(
      name,
      occurrences
    );
  }

  @Override
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
    builder.append(name);
    builder.append(", ");
    builder.append("occurrences=");
    builder.append(occurrences);
    builder.append("]");
    return builder.toString();
  }

}
