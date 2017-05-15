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
 * An node in the outline structure of a file.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class Outline {

  public static final Outline[] EMPTY_ARRAY = new Outline[0];

  public static final List<Outline> EMPTY_LIST = Lists.newArrayList();

  /**
   * A description of the element represented by this node.
   */
  private Element element;

  /**
   * The offset of the first character of the element. This is different than the offset in the
   * Element, which is the offset of the name of the element. It can be used, for example, to map
   * locations in the file back to an outline.
   */
  private int offset;

  /**
   * The length of the element.
   */
  private int length;

  private final Outline parent;

  private List<Outline> children;

  /**
   * Constructor for {@link Outline}.
   */
  public Outline(Outline parent, Element element, int offset, int length) {
    this.parent = parent;
    this.element = element;
    this.offset = offset;
    this.length = length;
  }

  public boolean containsInclusive(int x) {
    return offset <= x && x <= offset + length;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof Outline) {
      Outline other = (Outline) obj;
      return
        ObjectUtilities.equals(other.element, element) &&
        other.offset == offset &&
        other.length == length &&
        ObjectUtilities.equals(other.children, children);
    }
    return false;
  }

  public static Outline fromJson(Outline parent, JsonObject outlineObject) {
    JsonObject elementObject = outlineObject.get("element").getAsJsonObject();
    Element element = Element.fromJson(elementObject);
    int offset = outlineObject.get("offset").getAsInt();
    int length = outlineObject.get("length").getAsInt();

    // create outline object
    Outline outline = new Outline(parent, element, offset, length);

    // compute children recursively
    List<Outline> childrenList = Lists.newArrayList();
    JsonElement childrenJsonArray = outlineObject.get("children");
    if (childrenJsonArray instanceof JsonArray) {
      Iterator<JsonElement> childrenElementIterator = ((JsonArray) childrenJsonArray).iterator();
      while (childrenElementIterator.hasNext()) {
        JsonObject childObject = childrenElementIterator.next().getAsJsonObject();
        childrenList.add(fromJson(outline, childObject));
      }
    }
    outline.setChildren(childrenList);
    return outline;
  }

  public Outline getParent() {
    return parent;
  }

  /**
   * The children of the node. The field will be omitted if the node has no children.
   */
  public List<Outline> getChildren() {
    return children;
  }

  /**
   * A description of the element represented by this node.
   */
  public Element getElement() {
    return element;
  }

  /**
   * The length of the element.
   */
  public int getLength() {
    return length;
  }

  /**
   * The offset of the first character of the element. This is different than the offset in the
   * Element, which is the offset of the name of the element. It can be used, for example, to map
   * locations in the file back to an outline.
   */
  public int getOffset() {
    return offset;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(element);
    builder.append(offset);
    builder.append(length);
    builder.append(children);
    return builder.toHashCode();
  }

  /**
   * The children of the node. The field will be omitted if the node has no children.
   */
  public void setChildren(List<Outline> children) {
    this.children = children;
  }

  /**
   * A description of the element represented by this node.
   */
  public void setElement(Element element) {
    this.element = element;
  }

  /**
   * The length of the element.
   */
  public void setLength(int length) {
    this.length = length;
  }

  /**
   * The offset of the first character of the element. This is different than the offset in the
   * Element, which is the offset of the name of the element. It can be used, for example, to map
   * locations in the file back to an outline.
   */
  public void setOffset(int offset) {
    this.offset = offset;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("element=");
    builder.append(element + ", ");
    builder.append("offset=");
    builder.append(offset + ", ");
    builder.append("length=");
    builder.append(length + ", ");
    builder.append("children=");
    builder.append(StringUtils.join(children, ", "));
    builder.append("]");
    return builder.toString();
  }

}
