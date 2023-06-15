// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code as governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class NotEqual {
  bool operator ==(Object other) => false;
}

class A {
  final int i;
  const A(this.i);

  bool operator ==(Object other) => other is A && i == other.i;
  int get hashCode => i;
}

class B {
  final int i;
  bool equalsCalled = false;
  bool hashCodeCalled = false;

  B(this.i);

  bool operator ==(Object other) {
    equalsCalled = true;
    return other is B && i == other.i;
  }

  int get hashCode {
    hashCodeCalled = true;
    return i ^ 42;
  }
}

checkEqualsAndHash(Object? a, Object? b) {
  Expect.isTrue(a == b);
  Expect.equals(a.hashCode, b.hashCode);
}

checkNotEquals(Object? a, Object? b) {
  Expect.isFalse(a == b);
}

main() {
  checkEqualsAndHash((1, 2), (1, 2));
  checkEqualsAndHash((1, 2), const (1, 2));
  checkEqualsAndHash(const (42, foo: "hello3"),
      (foo: "hello${int.parse("3")}", 40 + int.parse("2")));
  checkEqualsAndHash((1, 2, 3, foo: 4, bar: 5, baz: 6),
      (baz: 6, 1, bar: 5, 2, foo: 4, int.parse("3")));
  checkEqualsAndHash((foo: 1, 2), (2, foo: 1));
  checkEqualsAndHash((foo: 3), (foo: 3));

  checkNotEquals((1, 2), (1, 3));
  checkNotEquals((1, 2), (3, 2));
  checkNotEquals((1, 2), (2, 1));
  checkNotEquals((1, foo: 2), (foo: 1, 2));
  checkNotEquals((1, foo: 2), (1, bar: 2));

  checkEqualsAndHash((A(1), A(2)), (A(1), A(2)));
  checkEqualsAndHash((A(1), A(2)), (A(1), const A(2)));
  checkEqualsAndHash((A(1), A(2)), const (A(1), A(2)));
  checkEqualsAndHash(const (A(1), A(2)), (A(1), A(int.parse("2"))));

  checkNotEquals((A(1), A(2)), (A(1), A(3)));

  Object? notEqual = NotEqual();
  checkNotEquals(notEqual, notEqual);
  checkNotEquals((1, notEqual), (1, notEqual));
  checkNotEquals((foo: notEqual), (foo: notEqual));

  B o1 = B(1);
  B o2 = B(2);
  checkNotEquals((1, o1), (1, o2));
  Expect.isTrue(o1.equalsCalled);
  Expect.isFalse(o2.equalsCalled);

  checkEqualsAndHash((2, o2), (2, B(int.parse("2"))));
  Expect.isTrue(o2.equalsCalled);
  Expect.isTrue(o2.hashCodeCalled);
}
