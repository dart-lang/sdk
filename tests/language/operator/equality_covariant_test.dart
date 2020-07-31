// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the dynamic semantics of expressions of the form `e1 == e2` when
// the `operator ==` parameter is covariant.

import "package:expect/expect.dart";

class EqNever {
  operator ==(covariant Never other) => throw "unreachable";
}

class EqTypeVar<T extends Object> {
  operator ==(covariant T other) => identical(this, other);
}

void main() {
  Object oNever = EqNever();
  Object oTypeNum = EqTypeVar<num>();
  Object? myNull = null;

  Expect.isFalse(oNever == null);
  Expect.isFalse(null == oNever);
  Expect.throws(() => oNever == 0);
  Expect.isFalse(0 == oNever);
  Expect.isFalse(oTypeNum == null);
  Expect.isFalse(null == oTypeNum);
  Expect.isFalse(oTypeNum == 0);
  Expect.isFalse(0 == oTypeNum);
  Expect.isFalse(oTypeNum == 0.0);
  Expect.isFalse(0.0 == oTypeNum);
  Expect.throws(() => oTypeNum == "not a number");
  Expect.isFalse("not a number" == oTypeNum);
  Expect.throws(() => oTypeNum == oTypeNum);
  Expect.isFalse(oNever == myNull);
  Expect.isFalse(myNull == oNever);
  Expect.isFalse(oTypeNum == myNull);
  Expect.isFalse(myNull == oTypeNum);
}
