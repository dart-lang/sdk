// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// This is a regression test for dartbug.com/26406. We test that the deferred
// loader analyzer doesn't trip over constant expression evaluation.
//
// Today the task uses constant values to calculate dependencies, and only uses
// those values that were previously computed by resolution. A change to compute
// the value on-demmand made the deferred task evaluate more expressions,
// including expressions with free variables (which can't be evaluated). See the
// dartbug.com/26406 for details on how we plan to make the task more robust.

// import is only used to trigger the deferred task
import 'deferred_class_library.dart' deferred as lib;

class A {
  final int x;

  const A(bool foo)
      // The deferred task would crash trying to compute the value here, where
      // [foo] is a free variable.
      : x = foo ? 1 : 0;
}

main() => const A(true);
