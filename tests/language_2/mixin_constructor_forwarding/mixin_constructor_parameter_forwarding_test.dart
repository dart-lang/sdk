// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that mixin application forwarding constructors correctly forward
// optional parameter default values.

import "package:expect/expect.dart";

import "mixin_constructor_parameter_forwarding_helper.dart"
    show B2, privateValue;

class B<T> {
  final T x;
  final Object y;
  const B(T x, [Object y = 0])
      : x = x,
        y = y;
  const B.b1(T x, {Object y = 0})
      : x = x,
        y = y;
  const B.b2(T x, [Object y = const <int>[0]])
      : x = x,
        y = y;
}

mixin M1 on B<int> {
  void check(int x, Object y) {
    Expect.identical(x, this.x);
    Expect.identical(y, this.y);
  }
}

mixin M2<T> on B<T> {
  void check(T x, Object y) {
    Expect.identical(x, this.x);
    Expect.identical(y, this.y);
  }
}

class A1 = B<int> with M1;
class A2 = B<int> with M2<int>;
class P1 = B2<int> with M2<int>;

main() {
  A1(1, 2).check(1, 2);
  A1.b1(1, y: 2).check(1, 2);
  A1.b2(1, 2).check(1, 2);
  A2(1, 2).check(1, 2);
  A2.b1(1, y: 2).check(1, 2);
  A2.b2(1, 2).check(1, 2);
  P1(1, 2).check(1, 2);

  A1(1).check(1, 0);
  A1.b1(1).check(1, 0);
  A1.b2(1).check(1, const <int>[0]);
  A2(1).check(1, 0);
  A2.b1(1).check(1, 0);
  A2.b2(1).check(1, const <int>[0]);
  P1(1).check(1, privateValue);

  const A1(1, 2).check(1, 2);
  const A1.b1(1, y: 2).check(1, 2);
  const A1.b2(1, 2).check(1, 2);
  const A2(1, 2).check(1, 2);
  const A2.b1(1, y: 2).check(1, 2);
  const A2.b2(1, 2).check(1, 2);
  const P1(1, 2).check(1, 2);

  const A1(1).check(1, 0);
  const A1.b1(1).check(1, 0);
  const A1.b2(1).check(1, const <int>[0]);
  const A2(1).check(1, 0);
  const A2.b1(1).check(1, 0);
  const A2.b2(1).check(1, const <int>[0]);
  const P1(1).check(1, privateValue);
}
