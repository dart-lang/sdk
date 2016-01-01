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
 * A description of a member that is being overridden.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class OverriddenMember {

  public static final OverriddenMember[] EMPTY_ARRAY = new OverriddenMember[0];

  public static final List<OverriddenMember> EMPTY_LIST = Lists.newArrayList();

  /**
   * The element that is being overridden.
   */
  private final Element element;

  /**
   * The name of the class in which the member is defined.
   */
  private final String className;

  /**
   * Constructor for {@link OverriddenMember}.
   */
  public OverriddenMember(Element element, String className) {
    this.element = element;
    this.className = className;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof OverriddenMember) {
      OverriddenMember other = (OverriddenMember) obj;
      return
        ObjectUtilities.equals(other.element, element) &&
        ObjectUtilities.equals(other.className, className);
    }
    return false;
  }

  public static OverriddenMember fromJson(JsonObject jsonObject) {
    Element element = Element.fromJson(jsonObject.get("element").getAsJsonObject());
    String className = jsonObject.get("className").getAsString();
    return new OverriddenMember(element, className);
  }

  public static List<OverriddenMember> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<OverriddenMember> list = new ArrayList<OverriddenMember>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * The name of the class in which the member is defined.
   */
  public String getClassName() {
    return className;
  }

  /**
   * The element that is being overridden.
   */
  public Element getElement() {
    return element;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(element);
    builder.append(className);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.add("element", element.toJson());
    jsonObject.addProperty("className", className);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("element=");
    builder.append(element + ", ");
    builder.append("className=");
    builder.append(className);
    builder.append("]");
    return builder.toString();
  }

}
