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
 * The description of a registered fix.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class FixDescription {

  public static final List<FixDescription> EMPTY_LIST = List.of();

  /**
   * The ID.
   */
  private final String id;

  /**
   * The message that is presented to the user, to carry out this fix.
   */
  private final String message;

  /**
   * The IDs of the diagnostic codes with which this fix was registered.
   */
  private final List<String> codes;

  /**
   * Constructor for {@link FixDescription}.
   */
  public FixDescription(String id, String message, List<String> codes) {
    this.id = id;
    this.message = message;
    this.codes = codes;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof FixDescription other) {
      return
        Objects.equals(other.id, id) &&
        Objects.equals(other.message, message) &&
        Objects.equals(other.codes, codes);
    }
    return false;
  }

  public static FixDescription fromJson(JsonObject jsonObject) {
    String id = jsonObject.get("id").getAsString();
    String message = jsonObject.get("message").getAsString();
    List<String> codes = JsonUtilities.decodeStringList(jsonObject.get("codes").getAsJsonArray());
    return new FixDescription(id, message, codes);
  }

  public static List<FixDescription> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    List<FixDescription> list = new ArrayList<>(jsonArray.size());
    for (final JsonElement element : jsonArray) {
      list.add(fromJson(element.getAsJsonObject()));
    }
    return list;
  }

  /**
   * The IDs of the diagnostic codes with which this fix was registered.
   */
  public List<String> getCodes() {
    return codes;
  }

  /**
   * The ID.
   */
  public String getId() {
    return id;
  }

  /**
   * The message that is presented to the user, to carry out this fix.
   */
  public String getMessage() {
    return message;
  }

  @Override
  public int hashCode() {
    return Objects.hash(
      id,
      message,
      codes
    );
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("id", id);
    jsonObject.addProperty("message", message);
    JsonArray jsonArrayCodes = new JsonArray();
    for (String elt : codes) {
      jsonArrayCodes.add(new JsonPrimitive(elt));
    }
    jsonObject.add("codes", jsonArrayCodes);
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
    builder.append(", ");
    builder.append("codes=");
    builder.append(codes.stream().map(String::valueOf).collect(Collectors.joining(", ")));
    builder.append("]");
    return builder.toString();
  }

}
