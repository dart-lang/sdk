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
public class ExtractWidgetFeedback extends RefactoringFeedback {

  public static final ExtractWidgetFeedback[] EMPTY_ARRAY = new ExtractWidgetFeedback[0];

  public static final List<ExtractWidgetFeedback> EMPTY_LIST = List.of();

  /**
   * Constructor for {@link ExtractWidgetFeedback}.
   */
  public ExtractWidgetFeedback() {
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof ExtractWidgetFeedback) {
      ExtractWidgetFeedback other = (ExtractWidgetFeedback) obj;
      return
        true;
    }
    return false;
  }

  public static ExtractWidgetFeedback fromJson(JsonObject jsonObject) {
    return new ExtractWidgetFeedback();
  }

  public static List<ExtractWidgetFeedback> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    List<ExtractWidgetFeedback> list = new ArrayList<>(jsonArray.size());
    for (final JsonElement element : jsonArray) {
      list.add(fromJson(element.getAsJsonObject()));
    }
    return list;
  }

  @Override
  public int hashCode() {
    return Objects.hash();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("]");
    return builder.toString();
  }

}
