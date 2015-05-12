/*
 * Copyright (c) 2014, the Dart project authors.
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
package com.google.dart.server.generated.types;

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
 * An abstract superclass of all refactoring options.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class RefactoringOptions {

  public static final RefactoringOptions[] EMPTY_ARRAY = new RefactoringOptions[0];

  public static final List<RefactoringOptions> EMPTY_LIST = Lists.newArrayList();

  /**
   * Constructor for {@link RefactoringOptions}.
   */
  public RefactoringOptions() {
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof RefactoringOptions) {
      RefactoringOptions other = (RefactoringOptions) obj;
      return
        true;
    }
    return false;
  }

  public static RefactoringOptions fromJson(JsonObject jsonObject) {
    return new RefactoringOptions();
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("]");
    return builder.toString();
  }

}
