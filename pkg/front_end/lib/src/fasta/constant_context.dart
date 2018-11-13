// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.constant_context;

enum ConstantContext {
  /// Not in a constant context.
  ///
  /// This means that `Object()` and `[]` are equivalent to `new Object()` and
  /// `[]` respectively. `new Object()` is **not** a compile-time error.
  ///
  /// TODO(ahe): Update the above specification and corresponding
  /// implementation because `Object()` is a compile-time constant. See [magic
  /// const](
  /// ../../../../../../docs/language/informal/docs/language/informal/implicit-creation.md
  /// ).
  none,

  /// In a context where constant expressions are required, and `const` may be
  /// inferred.
  ///
  /// This means that `Object()` and `[]` are equivalent to `const Object()` and
  /// `const []` respectively. `new Object()` is a compile-time error.
  inferred,
}
