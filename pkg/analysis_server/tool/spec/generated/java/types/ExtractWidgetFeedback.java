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
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class ExtractWidgetFeedback extends RefactoringFeedback {

  public static final ExtractWidgetFeedback[] EMPTY_ARRAY = new ExtractWidgetFeedback[0];

  public static final List<ExtractWidgetFeedback> EMPTY_LIST = Lists.newArrayList();

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
    ArrayList<ExtractWidgetFeedback> list = new ArrayList<ExtractWidgetFeedback>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    return builder.toHashCode();
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
