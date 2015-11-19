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
 * A location (character range) within a file.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class Location {

  public static final Location[] EMPTY_ARRAY = new Location[0];

  public static final List<Location> EMPTY_LIST = Lists.newArrayList();

  /**
   * The file containing the range.
   */
  private final String file;

  /**
   * The offset of the range.
   */
  private final int offset;

  /**
   * The length of the range.
   */
  private final int length;

  /**
   * The one-based index of the line containing the first character of the range.
   */
  private final int startLine;

  /**
   * The one-based index of the column containing the first character of the range.
   */
  private final int startColumn;

  /**
   * Constructor for {@link Location}.
   */
  public Location(String file, int offset, int length, int startLine, int startColumn) {
    this.file = file;
    this.offset = offset;
    this.length = length;
    this.startLine = startLine;
    this.startColumn = startColumn;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof Location) {
      Location other = (Location) obj;
      return
        ObjectUtilities.equals(other.file, file) &&
        other.offset == offset &&
        other.length == length &&
        other.startLine == startLine &&
        other.startColumn == startColumn;
    }
    return false;
  }

  public static Location fromJson(JsonObject jsonObject) {
    String file = jsonObject.get("file").getAsString();
    int offset = jsonObject.get("offset").getAsInt();
    int length = jsonObject.get("length").getAsInt();
    int startLine = jsonObject.get("startLine").getAsInt();
    int startColumn = jsonObject.get("startColumn").getAsInt();
    return new Location(file, offset, length, startLine, startColumn);
  }

  public static List<Location> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<Location> list = new ArrayList<Location>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * The file containing the range.
   */
  public String getFile() {
    return file;
  }

  /**
   * The length of the range.
   */
  public int getLength() {
    return length;
  }

  /**
   * The offset of the range.
   */
  public int getOffset() {
    return offset;
  }

  /**
   * The one-based index of the column containing the first character of the range.
   */
  public int getStartColumn() {
    return startColumn;
  }

  /**
   * The one-based index of the line containing the first character of the range.
   */
  public int getStartLine() {
    return startLine;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(file);
    builder.append(offset);
    builder.append(length);
    builder.append(startLine);
    builder.append(startColumn);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("file", file);
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
    builder.append("file=");
    builder.append(file + ", ");
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
