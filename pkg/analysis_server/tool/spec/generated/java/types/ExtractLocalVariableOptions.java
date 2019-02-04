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
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class ExtractLocalVariableOptions extends RefactoringOptions {

  public static final ExtractLocalVariableOptions[] EMPTY_ARRAY = new ExtractLocalVariableOptions[0];

  public static final List<ExtractLocalVariableOptions> EMPTY_LIST = Lists.newArrayList();

  /**
   * The name that the local variable should be given.
   */
  private String name;

  /**
   * True if all occurrences of the expression within the scope in which the variable will be defined
   * should be replaced by a reference to the local variable. The expression used to initiate the
   * refactoring will always be replaced.
   */
  private boolean extractAll;

  /**
   * Constructor for {@link ExtractLocalVariableOptions}.
   */
  public ExtractLocalVariableOptions(String name, boolean extractAll) {
    this.name = name;
    this.extractAll = extractAll;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof ExtractLocalVariableOptions) {
      ExtractLocalVariableOptions other = (ExtractLocalVariableOptions) obj;
      return
        ObjectUtilities.equals(other.name, name) &&
        other.extractAll == extractAll;
    }
    return false;
  }

  public static ExtractLocalVariableOptions fromJson(JsonObject jsonObject) {
    String name = jsonObject.get("name").getAsString();
    boolean extractAll = jsonObject.get("extractAll").getAsBoolean();
    return new ExtractLocalVariableOptions(name, extractAll);
  }

  public static List<ExtractLocalVariableOptions> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<ExtractLocalVariableOptions> list = new ArrayList<ExtractLocalVariableOptions>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * True if all occurrences of the expression within the scope in which the variable will be defined
   * should be replaced by a reference to the local variable. The expression used to initiate the
   * refactoring will always be replaced.
   */
  public boolean extractAll() {
    return extractAll;
  }

  /**
   * The name that the local variable should be given.
   */
  public String getName() {
    return name;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(name);
    builder.append(extractAll);
    return builder.toHashCode();
  }

  /**
   * True if all occurrences of the expression within the scope in which the variable will be defined
   * should be replaced by a reference to the local variable. The expression used to initiate the
   * refactoring will always be replaced.
   */
  public void setExtractAll(boolean extractAll) {
    this.extractAll = extractAll;
  }

  /**
   * The name that the local variable should be given.
   */
  public void setName(String name) {
    this.name = name;
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("name", name);
    jsonObject.addProperty("extractAll", extractAll);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("name=");
    builder.append(name + ", ");
    builder.append("extractAll=");
    builder.append(extractAll);
    builder.append("]");
    return builder.toString();
  }

}
