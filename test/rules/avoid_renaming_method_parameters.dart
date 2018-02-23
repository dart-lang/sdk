// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_renaming_method_parameters`

abstract class A {
  m1();
  m2(a);
  m3(String a, int b);
  m4([a]);
}

abstract class B extends A {
  m1(); // OK
  m2(a); // OK
  m3(Object a, num b); // OK
  m4([a]); // OK
}

abstract class C extends A {
  m1(); // OK
  m2(aa); // LINT
  m3(
    Object aa, // LINT
    num bb, // LINT
  );
  m4([aa]); // LINT
}
