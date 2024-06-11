// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests using wildcards in class generic type parameters.

// SharedOptions=--enable-experiment=wildcard-variables

import 'package:expect/expect.dart';

typedef _ = BB;

class AA {}

class BB extends AA {}

class A<T, U extends AA> {}

class B<_, _ extends AA> extends A<_, _> {
  int foo<_ extends _>([int _ = 2]) => 1;
}

class C<_, _ extends _> extends A<_, _> {
  static const int _ = 1;
}

void main() {
  var b = B();
  Expect.equals(1, b.foo());
  Expect.type<A<BB, BB>>(b);
  Expect.type<B<Object?, AA>>(b);

  Expect.equals(1, C._);
  Expect.type<C<dynamic, BB>>(C());
}
