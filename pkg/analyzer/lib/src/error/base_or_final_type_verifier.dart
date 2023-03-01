// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';

/// Helper for verifying that subelements of a base or final element must be
/// base, final, or sealed.
class BaseOrFinalTypeVerifier {
  final LibraryElement _definingLibrary;
  final ErrorReporter _errorReporter;

  /// Maps an element to a base or final superelement.
  /// May be null if the type does not have one.
  final Map<ClassOrMixinElementImpl, ClassOrMixinElementImpl?>
      _elementToBaseOrFinalSuperElement = {};

  BaseOrFinalTypeVerifier({
    required LibraryElement definingLibrary,
    required ErrorReporter errorReporter,
  })  : _definingLibrary = definingLibrary,
        _errorReporter = errorReporter;

  /// Check to ensure the subelement of a base or final element must be base,
  /// final, or sealed. Otherwise, an error is reported on that element.
  ///
  /// See [CompileTimeErrorCode.
  /// SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED]
  void checkElement(ClassOrMixinElementImpl element) {
    if (_elementToBaseOrFinalSuperElement.containsKey(element)) {
      // We've already visited this element. Don't check it again.
      return;
    } else {
      _elementToBaseOrFinalSuperElement[element] = null;
    }

    List<InterfaceType> supertypes = [];
    supertypes.addIfNotNull(element.supertype);
    supertypes.addAll(element.interfaces);
    supertypes.addAll(element.mixins);
    if (element is MixinElementImpl) {
      supertypes.addAll(element.superclassConstraints);
    }

    for (final supertype in supertypes) {
      final supertypeElement = supertype.element;
      if (supertypeElement is ClassOrMixinElementImpl) {
        // Ensure that all superelements are properly cached in
        // [_elementToBaseOrFinalSuperElement].
        checkElement(supertypeElement);

        // Return early if an error has been reported to prevent reporting
        // multiple errors on one element.
        if (_reportRestrictionError(element, supertypeElement)) {
          return;
        }
      }
    }
  }

  /// Returns true if a element modifier restriction error has been reported.
  ///
  /// Reports an error based on the modifier of the superElement.
  bool _reportRestrictionError(
      ClassOrMixinElementImpl element, ClassOrMixinElementImpl superElement) {
    final cachedBaseOrFinalSuperElement =
        _elementToBaseOrFinalSuperElement[superElement];
    final hasCachedBaseOrFinalSuperElement =
        cachedBaseOrFinalSuperElement != null;
    ClassOrMixinElementImpl? baseOrFinalSuperElement;

    if (superElement.isBase || superElement.isFinal) {
      // Prefer the direct base or final superelement.
      baseOrFinalSuperElement = superElement;
    } else if (hasCachedBaseOrFinalSuperElement) {
      // There's a base or final element higher up in the class hierarchy.
      // The superelement is a sealed element.
      baseOrFinalSuperElement = cachedBaseOrFinalSuperElement;
    } else {
      // There are no restrictions on this element's modifiers.
      return false;
    }

    _elementToBaseOrFinalSuperElement[element] = baseOrFinalSuperElement;

    if (element.library != _definingLibrary) {
      // Only report errors on elements within the current library.
      return false;
    }
    if (!element.isBase && !element.isFinal && !element.isSealed) {
      final contextMessage = <DiagnosticMessage>[
        DiagnosticMessageImpl(
          filePath: superElement.source.fullName,
          length: superElement.nameLength,
          message: "The type '${superElement.name}' is a subtype of "
              "'${baseOrFinalSuperElement.name}', and "
              "'${superElement.name}' is defined here.",
          offset: superElement.nameOffset,
          url: null,
        )
      ];

      _errorReporter.reportErrorForElement(
          CompileTimeErrorCode
              .SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
          element,
          [
            element.displayName,
            baseOrFinalSuperElement.displayName,
            baseOrFinalSuperElement.isBase
                ? Keyword.BASE.lexeme
                : Keyword.FINAL.lexeme
          ],
          hasCachedBaseOrFinalSuperElement ? contextMessage : null);
      return true;
    }

    return false;
  }
}
