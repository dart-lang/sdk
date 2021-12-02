// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An indication of the kind of an element.
enum ElementKind {
  classKind,
  constantKind,
  constructorKind,
  enumKind,
  extensionKind,
  fieldKind,
  functionKind,
  getterKind,
  methodKind,
  mixinKind,
  setterKind,
  typedefKind,
  variableKind
}

extension ElementKindUtilities on ElementKind {
  /// Return a human readable name for the kind.
  String get displayName {
    switch (this) {
      case ElementKind.classKind:
        return 'class';
      case ElementKind.constantKind:
        return 'constant';
      case ElementKind.constructorKind:
        return 'constructor';
      case ElementKind.enumKind:
        return 'enum';
      case ElementKind.extensionKind:
        return 'extension';
      case ElementKind.fieldKind:
        return 'field';
      case ElementKind.functionKind:
        return 'function';
      case ElementKind.getterKind:
        return 'getter';
      case ElementKind.methodKind:
        return 'method';
      case ElementKind.mixinKind:
        return 'mixin';
      case ElementKind.setterKind:
        return 'setter';
      case ElementKind.typedefKind:
        return 'typedef';
      case ElementKind.variableKind:
        return 'variable';
    }
  }

  /// Return the element kind corresponding to the given [name].
  static ElementKind? fromName(String name) {
    for (var kind in ElementKind.values) {
      if (kind.toString() == 'ElementKind.${name}Kind') {
        return kind;
      }
    }
    return null;
  }
}
