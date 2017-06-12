// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Check function subtyping.

import 'package:expect/expect.dart';

class A {}

class B extends A {}

class C extends A {}

class Class<K, V> {
  void forEach(void f(K k, V v)) {}
}

main() {
  Class<B, C> c = new Class<B, C>();
  c.forEach((A a, A b) {});
  c.forEach((B a, C b) {});
  try {
    c.forEach((A a, B b) {});
    Expect.isFalse(isCheckedMode());
  } catch (e) {
    Expect.isTrue(isCheckedMode());
  }
}

isCheckedMode() {
  try {
    var i = 1;
    String s = i;
    return false;
  } catch (e) {
    return true;
  }
}
