// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Summary information for components and libraries.
 *
 * These classes are used for modular compilation. Summaries are a subset of the
 * information collected by Info objects (see `info.dart`). When we are
 * compiling a single file, the information extracted from that file is stored
 * as info objects, but any information that is needed from other files (like
 * imported components) is stored as a summary.
 */
library polymer.src.summary;

import 'package:source_maps/span.dart' show Span;

// TODO(sigmund): consider moving UrlInfo out of info.dart
import 'info.dart' show UrlInfo;

/**
 * Summary information from other library-like objects, which includes HTML
 * components and dart libraries).
 */
class LibrarySummary {
  /** Path to the sources represented by this summary. */
  final UrlInfo dartCodeUrl;

  /** Name given to this source after it was compiled. */
  final String outputFilename;

  LibrarySummary(this.dartCodeUrl, this.outputFilename);
}

/** Summary information for an HTML file that defines custom elements. */
class HtmlFileSummary extends LibrarySummary {
  /**
   * Summary of each component defined either explicitly the HTML file or
   * included transitively from `<link rel="import">` tags.
   */
  final Map<String, ComponentSummary> components;

  HtmlFileSummary(UrlInfo dartCodeUrl, String outputFilename, this.components)
      : super(dartCodeUrl, outputFilename);
}

/** Information about a web component definition. */
class ComponentSummary extends LibrarySummary {
  /** The component tag name, defined with the `name` attribute on `element`. */
  final String tagName;

  /**
   * The tag name that this component extends, defined with the `extends`
   * attribute on `element`.
   */
  final String extendsTag;

  /**
   * The Dart class containing the component's behavior, derived from tagName or
   * defined in the `constructor` attribute on `element`.
   */
  final String className;

  /** Summary of the base component, if any. */
  final ComponentSummary extendsComponent;

  /**
   * True if [tagName] was defined by more than one component. Used internally
   * by the analyzer. Conflicting component will be skipped by the compiler.
   */
  bool hasConflict;

  /** Original span where this component is declared. */
  final Span sourceSpan;

  ComponentSummary(UrlInfo dartCodeUrl, String outputFilename,
      this.tagName, this.extendsTag, this.className, this.extendsComponent,
      this.sourceSpan, [this.hasConflict = false])
      : super(dartCodeUrl, outputFilename);

  /**
   * Gets the HTML tag extended by the base of the component hierarchy.
   * Equivalent to [extendsTag] if this inherits directly from an HTML element,
   * in other words, if [extendsComponent] is null.
   */
  String get baseExtendsTag =>
      extendsComponent == null ? extendsTag : extendsComponent.baseExtendsTag;
}
