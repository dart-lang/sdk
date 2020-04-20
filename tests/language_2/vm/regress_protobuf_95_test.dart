// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that compiler loads class id from the receiver and not from type
// arguments when performing polymorphic inlining in the AOT mode.

import "package:expect/expect.dart";

abstract class Base {
  Type rareMethod<T>();
}

class A extends Base {
  Type rareMethod<T>() => A;
}

class B extends Base {
  Type rareMethod<T>() => B;
}

Type trampoline<T>(Base v) => v.rareMethod<T>();

void main() {
  Expect.equals(A, trampoline(new A()));
  Expect.equals(B, trampoline(new B()));
}
