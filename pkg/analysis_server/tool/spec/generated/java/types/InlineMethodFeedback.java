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
public class InlineMethodFeedback extends RefactoringFeedback {

  public static final InlineMethodFeedback[] EMPTY_ARRAY = new InlineMethodFeedback[0];

  public static final List<InlineMethodFeedback> EMPTY_LIST = Lists.newArrayList();

  /**
   * The name of the class enclosing the method being inlined. If not a class member is being
   * inlined, this field will be absent.
   */
  private final String className;

  /**
   * The name of the method (or function) being inlined.
   */
  private final String methodName;

  /**
   * True if the declaration of the method is selected. So all references should be inlined.
   */
  private final boolean isDeclaration;

  /**
   * Constructor for {@link InlineMethodFeedback}.
   */
  public InlineMethodFeedback(String className, String methodName, boolean isDeclaration) {
    this.className = className;
    this.methodName = methodName;
    this.isDeclaration = isDeclaration;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof InlineMethodFeedback) {
      InlineMethodFeedback other = (InlineMethodFeedback) obj;
      return
        ObjectUtilities.equals(other.className, className) &&
        ObjectUtilities.equals(other.methodName, methodName) &&
        other.isDeclaration == isDeclaration;
    }
    return false;
  }

  public static InlineMethodFeedback fromJson(JsonObject jsonObject) {
    String className = jsonObject.get("className") == null ? null : jsonObject.get("className").getAsString();
    String methodName = jsonObject.get("methodName").getAsString();
    boolean isDeclaration = jsonObject.get("isDeclaration").getAsBoolean();
    return new InlineMethodFeedback(className, methodName, isDeclaration);
  }

  public static List<InlineMethodFeedback> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<InlineMethodFeedback> list = new ArrayList<InlineMethodFeedback>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * The name of the class enclosing the method being inlined. If not a class member is being
   * inlined, this field will be absent.
   */
  public String getClassName() {
    return className;
  }

  /**
   * True if the declaration of the method is selected. So all references should be inlined.
   */
  public boolean isDeclaration() {
    return isDeclaration;
  }

  /**
   * The name of the method (or function) being inlined.
   */
  public String getMethodName() {
    return methodName;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(className);
    builder.append(methodName);
    builder.append(isDeclaration);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    if (className != null) {
      jsonObject.addProperty("className", className);
    }
    jsonObject.addProperty("methodName", methodName);
    jsonObject.addProperty("isDeclaration", isDeclaration);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("className=");
    builder.append(className + ", ");
    builder.append("methodName=");
    builder.append(methodName + ", ");
    builder.append("isDeclaration=");
    builder.append(isDeclaration);
    builder.append("]");
    return builder.toString();
  }

}
