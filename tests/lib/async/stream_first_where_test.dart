// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:expect/variations.dart' show checkedParameters;

class A {
  const A();
}

class B extends A {
  const B();
}

class C extends B {
  const C();
}

void main() {
  if (checkedParameters) {
    Stream<A> stream = Stream<B>.fromIterable([B()]);
    A aFunc() => const A();
    // `firstWhere` does not dynamically allow you to return
    // instances that are not subtypes of the stream element type.
    Expect.throws<TypeError>(() {
      // `aFunc` is not a `B Function()`.
      stream.firstWhere((x) => false, orElse: aFunc);
    });
  }

  // Returning a subtype is fine.
  {
    asyncStart();
    C cFunc() => const C();
    Stream<B> stream = Stream<B>.fromIterable([B()]);
    // `firstWhere` does allow you to return instances of subtypes the
    // stream element type.
    stream.firstWhere((x) => false, orElse: cFunc).then((value) {
      Expect.identical(const C(), value);
      asyncEnd();
    });
  }
}
