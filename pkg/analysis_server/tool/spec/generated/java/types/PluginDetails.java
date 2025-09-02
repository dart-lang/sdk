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
import java.util.stream.Collectors;
import com.google.dart.server.utilities.general.JsonUtilities;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonPrimitive;

/**
 * The details of an active plugin.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class PluginDetails {

  public static final List<PluginDetails> EMPTY_LIST = List.of();

  /**
   * The name of the plugin.
   */
  private final String name;

  /**
   * A list of the IDs of the analysis rules which have been registered as lint rules.
   */
  private final List<String> lintRules;

  /**
   * A list of the IDs of the analysis rules which have been registered as warning rules.
   */
  private final List<String> warningRules;

  /**
   * A list of the descriptions of registered assists.
   */
  private final List<AssistDescription> assists;

  /**
   * A list of the descriptions of registered fixes.
   */
  private final List<FixDescription> fixes;

  /**
   * Constructor for {@link PluginDetails}.
   */
  public PluginDetails(String name, List<String> lintRules, List<String> warningRules, List<AssistDescription> assists, List<FixDescription> fixes) {
    this.name = name;
    this.lintRules = lintRules;
    this.warningRules = warningRules;
    this.assists = assists;
    this.fixes = fixes;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof PluginDetails other) {
      return
        Objects.equals(other.name, name) &&
        Objects.equals(other.lintRules, lintRules) &&
        Objects.equals(other.warningRules, warningRules) &&
        Objects.equals(other.assists, assists) &&
        Objects.equals(other.fixes, fixes);
    }
    return false;
  }

  public static PluginDetails fromJson(JsonObject jsonObject) {
    String name = jsonObject.get("name").getAsString();
    List<String> lintRules = JsonUtilities.decodeStringList(jsonObject.get("lintRules").getAsJsonArray());
    List<String> warningRules = JsonUtilities.decodeStringList(jsonObject.get("warningRules").getAsJsonArray());
    List<AssistDescription> assists = AssistDescription.fromJsonArray(jsonObject.get("assists").getAsJsonArray());
    List<FixDescription> fixes = FixDescription.fromJsonArray(jsonObject.get("fixes").getAsJsonArray());
    return new PluginDetails(name, lintRules, warningRules, assists, fixes);
  }

  public static List<PluginDetails> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    List<PluginDetails> list = new ArrayList<>(jsonArray.size());
    for (final JsonElement element : jsonArray) {
      list.add(fromJson(element.getAsJsonObject()));
    }
    return list;
  }

  /**
   * A list of the descriptions of registered assists.
   */
  public List<AssistDescription> getAssists() {
    return assists;
  }

  /**
   * A list of the descriptions of registered fixes.
   */
  public List<FixDescription> getFixes() {
    return fixes;
  }

  /**
   * A list of the IDs of the analysis rules which have been registered as lint rules.
   */
  public List<String> getLintRules() {
    return lintRules;
  }

  /**
   * The name of the plugin.
   */
  public String getName() {
    return name;
  }

  /**
   * A list of the IDs of the analysis rules which have been registered as warning rules.
   */
  public List<String> getWarningRules() {
    return warningRules;
  }

  @Override
  public int hashCode() {
    return Objects.hash(
      name,
      lintRules,
      warningRules,
      assists,
      fixes
    );
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("name", name);
    JsonArray jsonArrayLintRules = new JsonArray();
    for (String elt : lintRules) {
      jsonArrayLintRules.add(new JsonPrimitive(elt));
    }
    jsonObject.add("lintRules", jsonArrayLintRules);
    JsonArray jsonArrayWarningRules = new JsonArray();
    for (String elt : warningRules) {
      jsonArrayWarningRules.add(new JsonPrimitive(elt));
    }
    jsonObject.add("warningRules", jsonArrayWarningRules);
    JsonArray jsonArrayAssists = new JsonArray();
    for (AssistDescription elt : assists) {
      jsonArrayAssists.add(elt.toJson());
    }
    jsonObject.add("assists", jsonArrayAssists);
    JsonArray jsonArrayFixes = new JsonArray();
    for (FixDescription elt : fixes) {
      jsonArrayFixes.add(elt.toJson());
    }
    jsonObject.add("fixes", jsonArrayFixes);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("name=");
    builder.append(name);
    builder.append(", ");
    builder.append("lintRules=");
    builder.append(lintRules.stream().map(String::valueOf).collect(Collectors.joining(", ")));
    builder.append(", ");
    builder.append("warningRules=");
    builder.append(warningRules.stream().map(String::valueOf).collect(Collectors.joining(", ")));
    builder.append(", ");
    builder.append("assists=");
    builder.append(assists.stream().map(String::valueOf).collect(Collectors.joining(", ")));
    builder.append(", ");
    builder.append("fixes=");
    builder.append(fixes.stream().map(String::valueOf).collect(Collectors.joining(", ")));
    builder.append("]");
    return builder.toString();
  }

}
