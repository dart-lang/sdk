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
 * A description of a set of edits that implement a single conceptual change.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class SourceChange {

  public static final SourceChange[] EMPTY_ARRAY = new SourceChange[0];

  public static final List<SourceChange> EMPTY_LIST = Lists.newArrayList();

  /**
   * A human-readable description of the change to be applied.
   *
   * If this change includes multiple edits made for different reasons (such as during a bulk fix
   * operation), the individual items in edits may contain more specific descriptions.
   */
  private final String message;

  /**
   * A list of the edits used to effect the change, grouped by file.
   */
  private final List<SourceFileEdit> edits;

  /**
   * A list of the linked editing groups used to customize the changes that were made.
   */
  private final List<LinkedEditGroup> linkedEditGroups;

  /**
   * The position that should be selected after the edits have been applied.
   */
  private final Position selection;

  /**
   * The length of the selection (starting at Position) that should be selected after the edits have
   * been applied.
   */
  private final Integer selectionLength;

  /**
   * The optional identifier of the change kind. The identifier remains stable even if the message
   * changes, or is parameterized.
   */
  private final String id;

  /**
   * Constructor for {@link SourceChange}.
   */
  public SourceChange(String message, List<SourceFileEdit> edits, List<LinkedEditGroup> linkedEditGroups, Position selection, Integer selectionLength, String id) {
    this.message = message;
    this.edits = edits;
    this.linkedEditGroups = linkedEditGroups;
    this.selection = selection;
    this.selectionLength = selectionLength;
    this.id = id;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof SourceChange) {
      SourceChange other = (SourceChange) obj;
      return
        ObjectUtilities.equals(other.message, message) &&
        ObjectUtilities.equals(other.edits, edits) &&
        ObjectUtilities.equals(other.linkedEditGroups, linkedEditGroups) &&
        ObjectUtilities.equals(other.selection, selection) &&
        ObjectUtilities.equals(other.selectionLength, selectionLength) &&
        ObjectUtilities.equals(other.id, id);
    }
    return false;
  }

  public static SourceChange fromJson(JsonObject jsonObject) {
    String message = jsonObject.get("message").getAsString();
    List<SourceFileEdit> edits = SourceFileEdit.fromJsonArray(jsonObject.get("edits").getAsJsonArray());
    List<LinkedEditGroup> linkedEditGroups = LinkedEditGroup.fromJsonArray(jsonObject.get("linkedEditGroups").getAsJsonArray());
    Position selection = jsonObject.get("selection") == null ? null : Position.fromJson(jsonObject.get("selection").getAsJsonObject());
    Integer selectionLength = jsonObject.get("selectionLength") == null ? null : jsonObject.get("selectionLength").getAsInt();
    String id = jsonObject.get("id") == null ? null : jsonObject.get("id").getAsString();
    return new SourceChange(message, edits, linkedEditGroups, selection, selectionLength, id);
  }

  public static List<SourceChange> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<SourceChange> list = new ArrayList<SourceChange>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * A list of the edits used to effect the change, grouped by file.
   */
  public List<SourceFileEdit> getEdits() {
    return edits;
  }

  /**
   * The optional identifier of the change kind. The identifier remains stable even if the message
   * changes, or is parameterized.
   */
  public String getId() {
    return id;
  }

  /**
   * A list of the linked editing groups used to customize the changes that were made.
   */
  public List<LinkedEditGroup> getLinkedEditGroups() {
    return linkedEditGroups;
  }

  /**
   * A human-readable description of the change to be applied.
   *
   * If this change includes multiple edits made for different reasons (such as during a bulk fix
   * operation), the individual items in edits may contain more specific descriptions.
   */
  public String getMessage() {
    return message;
  }

  /**
   * The position that should be selected after the edits have been applied.
   */
  public Position getSelection() {
    return selection;
  }

  /**
   * The length of the selection (starting at Position) that should be selected after the edits have
   * been applied.
   */
  public Integer getSelectionLength() {
    return selectionLength;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(message);
    builder.append(edits);
    builder.append(linkedEditGroups);
    builder.append(selection);
    builder.append(selectionLength);
    builder.append(id);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("message", message);
    JsonArray jsonArrayEdits = new JsonArray();
    for (SourceFileEdit elt : edits) {
      jsonArrayEdits.add(elt.toJson());
    }
    jsonObject.add("edits", jsonArrayEdits);
    JsonArray jsonArrayLinkedEditGroups = new JsonArray();
    for (LinkedEditGroup elt : linkedEditGroups) {
      jsonArrayLinkedEditGroups.add(elt.toJson());
    }
    jsonObject.add("linkedEditGroups", jsonArrayLinkedEditGroups);
    if (selection != null) {
      jsonObject.add("selection", selection.toJson());
    }
    if (selectionLength != null) {
      jsonObject.addProperty("selectionLength", selectionLength);
    }
    if (id != null) {
      jsonObject.addProperty("id", id);
    }
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("message=");
    builder.append(message + ", ");
    builder.append("edits=");
    builder.append(StringUtils.join(edits, ", ") + ", ");
    builder.append("linkedEditGroups=");
    builder.append(StringUtils.join(linkedEditGroups, ", ") + ", ");
    builder.append("selection=");
    builder.append(selection + ", ");
    builder.append("selectionLength=");
    builder.append(selectionLength + ", ");
    builder.append("id=");
    builder.append(id);
    builder.append("]");
    return builder.toString();
  }

}
