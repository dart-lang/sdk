// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class B {
  call<T>();
}

class C implements B {
  call<T>() => print(T);
}

abstract class A {}

class Wrapper {
  Wrapper(this.b, this.call);
  final B b;
  final B call;
}

void main() {
  B b = C();
  b<A>();
  Wrapper(b, b).b<A>();
  (Wrapper(b, b).b)<A>();
  Wrapper(b, b).call<A>();
  (Wrapper(b, b).call)<A>();
}
