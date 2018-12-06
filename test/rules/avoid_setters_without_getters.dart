// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_setters_without_getters`

class A {
  set x(int x) {} // LINT
}

class B extends A {
  @override
  set x(int x) {} // OK because it is an inherited setter.
}

class C {
  int get x => 0;
}

class D extends C {
  set x(int x) {} // OK because has inherited getter.
}

class E {
  int get length => 0;

  set length (int v) {} // OK
}
