// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check that initializers of static const fields are compile time constants.

class CanonicalConstTest {
  static final A = const C1();
  static final B = const C2();

  static testMain() {
    Expect.isTrue(null===null);
    Expect.isTrue(null!==0);
    Expect.isTrue(1===1);
    Expect.isTrue(1!==2);
    Expect.isTrue(true===true);
    Expect.isTrue("so"==="so");
    Expect.isTrue(const Object()===const Object());
    Expect.isTrue(const Object()!==const C1());
    Expect.isTrue(const C1()===const C1());
    Expect.isTrue(A===const C1());
    Expect.isTrue(const C1()!==const C2());
    Expect.isTrue(B===const C2());
    // TODO(johnlenz): these two values don't currently have the same type
    // Expect.isTrue(const [1,2] === const List[1,2]);
    Expect.isTrue(const [2,1] !== const[1,2]);
    Expect.isTrue(const <int>[1,2] === const <int>[1,2]);
    Expect.isTrue(const <Object>[1,2] === const <Object>[1,2]);
    Expect.isTrue(const <int>[1,2] !== const <double>[1.0,2.0]);
    Expect.isTrue(const {"a":1, "b":2} === const {"a":1, "b":2});
    Expect.isTrue(const {"a":1, "b":2} !== const {"a":2, "b":2});
  }
}

class C1 {
  const C1();
}

class C2 extends C1 {
  const C2() : super();
}

main() {
  CanonicalConstTest.testMain();
}
