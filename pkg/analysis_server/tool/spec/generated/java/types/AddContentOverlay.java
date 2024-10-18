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
import com.google.common.collect.Lists;
import com.google.dart.server.utilities.general.JsonUtilities;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonPrimitive;
import org.apache.commons.lang3.StringUtils;

/**
 * A directive to begin overlaying the contents of a file. The supplied content will be used for
 * analysis in place of the file contents in the filesystem.
 *
 * If this directive is used on a file that already has a file content overlay, the old overlay is
 * discarded and replaced with the new one.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class AddContentOverlay {

  public static final AddContentOverlay[] EMPTY_ARRAY = new AddContentOverlay[0];

  public static final List<AddContentOverlay> EMPTY_LIST = List.of();

  private final String type;

  /**
   * The new content of the file.
   */
  private final String content;

  /**
   * Constructor for {@link AddContentOverlay}.
   */
  public AddContentOverlay(String content) {
    this.type = "add";
    this.content = content;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof AddContentOverlay) {
      AddContentOverlay other = (AddContentOverlay) obj;
      return
        Objects.equals(other.type, type) &&
        Objects.equals(other.content, content);
    }
    return false;
  }

  public static AddContentOverlay fromJson(JsonObject jsonObject) {
    String type = jsonObject.get("type").getAsString();
    String content = jsonObject.get("content").getAsString();
    return new AddContentOverlay(content);
  }

  public static List<AddContentOverlay> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    List<AddContentOverlay> list = new ArrayList<>(jsonArray.size());
    for (final JsonElement element : jsonArray) {
      list.add(fromJson(element.getAsJsonObject()));
    }
    return list;
  }

  /**
   * The new content of the file.
   */
  public String getContent() {
    return content;
  }

  public String getType() {
    return type;
  }

  @Override
  public int hashCode() {
    return Objects.hash(
      type,
      content
    );
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("type", type);
    jsonObject.addProperty("content", content);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("type=");
    builder.append(type + ", ");
    builder.append("content=");
    builder.append(content);
    builder.append("]");
    return builder.toString();
  }

}
