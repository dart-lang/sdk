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
 * Information about an analysis context.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class ContextData {

  public static final ContextData[] EMPTY_ARRAY = new ContextData[0];

  public static final List<ContextData> EMPTY_LIST = List.of();

  /**
   * The name of the context.
   */
  private final String name;

  /**
   * Explicitly analyzed files.
   */
  private final int explicitFileCount;

  /**
   * Implicitly analyzed files.
   */
  private final int implicitFileCount;

  /**
   * The number of work items in the queue.
   */
  private final int workItemQueueLength;

  /**
   * Exceptions associated with cache entries.
   */
  private final List<String> cacheEntryExceptions;

  /**
   * Constructor for {@link ContextData}.
   */
  public ContextData(String name, int explicitFileCount, int implicitFileCount, int workItemQueueLength, List<String> cacheEntryExceptions) {
    this.name = name;
    this.explicitFileCount = explicitFileCount;
    this.implicitFileCount = implicitFileCount;
    this.workItemQueueLength = workItemQueueLength;
    this.cacheEntryExceptions = cacheEntryExceptions;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof ContextData) {
      ContextData other = (ContextData) obj;
      return
        Objects.equals(other.name, name) &&
        other.explicitFileCount == explicitFileCount &&
        other.implicitFileCount == implicitFileCount &&
        other.workItemQueueLength == workItemQueueLength &&
        Objects.equals(other.cacheEntryExceptions, cacheEntryExceptions);
    }
    return false;
  }

  public static ContextData fromJson(JsonObject jsonObject) {
    String name = jsonObject.get("name").getAsString();
    int explicitFileCount = jsonObject.get("explicitFileCount").getAsInt();
    int implicitFileCount = jsonObject.get("implicitFileCount").getAsInt();
    int workItemQueueLength = jsonObject.get("workItemQueueLength").getAsInt();
    List<String> cacheEntryExceptions = JsonUtilities.decodeStringList(jsonObject.get("cacheEntryExceptions").getAsJsonArray());
    return new ContextData(name, explicitFileCount, implicitFileCount, workItemQueueLength, cacheEntryExceptions);
  }

  public static List<ContextData> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    List<ContextData> list = new ArrayList<>(jsonArray.size());
    for (final JsonElement element : jsonArray) {
      list.add(fromJson(element.getAsJsonObject()));
    }
    return list;
  }

  /**
   * Exceptions associated with cache entries.
   */
  public List<String> getCacheEntryExceptions() {
    return cacheEntryExceptions;
  }

  /**
   * Explicitly analyzed files.
   */
  public int getExplicitFileCount() {
    return explicitFileCount;
  }

  /**
   * Implicitly analyzed files.
   */
  public int getImplicitFileCount() {
    return implicitFileCount;
  }

  /**
   * The name of the context.
   */
  public String getName() {
    return name;
  }

  /**
   * The number of work items in the queue.
   */
  public int getWorkItemQueueLength() {
    return workItemQueueLength;
  }

  @Override
  public int hashCode() {
    return Objects.hash(
      name,
      explicitFileCount,
      implicitFileCount,
      workItemQueueLength,
      cacheEntryExceptions
    );
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("name", name);
    jsonObject.addProperty("explicitFileCount", explicitFileCount);
    jsonObject.addProperty("implicitFileCount", implicitFileCount);
    jsonObject.addProperty("workItemQueueLength", workItemQueueLength);
    JsonArray jsonArrayCacheEntryExceptions = new JsonArray();
    for (String elt : cacheEntryExceptions) {
      jsonArrayCacheEntryExceptions.add(new JsonPrimitive(elt));
    }
    jsonObject.add("cacheEntryExceptions", jsonArrayCacheEntryExceptions);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("name=");
    builder.append(name + ", ");
    builder.append("explicitFileCount=");
    builder.append(explicitFileCount + ", ");
    builder.append("implicitFileCount=");
    builder.append(implicitFileCount + ", ");
    builder.append("workItemQueueLength=");
    builder.append(workItemQueueLength + ", ");
    builder.append("cacheEntryExceptions=");
    builder.append(StringUtils.join(cacheEntryExceptions, ", "));
    builder.append("]");
    return builder.toString();
  }

}
