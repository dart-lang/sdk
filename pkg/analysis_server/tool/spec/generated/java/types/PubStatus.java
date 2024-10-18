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
 * An indication of the current state of pub execution.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class PubStatus {

  public static final PubStatus[] EMPTY_ARRAY = new PubStatus[0];

  public static final List<PubStatus> EMPTY_LIST = List.of();

  /**
   * True if the server is currently running pub to produce a list of package directories.
   */
  private final boolean isListingPackageDirs;

  /**
   * Constructor for {@link PubStatus}.
   */
  public PubStatus(boolean isListingPackageDirs) {
    this.isListingPackageDirs = isListingPackageDirs;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof PubStatus) {
      PubStatus other = (PubStatus) obj;
      return
        other.isListingPackageDirs == isListingPackageDirs;
    }
    return false;
  }

  public static PubStatus fromJson(JsonObject jsonObject) {
    boolean isListingPackageDirs = jsonObject.get("isListingPackageDirs").getAsBoolean();
    return new PubStatus(isListingPackageDirs);
  }

  public static List<PubStatus> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    List<PubStatus> list = new ArrayList<>(jsonArray.size());
    for (final JsonElement element : jsonArray) {
      list.add(fromJson(element.getAsJsonObject()));
    }
    return list;
  }

  /**
   * True if the server is currently running pub to produce a list of package directories.
   */
  public boolean isListingPackageDirs() {
    return isListingPackageDirs;
  }

  @Override
  public int hashCode() {
    return Objects.hash(
      isListingPackageDirs
    );
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("isListingPackageDirs", isListingPackageDirs);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("isListingPackageDirs=");
    builder.append(isListingPackageDirs);
    builder.append("]");
    return builder.toString();
  }

}
