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
public class RenameOptions extends RefactoringOptions {

  public static final RenameOptions[] EMPTY_ARRAY = new RenameOptions[0];

  public static final List<RenameOptions> EMPTY_LIST = Lists.newArrayList();

  /**
   * The name that the element should have after the refactoring.
   */
  private String newName;

  /**
   * Constructor for {@link RenameOptions}.
   */
  public RenameOptions(String newName) {
    this.newName = newName;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof RenameOptions) {
      RenameOptions other = (RenameOptions) obj;
      return
        ObjectUtilities.equals(other.newName, newName);
    }
    return false;
  }

  public static RenameOptions fromJson(JsonObject jsonObject) {
    String newName = jsonObject.get("newName").getAsString();
    return new RenameOptions(newName);
  }

  public static List<RenameOptions> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<RenameOptions> list = new ArrayList<RenameOptions>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * The name that the element should have after the refactoring.
   */
  public String getNewName() {
    return newName;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(newName);
    return builder.toHashCode();
  }

  /**
   * The name that the element should have after the refactoring.
   */
  public void setNewName(String newName) {
    this.newName = newName;
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("newName", newName);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("newName=");
    builder.append(newName);
    builder.append("]");
    return builder.toString();
  }

}
