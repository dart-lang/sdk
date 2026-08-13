// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

final String expected = '$A';

abstract class B {
  call<T>();
}

class C implements B {
  call<T>() => '$T';
}

abstract class A {}

class Wrapper {
  Wrapper(this.b, this.call);
  final B b;
  final B call;
}

void main() {
  B b = C();
  Expect.equals(b<A>(), expected);
  Expect.equals(Wrapper(b, b).b<A>(), expected);
  Expect.equals((Wrapper(b, b).b)<A>(), expected);
  Expect.equals(Wrapper(b, b).call<A>(), expected);
  Expect.equals((Wrapper(b, b).call)<A>(), expected);
}
