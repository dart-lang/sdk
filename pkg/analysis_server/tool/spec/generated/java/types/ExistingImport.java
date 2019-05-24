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
 * Information about an existing import, with elements that it provides.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class ExistingImport {

  public static final ExistingImport[] EMPTY_ARRAY = new ExistingImport[0];

  public static final List<ExistingImport> EMPTY_LIST = Lists.newArrayList();

  /**
   * The URI of the imported library. It is an index in the strings field, in the enclosing
   * ExistingImports and its ImportedElementSet object.
   */
  private final int uri;

  /**
   * The list of indexes of elements, in the enclosing ExistingImports object.
   */
  private final int[] elements;

  /**
   * Constructor for {@link ExistingImport}.
   */
  public ExistingImport(int uri, int[] elements) {
    this.uri = uri;
    this.elements = elements;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof ExistingImport) {
      ExistingImport other = (ExistingImport) obj;
      return
        other.uri == uri &&
        Arrays.equals(other.elements, elements);
    }
    return false;
  }

  public static ExistingImport fromJson(JsonObject jsonObject) {
    int uri = jsonObject.get("uri").getAsInt();
    int[] elements = JsonUtilities.decodeIntArray(jsonObject.get("elements").getAsJsonArray());
    return new ExistingImport(uri, elements);
  }

  public static List<ExistingImport> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<ExistingImport> list = new ArrayList<ExistingImport>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * The list of indexes of elements, in the enclosing ExistingImports object.
   */
  public int[] getElements() {
    return elements;
  }

  /**
   * The URI of the imported library. It is an index in the strings field, in the enclosing
   * ExistingImports and its ImportedElementSet object.
   */
  public int getUri() {
    return uri;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(uri);
    builder.append(elements);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("uri", uri);
    JsonArray jsonArrayElements = new JsonArray();
    for (int elt : elements) {
      jsonArrayElements.add(new JsonPrimitive(elt));
    }
    jsonObject.add("elements", jsonArrayElements);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("uri=");
    builder.append(uri + ", ");
    builder.append("elements=");
    builder.append(StringUtils.join(elements, ", "));
    builder.append("]");
    return builder.toString();
  }

}
