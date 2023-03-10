// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart';
import 'package:analyzer/src/error/codes.dart';

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
  /// See [CompileTimeErrorCode.SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED],
  /// [CompileTimeErrorCode.SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED]
  void checkElement(ClassOrMixinElementImpl element) {
    if (_elementToBaseOrFinalSuperElement.containsKey(element)) {
      // We've already visited this element. Don't check it again.
      return;
    } else {
      _elementToBaseOrFinalSuperElement[element] = null;
    }

    final supertype = element.supertype;
    if (supertype != null && _checkSupertypes([supertype], element)) {
      return;
    }
    if (_checkSupertypes(element.interfaces, element)) {
      return;
    }
    if (_checkSupertypes(element.mixins, element)) {
      return;
    }
    if (_checkSupertypes(element.interfaces, element)) {
      return;
    }
    if (element is MixinElementImpl &&
        _checkSupertypes(element.superclassConstraints, element,
            areSuperclassConstraints: true)) {
      return;
    }
  }

  bool _checkSupertypes(
      List<InterfaceType> supertypes, ClassOrMixinElementImpl subElement,
      {bool areSuperclassConstraints = false}) {
    for (final supertype in supertypes) {
      final supertypeElement = supertype.element;
      if (supertypeElement is ClassOrMixinElementImpl) {
        // Ensure that all superelements are properly cached in
        // [_elementToBaseOrFinalSuperElement].
        checkElement(supertypeElement);

        // Return early if an error has been reported to prevent reporting
        // multiple errors on one element.
        if (_reportRestrictionError(subElement, supertypeElement,
            isSuperclassConstraint: areSuperclassConstraints)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Checks whether a `final`, `base` or `interface` modifier can be ignored.
  ///
  /// Checks whether a subclass in the current library
  /// can ignore a class modifier of a declaration in [superLibrary].
  ///
  /// Only true if the supertype library is a platform library, and
  /// either the current library is also a platform library,
  /// or the current library has a language version which predates
  /// class modifiers
  bool _mayIgnoreClassModifiers(LibraryElement superLibrary) {
    // Only modifiers in platform libraries can be ignored.
    if (!superLibrary.isInSdk) return false;

    // Other platform libraries can ignore modifiers.
    if (_definingLibrary.isInSdk) return true;

    // Libraries predating class modifiers can ignore platform modifiers.
    return !_definingLibrary.featureSet.isEnabled(Feature.class_modifiers);
  }

  /// Returns true if a element modifier restriction error has been reported.
  ///
  /// Reports an error based on the modifier of the superElement.
  bool _reportRestrictionError(
      ClassOrMixinElementImpl element, ClassOrMixinElementImpl superElement,
      {bool isSuperclassConstraint = false}) {
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
      // The superelement is a sealed element or an element of a
      // legacy library.
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
    if (!element.isBase &&
        !element.isFinal &&
        !element.isSealed &&
        !_mayIgnoreClassModifiers(baseOrFinalSuperElement.library)) {
      final contextMessage = <DiagnosticMessage>[
        DiagnosticMessageImpl(
          filePath: superElement.source.fullName,
          length: superElement.nameLength,
          message: "The type '${superElement.displayName}' is a subtype of "
              "'${baseOrFinalSuperElement.displayName}', and "
              "'${superElement.name}' is defined here.",
          offset: superElement.nameOffset,
          url: null,
        )
      ];

      if (baseOrFinalSuperElement.isFinal) {
        if (!isSuperclassConstraint &&
            baseOrFinalSuperElement.library != element.library) {
          // If you can't extend, implement or mix in a final element outside of
          // its library anyways, it's not helpful to report a subelement
          // modifier error.
          return false;
        }
        _errorReporter.reportErrorForElement(
            CompileTimeErrorCode.SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
            element,
            [element.displayName, baseOrFinalSuperElement.displayName],
            hasCachedBaseOrFinalSuperElement ? contextMessage : null);
        return true;
      } else if (baseOrFinalSuperElement.isBase) {
        _errorReporter.reportErrorForElement(
            CompileTimeErrorCode.SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED,
            element,
            [element.displayName, baseOrFinalSuperElement.displayName],
            hasCachedBaseOrFinalSuperElement ? contextMessage : null);
        return true;
      }
    }

    return false;
  }
}
