// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart';
import 'package:analyzer/src/error/codes.dart';

/// Helper for verifying that subelements of a base or final element must be
/// base, final, or sealed.
class BaseOrFinalTypeVerifier {
  final LibraryElement2 _definingLibrary;
  final ErrorReporter _errorReporter;

  BaseOrFinalTypeVerifier({
    required LibraryElement2 definingLibrary,
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
      InterfaceElementImpl2 element, ImplementsClause? implementsClause) {
    var supertype = element.supertype;
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
    if (element is MixinElementImpl2 &&
        _checkSupertypes(element.superclassConstraints, element)) {
      return;
    }
  }

  /// Returns true if a 'base' or 'final' subtype modifier error is reported for
  /// an interface in [interfaces].
  bool _checkInterfaceSupertypes(
      List<NamedType> interfaces, InterfaceElementImpl2 subElement,
      {bool areImplementedInterfaces = false}) {
    for (NamedType interface in interfaces) {
      var interfaceType = interface.type;
      if (interfaceType is InterfaceType) {
        var interfaceElement = interfaceType.element3;
        if (interfaceElement is InterfaceElementImpl2) {
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
      List<InterfaceType> supertypes, InterfaceElementImpl2 subElement) {
    for (var supertype in supertypes) {
      var supertypeElement = supertype.element3;
      if (supertypeElement is InterfaceElementImpl2) {
        // Return early if an error has been reported to prevent reporting
        // multiple errors on one element.
        if (_reportRestrictionError(subElement, supertypeElement)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Returns the nearest explicitly declared 'base' or 'final' element in the
  /// element hierarchy for [element].
  InterfaceElementImpl2? _getExplicitlyBaseOrFinalElement(
      InterfaceElementImpl2 element) {
    // The current element has an explicit 'base' or 'final' modifier.
    if ((element.isBase || element.isFinal) && !element.isSealed) {
      return element;
    }

    InterfaceElementImpl2? baseOrFinalSuperElement;
    var supertype = element.supertype;
    if (supertype != null) {
      baseOrFinalSuperElement ??=
          _getExplicitlyBaseOrFinalElementFromSuperTypes([supertype]);
    }
    baseOrFinalSuperElement ??=
        _getExplicitlyBaseOrFinalElementFromSuperTypes(element.interfaces);
    baseOrFinalSuperElement ??=
        _getExplicitlyBaseOrFinalElementFromSuperTypes(element.mixins);
    if (element is MixinElementImpl2) {
      baseOrFinalSuperElement ??=
          _getExplicitlyBaseOrFinalElementFromSuperTypes(
              element.superclassConstraints);
    }
    return baseOrFinalSuperElement;
  }

  /// Returns the first explicitly declared 'base' or 'final' element found in
  /// the class hierarchies of a supertype in [supertypes], or `null` if there
  /// is none.
  InterfaceElementImpl2? _getExplicitlyBaseOrFinalElementFromSuperTypes(
      List<InterfaceType> supertypes) {
    InterfaceElementImpl2? baseOrFinalElement;
    for (var supertype in supertypes) {
      var supertypeElement = supertype.element3;
      if (supertypeElement is InterfaceElementImpl2) {
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
  bool _mayIgnoreClassModifiers(LibraryElement2 superLibrary) {
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
      InterfaceElementImpl2 element, InterfaceElementImpl2 superElement,
      {NamedType? implementsNamedType}) {
    // Only report errors on elements within the current library.
    if (element.library2 != _definingLibrary) {
      return false;
    }

    InterfaceElementImpl2? baseOrFinalSuperElement;
    if (superElement.isBase ||
        superElement.isFinal ||
        (!superElement.library2.featureSet.isEnabled(Feature.class_modifiers) &&
            element.library2.featureSet.isEnabled(Feature.class_modifiers))) {
      // The 'base' or 'final' modifier may be an induced modifier. Find the
      // explicitly declared 'base' or 'final' in the hierarchy.
      // In the case where the super element is in a pre-feature library, we
      // need to check if there's an indirect core library super element.
      baseOrFinalSuperElement = _getExplicitlyBaseOrFinalElement(superElement);
    } else {
      // There are no restrictions on this element's modifiers.
      return false;
    }

    if (baseOrFinalSuperElement == null) {
      return false;
    }

    if (_mayIgnoreClassModifiers(baseOrFinalSuperElement.library2)) {
      return false;
    }

    var fragment = baseOrFinalSuperElement.firstFragment;
    var fragmentName = fragment.name2;
    var fragmentNameOffset = fragment.nameOffset2;
    if (fragmentName == null || fragmentNameOffset == null) {
      return false;
    }

    // The context message links to the explicitly declared 'base' or 'final'
    // super element and is only added onto the error if 'base' or 'final' is
    // an induced modifier of the direct super element.
    var contextMessages = <DiagnosticMessage>[
      DiagnosticMessageImpl(
        filePath: fragment.libraryFragment.source.fullName,
        length: fragmentName.length,
        message: "The type '${superElement.displayName}' is a subtype of "
            "'${baseOrFinalSuperElement.displayName}', and "
            "'${baseOrFinalSuperElement.displayName}' is defined here.",
        offset: fragmentNameOffset,
        url: null,
      )
    ];

    // It's an error to implement a class if it has a supertype from a
    // different library which is marked base.
    if (implementsNamedType != null &&
        superElement.isSealed &&
        baseOrFinalSuperElement.library2 != element.library2) {
      if (baseOrFinalSuperElement.isBase) {
        var errorCode = baseOrFinalSuperElement is MixinElement2
            ? CompileTimeErrorCode.BASE_MIXIN_IMPLEMENTED_OUTSIDE_OF_LIBRARY
            : CompileTimeErrorCode.BASE_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY;
        _errorReporter.atNode(
          implementsNamedType,
          errorCode,
          arguments: [baseOrFinalSuperElement.displayName],
          contextMessages: contextMessages,
        );
        return true;
      }
    }

    if (!element.isBase && !element.isFinal && !element.isSealed) {
      if (baseOrFinalSuperElement.isFinal) {
        // If you can't extend, implement or mix in a final element outside of
        // its library anyways, it's not helpful to report a subelement
        // modifier error.
        if (baseOrFinalSuperElement.library2 != element.library2) {
          // In the case where the 'baseOrFinalSuperElement' is a core
          // library element and we are subtyping from a super element that's
          // from a pre-feature library, we want to produce a final
          // transitivity error.
          //
          // For implements clauses with the above scenario, we avoid
          // over-reporting since there will already be a
          // [FinalClassImplementedOutsideOfLibrary] error.
          if (superElement.library2.featureSet
                  .isEnabled(Feature.class_modifiers) ||
              !baseOrFinalSuperElement.library2.isInSdk ||
              implementsNamedType != null) {
            return false;
          }
        }
        var errorCode = element is MixinElement2
            ? CompileTimeErrorCode.MIXIN_SUBTYPE_OF_FINAL_IS_NOT_BASE
            : CompileTimeErrorCode.SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED;
        _errorReporter.atElement2(
          element,
          errorCode,
          arguments: [
            element.displayName,
            baseOrFinalSuperElement.displayName,
          ],
          contextMessages: superElement.isSealed ? contextMessages : null,
        );
        return true;
      } else if (baseOrFinalSuperElement.isBase) {
        var errorCode = element is MixinElement2
            ? CompileTimeErrorCode.MIXIN_SUBTYPE_OF_BASE_IS_NOT_BASE
            : CompileTimeErrorCode.SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED;
        _errorReporter.atElement2(
          element,
          errorCode,
          arguments: [
            element.displayName,
            baseOrFinalSuperElement.displayName,
          ],
          contextMessages: superElement.isSealed ? contextMessages : null,
        );
        return true;
      }
    }

    return false;
  }
}

extension on InterfaceElementImpl2 {
  bool get isBase {
    switch (this) {
      case ClassElementImpl2 element:
        return element.isBase;
      case MixinElementImpl2 element:
        return element.isBase;
    }
    return false;
  }

  bool get isFinal {
    switch (this) {
      case ClassElementImpl2 element:
        return element.isFinal;
    }
    return false;
  }

  bool get isSealed {
    switch (this) {
      case ClassElementImpl2 element:
        return element.isSealed;
    }
    return false;
  }
}
