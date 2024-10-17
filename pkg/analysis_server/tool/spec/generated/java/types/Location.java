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
 * A location (character range) within a file.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class Location {

  public static final Location[] EMPTY_ARRAY = new Location[0];

  public static final List<Location> EMPTY_LIST = List.of();

  /**
   * The file containing the range.
   */
  private final String file;

  /**
   * The offset of the range.
   */
  private final int offset;

  /**
   * The length of the range.
   */
  private final int length;

  /**
   * The one-based index of the line containing the first character of the range.
   */
  private final int startLine;

  /**
   * The one-based index of the column containing the first character of the range.
   */
  private final int startColumn;

  /**
   * The one-based index of the line containing the character immediately following the range.
   */
  private final Integer endLine;

  /**
   * The one-based index of the column containing the character immediately following the range.
   */
  private final Integer endColumn;

  /**
   * Constructor for {@link Location}.
   */
  public Location(String file, int offset, int length, int startLine, int startColumn, Integer endLine, Integer endColumn) {
    this.file = file;
    this.offset = offset;
    this.length = length;
    this.startLine = startLine;
    this.startColumn = startColumn;
    this.endLine = endLine;
    this.endColumn = endColumn;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof Location) {
      Location other = (Location) obj;
      return
        Objects.equals(other.file, file) &&
        other.offset == offset &&
        other.length == length &&
        other.startLine == startLine &&
        other.startColumn == startColumn &&
        Objects.equals(other.endLine, endLine) &&
        Objects.equals(other.endColumn, endColumn);
    }
    return false;
  }

  public static Location fromJson(JsonObject jsonObject) {
    String file = jsonObject.get("file").getAsString();
    int offset = jsonObject.get("offset").getAsInt();
    int length = jsonObject.get("length").getAsInt();
    int startLine = jsonObject.get("startLine").getAsInt();
    int startColumn = jsonObject.get("startColumn").getAsInt();
    Integer endLine = jsonObject.get("endLine") == null ? null : jsonObject.get("endLine").getAsInt();
    Integer endColumn = jsonObject.get("endColumn") == null ? null : jsonObject.get("endColumn").getAsInt();
    return new Location(file, offset, length, startLine, startColumn, endLine, endColumn);
  }

  public static List<Location> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    List<Location> list = new ArrayList<>(jsonArray.size());
    for (final JsonElement element : jsonArray) {
      list.add(fromJson(element.getAsJsonObject()));
    }
    return list;
  }

  /**
   * The one-based index of the column containing the character immediately following the range.
   */
  public Integer getEndColumn() {
    return endColumn;
  }

  /**
   * The one-based index of the line containing the character immediately following the range.
   */
  public Integer getEndLine() {
    return endLine;
  }

  /**
   * The file containing the range.
   */
  public String getFile() {
    return file;
  }

  /**
   * The length of the range.
   */
  public int getLength() {
    return length;
  }

  /**
   * The offset of the range.
   */
  public int getOffset() {
    return offset;
  }

  /**
   * The one-based index of the column containing the first character of the range.
   */
  public int getStartColumn() {
    return startColumn;
  }

  /**
   * The one-based index of the line containing the first character of the range.
   */
  public int getStartLine() {
    return startLine;
  }

  @Override
  public int hashCode() {
    return Objects.hash(
      file,
      offset,
      length,
      startLine,
      startColumn,
      endLine,
      endColumn
    );
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("file", file);
    jsonObject.addProperty("offset", offset);
    jsonObject.addProperty("length", length);
    jsonObject.addProperty("startLine", startLine);
    jsonObject.addProperty("startColumn", startColumn);
    if (endLine != null) {
      jsonObject.addProperty("endLine", endLine);
    }
    if (endColumn != null) {
      jsonObject.addProperty("endColumn", endColumn);
    }
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("file=");
    builder.append(file + ", ");
    builder.append("offset=");
    builder.append(offset + ", ");
    builder.append("length=");
    builder.append(length + ", ");
    builder.append("startLine=");
    builder.append(startLine + ", ");
    builder.append("startColumn=");
    builder.append(startColumn + ", ");
    builder.append("endLine=");
    builder.append(endLine + ", ");
    builder.append("endColumn=");
    builder.append(endColumn);
    builder.append("]");
    return builder.toString();
  }

}
