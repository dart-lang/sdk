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
 * An indication of the current state of analysis.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class AnalysisStatus {

  public static final AnalysisStatus[] EMPTY_ARRAY = new AnalysisStatus[0];

  public static final List<AnalysisStatus> EMPTY_LIST = List.of();

  /**
   * True if analysis is currently being performed.
   */
  private final boolean isAnalyzing;

  /**
   * The name of the current target of analysis. This field is omitted if analyzing is false.
   */
  private final String analysisTarget;

  /**
   * Constructor for {@link AnalysisStatus}.
   */
  public AnalysisStatus(boolean isAnalyzing, String analysisTarget) {
    this.isAnalyzing = isAnalyzing;
    this.analysisTarget = analysisTarget;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof AnalysisStatus) {
      AnalysisStatus other = (AnalysisStatus) obj;
      return
        other.isAnalyzing == isAnalyzing &&
        Objects.equals(other.analysisTarget, analysisTarget);
    }
    return false;
  }

  public static AnalysisStatus fromJson(JsonObject jsonObject) {
    boolean isAnalyzing = jsonObject.get("isAnalyzing").getAsBoolean();
    String analysisTarget = jsonObject.get("analysisTarget") == null ? null : jsonObject.get("analysisTarget").getAsString();
    return new AnalysisStatus(isAnalyzing, analysisTarget);
  }

  public static List<AnalysisStatus> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    List<AnalysisStatus> list = new ArrayList<>(jsonArray.size());
    for (final JsonElement element : jsonArray) {
      list.add(fromJson(element.getAsJsonObject()));
    }
    return list;
  }

  /**
   * The name of the current target of analysis. This field is omitted if analyzing is false.
   */
  public String getAnalysisTarget() {
    return analysisTarget;
  }

  /**
   * True if analysis is currently being performed.
   */
  public boolean isAnalyzing() {
    return isAnalyzing;
  }

  @Override
  public int hashCode() {
    return Objects.hash(
      isAnalyzing,
      analysisTarget
    );
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("isAnalyzing", isAnalyzing);
    if (analysisTarget != null) {
      jsonObject.addProperty("analysisTarget", analysisTarget);
    }
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("isAnalyzing=");
    builder.append(isAnalyzing + ", ");
    builder.append("analysisTarget=");
    builder.append(analysisTarget);
    builder.append("]");
    return builder.toString();
  }

}
