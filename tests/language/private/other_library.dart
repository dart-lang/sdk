// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that inlining in the compiler works with privacy.

library other_library;

// Make [foo] small enough that is can be inlined. Make it call a
// private method.
foo(a) => a._bar();

class A {
  _bar() => 42;
}
