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
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class MoveFileOptions extends RefactoringOptions {

  public static final MoveFileOptions[] EMPTY_ARRAY = new MoveFileOptions[0];

  public static final List<MoveFileOptions> EMPTY_LIST = Lists.newArrayList();

  /**
   * The new file path to which the given file is being moved.
   */
  private String newFile;

  /**
   * Constructor for {@link MoveFileOptions}.
   */
  public MoveFileOptions(String newFile) {
    this.newFile = newFile;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof MoveFileOptions) {
      MoveFileOptions other = (MoveFileOptions) obj;
      return
        ObjectUtilities.equals(other.newFile, newFile);
    }
    return false;
  }

  public static MoveFileOptions fromJson(JsonObject jsonObject) {
    String newFile = jsonObject.get("newFile").getAsString();
    return new MoveFileOptions(newFile);
  }

  public static List<MoveFileOptions> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<MoveFileOptions> list = new ArrayList<MoveFileOptions>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * The new file path to which the given file is being moved.
   */
  public String getNewFile() {
    return newFile;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(newFile);
    return builder.toHashCode();
  }

  /**
   * The new file path to which the given file is being moved.
   */
  public void setNewFile(String newFile) {
    this.newFile = newFile;
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("newFile", newFile);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("newFile=");
    builder.append(newFile);
    builder.append("]");
    return builder.toString();
  }

}
