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
 * A position within a file.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class Position {

  public static final Position[] EMPTY_ARRAY = new Position[0];

  public static final List<Position> EMPTY_LIST = List.of();

  /**
   * The file containing the position.
   */
  private final String file;

  /**
   * The offset of the position.
   */
  private final int offset;

  /**
   * Constructor for {@link Position}.
   */
  public Position(String file, int offset) {
    this.file = file;
    this.offset = offset;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof Position) {
      Position other = (Position) obj;
      return
        Objects.equals(other.file, file) &&
        other.offset == offset;
    }
    return false;
  }

  public static Position fromJson(JsonObject jsonObject) {
    String file = jsonObject.get("file").getAsString();
    int offset = jsonObject.get("offset").getAsInt();
    return new Position(file, offset);
  }

  public static List<Position> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    List<Position> list = new ArrayList<>(jsonArray.size());
    for (final JsonElement element : jsonArray) {
      list.add(fromJson(element.getAsJsonObject()));
    }
    return list;
  }

  /**
   * The file containing the position.
   */
  public String getFile() {
    return file;
  }

  /**
   * The offset of the position.
   */
  public int getOffset() {
    return offset;
  }

  @Override
  public int hashCode() {
    return Objects.hash(
      file,
      offset
    );
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("file", file);
    jsonObject.addProperty("offset", offset);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("file=");
    builder.append(file + ", ");
    builder.append("offset=");
    builder.append(offset);
    builder.append("]");
    return builder.toString();
  }

}
