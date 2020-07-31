// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';

extension ClassElementExtensions on ClassElement {
  /// Return `true` if this element represents the class `Iterable` from
  /// `dart:core`.
  bool get isDartCoreIterable =>
      this != null && name == 'Iterable' && library.isDartCore;

  /// Return `true` if this element represents the class `List` from
  /// `dart:core`.
  bool get isDartCoreList =>
      this != null && name == 'List' && library.isDartCore;

  /// Return `true` if this element represents the class `Map` from
  /// `dart:core`.
  bool get isDartCoreMap => this != null && name == 'Map' && library.isDartCore;

  /// Return `true` if this element represents the class `Set` from
  /// `dart:core`.
  bool get isDartCoreSet => this != null && name == 'Set' && library.isDartCore;
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
}

extension MethodElementExtensions on MethodElement {
  /// Return `true` if this element represents the method `cast` from either
  /// `Iterable`, `List`, `Map`, or `Set`.
  bool get isCastMethod {
    if (name != 'cast') {
      return false;
    }
    ClassElement definingClass = enclosingElement;
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
    ClassElement definingClass = enclosingElement;
    return definingClass.isDartCoreIterable || definingClass.isDartCoreList;
  }
}
