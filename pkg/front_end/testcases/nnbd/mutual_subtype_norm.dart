// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

class A {
  void method1() {}
  FutureOr<void> method2() {}
  FutureOr<void> method3() {}
}

class B {
  void method1() {}
  void method2() {}
  FutureOr<void> method3() {}
}

class C implements A, B {
  method1() {
    return new Future<Null>.value(null); // error
  }

  method2() {
    return new Future<Null>.value(null); // error
  }

  method3() {
    return new Future<Null>.value(null); // ok
  }
}

main() {}
