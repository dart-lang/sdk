// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Exercises flow analysis of patterns that match a non-nullable scrutinee when
// `sound-flow-analysis` is enabled.

// ignore_for_file: unnecessary_null_check_pattern

import '../static_type_helper.dart';

const Null null_ = null;

// `<pattern>?` is known to match a non-nullable expression.
testNullCheck() {
  {
    // <nonNullable> case <pattern>?
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (0 case _?) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }
}

// `<nonNullable> <var>` is known to match a suitably typed non-nullable expression.
testDeclaredVar() {
  {
    // <nonNullable> case <nonNullable> <var>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (0 case int i) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }
}

// `[...]` is known to match a suitably typed non-nullable expression.
testList() {
  {
    // [] case [...]
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if ([] case [...]) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }
}

// `<nonNullable>()` is known to match a suitably typed non-nullable expression.
testObject() {
  {
    // <nonNullable> case <nonNullable>()
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (0 case int()) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }
}

// `(<pattern>,)` is known to match a suitably typed non-nullable expression.
testRecord() {
  {
    // (<expr>,) case (<pattern>,)
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if ((0,) case (_,)) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }
}

// `<nonNullable> _` is known to match a suitably typed non-nullable expression.
testWildcard() {
  {
    // <nonNullable> case <nonNullable> _
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (0 case int _) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }
}

// `!= <Null>` is known to match a non-nullable expression.
testNotEqualNull() {
  {
    // <nonNullable> case != <null literal>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (0 case != null) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <nonNullable> case != <null const>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (0 case != null_) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }
}

main() {
  testNullCheck();
  testDeclaredVar();
  testList();
  testObject();
  testRecord();
  testWildcard();
  testNotEqualNull();
}
