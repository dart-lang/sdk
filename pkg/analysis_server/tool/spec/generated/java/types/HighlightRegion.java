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
 * A description of a region that could have special highlighting associated with it.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class HighlightRegion {

  public static final HighlightRegion[] EMPTY_ARRAY = new HighlightRegion[0];

  public static final List<HighlightRegion> EMPTY_LIST = Lists.newArrayList();

  /**
   * The type of highlight associated with the region.
   */
  private final String type;

  /**
   * The offset of the region to be highlighted.
   */
  private final int offset;

  /**
   * The length of the region to be highlighted.
   */
  private final int length;

  /**
   * Constructor for {@link HighlightRegion}.
   */
  public HighlightRegion(String type, int offset, int length) {
    this.type = type;
    this.offset = offset;
    this.length = length;
  }

  public boolean containsInclusive(int x) {
    return offset <= x && x <= offset + length;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof HighlightRegion) {
      HighlightRegion other = (HighlightRegion) obj;
      return
        ObjectUtilities.equals(other.type, type) &&
        other.offset == offset &&
        other.length == length;
    }
    return false;
  }

  public static HighlightRegion fromJson(JsonObject jsonObject) {
    String type = jsonObject.get("type").getAsString();
    int offset = jsonObject.get("offset").getAsInt();
    int length = jsonObject.get("length").getAsInt();
    return new HighlightRegion(type, offset, length);
  }

  public static List<HighlightRegion> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<HighlightRegion> list = new ArrayList<HighlightRegion>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * The length of the region to be highlighted.
   */
  public int getLength() {
    return length;
  }

  /**
   * The offset of the region to be highlighted.
   */
  public int getOffset() {
    return offset;
  }

  /**
   * The type of highlight associated with the region.
   */
  public String getType() {
    return type;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(type);
    builder.append(offset);
    builder.append(length);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("type", type);
    jsonObject.addProperty("offset", offset);
    jsonObject.addProperty("length", length);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("type=");
    builder.append(type + ", ");
    builder.append("offset=");
    builder.append(offset + ", ");
    builder.append("length=");
    builder.append(length);
    builder.append("]");
    return builder.toString();
  }

}
