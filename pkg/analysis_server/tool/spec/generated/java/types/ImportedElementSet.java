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
 * The set of top-level elements encoded as pairs of the defining library URI and the name, and
 * stored in the parallel lists elementUris and elementNames.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class ImportedElementSet {

  public static final ImportedElementSet[] EMPTY_ARRAY = new ImportedElementSet[0];

  public static final List<ImportedElementSet> EMPTY_LIST = Lists.newArrayList();

  /**
   * The list of unique strings in this object.
   */
  private final List<String> strings;

  /**
   * The library URI part of the element. It is an index in the strings field.
   */
  private final int[] uris;

  /**
   * The name part of a the element. It is an index in the strings field.
   */
  private final int[] names;

  /**
   * Constructor for {@link ImportedElementSet}.
   */
  public ImportedElementSet(List<String> strings, int[] uris, int[] names) {
    this.strings = strings;
    this.uris = uris;
    this.names = names;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof ImportedElementSet) {
      ImportedElementSet other = (ImportedElementSet) obj;
      return
        ObjectUtilities.equals(other.strings, strings) &&
        Arrays.equals(other.uris, uris) &&
        Arrays.equals(other.names, names);
    }
    return false;
  }

  public static ImportedElementSet fromJson(JsonObject jsonObject) {
    List<String> strings = JsonUtilities.decodeStringList(jsonObject.get("strings").getAsJsonArray());
    int[] uris = JsonUtilities.decodeIntArray(jsonObject.get("uris").getAsJsonArray());
    int[] names = JsonUtilities.decodeIntArray(jsonObject.get("names").getAsJsonArray());
    return new ImportedElementSet(strings, uris, names);
  }

  public static List<ImportedElementSet> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<ImportedElementSet> list = new ArrayList<ImportedElementSet>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * The name part of a the element. It is an index in the strings field.
   */
  public int[] getNames() {
    return names;
  }

  /**
   * The list of unique strings in this object.
   */
  public List<String> getStrings() {
    return strings;
  }

  /**
   * The library URI part of the element. It is an index in the strings field.
   */
  public int[] getUris() {
    return uris;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(strings);
    builder.append(uris);
    builder.append(names);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    JsonArray jsonArrayStrings = new JsonArray();
    for (String elt : strings) {
      jsonArrayStrings.add(new JsonPrimitive(elt));
    }
    jsonObject.add("strings", jsonArrayStrings);
    JsonArray jsonArrayUris = new JsonArray();
    for (int elt : uris) {
      jsonArrayUris.add(new JsonPrimitive(elt));
    }
    jsonObject.add("uris", jsonArrayUris);
    JsonArray jsonArrayNames = new JsonArray();
    for (int elt : names) {
      jsonArrayNames.add(new JsonPrimitive(elt));
    }
    jsonObject.add("names", jsonArrayNames);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("strings=");
    builder.append(StringUtils.join(strings, ", ") + ", ");
    builder.append("uris=");
    builder.append(StringUtils.join(uris, ", ") + ", ");
    builder.append("names=");
    builder.append(StringUtils.join(names, ", "));
    builder.append("]");
    return builder.toString();
  }

}
