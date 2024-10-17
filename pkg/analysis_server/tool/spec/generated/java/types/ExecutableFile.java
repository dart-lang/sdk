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
 * A description of an executable file.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class ExecutableFile {

  public static final ExecutableFile[] EMPTY_ARRAY = new ExecutableFile[0];

  public static final List<ExecutableFile> EMPTY_LIST = List.of();

  /**
   * The path of the executable file.
   */
  private final String file;

  /**
   * The kind of the executable file.
   */
  private final String kind;

  /**
   * Constructor for {@link ExecutableFile}.
   */
  public ExecutableFile(String file, String kind) {
    this.file = file;
    this.kind = kind;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof ExecutableFile) {
      ExecutableFile other = (ExecutableFile) obj;
      return
        Objects.equals(other.file, file) &&
        Objects.equals(other.kind, kind);
    }
    return false;
  }

  public static ExecutableFile fromJson(JsonObject jsonObject) {
    String file = jsonObject.get("file").getAsString();
    String kind = jsonObject.get("kind").getAsString();
    return new ExecutableFile(file, kind);
  }

  public static List<ExecutableFile> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    List<ExecutableFile> list = new ArrayList<>(jsonArray.size());
    for (final JsonElement element : jsonArray) {
      list.add(fromJson(element.getAsJsonObject()));
    }
    return list;
  }

  /**
   * The path of the executable file.
   */
  public String getFile() {
    return file;
  }

  /**
   * The kind of the executable file.
   */
  public String getKind() {
    return kind;
  }

  @Override
  public int hashCode() {
    return Objects.hash(
      file,
      kind
    );
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("file", file);
    jsonObject.addProperty("kind", kind);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("file=");
    builder.append(file + ", ");
    builder.append("kind=");
    builder.append(kind);
    builder.append("]");
    return builder.toString();
  }

}
