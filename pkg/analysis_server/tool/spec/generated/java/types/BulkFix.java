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
 * A description of bulk fixes to a library.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class BulkFix {

  public static final BulkFix[] EMPTY_ARRAY = new BulkFix[0];

  public static final List<BulkFix> EMPTY_LIST = Lists.newArrayList();

  /**
   * The path of the library.
   */
  private final String path;

  /**
   * A list of bulk fix details.
   */
  private final List<BulkFixDetail> fixes;

  /**
   * Constructor for {@link BulkFix}.
   */
  public BulkFix(String path, List<BulkFixDetail> fixes) {
    this.path = path;
    this.fixes = fixes;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof BulkFix) {
      BulkFix other = (BulkFix) obj;
      return
        ObjectUtilities.equals(other.path, path) &&
        ObjectUtilities.equals(other.fixes, fixes);
    }
    return false;
  }

  public static BulkFix fromJson(JsonObject jsonObject) {
    String path = jsonObject.get("path").getAsString();
    List<BulkFixDetail> fixes = BulkFixDetail.fromJsonArray(jsonObject.get("fixes").getAsJsonArray());
    return new BulkFix(path, fixes);
  }

  public static List<BulkFix> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<BulkFix> list = new ArrayList<BulkFix>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * A list of bulk fix details.
   */
  public List<BulkFixDetail> getFixes() {
    return fixes;
  }

  /**
   * The path of the library.
   */
  public String getPath() {
    return path;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(path);
    builder.append(fixes);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("path", path);
    JsonArray jsonArrayFixes = new JsonArray();
    for (BulkFixDetail elt : fixes) {
      jsonArrayFixes.add(elt.toJson());
    }
    jsonObject.add("fixes", jsonArrayFixes);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("path=");
    builder.append(path + ", ");
    builder.append("fixes=");
    builder.append(StringUtils.join(fixes, ", "));
    builder.append("]");
    return builder.toString();
  }

}
