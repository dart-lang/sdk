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
public class InlineMethodOptions extends RefactoringOptions {

  public static final InlineMethodOptions[] EMPTY_ARRAY = new InlineMethodOptions[0];

  public static final List<InlineMethodOptions> EMPTY_LIST = Lists.newArrayList();

  /**
   * True if the method being inlined should be removed. It is an error if this field is true and
   * inlineAll is false.
   */
  private boolean deleteSource;

  /**
   * True if all invocations of the method should be inlined, or false if only the invocation site
   * used to create this refactoring should be inlined.
   */
  private boolean inlineAll;

  /**
   * Constructor for {@link InlineMethodOptions}.
   */
  public InlineMethodOptions(boolean deleteSource, boolean inlineAll) {
    this.deleteSource = deleteSource;
    this.inlineAll = inlineAll;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof InlineMethodOptions) {
      InlineMethodOptions other = (InlineMethodOptions) obj;
      return
        other.deleteSource == deleteSource &&
        other.inlineAll == inlineAll;
    }
    return false;
  }

  public static InlineMethodOptions fromJson(JsonObject jsonObject) {
    boolean deleteSource = jsonObject.get("deleteSource").getAsBoolean();
    boolean inlineAll = jsonObject.get("inlineAll").getAsBoolean();
    return new InlineMethodOptions(deleteSource, inlineAll);
  }

  public static List<InlineMethodOptions> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<InlineMethodOptions> list = new ArrayList<InlineMethodOptions>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * True if the method being inlined should be removed. It is an error if this field is true and
   * inlineAll is false.
   */
  public boolean deleteSource() {
    return deleteSource;
  }

  /**
   * True if all invocations of the method should be inlined, or false if only the invocation site
   * used to create this refactoring should be inlined.
   */
  public boolean inlineAll() {
    return inlineAll;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(deleteSource);
    builder.append(inlineAll);
    return builder.toHashCode();
  }

  /**
   * True if the method being inlined should be removed. It is an error if this field is true and
   * inlineAll is false.
   */
  public void setDeleteSource(boolean deleteSource) {
    this.deleteSource = deleteSource;
  }

  /**
   * True if all invocations of the method should be inlined, or false if only the invocation site
   * used to create this refactoring should be inlined.
   */
  public void setInlineAll(boolean inlineAll) {
    this.inlineAll = inlineAll;
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("deleteSource", deleteSource);
    jsonObject.addProperty("inlineAll", inlineAll);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("deleteSource=");
    builder.append(deleteSource + ", ");
    builder.append("inlineAll=");
    builder.append(inlineAll);
    builder.append("]");
    return builder.toString();
  }

}
