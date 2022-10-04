// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';

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
    if (ancestor is InterfaceElement) {
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

extension LibraryElementExtensions on LibraryElement {
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
    var definingClass = enclosingElement;
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
    var definingClass = enclosingElement;
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
    var definingClass = enclosingElement;
    if (definingClass is! ClassElement) {
      return false;
    }
    return definingClass.isDartCoreIterable;
  }
}
