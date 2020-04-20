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
 * A label that is associated with a range of code that may be useful to render at the end of the
 * range to aid code readability. For example, a constructor call that spans multiple lines may
 * result in a closing label to allow the constructor type/name to be rendered alongside the
 * closing parenthesis.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class ClosingLabel {

  public static final ClosingLabel[] EMPTY_ARRAY = new ClosingLabel[0];

  public static final List<ClosingLabel> EMPTY_LIST = Lists.newArrayList();

  /**
   * The offset of the construct being labelled.
   */
  private final int offset;

  /**
   * The length of the whole construct to be labelled.
   */
  private final int length;

  /**
   * The label associated with this range that should be displayed to the user.
   */
  private final String label;

  /**
   * Constructor for {@link ClosingLabel}.
   */
  public ClosingLabel(int offset, int length, String label) {
    this.offset = offset;
    this.length = length;
    this.label = label;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof ClosingLabel) {
      ClosingLabel other = (ClosingLabel) obj;
      return
        other.offset == offset &&
        other.length == length &&
        ObjectUtilities.equals(other.label, label);
    }
    return false;
  }

  public static ClosingLabel fromJson(JsonObject jsonObject) {
    int offset = jsonObject.get("offset").getAsInt();
    int length = jsonObject.get("length").getAsInt();
    String label = jsonObject.get("label").getAsString();
    return new ClosingLabel(offset, length, label);
  }

  public static List<ClosingLabel> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<ClosingLabel> list = new ArrayList<ClosingLabel>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * The label associated with this range that should be displayed to the user.
   */
  public String getLabel() {
    return label;
  }

  /**
   * The length of the whole construct to be labelled.
   */
  public int getLength() {
    return length;
  }

  /**
   * The offset of the construct being labelled.
   */
  public int getOffset() {
    return offset;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(offset);
    builder.append(length);
    builder.append(label);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("offset", offset);
    jsonObject.addProperty("length", length);
    jsonObject.addProperty("label", label);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("offset=");
    builder.append(offset + ", ");
    builder.append("length=");
    builder.append(length + ", ");
    builder.append("label=");
    builder.append(label);
    builder.append("]");
    return builder.toString();
  }

}
