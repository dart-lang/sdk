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

  /// In a context that allows only constant values, but requires them to be
  /// defined as `const` explicitly.  For example, in default values of optional
  /// and named parameters.
  ///
  /// The following code should emit a compile-time error:
  ///
  ///     class Bar { const Bar(); }
  ///     class Foo { void foo({Bar bar: Bar()}) {} }
  ///
  /// The following code should compile without errors:
  ///
  ///     class Bar { const Bar(); }
  ///     class Foo { void foo({Bar bar: const Bar()}) {} }
  needsExplicitConst,
}
