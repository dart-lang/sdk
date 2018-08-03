// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class B {
  final z;
  B(this.z);

  foo() => this.z;
}

class A<T> extends B {
  var captured, captured2;
  var typedList;

  // p must be inside a box (in dart2js).
  A(p)
      : captured = (() => p),
        super(p++) {
    // Make non-inlinable.
    try {} catch (e) {}

    captured2 = () => p++;

    // In the current implementation of dart2js makes the generic type an
    // argument to the body.
    typedList = <T>[];
  }

  foo() => captured();
  bar() => captured2();
}

@NoInline()
@AssumeDynamic()
confuse(x) => x;

main() {
  var a = confuse(new A<int>(1));
  var a2 = confuse(new A(2));
  var b = confuse(new B(3));
  Expect.equals(2, a.foo());
  Expect.equals(3, a2.foo());
  Expect.equals(3, b.foo());
  Expect.equals(1, a.z);
  Expect.equals(2, a2.z);
  Expect.equals(3, b.z);
  Expect.isTrue(a is A<int>);
  Expect.isFalse(a is A<String>);
  Expect.isTrue(a2 is A<int>);
  Expect.isTrue(a2 is A<String>);
  Expect.equals(2, a.bar());
  Expect.equals(3, a2.bar());
  Expect.equals(3, a.foo());
  Expect.equals(4, a2.foo());
  Expect.equals(0, a.typedList.length);
  Expect.equals(0, a2.typedList.length);
  a.typedList.add(499);
  Expect.equals(1, a.typedList.length);
  Expect.equals(0, a2.typedList.length);
  Expect.isTrue(a.typedList is List<int>);
  Expect.isTrue(a2.typedList is List<int>);
  Expect.isFalse(a.typedList is List<String>);
  Expect.isTrue(a2.typedList is List<String>);
}
