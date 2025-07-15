// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/computer/computer_overrides.dart';
import 'package:analysis_server/src/utilities/extensions/element.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dartdoc/dartdoc_directive_info.dart';

/// Computes documentation for an [Element].
class DartDocumentationComputer {
  final DartdocDirectiveInfo dartdocInfo;

  DartDocumentationComputer(this.dartdocInfo);

  Documentation? compute(
    Element elementBeingDocumented, {
    bool includeSummary = false,
  }) {
    var element = elementBeingDocumented.elementWithDocumentation;
    if (element == null) {
      // This can happen when the code is invalid, such as having an
      // initializing formal parameter for a field that does not exist.
      return null;
    }

    Element? documentedElement;
    Element? documentedGetter;

    // Look for documentation comments of overridden members
    var overridden = findOverriddenElements(element);
    var candidates = [
      element,
      ...overridden.superElements,
      ...overridden.interfaceElements,
      if (element case PropertyAccessorElement(:var variable?)) variable,
    ];
    for (var candidate in candidates) {
      if (candidate.documentationCommentOrNull != null) {
        documentedElement = candidate;
        break;
      }
      if (documentedGetter == null && candidate is SetterElement) {
        var getter = candidate.correspondingGetter;
        if (getter != null && getter.documentationComment != null) {
          documentedGetter = getter;
        }
      }
    }

    // Use documentation of a corresponding getter if setters don't have it
    documentedElement ??= documentedGetter;
    if (documentedElement == null) {
      return null;
    }

    var rawDoc = documentedElement.documentationCommentOrNull;
    if (rawDoc == null) {
      return null;
    }
    var result = dartdocInfo.processDartdoc(
      rawDoc,
      includeSummary: includeSummary,
    );

    var documentedElementClass = documentedElement.enclosingElement;
    if (documentedElementClass != null &&
        documentedElementClass != element.enclosingElement) {
      var documentedClass = documentedElementClass.displayName;
      result.full = '${result.full}\n\nCopied from `$documentedClass`.';
    }

    return result;
  }

  /// Compute documentation for [element] and return either the summary or full
  /// docs (or `null`) depending on `preference`.
  String? computePreferred(
    Element element,
    DocumentationPreference preference,
  ) {
    if (preference == DocumentationPreference.none) {
      return null;
    }

    var doc = compute(
      element,
      includeSummary: preference == DocumentationPreference.summary,
    );

    return doc is DocumentationWithSummary ? doc.summary : doc?.full;
  }
}

/// The type of documentation the user prefers to see in hovers and other
/// related displays in their editor.
enum DocumentationPreference { none, summary, full }

extension on Element {
  /// The element whose documentation should be used when showing documentation
  /// for this element.
  Element? get elementWithDocumentation {
    var self = this;
    if (self is FieldFormalParameterElement) {
      return self.field;
    } else if (self is SuperFormalParameterElement) {
      // Treat a super formal parameter like a field formal parameter if it's
      // eventually assigned to a field, but as any other formal parameter if it
      // isn't.
      var superParameter = self.superConstructorParameter;
      while (superParameter is SuperFormalParameterElement) {
        superParameter = superParameter.superConstructorParameter;
      }
      if (superParameter is FieldFormalParameterElement) {
        return superParameter.field;
      }
      return self.enclosingElement;
    } else if (self is FormalParameterElement) {
      return self.enclosingElement;
    }
    return this;
  }
}
