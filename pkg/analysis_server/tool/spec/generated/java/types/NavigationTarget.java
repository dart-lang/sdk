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
 * A description of a target to which the user can navigate.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class NavigationTarget {

  public static final NavigationTarget[] EMPTY_ARRAY = new NavigationTarget[0];

  public static final List<NavigationTarget> EMPTY_LIST = Lists.newArrayList();

  /**
   * The kind of the element.
   */
  private final String kind;

  /**
   * The index of the file (in the enclosing navigation response) to navigate to.
   */
  private final int fileIndex;

  /**
   * The offset of the region from which the user can navigate.
   */
  private final int offset;

  /**
   * The length of the region from which the user can navigate.
   */
  private final int length;

  /**
   * The one-based index of the line containing the first character of the region.
   */
  private final int startLine;

  /**
   * The one-based index of the column containing the first character of the region.
   */
  private final int startColumn;

  private String file;

  /**
   * Constructor for {@link NavigationTarget}.
   */
  public NavigationTarget(String kind, int fileIndex, int offset, int length, int startLine, int startColumn) {
    this.kind = kind;
    this.fileIndex = fileIndex;
    this.offset = offset;
    this.length = length;
    this.startLine = startLine;
    this.startColumn = startColumn;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof NavigationTarget) {
      NavigationTarget other = (NavigationTarget) obj;
      return
        ObjectUtilities.equals(other.kind, kind) &&
        other.fileIndex == fileIndex &&
        other.offset == offset &&
        other.length == length &&
        other.startLine == startLine &&
        other.startColumn == startColumn;
    }
    return false;
  }

  public static NavigationTarget fromJson(JsonObject jsonObject) {
    String kind = jsonObject.get("kind").getAsString();
    int fileIndex = jsonObject.get("fileIndex").getAsInt();
    int offset = jsonObject.get("offset").getAsInt();
    int length = jsonObject.get("length").getAsInt();
    int startLine = jsonObject.get("startLine").getAsInt();
    int startColumn = jsonObject.get("startColumn").getAsInt();
    return new NavigationTarget(kind, fileIndex, offset, length, startLine, startColumn);
  }

  public static List<NavigationTarget> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<NavigationTarget> list = new ArrayList<NavigationTarget>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  public String getFile() {
    return file;
  }

  /**
   * The index of the file (in the enclosing navigation response) to navigate to.
   */
  public int getFileIndex() {
    return fileIndex;
  }

  /**
   * The kind of the element.
   */
  public String getKind() {
    return kind;
  }

  /**
   * The length of the region from which the user can navigate.
   */
  public int getLength() {
    return length;
  }

  /**
   * The offset of the region from which the user can navigate.
   */
  public int getOffset() {
    return offset;
  }

  /**
   * The one-based index of the column containing the first character of the region.
   */
  public int getStartColumn() {
    return startColumn;
  }

  /**
   * The one-based index of the line containing the first character of the region.
   */
  public int getStartLine() {
    return startLine;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(kind);
    builder.append(fileIndex);
    builder.append(offset);
    builder.append(length);
    builder.append(startLine);
    builder.append(startColumn);
    return builder.toHashCode();
  }

  public void lookupFile(String[] allTargetFiles) {
    file = allTargetFiles[fileIndex];
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("kind", kind);
    jsonObject.addProperty("fileIndex", fileIndex);
    jsonObject.addProperty("offset", offset);
    jsonObject.addProperty("length", length);
    jsonObject.addProperty("startLine", startLine);
    jsonObject.addProperty("startColumn", startColumn);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("kind=");
    builder.append(kind + ", ");
    builder.append("fileIndex=");
    builder.append(fileIndex + ", ");
    builder.append("offset=");
    builder.append(offset + ", ");
    builder.append("length=");
    builder.append(length + ", ");
    builder.append("startLine=");
    builder.append(startLine + ", ");
    builder.append("startColumn=");
    builder.append(startColumn);
    builder.append("]");
    return builder.toString();
  }

}
