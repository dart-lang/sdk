// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Exercises flow analysis of patterns that match a non-nullable scrutinee when
// `sound-flow-analysis` is disabled.

// @dart = 3.8

// ignore_for_file: unnecessary_null_check_pattern

import '../static_type_helper.dart';

const Null null_ = null;

// `<pattern>?` is not known to match a non-nullable expression.
testNullCheck() {
  {
    // <nonNullable> case <pattern>?
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (0 case _?) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }
}

// `<nonNullable> <var>` is known to match a suitably typed non-nullable expression.
// (this behavior predates sound-flow-analysis)
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
// (this behavior predates sound-flow-analysis)
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
// (this behavior predates sound-flow-analysis)
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
// (this behavior predates sound-flow-analysis)
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
// (this behavior predates sound-flow-analysis)
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

// `!= <Null>` is not known to match a non-nullable expression.
testNotEqualNull() {
  {
    // <nonNullable> case != <null literal>
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (0 case != null) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }

  {
    // <nonNullable> case != <null const>
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (0 case != null_) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
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
