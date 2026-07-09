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

  public static final List<AddContentOverlay> EMPTY_LIST = List.of();

  private final String type;

  /**
   * The new content of the file.
   */
  private final String content;

  /**
   * An optional version number for the document. Version numbers allow the server to tag edits with
   * the version of the document they apply to which can avoid applying edits to documents that have
   * already been updated since the edits were computed.
   *
   * If version numbers are supplied with AddContentOverlay and ChangeContentOverlay, they must be
   * increasing (but not necessarily consecutive) numbers.
   */
  private final Integer version;

  /**
   * Constructor for {@link AddContentOverlay}.
   */
  public AddContentOverlay(String content, Integer version) {
    this.type = "add";
    this.content = content;
    this.version = version;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof AddContentOverlay other) {
      return
        Objects.equals(other.type, type) &&
        Objects.equals(other.content, content) &&
        Objects.equals(other.version, version);
    }
    return false;
  }

  public static AddContentOverlay fromJson(JsonObject jsonObject) {
    String type = jsonObject.get("type").getAsString();
    String content = jsonObject.get("content").getAsString();
    Integer version = jsonObject.get("version") == null ? null : jsonObject.get("version").getAsInt();
    return new AddContentOverlay(content, version);
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

  /**
   * An optional version number for the document. Version numbers allow the server to tag edits with
   * the version of the document they apply to which can avoid applying edits to documents that have
   * already been updated since the edits were computed.
   *
   * If version numbers are supplied with AddContentOverlay and ChangeContentOverlay, they must be
   * increasing (but not necessarily consecutive) numbers.
   */
  public Integer getVersion() {
    return version;
  }

  @Override
  public int hashCode() {
    return Objects.hash(
      type,
      content,
      version
    );
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("type", type);
    jsonObject.addProperty("content", content);
    if (version != null) {
      jsonObject.addProperty("version", version);
    }
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("type=");
    builder.append(type);
    builder.append(", ");
    builder.append("content=");
    builder.append(content);
    builder.append(", ");
    builder.append("version=");
    builder.append(version);
    builder.append("]");
    return builder.toString();
  }

}
