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
 * A directive to remove an existing file content overlay. After processing this directive, the
 * file contents will once again be read from the file system.
 *
 * If this directive is used on a file that doesn't currently have a content overlay, it has no
 * effect.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class RemoveContentOverlay {

  public static final RemoveContentOverlay[] EMPTY_ARRAY = new RemoveContentOverlay[0];

  public static final List<RemoveContentOverlay> EMPTY_LIST = Lists.newArrayList();

  private final String type;

  /**
   * Constructor for {@link RemoveContentOverlay}.
   */
  public RemoveContentOverlay() {
    this.type = "remove";
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof RemoveContentOverlay) {
      RemoveContentOverlay other = (RemoveContentOverlay) obj;
      return
        ObjectUtilities.equals(other.type, type);
    }
    return false;
  }

  public static RemoveContentOverlay fromJson(JsonObject jsonObject) {
    String type = jsonObject.get("type").getAsString();
    return new RemoveContentOverlay();
  }

  public static List<RemoveContentOverlay> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<RemoveContentOverlay> list = new ArrayList<RemoveContentOverlay>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  public String getType() {
    return type;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(type);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("type", type);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("type=");
    builder.append(type);
    builder.append("]");
    return builder.toString();
  }

}
