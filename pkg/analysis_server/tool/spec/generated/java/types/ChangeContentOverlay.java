/*
 * Copyright (c) 2014, the Dart project authors.
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
package com.google.dart.server.generated.types;

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
 * A directive to modify an existing file content overlay. One or more ranges of text are deleted
 * from the old file content overlay and replaced with new text.
 *
 * The edits are applied in the order in which they occur in the list. This means that the offset
 * of each edit must be correct under the assumption that all previous edits have been applied.
 *
 * It is an error to use this overlay on a file that does not yet have a file content overlay or
 * that has had its overlay removed via RemoveContentOverlay.
 *
 * If any of the edits cannot be applied due to its offset or length being out of range, an
 * INVALID_OVERLAY_CHANGE error will be reported.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class ChangeContentOverlay {

  public static final ChangeContentOverlay[] EMPTY_ARRAY = new ChangeContentOverlay[0];

  public static final List<ChangeContentOverlay> EMPTY_LIST = Lists.newArrayList();

  private final String type;

  /**
   * The edits to be applied to the file.
   */
  private final List<SourceEdit> edits;

  /**
   * Constructor for {@link ChangeContentOverlay}.
   */
  public ChangeContentOverlay(List<SourceEdit> edits) {
    this.type = "change";
    this.edits = edits;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof ChangeContentOverlay) {
      ChangeContentOverlay other = (ChangeContentOverlay) obj;
      return
        ObjectUtilities.equals(other.type, type) &&
        ObjectUtilities.equals(other.edits, edits);
    }
    return false;
  }

  public static ChangeContentOverlay fromJson(JsonObject jsonObject) {
    String type = jsonObject.get("type").getAsString();
    List<SourceEdit> edits = SourceEdit.fromJsonArray(jsonObject.get("edits").getAsJsonArray());
    return new ChangeContentOverlay(edits);
  }

  public static List<ChangeContentOverlay> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<ChangeContentOverlay> list = new ArrayList<ChangeContentOverlay>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * The edits to be applied to the file.
   */
  public List<SourceEdit> getEdits() {
    return edits;
  }

  public String getType() {
    return type;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(type);
    builder.append(edits);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("type", type);
    JsonArray jsonArrayEdits = new JsonArray();
    for (SourceEdit elt : edits) {
      jsonArrayEdits.add(elt.toJson());
    }
    jsonObject.add("edits", jsonArrayEdits);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("type=");
    builder.append(type + ", ");
    builder.append("edits=");
    builder.append(StringUtils.join(edits, ", "));
    builder.append("]");
    return builder.toString();
  }

}
