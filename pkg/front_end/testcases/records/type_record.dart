// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract mixin class A<X> {}

typedef R = Record;

typedef AR = A<Record>;

typedef RR = R;

typedef AR2 = A<R>;

typedef AR3 = A<RR>;

typedef AR4 = A<AR>;

Record foo1() => throw '';

dynamic foo2() => <Record>[];

dynamic foo3() => Record;

dynamic foo4() => List<Record>;

dynamic foo5(Record r) => null;

dynamic foo6({required Record r}) => null;

List<Record> foo7() => throw '';

dynamic foo8(List<Record> l) => null;

R foo9() => throw '';

AR foo10() => throw '';

RR foo11() => throw '';

dynamic foo12(R r) => null;

dynamic foo13(AR l) => null;

dynamic foo14(RR l) => null;

abstract class A1 extends A<Record> {}

abstract class A2 implements A<Record> {}

abstract class A3 with A<Record> {}

abstract class A4 extends AR {}

abstract class A5 extends AR2 {}

abstract class A6 extends AR3 {}

abstract class A7 extends AR4 {}

foo((int, String) record) {
  bar(record); // Ok.
}

bar(Record record) {
  foo(record); // Error.
}

main() {}
