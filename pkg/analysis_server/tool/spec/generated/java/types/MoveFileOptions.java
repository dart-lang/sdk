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
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class MoveFileOptions extends RefactoringOptions {

  public static final MoveFileOptions[] EMPTY_ARRAY = new MoveFileOptions[0];

  public static final List<MoveFileOptions> EMPTY_LIST = List.of();

  /**
   * The new file path to which the given file is being moved.
   */
  private String newFile;

  /**
   * Constructor for {@link MoveFileOptions}.
   */
  public MoveFileOptions(String newFile) {
    this.newFile = newFile;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof MoveFileOptions) {
      MoveFileOptions other = (MoveFileOptions) obj;
      return
        Objects.equals(other.newFile, newFile);
    }
    return false;
  }

  public static MoveFileOptions fromJson(JsonObject jsonObject) {
    String newFile = jsonObject.get("newFile").getAsString();
    return new MoveFileOptions(newFile);
  }

  public static List<MoveFileOptions> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    List<MoveFileOptions> list = new ArrayList<>(jsonArray.size());
    for (final JsonElement element : jsonArray) {
      list.add(fromJson(element.getAsJsonObject()));
    }
    return list;
  }

  /**
   * The new file path to which the given file is being moved.
   */
  public String getNewFile() {
    return newFile;
  }

  @Override
  public int hashCode() {
    return Objects.hash(
      newFile
    );
  }

  /**
   * The new file path to which the given file is being moved.
   */
  public void setNewFile(String newFile) {
    this.newFile = newFile;
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("newFile", newFile);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("newFile=");
    builder.append(newFile);
    builder.append("]");
    return builder.toString();
  }

}
