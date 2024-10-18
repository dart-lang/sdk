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
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import com.google.common.collect.Lists;
import com.google.dart.server.utilities.general.JsonUtilities;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonPrimitive;
import org.apache.commons.lang3.StringUtils;

/**
 * A list of associations between paths and the libraries that should be included for code
 * completion when editing a file beneath that path.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class LibraryPathSet {

  public static final LibraryPathSet[] EMPTY_ARRAY = new LibraryPathSet[0];

  public static final List<LibraryPathSet> EMPTY_LIST = List.of();

  /**
   * The filepath for which this request's libraries should be active in completion suggestions. This
   * object associates filesystem regions to libraries and library directories of interest to the
   * client.
   */
  private final String scope;

  /**
   * The paths of the libraries of interest to the client for completion suggestions.
   */
  private final List<String> libraryPaths;

  /**
   * Constructor for {@link LibraryPathSet}.
   */
  public LibraryPathSet(String scope, List<String> libraryPaths) {
    this.scope = scope;
    this.libraryPaths = libraryPaths;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof LibraryPathSet) {
      LibraryPathSet other = (LibraryPathSet) obj;
      return
        Objects.equals(other.scope, scope) &&
        Objects.equals(other.libraryPaths, libraryPaths);
    }
    return false;
  }

  public static LibraryPathSet fromJson(JsonObject jsonObject) {
    String scope = jsonObject.get("scope").getAsString();
    List<String> libraryPaths = JsonUtilities.decodeStringList(jsonObject.get("libraryPaths").getAsJsonArray());
    return new LibraryPathSet(scope, libraryPaths);
  }

  public static List<LibraryPathSet> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    List<LibraryPathSet> list = new ArrayList<>(jsonArray.size());
    for (final JsonElement element : jsonArray) {
      list.add(fromJson(element.getAsJsonObject()));
    }
    return list;
  }

  /**
   * The paths of the libraries of interest to the client for completion suggestions.
   */
  public List<String> getLibraryPaths() {
    return libraryPaths;
  }

  /**
   * The filepath for which this request's libraries should be active in completion suggestions. This
   * object associates filesystem regions to libraries and library directories of interest to the
   * client.
   */
  public String getScope() {
    return scope;
  }

  @Override
  public int hashCode() {
    return Objects.hash(
      scope,
      libraryPaths
    );
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("scope", scope);
    JsonArray jsonArrayLibraryPaths = new JsonArray();
    for (String elt : libraryPaths) {
      jsonArrayLibraryPaths.add(new JsonPrimitive(elt));
    }
    jsonObject.add("libraryPaths", jsonArrayLibraryPaths);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("scope=");
    builder.append(scope + ", ");
    builder.append("libraryPaths=");
    builder.append(StringUtils.join(libraryPaths, ", "));
    builder.append("]");
    return builder.toString();
  }

}
