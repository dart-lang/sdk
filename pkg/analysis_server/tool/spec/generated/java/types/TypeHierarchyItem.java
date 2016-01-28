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
 * A representation of a class in a type hierarchy.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class TypeHierarchyItem {

  public static final TypeHierarchyItem[] EMPTY_ARRAY = new TypeHierarchyItem[0];

  public static final List<TypeHierarchyItem> EMPTY_LIST = Lists.newArrayList();

  /**
   * The class element represented by this item.
   */
  private final Element classElement;

  /**
   * The name to be displayed for the class. This field will be omitted if the display name is the
   * same as the name of the element. The display name is different if there is additional type
   * information to be displayed, such as type arguments.
   */
  private final String displayName;

  /**
   * The member in the class corresponding to the member on which the hierarchy was requested. This
   * field will be omitted if the hierarchy was not requested for a member or if the class does not
   * have a corresponding member.
   */
  private final Element memberElement;

  /**
   * The index of the item representing the superclass of this class. This field will be omitted if
   * this item represents the class Object.
   */
  private final Integer superclass;

  /**
   * The indexes of the items representing the interfaces implemented by this class. The list will be
   * empty if there are no implemented interfaces.
   */
  private final int[] interfaces;

  /**
   * The indexes of the items representing the mixins referenced by this class. The list will be
   * empty if there are no classes mixed in to this class.
   */
  private final int[] mixins;

  /**
   * The indexes of the items representing the subtypes of this class. The list will be empty if
   * there are no subtypes or if this item represents a supertype of the pivot type.
   */
  private final int[] subclasses;

  /**
   * Constructor for {@link TypeHierarchyItem}.
   */
  public TypeHierarchyItem(Element classElement, String displayName, Element memberElement, Integer superclass, int[] interfaces, int[] mixins, int[] subclasses) {
    this.classElement = classElement;
    this.displayName = displayName;
    this.memberElement = memberElement;
    this.superclass = superclass;
    this.interfaces = interfaces;
    this.mixins = mixins;
    this.subclasses = subclasses;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof TypeHierarchyItem) {
      TypeHierarchyItem other = (TypeHierarchyItem) obj;
      return
        ObjectUtilities.equals(other.classElement, classElement) &&
        ObjectUtilities.equals(other.displayName, displayName) &&
        ObjectUtilities.equals(other.memberElement, memberElement) &&
        ObjectUtilities.equals(other.superclass, superclass) &&
        Arrays.equals(other.interfaces, interfaces) &&
        Arrays.equals(other.mixins, mixins) &&
        Arrays.equals(other.subclasses, subclasses);
    }
    return false;
  }

  public static TypeHierarchyItem fromJson(JsonObject jsonObject) {
    Element classElement = Element.fromJson(jsonObject.get("classElement").getAsJsonObject());
    String displayName = jsonObject.get("displayName") == null ? null : jsonObject.get("displayName").getAsString();
    Element memberElement = jsonObject.get("memberElement") == null ? null : Element.fromJson(jsonObject.get("memberElement").getAsJsonObject());
    Integer superclass = jsonObject.get("superclass") == null ? null : jsonObject.get("superclass").getAsInt();
    int[] interfaces = JsonUtilities.decodeIntArray(jsonObject.get("interfaces").getAsJsonArray());
    int[] mixins = JsonUtilities.decodeIntArray(jsonObject.get("mixins").getAsJsonArray());
    int[] subclasses = JsonUtilities.decodeIntArray(jsonObject.get("subclasses").getAsJsonArray());
    return new TypeHierarchyItem(classElement, displayName, memberElement, superclass, interfaces, mixins, subclasses);
  }

  public static List<TypeHierarchyItem> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<TypeHierarchyItem> list = new ArrayList<TypeHierarchyItem>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  public String getBestName() {
    if (displayName == null) {
      return classElement.getName();
    } else {
      return displayName;
    }
  }

  /**
   * The class element represented by this item.
   */
  public Element getClassElement() {
    return classElement;
  }

  /**
   * The name to be displayed for the class. This field will be omitted if the display name is the
   * same as the name of the element. The display name is different if there is additional type
   * information to be displayed, such as type arguments.
   */
  public String getDisplayName() {
    return displayName;
  }

  /**
   * The indexes of the items representing the interfaces implemented by this class. The list will be
   * empty if there are no implemented interfaces.
   */
  public int[] getInterfaces() {
    return interfaces;
  }

  /**
   * The member in the class corresponding to the member on which the hierarchy was requested. This
   * field will be omitted if the hierarchy was not requested for a member or if the class does not
   * have a corresponding member.
   */
  public Element getMemberElement() {
    return memberElement;
  }

  /**
   * The indexes of the items representing the mixins referenced by this class. The list will be
   * empty if there are no classes mixed in to this class.
   */
  public int[] getMixins() {
    return mixins;
  }

  /**
   * The indexes of the items representing the subtypes of this class. The list will be empty if
   * there are no subtypes or if this item represents a supertype of the pivot type.
   */
  public int[] getSubclasses() {
    return subclasses;
  }

  /**
   * The index of the item representing the superclass of this class. This field will be omitted if
   * this item represents the class Object.
   */
  public Integer getSuperclass() {
    return superclass;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(classElement);
    builder.append(displayName);
    builder.append(memberElement);
    builder.append(superclass);
    builder.append(interfaces);
    builder.append(mixins);
    builder.append(subclasses);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.add("classElement", classElement.toJson());
    if (displayName != null) {
      jsonObject.addProperty("displayName", displayName);
    }
    if (memberElement != null) {
      jsonObject.add("memberElement", memberElement.toJson());
    }
    if (superclass != null) {
      jsonObject.addProperty("superclass", superclass);
    }
    JsonArray jsonArrayInterfaces = new JsonArray();
    for (int elt : interfaces) {
      jsonArrayInterfaces.add(new JsonPrimitive(elt));
    }
    jsonObject.add("interfaces", jsonArrayInterfaces);
    JsonArray jsonArrayMixins = new JsonArray();
    for (int elt : mixins) {
      jsonArrayMixins.add(new JsonPrimitive(elt));
    }
    jsonObject.add("mixins", jsonArrayMixins);
    JsonArray jsonArraySubclasses = new JsonArray();
    for (int elt : subclasses) {
      jsonArraySubclasses.add(new JsonPrimitive(elt));
    }
    jsonObject.add("subclasses", jsonArraySubclasses);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("classElement=");
    builder.append(classElement + ", ");
    builder.append("displayName=");
    builder.append(displayName + ", ");
    builder.append("memberElement=");
    builder.append(memberElement + ", ");
    builder.append("superclass=");
    builder.append(superclass + ", ");
    builder.append("interfaces=");
    builder.append(StringUtils.join(interfaces, ", ") + ", ");
    builder.append("mixins=");
    builder.append(StringUtils.join(mixins, ", ") + ", ");
    builder.append("subclasses=");
    builder.append(StringUtils.join(subclasses, ", "));
    builder.append("]");
    return builder.toString();
  }

}
