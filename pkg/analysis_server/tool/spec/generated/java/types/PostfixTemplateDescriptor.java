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
 * The description of a postfix completion template.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class PostfixTemplateDescriptor {

  public static final PostfixTemplateDescriptor[] EMPTY_ARRAY = new PostfixTemplateDescriptor[0];

  public static final List<PostfixTemplateDescriptor> EMPTY_LIST = Lists.newArrayList();

  /**
   * The template name, shown in the UI.
   */
  private final String name;

  /**
   * The unique template key, not shown in the UI.
   */
  private final String key;

  /**
   * A short example of the transformation performed when the template is applied.
   */
  private final String example;

  /**
   * Constructor for {@link PostfixTemplateDescriptor}.
   */
  public PostfixTemplateDescriptor(String name, String key, String example) {
    this.name = name;
    this.key = key;
    this.example = example;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof PostfixTemplateDescriptor) {
      PostfixTemplateDescriptor other = (PostfixTemplateDescriptor) obj;
      return
        ObjectUtilities.equals(other.name, name) &&
        ObjectUtilities.equals(other.key, key) &&
        ObjectUtilities.equals(other.example, example);
    }
    return false;
  }

  public static PostfixTemplateDescriptor fromJson(JsonObject jsonObject) {
    String name = jsonObject.get("name").getAsString();
    String key = jsonObject.get("key").getAsString();
    String example = jsonObject.get("example").getAsString();
    return new PostfixTemplateDescriptor(name, key, example);
  }

  public static List<PostfixTemplateDescriptor> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<PostfixTemplateDescriptor> list = new ArrayList<PostfixTemplateDescriptor>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * A short example of the transformation performed when the template is applied.
   */
  public String getExample() {
    return example;
  }

  /**
   * The unique template key, not shown in the UI.
   */
  public String getKey() {
    return key;
  }

  /**
   * The template name, shown in the UI.
   */
  public String getName() {
    return name;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(name);
    builder.append(key);
    builder.append(example);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("name", name);
    jsonObject.addProperty("key", key);
    jsonObject.addProperty("example", example);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("name=");
    builder.append(name + ", ");
    builder.append("key=");
    builder.append(key + ", ");
    builder.append("example=");
    builder.append(example);
    builder.append("]");
    return builder.toString();
  }

}
