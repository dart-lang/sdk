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
 * A scanned token along with its inferred type information.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class TokenDetails {

  public static final TokenDetails[] EMPTY_ARRAY = new TokenDetails[0];

  public static final List<TokenDetails> EMPTY_LIST = Lists.newArrayList();

  /**
   * The token's lexeme.
   */
  private final String lexeme;

  /**
   * A unique id for the type of the identifier. Omitted if the token is not an identifier in a
   * reference position.
   */
  private final String type;

  /**
   * An indication of whether this token is in a declaration or reference position. (If no other
   * purpose is found for this field then it should be renamed and converted to a boolean value.)
   * Omitted if the token is not an identifier.
   */
  private final List<String> validElementKinds;

  /**
   * The offset of the first character of the token in the file which it originated from.
   */
  private final int offset;

  /**
   * Constructor for {@link TokenDetails}.
   */
  public TokenDetails(String lexeme, String type, List<String> validElementKinds, int offset) {
    this.lexeme = lexeme;
    this.type = type;
    this.validElementKinds = validElementKinds;
    this.offset = offset;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof TokenDetails) {
      TokenDetails other = (TokenDetails) obj;
      return
        ObjectUtilities.equals(other.lexeme, lexeme) &&
        ObjectUtilities.equals(other.type, type) &&
        ObjectUtilities.equals(other.validElementKinds, validElementKinds) &&
        other.offset == offset;
    }
    return false;
  }

  public static TokenDetails fromJson(JsonObject jsonObject) {
    String lexeme = jsonObject.get("lexeme").getAsString();
    String type = jsonObject.get("type") == null ? null : jsonObject.get("type").getAsString();
    List<String> validElementKinds = jsonObject.get("validElementKinds") == null ? null : JsonUtilities.decodeStringList(jsonObject.get("validElementKinds").getAsJsonArray());
    int offset = jsonObject.get("offset").getAsInt();
    return new TokenDetails(lexeme, type, validElementKinds, offset);
  }

  public static List<TokenDetails> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<TokenDetails> list = new ArrayList<TokenDetails>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * The token's lexeme.
   */
  public String getLexeme() {
    return lexeme;
  }

  /**
   * The offset of the first character of the token in the file which it originated from.
   */
  public int getOffset() {
    return offset;
  }

  /**
   * A unique id for the type of the identifier. Omitted if the token is not an identifier in a
   * reference position.
   */
  public String getType() {
    return type;
  }

  /**
   * An indication of whether this token is in a declaration or reference position. (If no other
   * purpose is found for this field then it should be renamed and converted to a boolean value.)
   * Omitted if the token is not an identifier.
   */
  public List<String> getValidElementKinds() {
    return validElementKinds;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(lexeme);
    builder.append(type);
    builder.append(validElementKinds);
    builder.append(offset);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("lexeme", lexeme);
    if (type != null) {
      jsonObject.addProperty("type", type);
    }
    if (validElementKinds != null) {
      JsonArray jsonArrayValidElementKinds = new JsonArray();
      for (String elt : validElementKinds) {
        jsonArrayValidElementKinds.add(new JsonPrimitive(elt));
      }
      jsonObject.add("validElementKinds", jsonArrayValidElementKinds);
    }
    jsonObject.addProperty("offset", offset);
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("lexeme=");
    builder.append(lexeme + ", ");
    builder.append("type=");
    builder.append(type + ", ");
    builder.append("validElementKinds=");
    builder.append(StringUtils.join(validElementKinds, ", ") + ", ");
    builder.append("offset=");
    builder.append(offset);
    builder.append("]");
    return builder.toString();
  }

}
