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
 * An action associated with a message that the server is requesting the client to display to the
 * user.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class MessageAction {

  public static final MessageAction[] EMPTY_ARRAY = new MessageAction[0];

  public static final List<MessageAction> EMPTY_LIST = Lists.newArrayList();

  /**
   * The label of the button to be displayed, and the value to be returned to the server if the
   * button is clicked.
   */
  private final String label;

  /**
   * Constructor for {@link MessageAction}.
   */
  public MessageAction(String label) {
    this.label = label;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof MessageAction) {
      MessageAction other = (MessageAction) obj;
      return
        ObjectUtilities.equals(other.label, label);
    }
    return false;
  }

  public static MessageAction fromJson(JsonObject jsonObject) {
    String label = jsonObject.get("label").getAsString();
    return new MessageAction(label);
  }

  public static List<MessageAction> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<MessageAction> list = new ArrayList<MessageAction>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * The label of the button to be displayed, and the value to be returned to the server if the
   * button is clicked.
   */
  public String getLabel() {
    return label;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(label);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("label", label);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("label=");
    builder.append(label);
    builder.append("]");
    return builder.toString();
  }

}
