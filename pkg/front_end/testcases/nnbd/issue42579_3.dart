// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<X> {}

class B<Y1, Y2 extends List<Y3>, Y3> extends A<Y1> {
  Y1 get y1 => throw "B.y1";
  Y2 get y2 => throw "B.y2";
  Y3 get y3 => throw "B.y3";
}

foo<Z>(A<List<Z>> Function() f) {}

bar() {
  foo(() => B()..y1[0]?.unknown());
  foo(() => B()..y2[0]?.unknown());
  foo(() => B()..y3?.unknown());
}

main() {}
