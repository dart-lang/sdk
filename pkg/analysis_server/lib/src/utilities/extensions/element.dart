// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element2.dart';

extension ClassElementExtensions on ClassElement2 {
  /// Return `true` if this element represents the class `Iterable` from
  /// `dart:core`.
  bool get isDartCoreIterable => name3 == 'Iterable' && library2.isDartCore;

  /// Return `true` if this element represents the class `List` from
  /// `dart:core`.
  bool get isDartCoreList => name3 == 'List' && library2.isDartCore;

  /// Return `true` if this element represents the class `Map` from
  /// `dart:core`.
  bool get isDartCoreMap => name3 == 'Map' && library2.isDartCore;

  /// Return `true` if this element represents the class `Set` from
  /// `dart:core`.
  bool get isDartCoreSet => name3 == 'Set' && library2.isDartCore;
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
    if (this case Annotatable annotatable) {
      if (annotatable.metadata2.hasDeprecated) {
        return true;
      }
    }

    var ancestor = enclosingElement2;
    if (ancestor is InterfaceElement2) {
      if (ancestor.metadata2.hasDeprecated) {
        return true;
      }
      ancestor = ancestor.enclosingElement2;
    }
    return ancestor is LibraryElement2 && ancestor.metadata2.hasDeprecated;
  }

  /// Return this element and all its enclosing elements.
  Iterable<Element2> get withAncestors sync* {
    var current = this;
    while (true) {
      yield current;
      var enclosing = current.enclosingElement2;
      if (enclosing == null) {
        break;
      }
      current = enclosing;
    }
  }
}

extension FragmentExtension on Fragment {
  /// Return this fragment and all its enclosing fragment.
  Iterable<Fragment> get withAncestors sync* {
    var current = this;
    while (true) {
      yield current;
      var enclosing = current.enclosingFragment;
      if (enclosing == null) {
        break;
      }
      current = enclosing;
    }
  }
}

extension LibraryElementExtensions2 on LibraryElement2 {
  /// Return all extensions exported from this library.
  Iterable<ExtensionElement2> get exportedExtensions {
    return exportNamespace.definedNames2.values.whereType();
  }
}

extension MethodElementExtensions on MethodElement2 {
  /// Return `true` if this element represents the method `cast` from either
  /// `Iterable`, `List`, `Map`, or `Set`.
  bool get isCastMethod {
    if (name3 != 'cast') {
      return false;
    }
    var definingClass = enclosingElement2;
    if (definingClass is! ClassElement2) {
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
    if (name3 != 'toList') {
      return false;
    }
    var definingClass = enclosingElement2;
    if (definingClass is! ClassElement2) {
      return false;
    }
    return definingClass.isDartCoreIterable;
  }

  /// Return `true` if this element represents the method `toSet` from
  /// `Iterable`.
  bool get isToSetMethod {
    if (name3 != 'toSet') {
      return false;
    }
    var definingClass = enclosingElement2;
    if (definingClass is! ClassElement2) {
      return false;
    }
    return definingClass.isDartCoreIterable;
  }
}
