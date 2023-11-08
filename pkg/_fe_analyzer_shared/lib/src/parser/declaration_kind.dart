// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum DeclarationKind {
  /// A top level declaration.
  TopLevel,

  /// A class declaration. Not including a named mixin declaration.
  Class,

  /// A mixin declaration. Not including a named mixin declaration.
  Mixin,

  /// An extension declaration.
  Extension,

  /// An extension type declaration.
  ExtensionType,

  /// An enum.
  Enum,
}

/// Enum to specify in which declaration a header occurs.
enum DeclarationHeaderKind {
  /// Class declaration header, for instance `extends S with M implements I` in
  ///
  ///     class C extends S with M implements I {}
  ///
  Class,

  /// Extension type declaration header, for instance `implements I` in
  ///
  ///     extension type E(T t) implements I {}
  ///
  ExtensionType,
}
