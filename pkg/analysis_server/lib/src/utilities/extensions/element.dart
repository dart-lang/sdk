// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/generic_inferrer.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_system.dart';

extension ClassElementExtensions on ClassElement {
  /// Return `true` if this element represents the class `Iterable` from
  /// `dart:core`.
  bool get isDartCoreIterable => name == 'Iterable' && library.isDartCore;

  /// Return `true` if this element represents the class `List` from
  /// `dart:core`.
  bool get isDartCoreList => name == 'List' && library.isDartCore;

  /// Return `true` if this element represents the class `Map` from
  /// `dart:core`.
  bool get isDartCoreMap => name == 'Map' && library.isDartCore;

  /// Return `true` if this element represents the class `Set` from
  /// `dart:core`.
  bool get isDartCoreSet => name == 'Set' && library.isDartCore;
}

extension ElementExtension on Element {
  /// Return `true` if this element, the enclosing class (if there is one), or
  /// the enclosing library, has been annotated with the `@deprecated`
  /// annotation.
  bool get hasOrInheritsDeprecated {
    if (hasDeprecated) {
      return true;
    }
    var ancestor = enclosingElement;
    if (ancestor is ClassElement) {
      if (ancestor.hasDeprecated) {
        return true;
      }
      ancestor = ancestor.enclosingElement;
    }
    return ancestor is CompilationUnitElement &&
        ancestor.enclosingElement.hasDeprecated;
  }

  /// Return this element and all its enclosing elements.
  Iterable<Element> get withAncestors sync* {
    var current = this;
    while (true) {
      yield current;
      var enclosing = current.enclosingElement;
      if (enclosing == null) {
        break;
      }
      current = enclosing;
    }
  }
}

extension ExtensionElementExtensions on ExtensionElement {
  /// Use the [type] of the object being extended in the [library] to compute
  /// the actual type extended by this [extension]. Return the computed type,
  /// or `null` if the type can't be computed.
  DartType? resolvedExtendedType(LibraryElement library, DartType type) {
    final typeParameters = this.typeParameters;
    var inferrer =
        GenericInferrer(library.typeSystem as TypeSystemImpl, typeParameters);
    inferrer.constrainArgument(
      type,
      extendedType,
      'extendedType',
    );
    var typeArguments = inferrer.infer(typeParameters,
        failAtError: true, genericMetadataIsEnabled: true);
    if (typeArguments == null) {
      return null;
    }
    var substitution = Substitution.fromPairs(
      typeParameters,
      typeArguments,
    );
    return substitution.substituteType(
      extendedType,
    );
  }
}

extension LibraryElementExtensions on LibraryElement {
  /// Return the extensions in this library that can be applied, within the
  /// [containingLibrary], to the [targetType] and that define a member with the
  /// given [memberName].
  Iterable<ExtensionElement> matchingExtensionsWithMember(
      LibraryElement containingLibrary,
      DartType targetType,
      String memberName) sync* {
    for (var extension in exportNamespace.definedNames.values) {
      if (extension is ExtensionElement) {
        var extensionName = extension.name;
        if (extensionName != null && !Identifier.isPrivateName(extensionName)) {
          var extendedType =
              extension.resolvedExtendedType(containingLibrary, targetType);
          if (extendedType != null &&
              typeSystem.isSubtypeOf(targetType, extendedType)) {
            // TODO(scheglov) share with analyzer
            if (extension.getMethod(memberName) != null ||
                extension.getGetter(memberName) != null ||
                extension.getSetter(memberName) != null) {
              yield extension;
            }
          }
        }
      }
    }
  }
}

extension MethodElementExtensions on MethodElement {
  /// Return `true` if this element represents the method `cast` from either
  /// `Iterable`, `List`, `Map`, or `Set`.
  bool get isCastMethod {
    if (name != 'cast') {
      return false;
    }
    var definingClass = enclosingElement;
    if (definingClass is! ClassElement) {
      return false;
    }
    return definingClass.isDartCoreIterable ||
        definingClass.isDartCoreList ||
        definingClass.isDartCoreMap ||
        definingClass.isDartCoreSet;
  }

  /// Return `true` if this element represents the method `toList` from either
  /// `Iterable` or `List`.
  bool get isToListMethod {
    if (name != 'toList') {
      return false;
    }
    var definingClass = enclosingElement;
    if (definingClass is! ClassElement) {
      return false;
    }
    return definingClass.isDartCoreIterable || definingClass.isDartCoreList;
  }
}
