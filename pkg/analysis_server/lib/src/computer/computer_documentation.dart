// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/computer/computer_overrides.dart';
import 'package:analysis_server/src/utilities/extensions/element.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/dartdoc/dartdoc_directive_info.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';

/// Computes documentation for an [Element].
class DartDocumentationComputer {
  final DartdocDirectiveInfo dartdocInfo;

  DartDocumentationComputer(this.dartdocInfo);

  Documentation? compute(
    Element elementBeingDocumented, {
    bool includeSummary = false,
  }) {
    // TODO(dantup): Remove this temporary implementation used to split
    //  migration of this class and callers into separate changes.
    var element2 = elementBeingDocumented.asElement2;

    return element2 != null
        ? compute2(element2, includeSummary: includeSummary)
        : null;
  }

  Documentation? compute2(
    Element2 elementBeingDocumented, {
    bool includeSummary = false,
  }) {
    var element = switch (elementBeingDocumented) {
      FieldFormalParameterElement2() => elementBeingDocumented.field2,
      FormalParameterElement() => elementBeingDocumented.enclosingElement2,
      _ => elementBeingDocumented,
    };
    if (element == null) {
      // This can happen when the code is invalid, such as having a field formal
      // parameter for a field that does not exist.
      return null;
    }

    Element2? documentedElement;
    Element2? documentedGetter;

    // Look for documentation comments of overridden members
    var overridden = findOverriddenElements(element);
    var candidates = [
      element,
      ...overridden.superElements,
      ...overridden.interfaceElements,
      if (element case GetterElement(variable3: var variable?)) variable,
      if (element case SetterElement(variable3: var variable?)) variable
    ];
    for (var candidate in candidates) {
      if (candidate.documentationCommentOrNull != null) {
        documentedElement = candidate;
        break;
      }
      if (documentedGetter == null && candidate is SetterElement) {
        var getter = candidate.correspondingGetter2;
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
    var result =
        dartdocInfo.processDartdoc(rawDoc, includeSummary: includeSummary);

    var documentedElementClass = documentedElement.enclosingElement2;
    if (documentedElementClass != null &&
        documentedElementClass != element.enclosingElement2) {
      var documentedClass = documentedElementClass.displayName;
      result.full = '${result.full}\n\nCopied from `$documentedClass`.';
    }

    return result;
  }

  /// Compute documentation for [element] and return either the summary or full
  /// docs (or `null`) depending on `preference`.
  String? computePreferred(
      Element element, DocumentationPreference preference) {
    // TODO(dantup): Remove this temporary implementation used to split
    //  migration of this class and callers into separate changes.
    var element2 = element.asElement2;
    return element2 != null ? computePreferred2(element2, preference) : null;
  }

  /// Compute documentation for [element] and return either the summary or full
  /// docs (or `null`) depending on `preference`.
  String? computePreferred2(
      Element2 element, DocumentationPreference preference) {
    if (preference == DocumentationPreference.none) {
      return null;
    }

    var doc = compute2(
      element,
      includeSummary: preference == DocumentationPreference.summary,
    );

    return doc is DocumentationWithSummary ? doc.summary : doc?.full;
  }
}

/// The type of documentation the user prefers to see in hovers and other
/// related displays in their editor.
enum DocumentationPreference {
  none,
  summary,
  full,
}
