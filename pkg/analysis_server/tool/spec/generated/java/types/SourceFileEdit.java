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
 * A description of a set of changes to a single file.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class SourceFileEdit {

  public static final SourceFileEdit[] EMPTY_ARRAY = new SourceFileEdit[0];

  public static final List<SourceFileEdit> EMPTY_LIST = Lists.newArrayList();

  /**
   * The file containing the code to be modified.
   */
  private final String file;

  /**
   * The modification stamp of the file at the moment when the change was created, in milliseconds
   * since the "Unix epoch". Will be -1 if the file did not exist and should be created. The client
   * may use this field to make sure that the file was not changed since then, so it is safe to apply
   * the change.
   */
  private final long fileStamp;

  /**
   * A list of the edits used to effect the change.
   */
  private final List<SourceEdit> edits;

  /**
   * Constructor for {@link SourceFileEdit}.
   */
  public SourceFileEdit(String file, long fileStamp, List<SourceEdit> edits) {
    this.file = file;
    this.fileStamp = fileStamp;
    this.edits = edits;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof SourceFileEdit) {
      SourceFileEdit other = (SourceFileEdit) obj;
      return
        ObjectUtilities.equals(other.file, file) &&
        other.fileStamp == fileStamp &&
        ObjectUtilities.equals(other.edits, edits);
    }
    return false;
  }

  public static SourceFileEdit fromJson(JsonObject jsonObject) {
    String file = jsonObject.get("file").getAsString();
    long fileStamp = jsonObject.get("fileStamp").getAsLong();
    List<SourceEdit> edits = SourceEdit.fromJsonArray(jsonObject.get("edits").getAsJsonArray());
    return new SourceFileEdit(file, fileStamp, edits);
  }

  public static List<SourceFileEdit> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<SourceFileEdit> list = new ArrayList<SourceFileEdit>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * A list of the edits used to effect the change.
   */
  public List<SourceEdit> getEdits() {
    return edits;
  }

  /**
   * The file containing the code to be modified.
   */
  public String getFile() {
    return file;
  }

  /**
   * The modification stamp of the file at the moment when the change was created, in milliseconds
   * since the "Unix epoch". Will be -1 if the file did not exist and should be created. The client
   * may use this field to make sure that the file was not changed since then, so it is safe to apply
   * the change.
   */
  public long getFileStamp() {
    return fileStamp;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(file);
    builder.append(fileStamp);
    builder.append(edits);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("file", file);
    jsonObject.addProperty("fileStamp", fileStamp);
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
    builder.append("file=");
    builder.append(file + ", ");
    builder.append("fileStamp=");
    builder.append(fileStamp + ", ");
    builder.append("edits=");
    builder.append(StringUtils.join(edits, ", "));
    builder.append("]");
    return builder.toString();
  }

}
