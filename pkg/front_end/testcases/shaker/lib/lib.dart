// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Shaker tests verify that portions of this file are preserved and that the
/// rest is tree-shaken.
library lib;

toplevel() => null;

class _A {}

class B extends _A {}

class C extends _A {}

class K {}

class M2 {}

class M3 {}

class M1 extends Object with M2 implements M3 {}

class Bound {}

class Base<T extends Bound> {}

typedef T MyTypedef<T>(T arg);

class F {
  K field;
}
