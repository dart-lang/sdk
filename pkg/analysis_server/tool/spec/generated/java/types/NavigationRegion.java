/*
 * Copyright (c) 2015, the Dart project authors.
 *
 * Licensed under the Eclipse Public License v1.0 (the "License"); you may not use this file except
 * in compliance with the License. You may obtain a copy of the License at
 *
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License
 * is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
 * or implied. See the License for the specific language governing permissions and limitations under
 * the License.
 *
 * This file has been automatically generated.  Please do not edit it manually.
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
 * A description of a region from which the user can navigate to the declaration of an element.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class NavigationRegion {

  public static final NavigationRegion[] EMPTY_ARRAY = new NavigationRegion[0];

  public static final List<NavigationRegion> EMPTY_LIST = Lists.newArrayList();

  /**
   * The offset of the region from which the user can navigate.
   */
  private final int offset;

  /**
   * The length of the region from which the user can navigate.
   */
  private final int length;

  /**
   * The indexes of the targets (in the enclosing navigation response) to which the given region is
   * bound. By opening the target, clients can implement one form of navigation. This list cannot be
   * empty.
   */
  private final int[] targets;

  private final List<NavigationTarget> targetObjects = Lists.newArrayList();

  /**
   * Constructor for {@link NavigationRegion}.
   */
  public NavigationRegion(int offset, int length, int[] targets) {
    this.offset = offset;
    this.length = length;
    this.targets = targets;
  }

  public boolean containsInclusive(int x) {
    return offset <= x && x <= offset + length;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof NavigationRegion) {
      NavigationRegion other = (NavigationRegion) obj;
      return
        other.offset == offset &&
        other.length == length &&
        Arrays.equals(other.targets, targets);
    }
    return false;
  }

  public static NavigationRegion fromJson(JsonObject jsonObject) {
    int offset = jsonObject.get("offset").getAsInt();
    int length = jsonObject.get("length").getAsInt();
    int[] targets = JsonUtilities.decodeIntArray(jsonObject.get("targets").getAsJsonArray());
    return new NavigationRegion(offset, length, targets);
  }

  public static List<NavigationRegion> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<NavigationRegion> list = new ArrayList<NavigationRegion>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  public List<NavigationTarget> getTargetObjects() {
    return targetObjects;
  }

  /**
   * The length of the region from which the user can navigate.
   */
  public int getLength() {
    return length;
  }

  /**
   * The offset of the region from which the user can navigate.
   */
  public int getOffset() {
    return offset;
  }

  /**
   * The indexes of the targets (in the enclosing navigation response) to which the given region is
   * bound. By opening the target, clients can implement one form of navigation. This list cannot be
   * empty.
   */
  public int[] getTargets() {
    return targets;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(offset);
    builder.append(length);
    builder.append(targets);
    return builder.toHashCode();
  }

  public void lookupTargets(List<NavigationTarget> allTargets) {
    for (int i = 0; i < targets.length; i++) {
      int targetIndex = targets[i];
      NavigationTarget target = allTargets.get(targetIndex);
      targetObjects.add(target);
    }
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("offset", offset);
    jsonObject.addProperty("length", length);
    JsonArray jsonArrayTargets = new JsonArray();
    for (int elt : targets) {
      jsonArrayTargets.add(new JsonPrimitive(elt));
    }
    jsonObject.add("targets", jsonArrayTargets);
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
    builder.append("targets=");
    builder.append(StringUtils.join(targets, ", "));
    builder.append("]");
    return builder.toString();
  }

}
