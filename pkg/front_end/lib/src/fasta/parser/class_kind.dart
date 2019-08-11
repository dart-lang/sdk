// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.parser.class_kind;

enum ClassKind {
  /// A class declaration. Not including a named mixin declaration.
  Class,

  /// A mixin declaration. Not including a named mixin declaration.
  Mixin,

  /// An extension declaration.
  Extension,
}
