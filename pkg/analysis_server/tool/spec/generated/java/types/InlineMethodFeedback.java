/*
 * Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
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
