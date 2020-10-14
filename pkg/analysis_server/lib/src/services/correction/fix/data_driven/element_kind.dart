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
  /// Return the element kind corresponding to the given [name].
  static ElementKind fromName(String name) {
    for (var kind in ElementKind.values) {
      if (kind.toString() == 'ElementKind.${name}Kind') {
        return kind;
      }
    }
    return null;
  }
}
