// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/computer/computer_overrides.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dartdoc/dartdoc_directive_info.dart';

/// Intermediate targets used to split computing documentation into two steps
/// to optimize some requests (like code completion).
typedef DocumentationTargets = ({
  Element targetElement,
  Element documentedElement,
});

/// Computes documentation for an [Element].
class DartDocumentationComputer {
  final DartdocDirectiveInfo dartdocInfo;

  new(this.dartdocInfo);

  /// Computes the documentation to show for [sourceElement].
  ///
  /// This is a the same as calling [computeDocumentedElement] and
  /// [computeForTargets] which are split out for operations like Code
  /// Completion that might need to compute docs for a large number of elements
  /// and can lazily (via `/resolve`) compute the final docs.
  Documentation? compute(
    Element sourceElement, {
    required bool includeSummary,
    required bool includeFull,
  }) {
    var elements = computeDocumentedElement(sourceElement);
    if (elements == null) {
      return null;
    }

    return computeForTargets(
      elements,
      includeSummary: includeSummary,
      includeFull: includeFull,
    );
  }

  /// Given a [sourceElement], computes the element whose documentation should be
  /// look for (the target element) and the actual element that contains the
  /// documentation to show (the documented element).
  ///
  /// The target element is different to [sourceElement] for things like field
  /// formal parameters.
  ///
  /// The documented element is different to the target element when the target
  /// overrides a base member and does not have its own documentation but
  /// instead inherits it from the base.
  DocumentationTargets? computeDocumentedElement(Element sourceElement) {
    var targetElement = sourceElement.elementWithDocumentation;
    if (targetElement == null) {
      // This can happen when the code is invalid, such as having an
      // initializing formal parameter for a field that does not exist.
      return null;
    }

    Element? documentedElement;
    Element? documentedGetter;

    // Look for documentation comments of overridden members
    for (var candidate in _documentationCandidates(targetElement)) {
      if (candidate.documentationComment != null) {
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

    var rawDoc = documentedElement.documentationComment;
    if (rawDoc == null) {
      return null;
    }

    return (targetElement: targetElement, documentedElement: documentedElement);
  }

  /// Computes the final documentation given the precomputed target [elements].
  ///
  /// This resolves documentation macros, adds "Copied from..." suffixes, and if
  /// [includeSummary] computes the summary doc and [includeFull] computes the
  /// full doc.
  Documentation? computeForTargets(
    DocumentationTargets elements, {
    required bool includeSummary,
    required bool includeFull,
  }) {
    var (:targetElement, :documentedElement) = elements;

    var rawDoc = documentedElement.documentationComment;
    if (rawDoc == null) {
      return null;
    }
    var result = dartdocInfo.processDartdoc(
      rawDoc,
      includeSummary: includeSummary,
      includeFull: includeFull,
    );

    var full = result.full;
    var documentedElementClass = documentedElement.enclosingElement;
    if (full != null &&
        documentedElementClass != null &&
        documentedElementClass != targetElement.enclosingElement) {
      var documentedClass = documentedElementClass.displayName;
      result.full = '$full\n\nCopied from `$documentedClass`.';
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

    var wantSummary = preference == DocumentationPreference.summary;
    var doc = compute(
      element,
      includeSummary: wantSummary,
      includeFull: !wantSummary,
    );

    return wantSummary ? doc?.summary : doc?.full;
  }

  /// Lazily iterates through elements that might supply documentation for
  /// [element], in priority order.
  Iterable<Element> _documentationCandidates(Element element) sync* {
    // Use yield so we can avoid calling `findOverridenElements` unnecessarily
    // if `element` has the documentation we want.
    yield element;
    var overridden = findOverriddenElements(element);
    yield* overridden.superElements;
    yield* overridden.interfaceElements;
    if (element case PropertyAccessorElement(:var variable)) yield variable;
  }
}

/// The preferred kind of documentation for requests that might return many
/// results and could have large payloads when docs are included
enum DocumentationPreference { none, summary, full }

extension on Element {
  /// The element whose documentation should be used when showing documentation
  /// for this element.
  Element? get elementWithDocumentation {
    if (this is FieldFormalParameterElement) {
      return field;
    } else if (this is SuperFormalParameterElement) {
      // Treat a super formal parameter like a field formal parameter if it's
      // eventually assigned to a field, but as any other formal parameter if it
      // isn't.
      var superParameter = superConstructorParameter;
      while (superParameter is SuperFormalParameterElement) {
        superParameter = superParameter.superConstructorParameter;
      }
      if (superParameter is FieldFormalParameterElement) {
        return superParameter.field;
      }
      return enclosingElement;
    } else if (this is FormalParameterElement) {
      return enclosingElement;
    }
    return this;
  }
}
