// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N prefer_constructors_over_static_methods`

class A {
  static final array = <A>[];

  A.internal();

  static A bad1() => // LINT
  new A.internal();

  static A get newA => // LINT
  new A.internal();

  static A bad2(){ // LINT
    final a = new A.internal();
    return a;
  }

  static A good1(int i) { // OK
    return array[i];
  }

  factory A.good2(){ // OK
    return new A.internal();
  }

  factory A.good3(){ // OK
    return new A.internal();
  }
}

extension E on A {
  static A foo() => A(); // OK
}
