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
 * A description of a class that is implemented or extended.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class ImplementedClass {

  public static final ImplementedClass[] EMPTY_ARRAY = new ImplementedClass[0];

  public static final List<ImplementedClass> EMPTY_LIST = Lists.newArrayList();

  /**
   * The offset of the name of the implemented class.
   */
  private final int offset;

  /**
   * The length of the name of the implemented class.
   */
  private final int length;

  /**
   * Constructor for {@link ImplementedClass}.
   */
  public ImplementedClass(int offset, int length) {
    this.offset = offset;
    this.length = length;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof ImplementedClass) {
      ImplementedClass other = (ImplementedClass) obj;
      return
        other.offset == offset &&
        other.length == length;
    }
    return false;
  }

  public static ImplementedClass fromJson(JsonObject jsonObject) {
    int offset = jsonObject.get("offset").getAsInt();
    int length = jsonObject.get("length").getAsInt();
    return new ImplementedClass(offset, length);
  }

  public static List<ImplementedClass> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<ImplementedClass> list = new ArrayList<ImplementedClass>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * The length of the name of the implemented class.
   */
  public int getLength() {
    return length;
  }

  /**
   * The offset of the name of the implemented class.
   */
  public int getOffset() {
    return offset;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(offset);
    builder.append(length);
    return builder.toHashCode();
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
