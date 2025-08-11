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
 * A directive to modify an existing file content overlay. One or more ranges of text are deleted
 * from the old file content overlay and replaced with new text.
 *
 * The edits are applied in the order in which they occur in the list. This means that the offset
 * of each edit must be correct under the assumption that all previous edits have been applied.
 *
 * It is an error to use this overlay on a file that does not yet have a file content overlay or
 * that has had its overlay removed via RemoveContentOverlay.
 *
 * If any of the edits cannot be applied due to its offset or length being out of range, an
 * <code>INVALID_OVERLAY_CHANGE</code> error will be reported.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class ChangeContentOverlay {

  public static final List<ChangeContentOverlay> EMPTY_LIST = List.of();

  private final String type;

  /**
   * The edits to be applied to the file.
   */
  private final List<SourceEdit> edits;

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
   * Constructor for {@link ChangeContentOverlay}.
   */
  public ChangeContentOverlay(List<SourceEdit> edits, Integer version) {
    this.type = "change";
    this.edits = edits;
    this.version = version;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof ChangeContentOverlay other) {
      return
        Objects.equals(other.type, type) &&
        Objects.equals(other.edits, edits) &&
        Objects.equals(other.version, version);
    }
    return false;
  }

  public static ChangeContentOverlay fromJson(JsonObject jsonObject) {
    String type = jsonObject.get("type").getAsString();
    List<SourceEdit> edits = SourceEdit.fromJsonArray(jsonObject.get("edits").getAsJsonArray());
    Integer version = jsonObject.get("version") == null ? null : jsonObject.get("version").getAsInt();
    return new ChangeContentOverlay(edits, version);
  }

  public static List<ChangeContentOverlay> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    List<ChangeContentOverlay> list = new ArrayList<>(jsonArray.size());
    for (final JsonElement element : jsonArray) {
      list.add(fromJson(element.getAsJsonObject()));
    }
    return list;
  }

  /**
   * The edits to be applied to the file.
   */
  public List<SourceEdit> getEdits() {
    return edits;
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
      edits,
      version
    );
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("type", type);
    JsonArray jsonArrayEdits = new JsonArray();
    for (SourceEdit elt : edits) {
      jsonArrayEdits.add(elt.toJson());
    }
    jsonObject.add("edits", jsonArrayEdits);
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
    builder.append("edits=");
    builder.append(edits.stream().map(String::valueOf).collect(Collectors.joining(", ")));
    builder.append(", ");
    builder.append("version=");
    builder.append(version);
    builder.append("]");
    return builder.toString();
  }

}
