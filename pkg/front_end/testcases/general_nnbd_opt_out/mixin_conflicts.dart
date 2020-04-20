// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

// This class has no problems.
class M {
  foo() {}
}

// This class has no problems.
class N = Object with M;

// This class has no problems.
class C extends Object with N {}

// This class has no problems.
abstract class M2 implements M {
  bar() {}
}

// This class has an error as it lacks an implementation of M.foo.
class N2 = Object with M2;

// This class lacks an implementation of M.foo, but it is abstract so there's
// no error.
abstract class N3 = Object with M2;

// This class has an error as it lacks an implementation of M.foo.
class C2 extends Object with M2 {}

// This class lacks an implementation of M.foo, but it is abstract so there's
// no error.
abstract class C3 extends Object with M2 {}

main() {}
