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
 * A suggestion for how to complete partially entered text. Many of the fields are optional,
 * depending on the kind of element being suggested.
 *
 * @coverage dart.server.generated.types
 */
@SuppressWarnings("unused")
public class CompletionSuggestion {

  public static final CompletionSuggestion[] EMPTY_ARRAY = new CompletionSuggestion[0];

  public static final List<CompletionSuggestion> EMPTY_LIST = Lists.newArrayList();

  /**
   * The kind of element being suggested.
   */
  private final String kind;

  /**
   * The relevance of this completion suggestion where a higher number indicates a higher relevance.
   */
  private final int relevance;

  /**
   * The identifier to be inserted if the suggestion is selected. If the suggestion is for a method
   * or function, the client might want to additionally insert a template for the parameters. The
   * information required in order to do so is contained in other fields.
   */
  private final String completion;

  /**
   * Text to be displayed in, for example, a completion pop-up. This field is only defined if the
   * displayed text should be different than the completion. Otherwise it is omitted.
   */
  private final String displayText;

  /**
   * The offset of the start of the text to be replaced. If supplied, this should be used in
   * preference to the offset provided on the containing completion results. This value may be
   * provided independently of replacementLength (for example if only one differs from the completion
   * result value).
   */
  private final Integer replacementOffset;

  /**
   * The length of the text to be replaced. If supplied, this should be used in preference to the
   * offset provided on the containing completion results. This value may be provided independently
   * of replacementOffset (for example if only one differs from the completion result value).
   */
  private final Integer replacementLength;

  /**
   * The offset, relative to the beginning of the completion, of where the selection should be placed
   * after insertion.
   */
  private final int selectionOffset;

  /**
   * The number of characters that should be selected after insertion.
   */
  private final int selectionLength;

  /**
   * True if the suggested element is deprecated.
   */
  private final boolean isDeprecated;

  /**
   * True if the element is not known to be valid for the target. This happens if the type of the
   * target is dynamic.
   */
  private final boolean isPotential;

  /**
   * An abbreviated version of the Dartdoc associated with the element being suggested. This field is
   * omitted if there is no Dartdoc associated with the element.
   */
  private final String docSummary;

  /**
   * The Dartdoc associated with the element being suggested. This field is omitted if there is no
   * Dartdoc associated with the element.
   */
  private final String docComplete;

  /**
   * The class that declares the element being suggested. This field is omitted if the suggested
   * element is not a member of a class.
   */
  private final String declaringType;

  /**
   * A default String for use in generating argument list source contents on the client side.
   */
  private final String defaultArgumentListString;

  /**
   * Pairs of offsets and lengths describing 'defaultArgumentListString' text ranges suitable for use
   * by clients to set up linked edits of default argument source contents. For example, given an
   * argument list string 'x, y', the corresponding text range [0, 1, 3, 1], indicates two text
   * ranges of length 1, starting at offsets 0 and 3. Clients can use these ranges to treat the 'x'
   * and 'y' values specially for linked edits.
   */
  private final int[] defaultArgumentListTextRanges;

  /**
   * Information about the element reference being suggested.
   */
  private final Element element;

  /**
   * The return type of the getter, function or method or the type of the field being suggested. This
   * field is omitted if the suggested element is not a getter, function or method.
   */
  private final String returnType;

  /**
   * The names of the parameters of the function or method being suggested. This field is omitted if
   * the suggested element is not a setter, function or method.
   */
  private final List<String> parameterNames;

  /**
   * The types of the parameters of the function or method being suggested. This field is omitted if
   * the parameterNames field is omitted.
   */
  private final List<String> parameterTypes;

  /**
   * The number of required parameters for the function or method being suggested. This field is
   * omitted if the parameterNames field is omitted.
   */
  private final Integer requiredParameterCount;

  /**
   * True if the function or method being suggested has at least one named parameter. This field is
   * omitted if the parameterNames field is omitted.
   */
  private final Boolean hasNamedParameters;

  /**
   * The name of the optional parameter being suggested. This field is omitted if the suggestion is
   * not the addition of an optional argument within an argument list.
   */
  private final String parameterName;

  /**
   * The type of the options parameter being suggested. This field is omitted if the parameterName
   * field is omitted.
   */
  private final String parameterType;

  /**
   * Constructor for {@link CompletionSuggestion}.
   */
  public CompletionSuggestion(String kind, int relevance, String completion, String displayText, Integer replacementOffset, Integer replacementLength, int selectionOffset, int selectionLength, boolean isDeprecated, boolean isPotential, String docSummary, String docComplete, String declaringType, String defaultArgumentListString, int[] defaultArgumentListTextRanges, Element element, String returnType, List<String> parameterNames, List<String> parameterTypes, Integer requiredParameterCount, Boolean hasNamedParameters, String parameterName, String parameterType) {
    this.kind = kind;
    this.relevance = relevance;
    this.completion = completion;
    this.displayText = displayText;
    this.replacementOffset = replacementOffset;
    this.replacementLength = replacementLength;
    this.selectionOffset = selectionOffset;
    this.selectionLength = selectionLength;
    this.isDeprecated = isDeprecated;
    this.isPotential = isPotential;
    this.docSummary = docSummary;
    this.docComplete = docComplete;
    this.declaringType = declaringType;
    this.defaultArgumentListString = defaultArgumentListString;
    this.defaultArgumentListTextRanges = defaultArgumentListTextRanges;
    this.element = element;
    this.returnType = returnType;
    this.parameterNames = parameterNames;
    this.parameterTypes = parameterTypes;
    this.requiredParameterCount = requiredParameterCount;
    this.hasNamedParameters = hasNamedParameters;
    this.parameterName = parameterName;
    this.parameterType = parameterType;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof CompletionSuggestion) {
      CompletionSuggestion other = (CompletionSuggestion) obj;
      return
        ObjectUtilities.equals(other.kind, kind) &&
        other.relevance == relevance &&
        ObjectUtilities.equals(other.completion, completion) &&
        ObjectUtilities.equals(other.displayText, displayText) &&
        ObjectUtilities.equals(other.replacementOffset, replacementOffset) &&
        ObjectUtilities.equals(other.replacementLength, replacementLength) &&
        other.selectionOffset == selectionOffset &&
        other.selectionLength == selectionLength &&
        other.isDeprecated == isDeprecated &&
        other.isPotential == isPotential &&
        ObjectUtilities.equals(other.docSummary, docSummary) &&
        ObjectUtilities.equals(other.docComplete, docComplete) &&
        ObjectUtilities.equals(other.declaringType, declaringType) &&
        ObjectUtilities.equals(other.defaultArgumentListString, defaultArgumentListString) &&
        Arrays.equals(other.defaultArgumentListTextRanges, defaultArgumentListTextRanges) &&
        ObjectUtilities.equals(other.element, element) &&
        ObjectUtilities.equals(other.returnType, returnType) &&
        ObjectUtilities.equals(other.parameterNames, parameterNames) &&
        ObjectUtilities.equals(other.parameterTypes, parameterTypes) &&
        ObjectUtilities.equals(other.requiredParameterCount, requiredParameterCount) &&
        ObjectUtilities.equals(other.hasNamedParameters, hasNamedParameters) &&
        ObjectUtilities.equals(other.parameterName, parameterName) &&
        ObjectUtilities.equals(other.parameterType, parameterType);
    }
    return false;
  }

  public static CompletionSuggestion fromJson(JsonObject jsonObject) {
    String kind = jsonObject.get("kind").getAsString();
    int relevance = jsonObject.get("relevance").getAsInt();
    String completion = jsonObject.get("completion").getAsString();
    String displayText = jsonObject.get("displayText") == null ? null : jsonObject.get("displayText").getAsString();
    Integer replacementOffset = jsonObject.get("replacementOffset") == null ? null : jsonObject.get("replacementOffset").getAsInt();
    Integer replacementLength = jsonObject.get("replacementLength") == null ? null : jsonObject.get("replacementLength").getAsInt();
    int selectionOffset = jsonObject.get("selectionOffset").getAsInt();
    int selectionLength = jsonObject.get("selectionLength").getAsInt();
    boolean isDeprecated = jsonObject.get("isDeprecated").getAsBoolean();
    boolean isPotential = jsonObject.get("isPotential").getAsBoolean();
    String docSummary = jsonObject.get("docSummary") == null ? null : jsonObject.get("docSummary").getAsString();
    String docComplete = jsonObject.get("docComplete") == null ? null : jsonObject.get("docComplete").getAsString();
    String declaringType = jsonObject.get("declaringType") == null ? null : jsonObject.get("declaringType").getAsString();
    String defaultArgumentListString = jsonObject.get("defaultArgumentListString") == null ? null : jsonObject.get("defaultArgumentListString").getAsString();
    int[] defaultArgumentListTextRanges = jsonObject.get("defaultArgumentListTextRanges") == null ? null : JsonUtilities.decodeIntArray(jsonObject.get("defaultArgumentListTextRanges").getAsJsonArray());
    Element element = jsonObject.get("element") == null ? null : Element.fromJson(jsonObject.get("element").getAsJsonObject());
    String returnType = jsonObject.get("returnType") == null ? null : jsonObject.get("returnType").getAsString();
    List<String> parameterNames = jsonObject.get("parameterNames") == null ? null : JsonUtilities.decodeStringList(jsonObject.get("parameterNames").getAsJsonArray());
    List<String> parameterTypes = jsonObject.get("parameterTypes") == null ? null : JsonUtilities.decodeStringList(jsonObject.get("parameterTypes").getAsJsonArray());
    Integer requiredParameterCount = jsonObject.get("requiredParameterCount") == null ? null : jsonObject.get("requiredParameterCount").getAsInt();
    Boolean hasNamedParameters = jsonObject.get("hasNamedParameters") == null ? null : jsonObject.get("hasNamedParameters").getAsBoolean();
    String parameterName = jsonObject.get("parameterName") == null ? null : jsonObject.get("parameterName").getAsString();
    String parameterType = jsonObject.get("parameterType") == null ? null : jsonObject.get("parameterType").getAsString();
    return new CompletionSuggestion(kind, relevance, completion, displayText, replacementOffset, replacementLength, selectionOffset, selectionLength, isDeprecated, isPotential, docSummary, docComplete, declaringType, defaultArgumentListString, defaultArgumentListTextRanges, element, returnType, parameterNames, parameterTypes, requiredParameterCount, hasNamedParameters, parameterName, parameterType);
  }

  public static List<CompletionSuggestion> fromJsonArray(JsonArray jsonArray) {
    if (jsonArray == null) {
      return EMPTY_LIST;
    }
    ArrayList<CompletionSuggestion> list = new ArrayList<CompletionSuggestion>(jsonArray.size());
    Iterator<JsonElement> iterator = jsonArray.iterator();
    while (iterator.hasNext()) {
      list.add(fromJson(iterator.next().getAsJsonObject()));
    }
    return list;
  }

  /**
   * The identifier to be inserted if the suggestion is selected. If the suggestion is for a method
   * or function, the client might want to additionally insert a template for the parameters. The
   * information required in order to do so is contained in other fields.
   */
  public String getCompletion() {
    return completion;
  }

  /**
   * The class that declares the element being suggested. This field is omitted if the suggested
   * element is not a member of a class.
   */
  public String getDeclaringType() {
    return declaringType;
  }

  /**
   * A default String for use in generating argument list source contents on the client side.
   */
  public String getDefaultArgumentListString() {
    return defaultArgumentListString;
  }

  /**
   * Pairs of offsets and lengths describing 'defaultArgumentListString' text ranges suitable for use
   * by clients to set up linked edits of default argument source contents. For example, given an
   * argument list string 'x, y', the corresponding text range [0, 1, 3, 1], indicates two text
   * ranges of length 1, starting at offsets 0 and 3. Clients can use these ranges to treat the 'x'
   * and 'y' values specially for linked edits.
   */
  public int[] getDefaultArgumentListTextRanges() {
    return defaultArgumentListTextRanges;
  }

  /**
   * Text to be displayed in, for example, a completion pop-up. This field is only defined if the
   * displayed text should be different than the completion. Otherwise it is omitted.
   */
  public String getDisplayText() {
    return displayText;
  }

  /**
   * The Dartdoc associated with the element being suggested. This field is omitted if there is no
   * Dartdoc associated with the element.
   */
  public String getDocComplete() {
    return docComplete;
  }

  /**
   * An abbreviated version of the Dartdoc associated with the element being suggested. This field is
   * omitted if there is no Dartdoc associated with the element.
   */
  public String getDocSummary() {
    return docSummary;
  }

  /**
   * Information about the element reference being suggested.
   */
  public Element getElement() {
    return element;
  }

  /**
   * True if the function or method being suggested has at least one named parameter. This field is
   * omitted if the parameterNames field is omitted.
   */
  public Boolean getHasNamedParameters() {
    return hasNamedParameters;
  }

  /**
   * True if the suggested element is deprecated.
   */
  public boolean isDeprecated() {
    return isDeprecated;
  }

  /**
   * True if the element is not known to be valid for the target. This happens if the type of the
   * target is dynamic.
   */
  public boolean isPotential() {
    return isPotential;
  }

  /**
   * The kind of element being suggested.
   */
  public String getKind() {
    return kind;
  }

  /**
   * The name of the optional parameter being suggested. This field is omitted if the suggestion is
   * not the addition of an optional argument within an argument list.
   */
  public String getParameterName() {
    return parameterName;
  }

  /**
   * The names of the parameters of the function or method being suggested. This field is omitted if
   * the suggested element is not a setter, function or method.
   */
  public List<String> getParameterNames() {
    return parameterNames;
  }

  /**
   * The type of the options parameter being suggested. This field is omitted if the parameterName
   * field is omitted.
   */
  public String getParameterType() {
    return parameterType;
  }

  /**
   * The types of the parameters of the function or method being suggested. This field is omitted if
   * the parameterNames field is omitted.
   */
  public List<String> getParameterTypes() {
    return parameterTypes;
  }

  /**
   * The relevance of this completion suggestion where a higher number indicates a higher relevance.
   */
  public int getRelevance() {
    return relevance;
  }

  /**
   * The length of the text to be replaced. If supplied, this should be used in preference to the
   * offset provided on the containing completion results. This value may be provided independently
   * of replacementOffset (for example if only one differs from the completion result value).
   */
  public Integer getReplacementLength() {
    return replacementLength;
  }

  /**
   * The offset of the start of the text to be replaced. If supplied, this should be used in
   * preference to the offset provided on the containing completion results. This value may be
   * provided independently of replacementLength (for example if only one differs from the completion
   * result value).
   */
  public Integer getReplacementOffset() {
    return replacementOffset;
  }

  /**
   * The number of required parameters for the function or method being suggested. This field is
   * omitted if the parameterNames field is omitted.
   */
  public Integer getRequiredParameterCount() {
    return requiredParameterCount;
  }

  /**
   * The return type of the getter, function or method or the type of the field being suggested. This
   * field is omitted if the suggested element is not a getter, function or method.
   */
  public String getReturnType() {
    return returnType;
  }

  /**
   * The number of characters that should be selected after insertion.
   */
  public int getSelectionLength() {
    return selectionLength;
  }

  /**
   * The offset, relative to the beginning of the completion, of where the selection should be placed
   * after insertion.
   */
  public int getSelectionOffset() {
    return selectionOffset;
  }

  @Override
  public int hashCode() {
    HashCodeBuilder builder = new HashCodeBuilder();
    builder.append(kind);
    builder.append(relevance);
    builder.append(completion);
    builder.append(displayText);
    builder.append(replacementOffset);
    builder.append(replacementLength);
    builder.append(selectionOffset);
    builder.append(selectionLength);
    builder.append(isDeprecated);
    builder.append(isPotential);
    builder.append(docSummary);
    builder.append(docComplete);
    builder.append(declaringType);
    builder.append(defaultArgumentListString);
    builder.append(defaultArgumentListTextRanges);
    builder.append(element);
    builder.append(returnType);
    builder.append(parameterNames);
    builder.append(parameterTypes);
    builder.append(requiredParameterCount);
    builder.append(hasNamedParameters);
    builder.append(parameterName);
    builder.append(parameterType);
    return builder.toHashCode();
  }

  public JsonObject toJson() {
    JsonObject jsonObject = new JsonObject();
    jsonObject.addProperty("kind", kind);
    jsonObject.addProperty("relevance", relevance);
    jsonObject.addProperty("completion", completion);
    if (displayText != null) {
      jsonObject.addProperty("displayText", displayText);
    }
    if (replacementOffset != null) {
      jsonObject.addProperty("replacementOffset", replacementOffset);
    }
    if (replacementLength != null) {
      jsonObject.addProperty("replacementLength", replacementLength);
    }
    jsonObject.addProperty("selectionOffset", selectionOffset);
    jsonObject.addProperty("selectionLength", selectionLength);
    jsonObject.addProperty("isDeprecated", isDeprecated);
    jsonObject.addProperty("isPotential", isPotential);
    if (docSummary != null) {
      jsonObject.addProperty("docSummary", docSummary);
    }
    if (docComplete != null) {
      jsonObject.addProperty("docComplete", docComplete);
    }
    if (declaringType != null) {
      jsonObject.addProperty("declaringType", declaringType);
    }
    if (defaultArgumentListString != null) {
      jsonObject.addProperty("defaultArgumentListString", defaultArgumentListString);
    }
    if (defaultArgumentListTextRanges != null) {
      JsonArray jsonArrayDefaultArgumentListTextRanges = new JsonArray();
      for (int elt : defaultArgumentListTextRanges) {
        jsonArrayDefaultArgumentListTextRanges.add(new JsonPrimitive(elt));
      }
      jsonObject.add("defaultArgumentListTextRanges", jsonArrayDefaultArgumentListTextRanges);
    }
    if (element != null) {
      jsonObject.add("element", element.toJson());
    }
    if (returnType != null) {
      jsonObject.addProperty("returnType", returnType);
    }
    if (parameterNames != null) {
      JsonArray jsonArrayParameterNames = new JsonArray();
      for (String elt : parameterNames) {
        jsonArrayParameterNames.add(new JsonPrimitive(elt));
      }
      jsonObject.add("parameterNames", jsonArrayParameterNames);
    }
    if (parameterTypes != null) {
      JsonArray jsonArrayParameterTypes = new JsonArray();
      for (String elt : parameterTypes) {
        jsonArrayParameterTypes.add(new JsonPrimitive(elt));
      }
      jsonObject.add("parameterTypes", jsonArrayParameterTypes);
    }
    if (requiredParameterCount != null) {
      jsonObject.addProperty("requiredParameterCount", requiredParameterCount);
    }
    if (hasNamedParameters != null) {
      jsonObject.addProperty("hasNamedParameters", hasNamedParameters);
    }
    if (parameterName != null) {
      jsonObject.addProperty("parameterName", parameterName);
    }
    if (parameterType != null) {
      jsonObject.addProperty("parameterType", parameterType);
    }
    return jsonObject;
  }

  @Override
  public String toString() {
    StringBuilder builder = new StringBuilder();
    builder.append("[");
    builder.append("kind=");
    builder.append(kind + ", ");
    builder.append("relevance=");
    builder.append(relevance + ", ");
    builder.append("completion=");
    builder.append(completion + ", ");
    builder.append("displayText=");
    builder.append(displayText + ", ");
    builder.append("replacementOffset=");
    builder.append(replacementOffset + ", ");
    builder.append("replacementLength=");
    builder.append(replacementLength + ", ");
    builder.append("selectionOffset=");
    builder.append(selectionOffset + ", ");
    builder.append("selectionLength=");
    builder.append(selectionLength + ", ");
    builder.append("isDeprecated=");
    builder.append(isDeprecated + ", ");
    builder.append("isPotential=");
    builder.append(isPotential + ", ");
    builder.append("docSummary=");
    builder.append(docSummary + ", ");
    builder.append("docComplete=");
    builder.append(docComplete + ", ");
    builder.append("declaringType=");
    builder.append(declaringType + ", ");
    builder.append("defaultArgumentListString=");
    builder.append(defaultArgumentListString + ", ");
    builder.append("defaultArgumentListTextRanges=");
    builder.append(StringUtils.join(defaultArgumentListTextRanges, ", ") + ", ");
    builder.append("element=");
    builder.append(element + ", ");
    builder.append("returnType=");
    builder.append(returnType + ", ");
    builder.append("parameterNames=");
    builder.append(StringUtils.join(parameterNames, ", ") + ", ");
    builder.append("parameterTypes=");
    builder.append(StringUtils.join(parameterTypes, ", ") + ", ");
    builder.append("requiredParameterCount=");
    builder.append(requiredParameterCount + ", ");
    builder.append("hasNamedParameters=");
    builder.append(hasNamedParameters + ", ");
    builder.append("parameterName=");
    builder.append(parameterName + ", ");
    builder.append("parameterType=");
    builder.append(parameterType);
    builder.append("]");
    return builder.toString();
  }

}
