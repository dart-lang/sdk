// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library stream_controller_async_test;

import 'dart:async';

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';

class A {
  const A();
}

class B extends A {
  const B();
}

class C extends B {
  const C();
}

main() {
  asyncStart();
  {
    Stream<B> stream = new Stream<B>.fromIterable([new B()]);
    A aFunc() => const A();
    // Make sure that lastWhere does not allow you to return instances
    // of types that are not subtypes of the generic type of the stream.
    stream.lastWhere((x) => false, //# badType: compile-time error
        orElse: aFunc); //         //# badType: continued
  }
  {
    asyncStart();
    C cFunc() => const C();
    Stream<B> stream = new Stream<B>.fromIterable([new B()]);
    // Make sure that lastWhere does allow you to return instances
    // of types that are subtypes of the generic type of the stream.
    stream.lastWhere((x) => false, orElse: cFunc).then((value) {
      Expect.identical(const C(), value);
      asyncEnd();
    });
  }
  asyncEnd();
}
