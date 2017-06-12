// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// In non strong-mode, `FutureOr<T>` is dynamic, even if `T` doesn't exist.
// `FutureOr<T>` can not be used as superclass, mixin, nor can it be
// implemented (as interface).

import 'dart:async';
import 'package:expect/expect.dart';

class A
    extends FutureOr<String> // //# extends: compile-time error
    extends Object with FutureOr<bool> // //# with: compile-time error
    implements FutureOr<int> // //# implements: compile-time error
{}

main() {
  // FutureOr<T> should be treated like `dynamic`. Dynamically the `T` is
  // completely ignored. It can be a malformed type.
  Expect.isTrue(499 is FutureOr<A>);
  Expect.isTrue(499 is FutureOr<Does<Not<Exist>>>); // //# 00: static type warning
  Expect.isTrue(499 is FutureOr<A, A>); //             //# 01: static type warning

  var a = new A();
  Expect.isTrue(a.toString() is String);
}
