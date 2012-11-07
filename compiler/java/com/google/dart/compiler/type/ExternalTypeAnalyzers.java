// Copyright (c) 2012, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.type;

import com.google.common.collect.Maps;
import com.google.dart.compiler.ast.DartExpression;
import com.google.dart.compiler.ast.DartMethodInvocation;
import com.google.dart.compiler.ast.DartStringLiteral;
import com.google.dart.compiler.ast.DartUnqualifiedInvocation;
import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.ElementKind;
import com.google.dart.compiler.resolver.Elements;
import com.google.dart.compiler.resolver.EnclosingElement;
import com.google.dart.compiler.resolver.LibraryElement;
import com.google.dart.compiler.util.apache.StringUtils;

import java.util.List;
import java.util.Map;

/**
 * Provides type information which cannot be inferred from source itself.
 */
public class ExternalTypeAnalyzers {
  private static final Map<String, String> tagToElementType = Maps.newHashMap();
  static {
    tagToElementType.put("A", "AnchorElement");
    tagToElementType.put("AREA", "AreaElement");
    tagToElementType.put("BR", "BRElement");
    tagToElementType.put("BASE", "BaseElement");
    tagToElementType.put("BODY", "BodyElement");
    tagToElementType.put("BUTTON", "ButtonElement");
    tagToElementType.put("CANVAS", "CanvasElement");
    tagToElementType.put("DL", "DListElement");
    tagToElementType.put("DETAILS", "DetailsElement");
    tagToElementType.put("DIV", "DivElement");
    tagToElementType.put("EMBED", "EmbedElement");
    tagToElementType.put("FIELDSET", "FieldSetElement");
    tagToElementType.put("FORM", "FormElement");
    tagToElementType.put("HR", "HRElement");
    tagToElementType.put("HEAD", "HeadElement");
    tagToElementType.put("H1", "HeadingElement");
    tagToElementType.put("H2", "HeadingElement");
    tagToElementType.put("H3", "HeadingElement");
    tagToElementType.put("H4", "HeadingElement");
    tagToElementType.put("H5", "HeadingElement");
    tagToElementType.put("H6", "HeadingElement");
    tagToElementType.put("HTML", "HtmlElement");
    tagToElementType.put("IFRAME", "IFrameElement");
    tagToElementType.put("IMG", "ImageElement");
    tagToElementType.put("INPUT", "InputElement");
    tagToElementType.put("KEYGEN", "KeygenElement");
    tagToElementType.put("LI", "LIElement");
    tagToElementType.put("LABEL", "LabelElement");
    tagToElementType.put("LEGEND", "LegendElement");
    tagToElementType.put("LINK", "LinkElement");
    tagToElementType.put("MAP", "MapElement");
    tagToElementType.put("MENU", "MenuElement");
    tagToElementType.put("METER", "MeterElement");
    tagToElementType.put("OL", "OListElement");
    tagToElementType.put("OBJECT", "ObjectElement");
    tagToElementType.put("OPTGROUP", "OptGroupElement");
    tagToElementType.put("OUTPUT", "OutputElement");
    tagToElementType.put("P", "ParagraphElement");
    tagToElementType.put("PARAM", "ParamElement");
    tagToElementType.put("PRE", "PreElement");
    tagToElementType.put("PROGRESS", "ProgressElement");
    tagToElementType.put("SCRIPT", "ScriptElement");
    tagToElementType.put("SELECT", "SelectElement");
    tagToElementType.put("SOURCE", "SourceElement");
    tagToElementType.put("SPAN", "SpanElement");
    tagToElementType.put("STYLE", "StyleElement");
    tagToElementType.put("CAPTION", "TableCaptionElement");
    tagToElementType.put("TD", "TableCellElement");
    tagToElementType.put("COL", "TableColElement");
    tagToElementType.put("TABLE", "TableElement");
    tagToElementType.put("TR", "TableRowElement");
    tagToElementType.put("TEXTAREA", "TextAreaElement");
    tagToElementType.put("TITLE", "TitleElement");
    tagToElementType.put("TRACK", "TrackElement");
    tagToElementType.put("UL", "UListElement");
    tagToElementType.put("VIDEO", "VideoElement");
    tagToElementType.put("DART_EDITOR_NO_SUCH_TYPE", "DartEditorNoSuchElement");
  }

  /**
   * Attempts to make better guess about return type of invocation.
   * 
   * @return the better {@link Type} guess, may be "defaultType" if cannot make better guess.
   */
  public static Type resolve(Types types, DartUnqualifiedInvocation invocation, Element element,
      Type defaultType) {
    if (element == null) {
      return defaultType;
    }
    String name = element.getName();
    List<DartExpression> arguments = invocation.getArguments();
    LibraryElement libraryElement = Elements.getDeclaringLibrary(element);
    // html.query(String)
    if ("query".equals(name) && isHtmlLibraryFunction(element)) {
      return analyzeQuery(arguments, libraryElement, defaultType);
    }
    // no guess
    return defaultType;
  }

  /**
   * Attempts to make better guess about return type of invocation.
   * 
   * @return the better {@link Type} guess, may be "defaultType" if cannot make better guess.
   */
  public static Type resolve(Types types, DartMethodInvocation invocation, Element element,
      Type defaultType) {
    if (element == null) {
      return defaultType;
    }
    String name = element.getName();
    List<DartExpression> arguments = invocation.getArguments();
    LibraryElement libraryElement = Elements.getDeclaringLibrary(element);
    // Document.query(String)
    if ("query".equals(name) && isDeclaredInHtmlLibrary(element)) {
      return analyzeQuery(arguments, libraryElement, defaultType);
    }
    // no guess
    return defaultType;
  }

  private static Type analyzeQuery(List<DartExpression> arguments, LibraryElement libraryElement,
      Type defaultType) {
    if (arguments.size() == 1 && arguments.get(0) instanceof DartStringLiteral) {
      String selectors = ((DartStringLiteral) arguments.get(0)).getValue();
      // if has spaces, full parsing required, because may be: E[text='warning text']
      if (selectors.contains(" ")) {
        return defaultType;
      }
      // try to extract tag
      // http://www.w3.org/TR/CSS2/selector.html
      String tag = selectors;
      tag = StringUtils.substringBefore(tag, ":");
      tag = StringUtils.substringBefore(tag, "[");
      tag = StringUtils.substringBefore(tag, ".");
      tag = StringUtils.substringBefore(tag, "#");
      tag = tag.toUpperCase();
      // prepare Element type name
      String tagTypeName = tagToElementType.get(tag);
      if (tagTypeName == null) {
        return defaultType;
      }
      // lookup tag Element
      Element tagTypeElement = libraryElement.lookupLocalElement(tagTypeName);
      if (tagTypeElement == null) {
        return defaultType;
      }
      // OK, we know more specific return type
      Type tagType = tagTypeElement.getType();
      if (tagType != null) {
        return tagType;
      }
    }
    // no guess
    return defaultType;
  }

  private static boolean isHtmlLibraryFunction(Element element) {
    return ElementKind.of(element) == ElementKind.METHOD && isDeclaredInHtmlLibrary(element);
  }

  private static boolean isDeclaredInHtmlLibrary(Element element) {
    LibraryElement libraryElement = Elements.getDeclaringLibrary(element);
    return StringUtils.startsWith(libraryElement.getName(), "dart://html");
  }
}
