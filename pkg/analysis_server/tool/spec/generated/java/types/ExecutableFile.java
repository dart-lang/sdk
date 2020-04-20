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
import java.util.List;
import java.util.Map;
import com.google.common.collect.Lists;
import com.google.dart.server.utilities.general.JsonUtilities;
import com.google.dart.server.utilities.general.ObjectUtilities;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonPrimitive;
import org.apache.commons.lang3.builder.HashCodeBuilder;
import java.util.ArrayList;
import java.util.Iterator;
import org.apache.commons.lang3.StringUtils;

/**
 * A description of an executable file.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class ExecutableFile {

  public static final ExecutableFile[] EMPTY_ARRAY = new ExecutableFile[0];

  public static final List<ExecutableFile> EMPTY_LIST = Lists.newArrayList();

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
        ObjectUtilities.equals(other.file, file) &&
        ObjectUtilities.equals(other.kind, kind);
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
    ArrayList<ExecutableFile> list = new ArrayList<ExecutableFile>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
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
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(file);
    builder.append(kind);
    return builder.toHashCode();
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
