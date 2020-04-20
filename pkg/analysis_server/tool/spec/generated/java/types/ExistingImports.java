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
 * Information about all existing imports in a library.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class ExistingImports {

  public static final ExistingImports[] EMPTY_ARRAY = new ExistingImports[0];

  public static final List<ExistingImports> EMPTY_LIST = Lists.newArrayList();

  /**
   * The set of all unique imported elements for all imports.
   */
  private final ImportedElementSet elements;

  /**
   * The list of imports in the library.
   */
  private final List<ExistingImport> imports;

  /**
   * Constructor for {@link ExistingImports}.
   */
  public ExistingImports(ImportedElementSet elements, List<ExistingImport> imports) {
    this.elements = elements;
    this.imports = imports;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof ExistingImports) {
      ExistingImports other = (ExistingImports) obj;
      return
        ObjectUtilities.equals(other.elements, elements) &&
        ObjectUtilities.equals(other.imports, imports);
    }
    return false;
  }

  public static ExistingImports fromJson(JsonObject jsonObject) {
    ImportedElementSet elements = ImportedElementSet.fromJson(jsonObject.get("elements").getAsJsonObject());
    List<ExistingImport> imports = ExistingImport.fromJsonArray(jsonObject.get("imports").getAsJsonArray());
    return new ExistingImports(elements, imports);
  }

  public static List<ExistingImports> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<ExistingImports> list = new ArrayList<ExistingImports>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * The set of all unique imported elements for all imports.
   */
  public ImportedElementSet getElements() {
    return elements;
  }

  /**
   * The list of imports in the library.
   */
  public List<ExistingImport> getImports() {
    return imports;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(elements);
    builder.append(imports);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.add("elements", elements.toJson());
    JsonArray jsonArrayImports = new JsonArray();
    for (ExistingImport elt : imports) {
      jsonArrayImports.add(elt.toJson());
    }
    jsonObject.add("imports", jsonArrayImports);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("elements=");
    builder.append(elements + ", ");
    builder.append("imports=");
    builder.append(StringUtils.join(imports, ", "));
    builder.append("]");
    return builder.toString();
  }

}
