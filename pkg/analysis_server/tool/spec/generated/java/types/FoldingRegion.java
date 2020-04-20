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
 * A description of a region that can be folded.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class FoldingRegion {

  public static final FoldingRegion[] EMPTY_ARRAY = new FoldingRegion[0];

  public static final List<FoldingRegion> EMPTY_LIST = Lists.newArrayList();

  /**
   * The kind of the region.
   */
  private final String kind;

  /**
   * The offset of the region to be folded.
   */
  private final int offset;

  /**
   * The length of the region to be folded.
   */
  private final int length;

  /**
   * Constructor for {@link FoldingRegion}.
   */
  public FoldingRegion(String kind, int offset, int length) {
    this.kind = kind;
    this.offset = offset;
    this.length = length;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof FoldingRegion) {
      FoldingRegion other = (FoldingRegion) obj;
      return
        ObjectUtilities.equals(other.kind, kind) &&
        other.offset == offset &&
        other.length == length;
    }
    return false;
  }

  public static FoldingRegion fromJson(JsonObject jsonObject) {
    String kind = jsonObject.get("kind").getAsString();
    int offset = jsonObject.get("offset").getAsInt();
    int length = jsonObject.get("length").getAsInt();
    return new FoldingRegion(kind, offset, length);
  }

  public static List<FoldingRegion> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<FoldingRegion> list = new ArrayList<FoldingRegion>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * The kind of the region.
   */
  public String getKind() {
    return kind;
  }

  /**
   * The length of the region to be folded.
   */
  public int getLength() {
    return length;
  }

  /**
   * The offset of the region to be folded.
   */
  public int getOffset() {
    return offset;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(kind);
    builder.append(offset);
    builder.append(length);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("kind", kind);
    jsonObject.addProperty("offset", offset);
    jsonObject.addProperty("length", length);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("kind=");
    builder.append(kind + ", ");
    builder.append("offset=");
    builder.append(offset + ", ");
    builder.append("length=");
    builder.append(length);
    builder.append("]");
    return builder.toString();
  }

}
