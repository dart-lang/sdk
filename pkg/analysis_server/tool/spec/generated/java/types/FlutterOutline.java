/*
 * Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
 *
 * This file has been automatically generated. Please do not edit it manually.
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
 * An node in the Flutter specific outline structure of a file.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class FlutterOutline {

  public static final FlutterOutline[] EMPTY_ARRAY = new FlutterOutline[0];

  public static final List<FlutterOutline> EMPTY_LIST = Lists.newArrayList();

  /**
   * The kind of the node.
   */
  private final String kind;

  /**
   * The offset of the first character of the element. This is different than the offset in the
   * Element, which is the offset of the name of the element. It can be used, for example, to map
   * locations in the file back to an outline.
   */
  private final int offset;

  /**
   * The length of the element.
   */
  private final int length;

  /**
   * The offset of the first character of the element code, which is neither documentation, nor
   * annotation.
   */
  private final int codeOffset;

  /**
   * The length of the element code.
   */
  private final int codeLength;

  /**
   * The text label of the node children of the node. It is provided for any
   * FlutterOutlineKind.GENERIC node, where better information is not available.
   */
  private final String label;

  /**
   * If this node is a Dart element, the description of it; omitted otherwise.
   */
  private final Element dartElement;

  /**
   * Additional attributes for this node, which might be interesting to display on the client. These
   * attributes are usually arguments for the instance creation or the invocation that created the
   * widget.
   */
  private final List<FlutterOutlineAttribute> attributes;

  /**
   * If the node creates a new class instance, or a reference to an instance, this field has the name
   * of the class.
   */
  private final String className;

  /**
   * A short text description how this node is associated with the parent node. For example "appBar"
   * or "body" in Scaffold.
   */
  private final String parentAssociationLabel;

  /**
   * If FlutterOutlineKind.VARIABLE, the name of the variable.
   */
  private final String variableName;

  /**
   * The children of the node. The field will be omitted if the node has no children.
   */
  private final List<FlutterOutline> children;

  /**
   * If the node is a widget, and it is instrumented, the unique identifier of this widget, that can
   * be used to associate rendering information with this node.
   */
  private final Integer id;

  /**
   * True if the node is a widget class, so it can potentially be rendered, even if it does not yet
   * have the rendering constructor. This field is omitted if the node is not a widget class.
   */
  private final Boolean isWidgetClass;

  /**
   * If the node is a widget class that can be rendered for IDE, the name of the constructor that
   * should be used to instantiate the widget. Empty string for default constructor. Absent if the
   * node is not a widget class that can be rendered.
   */
  private final String renderConstructor;

  /**
   * If the node is a StatefulWidget, and its state class is defined in the same file, the name of
   * the state class.
   */
  private final String stateClassName;

  /**
   * If the node is a StatefulWidget that can be rendered, and its state class is defined in the same
   * file, the offset of the state class code in the file.
   */
  private final Integer stateOffset;

  /**
   * If the node is a StatefulWidget that can be rendered, and its state class is defined in the same
   * file, the length of the state class code in the file.
   */
  private final Integer stateLength;

  /**
   * Constructor for {@link FlutterOutline}.
   */
  public FlutterOutline(String kind, int offset, int length, int codeOffset, int codeLength, String label, Element dartElement, List<FlutterOutlineAttribute> attributes, String className, String parentAssociationLabel, String variableName, List<FlutterOutline> children, Integer id, Boolean isWidgetClass, String renderConstructor, String stateClassName, Integer stateOffset, Integer stateLength) {
    this.kind = kind;
    this.offset = offset;
    this.length = length;
    this.codeOffset = codeOffset;
    this.codeLength = codeLength;
    this.label = label;
    this.dartElement = dartElement;
    this.attributes = attributes;
    this.className = className;
    this.parentAssociationLabel = parentAssociationLabel;
    this.variableName = variableName;
    this.children = children;
    this.id = id;
    this.isWidgetClass = isWidgetClass;
    this.renderConstructor = renderConstructor;
    this.stateClassName = stateClassName;
    this.stateOffset = stateOffset;
    this.stateLength = stateLength;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof FlutterOutline) {
      FlutterOutline other = (FlutterOutline) obj;
      return
        ObjectUtilities.equals(other.kind, kind) &&
        other.offset == offset &&
        other.length == length &&
        other.codeOffset == codeOffset &&
        other.codeLength == codeLength &&
        ObjectUtilities.equals(other.label, label) &&
        ObjectUtilities.equals(other.dartElement, dartElement) &&
        ObjectUtilities.equals(other.attributes, attributes) &&
        ObjectUtilities.equals(other.className, className) &&
        ObjectUtilities.equals(other.parentAssociationLabel, parentAssociationLabel) &&
        ObjectUtilities.equals(other.variableName, variableName) &&
        ObjectUtilities.equals(other.children, children) &&
        ObjectUtilities.equals(other.id, id) &&
        ObjectUtilities.equals(other.isWidgetClass, isWidgetClass) &&
        ObjectUtilities.equals(other.renderConstructor, renderConstructor) &&
        ObjectUtilities.equals(other.stateClassName, stateClassName) &&
        ObjectUtilities.equals(other.stateOffset, stateOffset) &&
        ObjectUtilities.equals(other.stateLength, stateLength);
    }
    return false;
  }

  public static FlutterOutline fromJson(JsonObject jsonObject) {
    String kind = jsonObject.get("kind").getAsString();
    int offset = jsonObject.get("offset").getAsInt();
    int length = jsonObject.get("length").getAsInt();
    int codeOffset = jsonObject.get("codeOffset").getAsInt();
    int codeLength = jsonObject.get("codeLength").getAsInt();
    String label = jsonObject.get("label") == null ? null : jsonObject.get("label").getAsString();
    Element dartElement = jsonObject.get("dartElement") == null ? null : Element.fromJson(jsonObject.get("dartElement").getAsJsonObject());
    List<FlutterOutlineAttribute> attributes = jsonObject.get("attributes") == null ? null : FlutterOutlineAttribute.fromJsonArray(jsonObject.get("attributes").getAsJsonArray());
    String className = jsonObject.get("className") == null ? null : jsonObject.get("className").getAsString();
    String parentAssociationLabel = jsonObject.get("parentAssociationLabel") == null ? null : jsonObject.get("parentAssociationLabel").getAsString();
    String variableName = jsonObject.get("variableName") == null ? null : jsonObject.get("variableName").getAsString();
    List<FlutterOutline> children = jsonObject.get("children") == null ? null : FlutterOutline.fromJsonArray(jsonObject.get("children").getAsJsonArray());
    Integer id = jsonObject.get("id") == null ? null : jsonObject.get("id").getAsInt();
    Boolean isWidgetClass = jsonObject.get("isWidgetClass") == null ? null : jsonObject.get("isWidgetClass").getAsBoolean();
    String renderConstructor = jsonObject.get("renderConstructor") == null ? null : jsonObject.get("renderConstructor").getAsString();
    String stateClassName = jsonObject.get("stateClassName") == null ? null : jsonObject.get("stateClassName").getAsString();
    Integer stateOffset = jsonObject.get("stateOffset") == null ? null : jsonObject.get("stateOffset").getAsInt();
    Integer stateLength = jsonObject.get("stateLength") == null ? null : jsonObject.get("stateLength").getAsInt();
    return new FlutterOutline(kind, offset, length, codeOffset, codeLength, label, dartElement, attributes, className, parentAssociationLabel, variableName, children, id, isWidgetClass, renderConstructor, stateClassName, stateOffset, stateLength);
  }

  public static List<FlutterOutline> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<FlutterOutline> list = new ArrayList<FlutterOutline>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * Additional attributes for this node, which might be interesting to display on the client. These
   * attributes are usually arguments for the instance creation or the invocation that created the
   * widget.
   */
  public List<FlutterOutlineAttribute> getAttributes() {
    return attributes;
  }

  /**
   * The children of the node. The field will be omitted if the node has no children.
   */
  public List<FlutterOutline> getChildren() {
    return children;
  }

  /**
   * If the node creates a new class instance, or a reference to an instance, this field has the name
   * of the class.
   */
  public String getClassName() {
    return className;
  }

  /**
   * The length of the element code.
   */
  public int getCodeLength() {
    return codeLength;
  }

  /**
   * The offset of the first character of the element code, which is neither documentation, nor
   * annotation.
   */
  public int getCodeOffset() {
    return codeOffset;
  }

  /**
   * If this node is a Dart element, the description of it; omitted otherwise.
   */
  public Element getDartElement() {
    return dartElement;
  }

  /**
   * If the node is a widget, and it is instrumented, the unique identifier of this widget, that can
   * be used to associate rendering information with this node.
   */
  public Integer getId() {
    return id;
  }

  /**
   * True if the node is a widget class, so it can potentially be rendered, even if it does not yet
   * have the rendering constructor. This field is omitted if the node is not a widget class.
   */
  public Boolean getIsWidgetClass() {
    return isWidgetClass;
  }

  /**
   * The kind of the node.
   */
  public String getKind() {
    return kind;
  }

  /**
   * The text label of the node children of the node. It is provided for any
   * FlutterOutlineKind.GENERIC node, where better information is not available.
   */
  public String getLabel() {
    return label;
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

  /**
   * A short text description how this node is associated with the parent node. For example "appBar"
   * or "body" in Scaffold.
   */
  public String getParentAssociationLabel() {
    return parentAssociationLabel;
  }

  /**
   * If the node is a widget class that can be rendered for IDE, the name of the constructor that
   * should be used to instantiate the widget. Empty string for default constructor. Absent if the
   * node is not a widget class that can be rendered.
   */
  public String getRenderConstructor() {
    return renderConstructor;
  }

  /**
   * If the node is a StatefulWidget, and its state class is defined in the same file, the name of
   * the state class.
   */
  public String getStateClassName() {
    return stateClassName;
  }

  /**
   * If the node is a StatefulWidget that can be rendered, and its state class is defined in the same
   * file, the length of the state class code in the file.
   */
  public Integer getStateLength() {
    return stateLength;
  }

  /**
   * If the node is a StatefulWidget that can be rendered, and its state class is defined in the same
   * file, the offset of the state class code in the file.
   */
  public Integer getStateOffset() {
    return stateOffset;
  }

  /**
   * If FlutterOutlineKind.VARIABLE, the name of the variable.
   */
  public String getVariableName() {
    return variableName;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(kind);
    builder.append(offset);
    builder.append(length);
    builder.append(codeOffset);
    builder.append(codeLength);
    builder.append(label);
    builder.append(dartElement);
    builder.append(attributes);
    builder.append(className);
    builder.append(parentAssociationLabel);
    builder.append(variableName);
    builder.append(children);
    builder.append(id);
    builder.append(isWidgetClass);
    builder.append(renderConstructor);
    builder.append(stateClassName);
    builder.append(stateOffset);
    builder.append(stateLength);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("kind", kind);
    jsonObject.addProperty("offset", offset);
    jsonObject.addProperty("length", length);
    jsonObject.addProperty("codeOffset", codeOffset);
    jsonObject.addProperty("codeLength", codeLength);
    if (label != null) {
      jsonObject.addProperty("label", label);
    }
    if (dartElement != null) {
      jsonObject.add("dartElement", dartElement.toJson());
    }
    if (attributes != null) {
      JsonArray jsonArrayAttributes = new JsonArray();
      for (FlutterOutlineAttribute elt : attributes) {
        jsonArrayAttributes.add(elt.toJson());
      }
      jsonObject.add("attributes", jsonArrayAttributes);
    }
    if (className != null) {
      jsonObject.addProperty("className", className);
    }
    if (parentAssociationLabel != null) {
      jsonObject.addProperty("parentAssociationLabel", parentAssociationLabel);
    }
    if (variableName != null) {
      jsonObject.addProperty("variableName", variableName);
    }
    if (children != null) {
      JsonArray jsonArrayChildren = new JsonArray();
      for (FlutterOutline elt : children) {
        jsonArrayChildren.add(elt.toJson());
      }
      jsonObject.add("children", jsonArrayChildren);
    }
    if (id != null) {
      jsonObject.addProperty("id", id);
    }
    if (isWidgetClass != null) {
      jsonObject.addProperty("isWidgetClass", isWidgetClass);
    }
    if (renderConstructor != null) {
      jsonObject.addProperty("renderConstructor", renderConstructor);
    }
    if (stateClassName != null) {
      jsonObject.addProperty("stateClassName", stateClassName);
    }
    if (stateOffset != null) {
      jsonObject.addProperty("stateOffset", stateOffset);
    }
    if (stateLength != null) {
      jsonObject.addProperty("stateLength", stateLength);
    }
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("kind=");
    builder.append(kind + ", ");
    builder.append("offset=");
    builder.append(offset + ", ");
    builder.append("length=");
    builder.append(length + ", ");
    builder.append("codeOffset=");
    builder.append(codeOffset + ", ");
    builder.append("codeLength=");
    builder.append(codeLength + ", ");
    builder.append("label=");
    builder.append(label + ", ");
    builder.append("dartElement=");
    builder.append(dartElement + ", ");
    builder.append("attributes=");
    builder.append(StringUtils.join(attributes, ", ") + ", ");
    builder.append("className=");
    builder.append(className + ", ");
    builder.append("parentAssociationLabel=");
    builder.append(parentAssociationLabel + ", ");
    builder.append("variableName=");
    builder.append(variableName + ", ");
    builder.append("children=");
    builder.append(StringUtils.join(children, ", ") + ", ");
    builder.append("id=");
    builder.append(id + ", ");
    builder.append("isWidgetClass=");
    builder.append(isWidgetClass + ", ");
    builder.append("renderConstructor=");
    builder.append(renderConstructor + ", ");
    builder.append("stateClassName=");
    builder.append(stateClassName + ", ");
    builder.append("stateOffset=");
    builder.append(stateOffset + ", ");
    builder.append("stateLength=");
    builder.append(stateLength);
    builder.append("]");
    return builder.toString();
  }

}
