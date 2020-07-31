// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(nshahan) Merge back into constructor12_test.dart along with the
// expectation from constructor12_strong_test.dart after ending support for weak
// mode.

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
    // Make constructor body non-inlinable.
    try {} catch (e) {}

    captured2 = () => p++;

    // In the current implementation of dart2js makes the generic type an
    // argument to the body.
    typedList = <T>[];
  }

  foo() => captured();
  bar() => captured2();
}

@pragma('dart2js:noInline')
@pragma('dart2js:assumeDynamic')
confuse(x) => x;
