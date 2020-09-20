// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import "package:expect/expect.dart";

// SharedOptions=--enable-experiment=non-nullable

// Test that `super == x` is allowed when `x` has a nullable type, even if the
// targeted definition of `operator==` has a parameter with a non-nullable type,
// as per this spec text (from
// accepted/future-releases/nnbd/feature-specification.md):
//
//     Similarly, consider an expression `e` of the form `super == e2` that
//     occurs in a class whose superclass is `C`, where the static type of `e2`
//     is `T2`. Let `S` be the formal parameter type of the concrete declaration
//     of `operator ==` found by method lookup in `C` (_if that search succeeds,
//     otherwise it is a compile-time error_).  It is a compile-time error
//     unless `T2` is assignable to `S?`.
//
// Also test that `super == null` evaluates to `false` without calling
// `super.operator==`, as per this spec text (from section "Equality"):
//
//     Evaluation of an equality expression ee of the form super == e proceeds
//     as follows:
//     - The expression e is evaluated to an object o.
//     - If either this or o is the null object (16.4), then ee evaluates to
//       evaluates to true if both this and o are the null object and to false
//       otherwise.  Otherwise,
//     - evaluation of ee is equivalent to the method invocation super.==(o).

MapEntry<dynamic, dynamic>? _call = null;

class BaseObject {
  bool operator ==(Object other) {
    Expect.isNull(_call);
    _call = MapEntry(this, other);
    return false;
  }
}

class DerivedObject extends BaseObject {
  void test() {
    Object? nullAsObjectQuestion = null;
    Object? nonNullAsObjectQuestion = 0;
    dynamic nullAsDynamic = null;
    dynamic nonNullAsDynamic = 1;
    Expect.isFalse(super == nullAsObjectQuestion);
    Expect.isNull(_call);
    Expect.isFalse(super == nonNullAsObjectQuestion);
    Expect.identical(_call!.key, this);
    Expect.identical(_call!.value, nonNullAsObjectQuestion);
    _call = null;
    Expect.isFalse(super == nullAsDynamic);
    Expect.isNull(_call);
    Expect.isFalse(super == nonNullAsDynamic);
    Expect.identical(_call!.key, this);
    Expect.identical(_call!.value, nonNullAsDynamic);
    _call = null;
  }
}

class BaseNum {
  bool operator ==(covariant num other) {
    Expect.isNull(_call);
    _call = MapEntry(this, other);
    return false;
  }
}

class DerivedNum extends BaseNum {
  void test() {
    num? nullAsNumQuestion = null;
    num? nonNullAsNumQuestion = 0;
    dynamic nullAsDynamic = null;
    dynamic nonNullAsDynamic = 1;
    dynamic nonNumAsDynamic = 'foo';
    Expect.isFalse(super == nullAsNumQuestion);
    Expect.isNull(_call);
    Expect.isFalse(super == nonNullAsNumQuestion);
    Expect.identical(_call!.key, this);
    Expect.identical(_call!.value, nonNullAsNumQuestion);
    _call = null;
    Expect.isFalse(super == nullAsDynamic);
    Expect.isNull(_call);
    Expect.isFalse(super == nonNullAsDynamic);
    Expect.identical(_call!.key, this);
    Expect.identical(_call!.value, nonNullAsDynamic);
    _call = null;
    Expect.throwsTypeError(() => super == nonNumAsDynamic);
    Expect.isNull(_call);
  }
}

main() {
  DerivedObject().test();
  DerivedNum().test();
}
