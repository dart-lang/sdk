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
 * A description of the elements that are referenced in a region of a file that come from a single
 * imported library.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class ImportedElements {

  public static final ImportedElements[] EMPTY_ARRAY = new ImportedElements[0];

  public static final List<ImportedElements> EMPTY_LIST = Lists.newArrayList();

  /**
   * The absolute and normalized path of the file containing the library.
   */
  private final String path;

  /**
   * The prefix that was used when importing the library into the original source.
   */
  private final String prefix;

  /**
   * The names of the elements imported from the library.
   */
  private final List<String> elements;

  /**
   * Constructor for {@link ImportedElements}.
   */
  public ImportedElements(String path, String prefix, List<String> elements) {
    this.path = path;
    this.prefix = prefix;
    this.elements = elements;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof ImportedElements) {
      ImportedElements other = (ImportedElements) obj;
      return
        ObjectUtilities.equals(other.path, path) &&
        ObjectUtilities.equals(other.prefix, prefix) &&
        ObjectUtilities.equals(other.elements, elements);
    }
    return false;
  }

  public static ImportedElements fromJson(JsonObject jsonObject) {
    String path = jsonObject.get("path").getAsString();
    String prefix = jsonObject.get("prefix").getAsString();
    List<String> elements = JsonUtilities.decodeStringList(jsonObject.get("elements").getAsJsonArray());
    return new ImportedElements(path, prefix, elements);
  }

  public static List<ImportedElements> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<ImportedElements> list = new ArrayList<ImportedElements>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * The names of the elements imported from the library.
   */
  public List<String> getElements() {
    return elements;
  }

  /**
   * The absolute and normalized path of the file containing the library.
   */
  public String getPath() {
    return path;
  }

  /**
   * The prefix that was used when importing the library into the original source.
   */
  public String getPrefix() {
    return prefix;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(path);
    builder.append(prefix);
    builder.append(elements);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("path", path);
    jsonObject.addProperty("prefix", prefix);
    JsonArray jsonArrayElements = new JsonArray();
    for (String elt : elements) {
      jsonArrayElements.add(new JsonPrimitive(elt));
    }
    jsonObject.add("elements", jsonArrayElements);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("path=");
    builder.append(path + ", ");
    builder.append("prefix=");
    builder.append(prefix + ", ");
    builder.append("elements=");
    builder.append(StringUtils.join(elements, ", "));
    builder.append("]");
    return builder.toString();
  }

}
