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
 * A list of fixes associated with a specific error.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class AnalysisErrorFixes {

  public static final AnalysisErrorFixes[] EMPTY_ARRAY = new AnalysisErrorFixes[0];

  public static final List<AnalysisErrorFixes> EMPTY_LIST = Lists.newArrayList();

  /**
   * The error with which the fixes are associated.
   */
  private final AnalysisError error;

  /**
   * The fixes associated with the error.
   */
  private final List<SourceChange> fixes;

  /**
   * Constructor for {@link AnalysisErrorFixes}.
   */
  public AnalysisErrorFixes(AnalysisError error, List<SourceChange> fixes) {
    this.error = error;
    this.fixes = fixes;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof AnalysisErrorFixes) {
      AnalysisErrorFixes other = (AnalysisErrorFixes) obj;
      return
        ObjectUtilities.equals(other.error, error) &&
        ObjectUtilities.equals(other.fixes, fixes);
    }
    return false;
  }

  public static AnalysisErrorFixes fromJson(JsonObject jsonObject) {
    AnalysisError error = AnalysisError.fromJson(jsonObject.get("error").getAsJsonObject());
    List<SourceChange> fixes = SourceChange.fromJsonArray(jsonObject.get("fixes").getAsJsonArray());
    return new AnalysisErrorFixes(error, fixes);
  }

  public static List<AnalysisErrorFixes> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<AnalysisErrorFixes> list = new ArrayList<AnalysisErrorFixes>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * The error with which the fixes are associated.
   */
  public AnalysisError getError() {
    return error;
  }

  /**
   * The fixes associated with the error.
   */
  public List<SourceChange> getFixes() {
    return fixes;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(error);
    builder.append(fixes);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.add("error", error.toJson());
    JsonArray jsonArrayFixes = new JsonArray();
    for (SourceChange elt : fixes) {
      jsonArrayFixes.add(elt.toJson());
    }
    jsonObject.add("fixes", jsonArrayFixes);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("error=");
    builder.append(error + ", ");
    builder.append("fixes=");
    builder.append(StringUtils.join(fixes, ", "));
    builder.append("]");
    return builder.toString();
  }

}
