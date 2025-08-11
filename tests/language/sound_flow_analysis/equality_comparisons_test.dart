// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Exercises flow analysis of equality comparisons (binary expressions using
// `==` or `!=`) when `sound-flow-analysis` is enabled.

// SharedOptions=--enable-experiment=sound-flow-analysis

import '../static_type_helper.dart';

// `<nonNullable> == <Null>` is known to evaluate to `false`.
testNonNullableEqualsNull({
  required int intValue,
  required int Function() intFunction,
  required Null nullValue,
  required Null Function() nullFunction,
}) {
  {
    // <var> == null
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (intValue == null) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <var> == <var>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (intValue == nullValue) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <var> == <expr>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (intValue == nullFunction()) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> == null
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (intFunction() == null) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> == <var>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (intFunction() == nullValue) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> == <expr>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (intFunction() == nullFunction()) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }
}

// `<Null> == <nonNullable>` is known to evaluate to `false`.
testNullEqualsNonNullable({
  required int intValue,
  required int Function() intFunction,
  required Null nullValue,
  required Null Function() nullFunction,
}) {
  {
    // null == <var>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (null == intValue) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <var> == <var>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullValue == intValue) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> == <var>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullFunction() == intValue) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // null == <expr>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (null == intFunction()) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <var> == <expr>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullValue == intFunction()) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> == <expr>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullFunction() == intFunction()) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }
}

// `<nonNullable> != <Null>` is known to evaluate to `true`.
testNonNullableNotEqualsNull({
  required int intValue,
  required int Function() intFunction,
  required Null nullValue,
  required Null Function() nullFunction,
}) {
  {
    // <var> != null
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (intValue != null) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <var> != <var>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (intValue != nullValue) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <var> != <expr>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (intValue != nullFunction()) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> != null
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (intFunction() != null) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> != <var>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (intFunction() != nullValue) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> != <expr>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (intFunction() != nullFunction()) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }
}

// `<Null> != <nonNullable>` is known to evaluate to `true`.
testNullNotEqualsNonNullable({
  required int intValue,
  required int Function() intFunction,
  required Null nullValue,
  required Null Function() nullFunction,
}) {
  {
    // null != <var>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (null != intValue) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <var> != <var>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullValue != intValue) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> != <var>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullFunction() != intValue) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // null != <expr>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (null != intFunction()) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <var> != <expr>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullValue != intFunction()) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> != <expr>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullFunction() != intFunction()) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }
}

// `<Null> == <Null>` is known to evaluate to `true`.
testNullEqualsNull({
  required Null nullValue,
  required Null Function() nullFunction,
}) {
  {
    // null == null
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (null == null) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // null == <var>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (null == nullValue) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // null == <expr>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (null == nullFunction()) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <var> == null
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullValue == null) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <var> == <var>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullValue == nullValue) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <var> == <expr>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullValue == nullFunction()) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> == null
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullFunction() == null) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> == <var>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullFunction() == nullValue) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> == <expr>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullFunction() == nullFunction()) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }
}

// `<Null> != <Null>` is known to evaluate to `false`.
testNullNotEqualsNull({
  required Null nullValue,
  required Null Function() nullFunction,
}) {
  {
    // null != null
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (null != null) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // null != <var>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (null != nullValue) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // null != <expr>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (null != nullFunction()) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <var> != null
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullValue != null) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <var> != <var>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullValue != nullValue) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <var> != <expr>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullValue != nullFunction()) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> != null
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullFunction() != null) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> != <var>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullFunction() != nullValue) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> != <expr>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullFunction() != nullFunction()) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }
}

main() {
  testNonNullableEqualsNull(
    intValue: 0,
    intFunction: () => 0,
    nullValue: null,
    nullFunction: () => null,
  );
  testNullEqualsNonNullable(
    intValue: 0,
    intFunction: () => 0,
    nullValue: null,
    nullFunction: () => null,
  );
  testNonNullableNotEqualsNull(
    intValue: 0,
    intFunction: () => 0,
    nullValue: null,
    nullFunction: () => null,
  );
  testNullNotEqualsNonNullable(
    intValue: 0,
    intFunction: () => 0,
    nullValue: null,
    nullFunction: () => null,
  );
  testNullEqualsNull(nullValue: null, nullFunction: () => null);
  testNullNotEqualsNull(nullValue: null, nullFunction: () => null);
}
