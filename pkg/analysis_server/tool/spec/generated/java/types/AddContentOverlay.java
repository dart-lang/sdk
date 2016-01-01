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
 * A directive to begin overlaying the contents of a file. The supplied content will be used for
 * analysis in place of the file contents in the filesystem.
 *
 * If this directive is used on a file that already has a file content overlay, the old overlay is
 * discarded and replaced with the new one.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class AddContentOverlay {

  public static final AddContentOverlay[] EMPTY_ARRAY = new AddContentOverlay[0];

  public static final List<AddContentOverlay> EMPTY_LIST = Lists.newArrayList();

  private final String type;

  /**
   * The new content of the file.
   */
  private final String content;

  /**
   * Constructor for {@link AddContentOverlay}.
   */
  public AddContentOverlay(String content) {
    this.type = "add";
    this.content = content;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof AddContentOverlay) {
      AddContentOverlay other = (AddContentOverlay) obj;
      return
        ObjectUtilities.equals(other.type, type) &&
        ObjectUtilities.equals(other.content, content);
    }
    return false;
  }

  public static AddContentOverlay fromJson(JsonObject jsonObject) {
    String type = jsonObject.get("type").getAsString();
    String content = jsonObject.get("content").getAsString();
    return new AddContentOverlay(content);
  }

  public static List<AddContentOverlay> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<AddContentOverlay> list = new ArrayList<AddContentOverlay>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * The new content of the file.
   */
  public String getContent() {
    return content;
  }

  public String getType() {
    return type;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(type);
    builder.append(content);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("type", type);
    jsonObject.addProperty("content", content);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("type=");
    builder.append(type + ", ");
    builder.append("content=");
    builder.append(content);
    builder.append("]");
    return builder.toString();
  }

}
