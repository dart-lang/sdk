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
 * The description of a registered assist.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class AssistDescription {

  public static final List<AssistDescription> EMPTY_LIST = List.of();

  /**
   * The ID.
   */
  private final String id;

  /**
   * The message that is presented to the user, to carry out this assist.
   */
  private final String message;

  /**
   * Constructor for {@link AssistDescription}.
   */
  public AssistDescription(String id, String message) {
    this.id = id;
    this.message = message;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof AssistDescription other) {
      return
        Objects.equals(other.id, id) &&
        Objects.equals(other.message, message);
    }
    return false;
  }

  public static AssistDescription fromJson(JsonObject jsonObject) {
    String id = jsonObject.get("id").getAsString();
    String message = jsonObject.get("message").getAsString();
    return new AssistDescription(id, message);
  }

  public static List<AssistDescription> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    List<AssistDescription> list = new ArrayList<>(jsonArray.size());
    for (final JsonElement element : jsonArray) {
      list.add(fromJson(element.getAsJsonObject()));
    }
    return list;
  }

  /**
   * The ID.
   */
  public String getId() {
    return id;
  }

  /**
   * The message that is presented to the user, to carry out this assist.
   */
  public String getMessage() {
    return message;
  }

  @Override
  public int hashCode() {
    return Objects.hash(
      id,
      message
    );
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("id", id);
    jsonObject.addProperty("message", message);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("id=");
    builder.append(id);
    builder.append(", ");
    builder.append("message=");
    builder.append(message);
    builder.append("]");
    return builder.toString();
  }

}
