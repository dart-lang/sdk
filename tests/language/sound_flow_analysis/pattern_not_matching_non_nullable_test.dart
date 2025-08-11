// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Exercises flow analysis of patterns that fail to match a non-nullable
// scrutinee when `sound-flow-analysis` is enabled.

// SharedOptions=--enable-experiment=sound-flow-analysis

import 'package:expect/expect.dart';

import '../static_type_helper.dart';

const Null null_ = null;

// `<Null>` is known to mismatch a non-nullable expression.
testConstNull() {
  {
    // <nonNullable> case <null literal>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (0 case null) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <nonNullable> case <null const>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (0 case null_) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }
}

// `Null <var>` is known to mismatch a non-nullable expression.
testDeclaredVar() {
  {
    // <nonNullable> case Null <var>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (0 case Null n) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }
}

// `<pattern> as Null` is known to throw when matching a non-nullable expression.
testCast({required bool true_}) {
  {
    // <nonNullable> case _ as Null
    Expect.throws(() {
      int? shouldNotBeDemoted = 0;
      if (true_) {
        if (0 case _ as Null) {}
        shouldNotBeDemoted = null; // Unreachable
      }
      shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    });
  }
}

// `Null()` is known to mismatch a non-nullable expression.
testObject() {
  {
    // <nonNullable> case Null()
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (0 case Null()) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }
}

// `Null _` is known to mismatch a non-nullable expression.
testWildcard() {
  {
    // <nonNullable> case Null _
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (0 case Null _) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }
}

// `== <Null>` is known to mismatch a non-nullable expression.
testEqualNull() {
  {
    // <nonNullable> case == <null literal>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (0 case == null) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <nonNullable> case == <null const>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (0 case == null_) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
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
