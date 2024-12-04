// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';

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

extension Element2Extension on Element2 {
  /// The content of the documentation comment (including delimiters) for this
  /// element.
  ///
  /// If the receiver is an element that has fragments, the comment will be a
  /// concatenation of the comments from all of the fragments.
  ///
  /// Returns `null` if the receiver does not have or does not support
  /// documentation.
  String? get documentationCommentOrNull {
    return switch (this) {
      Annotatable(:var documentationComment) => documentationComment,
      _ => null,
    };
  }

  /// Return `true` if this element, the enclosing class (if there is one), or
  /// the enclosing library, has been annotated with the `@deprecated`
  /// annotation.
  bool get hasOrInheritsDeprecated {
    if (this is Annotatable && (this as Annotatable).metadata2.hasDeprecated) {
      return true;
    }
    if (this is FormalParameterElement) {
      return false;
    }
    var ancestor = enclosingElement2;
    if (ancestor is InterfaceElement2) {
      if (ancestor.metadata2.hasDeprecated) {
        return true;
      }
      ancestor = ancestor.enclosingElement2;
    }
    return ancestor is LibraryFragment &&
        (ancestor as LibraryFragment).metadata2.hasDeprecated;
  }
}

extension ElementExtension on Element {
  /// Return `true` if this element, the enclosing class (if there is one), or
  /// the enclosing library, has been annotated with the `@deprecated`
  /// annotation.
  bool get hasOrInheritsDeprecated {
    if (hasDeprecated) {
      return true;
    }
    var ancestor = enclosingElement3;
    if (ancestor is InterfaceElement) {
      if (ancestor.hasDeprecated) {
        return true;
      }
      ancestor = ancestor.enclosingElement3;
    }
    return ancestor is CompilationUnitElement && ancestor.library.hasDeprecated;
  }

  /// Return this element and all its enclosing elements.
  Iterable<Element> get withAncestors sync* {
    var current = this;
    while (true) {
      yield current;
      var enclosing = current.enclosingElement3;
      if (enclosing == null) {
        if (current is CompilationUnitElement) {
          yield current.library;
        }
        break;
      }
      current = enclosing;
    }
  }
}

extension LibraryElementExtensions on LibraryElement {
  /// Return all extensions exported from this library.
  Iterable<ExtensionElement> get exportedExtensions {
    return exportNamespace.definedNames.values.whereType();
  }
}

extension LibraryElementExtensions2 on LibraryElement2 {
  /// Return all extensions exported from this library.
  Iterable<ExtensionElement> get exportedExtensions {
    return exportNamespace.definedNames.values.whereType();
  }
}

extension MethodElementExtensions on MethodElement {
  /// Return `true` if this element represents the method `cast` from either
  /// `Iterable`, `List`, `Map`, or `Set`.
  bool get isCastMethod {
    if (name != 'cast') {
      return false;
    }
    var definingClass = enclosingElement3;
    if (definingClass is! ClassElement) {
      return false;
    }
    return definingClass.isDartCoreIterable ||
        definingClass.isDartCoreList ||
        definingClass.isDartCoreMap ||
        definingClass.isDartCoreSet;
  }

  /// Return `true` if this element represents the method `toList` from
  /// `Iterable`.
  bool get isToListMethod {
    if (name != 'toList') {
      return false;
    }
    var definingClass = enclosingElement3;
    if (definingClass is! ClassElement) {
      return false;
    }
    return definingClass.isDartCoreIterable;
  }

  /// Return `true` if this element represents the method `toSet` from
  /// `Iterable`.
  bool get isToSetMethod {
    if (name != 'toSet') {
      return false;
    }
    var definingClass = enclosingElement3;
    if (definingClass is! ClassElement) {
      return false;
    }
    return definingClass.isDartCoreIterable;
  }
}
