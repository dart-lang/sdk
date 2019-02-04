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
 * This object matches the format and documentation of the Entry object documented in the Kythe
 * Storage Model.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class KytheEntry {

  public static final KytheEntry[] EMPTY_ARRAY = new KytheEntry[0];

  public static final List<KytheEntry> EMPTY_LIST = Lists.newArrayList();

  /**
   * The ticket of the source node.
   */
  private final KytheVName source;

  /**
   * An edge label. The schema defines which labels are meaningful.
   */
  private final String kind;

  /**
   * The ticket of the target node.
   */
  private final KytheVName target;

  /**
   * A fact label. The schema defines which fact labels are meaningful.
   */
  private final String fact;

  /**
   * The String value of the fact.
   */
  private final int[] value;

  /**
   * Constructor for {@link KytheEntry}.
   */
  public KytheEntry(KytheVName source, String kind, KytheVName target, String fact, int[] value) {
    this.source = source;
    this.kind = kind;
    this.target = target;
    this.fact = fact;
    this.value = value;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof KytheEntry) {
      KytheEntry other = (KytheEntry) obj;
      return
        ObjectUtilities.equals(other.source, source) &&
        ObjectUtilities.equals(other.kind, kind) &&
        ObjectUtilities.equals(other.target, target) &&
        ObjectUtilities.equals(other.fact, fact) &&
        Arrays.equals(other.value, value);
    }
    return false;
  }

  public static KytheEntry fromJson(JsonObject jsonObject) {
    KytheVName source = KytheVName.fromJson(jsonObject.get("source").getAsJsonObject());
    String kind = jsonObject.get("kind") == null ? null : jsonObject.get("kind").getAsString();
    KytheVName target = jsonObject.get("target") == null ? null : KytheVName.fromJson(jsonObject.get("target").getAsJsonObject());
    String fact = jsonObject.get("fact").getAsString();
    int[] value = jsonObject.get("value") == null ? null : JsonUtilities.decodeIntArray(jsonObject.get("value").getAsJsonArray());
    return new KytheEntry(source, kind, target, fact, value);
  }

  public static List<KytheEntry> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<KytheEntry> list = new ArrayList<KytheEntry>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * A fact label. The schema defines which fact labels are meaningful.
   */
  public String getFact() {
    return fact;
  }

  /**
   * An edge label. The schema defines which labels are meaningful.
   */
  public String getKind() {
    return kind;
  }

  /**
   * The ticket of the source node.
   */
  public KytheVName getSource() {
    return source;
  }

  /**
   * The ticket of the target node.
   */
  public KytheVName getTarget() {
    return target;
  }

  /**
   * The String value of the fact.
   */
  public int[] getValue() {
    return value;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(source);
    builder.append(kind);
    builder.append(target);
    builder.append(fact);
    builder.append(value);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.add("source", source.toJson());
    if (kind != null) {
      jsonObject.addProperty("kind", kind);
    }
    if (target != null) {
      jsonObject.add("target", target.toJson());
    }
    jsonObject.addProperty("fact", fact);
    if (value != null) {
      JsonArray jsonArrayValue = new JsonArray();
      for (int elt : value) {
        jsonArrayValue.add(new JsonPrimitive(elt));
      }
      jsonObject.add("value", jsonArrayValue);
    }
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("source=");
    builder.append(source + ", ");
    builder.append("kind=");
    builder.append(kind + ", ");
    builder.append("target=");
    builder.append(target + ", ");
    builder.append("fact=");
    builder.append(fact + ", ");
    builder.append("value=");
    builder.append(StringUtils.join(value, ", "));
    builder.append("]");
    return builder.toString();
  }

}
