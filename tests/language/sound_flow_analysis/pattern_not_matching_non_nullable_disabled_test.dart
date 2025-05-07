// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Exercises flow analysis of patterns that fail to match a non-nullable
// scrutinee when `sound-flow-analysis` is disabled.

// @dart = 3.8

import 'package:expect/expect.dart';

import '../static_type_helper.dart';

const Null null_ = null;

// `<Null>` is not known to mismatch a non-nullable expression.
testConstNull() {
  {
    // <nonNullable> case <null literal>
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (0 case null) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }

  {
    // <nonNullable> case <null const>
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (0 case null_) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }
}

// `Null <var>` is not known to mismatch a non-nullable expression.
testDeclaredVar() {
  {
    // <nonNullable> case Null <var>
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (0 case Null n) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }
}

// `<pattern> as Null` is not known to throw when matching a non-nullable expression.
testCast({required bool true_}) {
  {
    // <nonNullable> case _ as Null
    Expect.throws(() {
      int? shouldBeDemoted = 0;
      if (true_) {
        if (0 case _ as Null) {}
        shouldBeDemoted = null; // Reachable
      }
      shouldBeDemoted.expectStaticType<Exactly<int?>>();
    });
  }
}

// `Null()` is not known to mismatch a non-nullable expression.
testObject() {
  {
    // <nonNullable> case Null()
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (0 case Null()) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }
}

// `Null _` is not known to mismatch a non-nullable expression.
testWildcard() {
  {
    // <nonNullable> case Null _
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (0 case Null _) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }
}

// `== <Null>` is not known to mismatch a non-nullable expression.
testEqualNull() {
  {
    // <nonNullable> case == <null literal>
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (0 case == null) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }

  {
    // <nonNullable> case == <null const>
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (0 case == null_) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }
}

main() {
  testConstNull();
  testDeclaredVar();
  testCast(true_: true);
  testObject();
  testWildcard();
  testEqualNull();
}
