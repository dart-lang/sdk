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
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class RenameFeedback extends RefactoringFeedback {

  public static final RenameFeedback[] EMPTY_ARRAY = new RenameFeedback[0];

  public static final List<RenameFeedback> EMPTY_LIST = Lists.newArrayList();

  /**
   * The offset to the beginning of the name selected to be renamed.
   */
  private final int offset;

  /**
   * The length of the name selected to be renamed.
   */
  private final int length;

  /**
   * The human-readable description of the kind of element being renamed (such as “class” or
   * “function type alias”).
   */
  private final String elementKindName;

  /**
   * The old name of the element before the refactoring.
   */
  private final String oldName;

  /**
   * Constructor for {@link RenameFeedback}.
   */
  public RenameFeedback(int offset, int length, String elementKindName, String oldName) {
    this.offset = offset;
    this.length = length;
    this.elementKindName = elementKindName;
    this.oldName = oldName;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof RenameFeedback) {
      RenameFeedback other = (RenameFeedback) obj;
      return
        other.offset == offset &&
        other.length == length &&
        ObjectUtilities.equals(other.elementKindName, elementKindName) &&
        ObjectUtilities.equals(other.oldName, oldName);
    }
    return false;
  }

  public static RenameFeedback fromJson(JsonObject jsonObject) {
    int offset = jsonObject.get("offset").getAsInt();
    int length = jsonObject.get("length").getAsInt();
    String elementKindName = jsonObject.get("elementKindName").getAsString();
    String oldName = jsonObject.get("oldName").getAsString();
    return new RenameFeedback(offset, length, elementKindName, oldName);
  }

  public static List<RenameFeedback> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<RenameFeedback> list = new ArrayList<RenameFeedback>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * The human-readable description of the kind of element being renamed (such as “class” or
   * “function type alias”).
   */
  public String getElementKindName() {
    return elementKindName;
  }

  /**
   * The length of the name selected to be renamed.
   */
  public int getLength() {
    return length;
  }

  /**
   * The offset to the beginning of the name selected to be renamed.
   */
  public int getOffset() {
    return offset;
  }

  /**
   * The old name of the element before the refactoring.
   */
  public String getOldName() {
    return oldName;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(offset);
    builder.append(length);
    builder.append(elementKindName);
    builder.append(oldName);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("offset", offset);
    jsonObject.addProperty("length", length);
    jsonObject.addProperty("elementKindName", elementKindName);
    jsonObject.addProperty("oldName", oldName);
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
    builder.append("elementKindName=");
    builder.append(elementKindName + ", ");
    builder.append("oldName=");
    builder.append(oldName);
    builder.append("]");
    return builder.toString();
  }

}
