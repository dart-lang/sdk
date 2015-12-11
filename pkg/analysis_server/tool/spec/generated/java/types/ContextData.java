/*
 * Copyright (c) 2015, the Dart project authors.
 *
 * Licensed under the Eclipse Public License v1.0 (the "License"); you may not use this file except
 * in compliance with the License. You may obtain a copy of the License at
 *
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License
 * is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
 * or implied. See the License for the specific language governing permissions and limitations under
 * the License.
 *
 * This file has been automatically generated.  Please do not edit it manually.
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
 * Information about an analysis context.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class ContextData {

  public static final ContextData[] EMPTY_ARRAY = new ContextData[0];

  public static final List<ContextData> EMPTY_LIST = Lists.newArrayList();

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
        ObjectUtilities.equals(other.name, name) &&
        other.explicitFileCount == explicitFileCount &&
        other.implicitFileCount == implicitFileCount &&
        other.workItemQueueLength == workItemQueueLength &&
        ObjectUtilities.equals(other.cacheEntryExceptions, cacheEntryExceptions);
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
    ArrayList<ContextData> list = new ArrayList<ContextData>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
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
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(name);
    builder.append(explicitFileCount);
    builder.append(implicitFileCount);
    builder.append(workItemQueueLength);
    builder.append(cacheEntryExceptions);
    return builder.toHashCode();
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
