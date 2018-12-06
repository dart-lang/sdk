// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_renaming_method_parameters`

abstract class A {
  m1();
  m2(a);
  m3(String a, int b);
  m4([a]);
  m5(a);
  m6(a, {b});
  m7(a, {b});
}

abstract class B extends A {
  m1(); // OK
  m2(a); // OK
  m3(Object a, num b); // OK
  m4([a]); // OK
  m5(a, [b]); // OK
  m6(a, {b}); // OK
  m7(a, {b}); // OK
}

abstract class C extends A {
  m1(); // OK
  m2(aa); // LINT
  m3(
    Object aa, // LINT
    num bb, // LINT
  );
  m4([aa]); // LINT
  m5(aa, [b]); // LINT
  m6(aa, {b}); // LINT
  m7(a, {c, b}); // OK
}

abstract class D extends A {
  /// doc comments
  m1(); // OK
  /// doc comments
  m2(aa); // OK
  /// doc comments
  m3(
    Object aa, // OK
    num bb, // OK
  );
  /// doc comments
  m4([aa]); // OK
  /// doc comments
  m5(aa, [b]); // OK
  /// doc comments
  m6(aa, {b}); // OK
  /// doc comments
  m7(a, {c, b}); // OK
}

abstract class _E extends A {
  m1(); // OK
  m2(aa); // OK
  m3(
    Object aa, // OK
    num bb, // OK
  );
  m4([aa]); // OK
  m5(aa, [b]); // OK
  m6(aa, {b}); // OK
  m7(a, {c, b}); // OK
}