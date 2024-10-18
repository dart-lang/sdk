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
 * A description of a class member that is implemented or overridden.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class ImplementedMember {

  public static final ImplementedMember[] EMPTY_ARRAY = new ImplementedMember[0];

  public static final List<ImplementedMember> EMPTY_LIST = List.of();

  /**
   * The offset of the name of the implemented member.
   */
  private final int offset;

  /**
   * The length of the name of the implemented member.
   */
  private final int length;

  /**
   * Constructor for {@link ImplementedMember}.
   */
  public ImplementedMember(int offset, int length) {
    this.offset = offset;
    this.length = length;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof ImplementedMember) {
      ImplementedMember other = (ImplementedMember) obj;
      return
        other.offset == offset &&
        other.length == length;
    }
    return false;
  }

  public static ImplementedMember fromJson(JsonObject jsonObject) {
    int offset = jsonObject.get("offset").getAsInt();
    int length = jsonObject.get("length").getAsInt();
    return new ImplementedMember(offset, length);
  }

  public static List<ImplementedMember> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    List<ImplementedMember> list = new ArrayList<>(jsonArray.size());
    for (final JsonElement element : jsonArray) {
      list.add(fromJson(element.getAsJsonObject()));
    }
    return list;
  }

  /**
   * The length of the name of the implemented member.
   */
  public int getLength() {
    return length;
  }

  /**
   * The offset of the name of the implemented member.
   */
  public int getOffset() {
    return offset;
  }

  @Override
  public int hashCode() {
    return Objects.hash(
      offset,
      length
    );
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("offset", offset);
    jsonObject.addProperty("length", length);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("offset=");
    builder.append(offset + ", ");
    builder.append("length=");
    builder.append(length);
    builder.append("]");
    return builder.toString();
  }

}
