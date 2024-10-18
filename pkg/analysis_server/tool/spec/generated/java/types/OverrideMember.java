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
 * A description of a member that overrides an inherited member.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class OverrideMember {

  public static final OverrideMember[] EMPTY_ARRAY = new OverrideMember[0];

  public static final List<OverrideMember> EMPTY_LIST = List.of();

  /**
   * The offset of the name of the overriding member.
   */
  private final int offset;

  /**
   * The length of the name of the overriding member.
   */
  private final int length;

  /**
   * The member inherited from a superclass that is overridden by the overriding member. The field is
   * omitted if there is no superclass member, in which case there must be at least one interface
   * member.
   */
  private final OverriddenMember superclassMember;

  /**
   * The members inherited from interfaces that are overridden by the overriding member. The field is
   * omitted if there are no interface members, in which case there must be a superclass member.
   */
  private final List<OverriddenMember> interfaceMembers;

  /**
   * Constructor for {@link OverrideMember}.
   */
  public OverrideMember(int offset, int length, OverriddenMember superclassMember, List<OverriddenMember> interfaceMembers) {
    this.offset = offset;
    this.length = length;
    this.superclassMember = superclassMember;
    this.interfaceMembers = interfaceMembers;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof OverrideMember) {
      OverrideMember other = (OverrideMember) obj;
      return
        other.offset == offset &&
        other.length == length &&
        Objects.equals(other.superclassMember, superclassMember) &&
        Objects.equals(other.interfaceMembers, interfaceMembers);
    }
    return false;
  }

  public static OverrideMember fromJson(JsonObject jsonObject) {
    int offset = jsonObject.get("offset").getAsInt();
    int length = jsonObject.get("length").getAsInt();
    OverriddenMember superclassMember = jsonObject.get("superclassMember") == null ? null : OverriddenMember.fromJson(jsonObject.get("superclassMember").getAsJsonObject());
    List<OverriddenMember> interfaceMembers = jsonObject.get("interfaceMembers") == null ? null : OverriddenMember.fromJsonArray(jsonObject.get("interfaceMembers").getAsJsonArray());
    return new OverrideMember(offset, length, superclassMember, interfaceMembers);
  }

  public static List<OverrideMember> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    List<OverrideMember> list = new ArrayList<>(jsonArray.size());
    for (final JsonElement element : jsonArray) {
      list.add(fromJson(element.getAsJsonObject()));
    }
    return list;
  }

  /**
   * The members inherited from interfaces that are overridden by the overriding member. The field is
   * omitted if there are no interface members, in which case there must be a superclass member.
   */
  public List<OverriddenMember> getInterfaceMembers() {
    return interfaceMembers;
  }

  /**
   * The length of the name of the overriding member.
   */
  public int getLength() {
    return length;
  }

  /**
   * The offset of the name of the overriding member.
   */
  public int getOffset() {
    return offset;
  }

  /**
   * The member inherited from a superclass that is overridden by the overriding member. The field is
   * omitted if there is no superclass member, in which case there must be at least one interface
   * member.
   */
  public OverriddenMember getSuperclassMember() {
    return superclassMember;
  }

  @Override
  public int hashCode() {
    return Objects.hash(
      offset,
      length,
      superclassMember,
      interfaceMembers
    );
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("offset", offset);
    jsonObject.addProperty("length", length);
    if (superclassMember != null) {
      jsonObject.add("superclassMember", superclassMember.toJson());
    }
    if (interfaceMembers != null) {
      JsonArray jsonArrayInterfaceMembers = new JsonArray();
      for (OverriddenMember elt : interfaceMembers) {
        jsonArrayInterfaceMembers.add(elt.toJson());
      }
      jsonObject.add("interfaceMembers", jsonArrayInterfaceMembers);
    }
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("offset=");
    builder.append(offset + ", ");
    builder.append("length=");
    builder.append(length + ", ");
    builder.append("superclassMember=");
    builder.append(superclassMember + ", ");
    builder.append("interfaceMembers=");
    builder.append(StringUtils.join(interfaceMembers, ", "));
    builder.append("]");
    return builder.toString();
  }

}
