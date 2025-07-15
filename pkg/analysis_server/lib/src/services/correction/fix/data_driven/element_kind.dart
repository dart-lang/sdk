// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An indication of the kind of an element.
enum ElementKind {
  classKind('class'),
  constantKind('constant'),
  constructorKind('constructor'),
  enumKind('enum'),
  extensionKind('extension'),
  extensionTypeKind('extensionType'),
  fieldKind('field'),
  functionKind('function'),
  getterKind('getter'),
  methodKind('method'),
  mixinKind('mixin'),
  setterKind('setter'),
  typedefKind('typedef'),
  variableKind('variable');

  /// A human readable name for the kind.
  final String displayName;
  const ElementKind(this.displayName);

  /// The element kind corresponding to the given [name].
  static ElementKind? fromName(String name) {
    for (var kind in values) {
      if (kind.displayName == name) {
        return kind;
      }
    }
    return null;
  }
}
