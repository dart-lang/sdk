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
 * Deprecated: the only reference to this type has been deprecated.
 *
 * A set of options controlling what kind of analysis is to be performed. If the value of a field
 * is omitted the value of the option will not be changed.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class AnalysisOptions {

  public static final AnalysisOptions[] EMPTY_ARRAY = new AnalysisOptions[0];

  public static final List<AnalysisOptions> EMPTY_LIST = Lists.newArrayList();

  /**
   * Deprecated: this feature is always enabled.
   *
   * True if the client wants to enable support for the proposed async feature.
   */
  private final Boolean enableAsync;

  /**
   * Deprecated: this feature is always enabled.
   *
   * True if the client wants to enable support for the proposed deferred loading feature.
   */
  private final Boolean enableDeferredLoading;

  /**
   * Deprecated: this feature is always enabled.
   *
   * True if the client wants to enable support for the proposed enum feature.
   */
  private final Boolean enableEnums;

  /**
   * Deprecated: this feature is always enabled.
   *
   * True if the client wants to enable support for the proposed "null aware operators" feature.
   */
  private final Boolean enableNullAwareOperators;

  /**
   * True if the client wants to enable support for the proposed "less restricted mixins" proposal
   * (DEP 34).
   */
  private final Boolean enableSuperMixins;

  /**
   * True if hints that are specific to dart2js should be generated. This option is ignored if
   * generateHints is false.
   */
  private final Boolean generateDart2jsHints;

  /**
   * True if hints should be generated as part of generating errors and warnings.
   */
  private final Boolean generateHints;

  /**
   * True if lints should be generated as part of generating errors and warnings.
   */
  private final Boolean generateLints;

  /**
   * Constructor for {@link AnalysisOptions}.
   */
  public AnalysisOptions(Boolean enableAsync, Boolean enableDeferredLoading, Boolean enableEnums, Boolean enableNullAwareOperators, Boolean enableSuperMixins, Boolean generateDart2jsHints, Boolean generateHints, Boolean generateLints) {
    this.enableAsync = enableAsync;
    this.enableDeferredLoading = enableDeferredLoading;
    this.enableEnums = enableEnums;
    this.enableNullAwareOperators = enableNullAwareOperators;
    this.enableSuperMixins = enableSuperMixins;
    this.generateDart2jsHints = generateDart2jsHints;
    this.generateHints = generateHints;
    this.generateLints = generateLints;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof AnalysisOptions) {
      AnalysisOptions other = (AnalysisOptions) obj;
      return
        ObjectUtilities.equals(other.enableAsync, enableAsync) &&
        ObjectUtilities.equals(other.enableDeferredLoading, enableDeferredLoading) &&
        ObjectUtilities.equals(other.enableEnums, enableEnums) &&
        ObjectUtilities.equals(other.enableNullAwareOperators, enableNullAwareOperators) &&
        ObjectUtilities.equals(other.enableSuperMixins, enableSuperMixins) &&
        ObjectUtilities.equals(other.generateDart2jsHints, generateDart2jsHints) &&
        ObjectUtilities.equals(other.generateHints, generateHints) &&
        ObjectUtilities.equals(other.generateLints, generateLints);
    }
    return false;
  }

  public static AnalysisOptions fromJson(JsonObject jsonObject) {
    Boolean enableAsync = jsonObject.get("enableAsync") == null ? null : jsonObject.get("enableAsync").getAsBoolean();
    Boolean enableDeferredLoading = jsonObject.get("enableDeferredLoading") == null ? null : jsonObject.get("enableDeferredLoading").getAsBoolean();
    Boolean enableEnums = jsonObject.get("enableEnums") == null ? null : jsonObject.get("enableEnums").getAsBoolean();
    Boolean enableNullAwareOperators = jsonObject.get("enableNullAwareOperators") == null ? null : jsonObject.get("enableNullAwareOperators").getAsBoolean();
    Boolean enableSuperMixins = jsonObject.get("enableSuperMixins") == null ? null : jsonObject.get("enableSuperMixins").getAsBoolean();
    Boolean generateDart2jsHints = jsonObject.get("generateDart2jsHints") == null ? null : jsonObject.get("generateDart2jsHints").getAsBoolean();
    Boolean generateHints = jsonObject.get("generateHints") == null ? null : jsonObject.get("generateHints").getAsBoolean();
    Boolean generateLints = jsonObject.get("generateLints") == null ? null : jsonObject.get("generateLints").getAsBoolean();
    return new AnalysisOptions(enableAsync, enableDeferredLoading, enableEnums, enableNullAwareOperators, enableSuperMixins, generateDart2jsHints, generateHints, generateLints);
  }

  public static List<AnalysisOptions> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<AnalysisOptions> list = new ArrayList<AnalysisOptions>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * Deprecated: this feature is always enabled.
   *
   * True if the client wants to enable support for the proposed async feature.
   */
  public Boolean getEnableAsync() {
    return enableAsync;
  }

  /**
   * Deprecated: this feature is always enabled.
   *
   * True if the client wants to enable support for the proposed deferred loading feature.
   */
  public Boolean getEnableDeferredLoading() {
    return enableDeferredLoading;
  }

  /**
   * Deprecated: this feature is always enabled.
   *
   * True if the client wants to enable support for the proposed enum feature.
   */
  public Boolean getEnableEnums() {
    return enableEnums;
  }

  /**
   * Deprecated: this feature is always enabled.
   *
   * True if the client wants to enable support for the proposed "null aware operators" feature.
   */
  public Boolean getEnableNullAwareOperators() {
    return enableNullAwareOperators;
  }

  /**
   * True if the client wants to enable support for the proposed "less restricted mixins" proposal
   * (DEP 34).
   */
  public Boolean getEnableSuperMixins() {
    return enableSuperMixins;
  }

  /**
   * True if hints that are specific to dart2js should be generated. This option is ignored if
   * generateHints is false.
   */
  public Boolean getGenerateDart2jsHints() {
    return generateDart2jsHints;
  }

  /**
   * True if hints should be generated as part of generating errors and warnings.
   */
  public Boolean getGenerateHints() {
    return generateHints;
  }

  /**
   * True if lints should be generated as part of generating errors and warnings.
   */
  public Boolean getGenerateLints() {
    return generateLints;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(enableAsync);
    builder.append(enableDeferredLoading);
    builder.append(enableEnums);
    builder.append(enableNullAwareOperators);
    builder.append(enableSuperMixins);
    builder.append(generateDart2jsHints);
    builder.append(generateHints);
    builder.append(generateLints);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    if (enableAsync != null) {
      jsonObject.addProperty("enableAsync", enableAsync);
    }
    if (enableDeferredLoading != null) {
      jsonObject.addProperty("enableDeferredLoading", enableDeferredLoading);
    }
    if (enableEnums != null) {
      jsonObject.addProperty("enableEnums", enableEnums);
    }
    if (enableNullAwareOperators != null) {
      jsonObject.addProperty("enableNullAwareOperators", enableNullAwareOperators);
    }
    if (enableSuperMixins != null) {
      jsonObject.addProperty("enableSuperMixins", enableSuperMixins);
    }
    if (generateDart2jsHints != null) {
      jsonObject.addProperty("generateDart2jsHints", generateDart2jsHints);
    }
    if (generateHints != null) {
      jsonObject.addProperty("generateHints", generateHints);
    }
    if (generateLints != null) {
      jsonObject.addProperty("generateLints", generateLints);
    }
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("enableAsync=");
    builder.append(enableAsync + ", ");
    builder.append("enableDeferredLoading=");
    builder.append(enableDeferredLoading + ", ");
    builder.append("enableEnums=");
    builder.append(enableEnums + ", ");
    builder.append("enableNullAwareOperators=");
    builder.append(enableNullAwareOperators + ", ");
    builder.append("enableSuperMixins=");
    builder.append(enableSuperMixins + ", ");
    builder.append("generateDart2jsHints=");
    builder.append(generateDart2jsHints + ", ");
    builder.append("generateHints=");
    builder.append(generateHints + ", ");
    builder.append("generateLints=");
    builder.append(generateLints);
    builder.append("]");
    return builder.toString();
  }

}
