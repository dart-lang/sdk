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
 * A description of a single change to a single file.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class SourceEdit {

  public static final SourceEdit[] EMPTY_ARRAY = new SourceEdit[0];

  public static final List<SourceEdit> EMPTY_LIST = Lists.newArrayList();

  /**
   * The offset of the region to be modified.
   */
  private final int offset;

  /**
   * The length of the region to be modified.
   */
  private final int length;

  /**
   * The code that is to replace the specified region in the original code.
   */
  private final String replacement;

  /**
   * An identifier that uniquely identifies this source edit from other edits in the same response.
   * This field is omitted unless a containing structure needs to be able to identify the edit for
   * some reason.
   *
   * For example, some refactoring operations can produce edits that might not be appropriate
   * (referred to as potential edits). Such edits will have an id so that they can be referenced.
   * Edits in the same response that do not need to be referenced will not have an id.
   */
  private final String id;

  /**
   * Constructor for {@link SourceEdit}.
   */
  public SourceEdit(int offset, int length, String replacement, String id) {
    this.offset = offset;
    this.length = length;
    this.replacement = replacement;
    this.id = id;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof SourceEdit) {
      SourceEdit other = (SourceEdit) obj;
      return
        other.offset == offset &&
        other.length == length &&
        ObjectUtilities.equals(other.replacement, replacement) &&
        ObjectUtilities.equals(other.id, id);
    }
    return false;
  }

  public static SourceEdit fromJson(JsonObject jsonObject) {
    int offset = jsonObject.get("offset").getAsInt();
    int length = jsonObject.get("length").getAsInt();
    String replacement = jsonObject.get("replacement").getAsString();
    String id = jsonObject.get("id") == null ? null : jsonObject.get("id").getAsString();
    return new SourceEdit(offset, length, replacement, id);
  }

  public static List<SourceEdit> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<SourceEdit> list = new ArrayList<SourceEdit>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * An identifier that uniquely identifies this source edit from other edits in the same response.
   * This field is omitted unless a containing structure needs to be able to identify the edit for
   * some reason.
   *
   * For example, some refactoring operations can produce edits that might not be appropriate
   * (referred to as potential edits). Such edits will have an id so that they can be referenced.
   * Edits in the same response that do not need to be referenced will not have an id.
   */
  public String getId() {
    return id;
  }

  /**
   * The length of the region to be modified.
   */
  public int getLength() {
    return length;
  }

  /**
   * The offset of the region to be modified.
   */
  public int getOffset() {
    return offset;
  }

  /**
   * The code that is to replace the specified region in the original code.
   */
  public String getReplacement() {
    return replacement;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(offset);
    builder.append(length);
    builder.append(replacement);
    builder.append(id);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("offset", offset);
    jsonObject.addProperty("length", length);
    jsonObject.addProperty("replacement", replacement);
    if (id != null) {
      jsonObject.addProperty("id", id);
    }
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("offset=");
    builder.append(offset + ", ");
    builder.append("length=");
    builder.append(length + ", ");
    builder.append("replacement=");
    builder.append(replacement + ", ");
    builder.append("id=");
    builder.append(id);
    builder.append("]");
    return builder.toString();
  }

}
