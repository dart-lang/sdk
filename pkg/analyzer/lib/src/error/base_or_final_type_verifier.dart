// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
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

  BaseOrFinalTypeVerifier({
    required LibraryElement definingLibrary,
    required ErrorReporter errorReporter,
  })  : _definingLibrary = definingLibrary,
        _errorReporter = errorReporter;

  /// Check to ensure the subelement of a base or final element must be base,
  /// final, or sealed and that base elements are not implemented outside of its
  /// library. Otherwise, an error is reported on that element.
  ///
  /// See [CompileTimeErrorCode.SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED],
  /// [CompileTimeErrorCode.SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED],
  /// [CompileTimeErrorCode.BASE_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY].
  void checkElement(
      ClassOrMixinElementImpl element, ImplementsClause? implementsClause) {
    final supertype = element.supertype;
    if (supertype != null && _checkSupertypes([supertype], element)) {
      return;
    }
    if (implementsClause != null &&
        _checkInterfaceSupertypes(implementsClause.interfaces, element,
            areImplementedInterfaces: true)) {
      return;
    }
    if (_checkSupertypes(element.mixins, element)) {
      return;
    }
    if (element is MixinElementImpl &&
        _checkSupertypes(element.superclassConstraints, element,
            areSuperclassConstraints: true)) {
      return;
    }
  }

  /// Returns true if a 'base' or 'final' subtype modifier error is reported for
  /// an interface in [interfaces].
  bool _checkInterfaceSupertypes(
      List<NamedType> interfaces, ClassOrMixinElementImpl subElement,
      {bool areImplementedInterfaces = false}) {
    for (NamedType interface in interfaces) {
      final interfaceType = interface.type;
      if (interfaceType is InterfaceType) {
        final interfaceElement = interfaceType.element;
        if (interfaceElement is ClassOrMixinElementImpl) {
          // Return early if an error has been reported to prevent reporting
          // multiple errors on one element.
          if (_reportRestrictionError(subElement, interfaceElement,
              implementsNamedType: interface)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  /// Returns true if a 'base' or 'final' subtype modifier error is reported for
  /// a supertype in [supertypes].
  bool _checkSupertypes(
      List<InterfaceType> supertypes, ClassOrMixinElementImpl subElement,
      {bool areSuperclassConstraints = false}) {
    for (final supertype in supertypes) {
      final supertypeElement = supertype.element;
      if (supertypeElement is ClassOrMixinElementImpl) {
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

  /// Returns the nearest explicitly declared 'base' or 'final' element in the
  /// element hierarchy for [element].
  ClassOrMixinElementImpl? _getExplicitlyBaseOrFinalElement(
      ClassOrMixinElementImpl element) {
    // The current element has an explicit 'base' or 'final' modifier.
    if ((element.isBase || element.isFinal) && !element.isSealed) {
      return element;
    }

    ClassOrMixinElementImpl? baseOrFinalSuperElement;
    final supertype = element.supertype;
    if (supertype != null) {
      baseOrFinalSuperElement ??=
          _getExplicitlyBaseOrFinalElementFromSuperTypes([supertype]);
    }
    baseOrFinalSuperElement ??=
        _getExplicitlyBaseOrFinalElementFromSuperTypes(element.interfaces);
    baseOrFinalSuperElement ??=
        _getExplicitlyBaseOrFinalElementFromSuperTypes(element.mixins);
    if (element is MixinElementImpl) {
      baseOrFinalSuperElement ??=
          _getExplicitlyBaseOrFinalElementFromSuperTypes(
              element.superclassConstraints);
    }
    return baseOrFinalSuperElement;
  }

  /// Returns the first explicitly declared 'base' or 'final' element found in
  /// the class hierarchies of a supertype in [supertypes], or `null` if there
  /// is none.
  ClassOrMixinElementImpl? _getExplicitlyBaseOrFinalElementFromSuperTypes(
      List<InterfaceType> supertypes) {
    ClassOrMixinElementImpl? baseOrFinalElement;
    for (final supertype in supertypes) {
      final supertypeElement = supertype.element;
      if (supertypeElement is ClassOrMixinElementImpl) {
        baseOrFinalElement = _getExplicitlyBaseOrFinalElement(supertypeElement);
        if (baseOrFinalElement != null) {
          return baseOrFinalElement;
        }
      }
    }
    return baseOrFinalElement;
  }

  /// Checks whether a `final`, `base` or `interface` modifier can be ignored.
  ///
  /// Checks whether a subclass in the current library
  /// can ignore a class modifier of a declaration in [superLibrary].
  ///
  /// Only true if the supertype library is a platform library, and
  /// either the current library is also a platform library,
  /// or the current library has a language version which predates
  /// class modifiers.
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
  /// Reports an error based on the modifier of the [superElement].
  bool _reportRestrictionError(
      ClassOrMixinElementImpl element, ClassOrMixinElementImpl superElement,
      {bool isSuperclassConstraint = false, NamedType? implementsNamedType}) {
    ClassOrMixinElementImpl? baseOrFinalSuperElement;
    if (superElement.isBase || superElement.isFinal) {
      // The 'base' or 'final' modifier may be an induced modifier. Find the
      // explicitly declared 'base' or 'final' in the hierarchy.
      baseOrFinalSuperElement = _getExplicitlyBaseOrFinalElement(superElement);
    } else {
      // There are no restrictions on this element's modifiers.
      return false;
    }

    if (element.library != _definingLibrary) {
      // Only report errors on elements within the current library.
      return false;
    }
    if (baseOrFinalSuperElement != null &&
        !_mayIgnoreClassModifiers(baseOrFinalSuperElement.library)) {
      // The context message links to the explicitly declared 'base' or 'final'
      // super element and is only added onto the error if 'base' or 'final' is
      // an induced modifier of the direct super element.
      final contextMessage = <DiagnosticMessage>[
        DiagnosticMessageImpl(
          filePath: baseOrFinalSuperElement.source.fullName,
          length: baseOrFinalSuperElement.nameLength,
          message: "The type '${superElement.displayName}' is a subtype of "
              "'${baseOrFinalSuperElement.displayName}', and "
              "'${baseOrFinalSuperElement.displayName}' is defined here.",
          offset: baseOrFinalSuperElement.nameOffset,
          url: null,
        )
      ];

      // It's an error to implement a class if it has a supertype from a
      // different library which is marked base.
      if (implementsNamedType != null &&
          superElement.isSealed &&
          baseOrFinalSuperElement.library != element.library) {
        if (baseOrFinalSuperElement.isBase) {
          _errorReporter.reportErrorForNode(
              CompileTimeErrorCode.BASE_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY,
              implementsNamedType,
              [baseOrFinalSuperElement.displayName],
              contextMessage);
          return true;
        }
      }

      if (!element.isBase && !element.isFinal && !element.isSealed) {
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
              superElement.isSealed ? contextMessage : null);
          return true;
        } else if (baseOrFinalSuperElement.isBase) {
          _errorReporter.reportErrorForElement(
              CompileTimeErrorCode.SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED,
              element,
              [element.displayName, baseOrFinalSuperElement.displayName],
              superElement.isSealed ? contextMessage : null);
          return true;
        }
      }
    }

    return false;
  }
}
