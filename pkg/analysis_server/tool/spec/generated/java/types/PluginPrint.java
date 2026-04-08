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
 * A message printed from a plugin with 'print'.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class PluginPrint {

  public static final List<PluginPrint> EMPTY_LIST = List.of();

  /**
   * The name of the plugin which called 'print'.
   */
  private final String pluginName;

  /**
   * The message which has been printed.
   */
  private final String message;

  /**
   * The timestamp, in milliseconds since the epoch, of when the message was requested to be printed.
   */
  private final int timestamp;

  /**
   * Constructor for {@link PluginPrint}.
   */
  public PluginPrint(String pluginName, String message, int timestamp) {
    this.pluginName = pluginName;
    this.message = message;
    this.timestamp = timestamp;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof PluginPrint other) {
      return
        Objects.equals(other.pluginName, pluginName) &&
        Objects.equals(other.message, message) &&
        other.timestamp == timestamp;
    }
    return false;
  }

  public static PluginPrint fromJson(JsonObject jsonObject) {
    String pluginName = jsonObject.get("pluginName").getAsString();
    String message = jsonObject.get("message").getAsString();
    int timestamp = jsonObject.get("timestamp").getAsInt();
    return new PluginPrint(pluginName, message, timestamp);
  }

  public static List<PluginPrint> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    List<PluginPrint> list = new ArrayList<>(jsonArray.size());
    for (final JsonElement element : jsonArray) {
      list.add(fromJson(element.getAsJsonObject()));
    }
    return list;
  }

  /**
   * The message which has been printed.
   */
  public String getMessage() {
    return message;
  }

  /**
   * The name of the plugin which called 'print'.
   */
  public String getPluginName() {
    return pluginName;
  }

  /**
   * The timestamp, in milliseconds since the epoch, of when the message was requested to be printed.
   */
  public int getTimestamp() {
    return timestamp;
  }

  @Override
  public int hashCode() {
    return Objects.hash(
      pluginName,
      message,
      timestamp
    );
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("pluginName", pluginName);
    jsonObject.addProperty("message", message);
    jsonObject.addProperty("timestamp", timestamp);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("pluginName=");
    builder.append(pluginName);
    builder.append(", ");
    builder.append("message=");
    builder.append(message);
    builder.append(", ");
    builder.append("timestamp=");
    builder.append(timestamp);
    builder.append("]");
    return builder.toString();
  }

}
