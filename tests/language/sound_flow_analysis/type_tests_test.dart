// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Exercises flow analysis of type tests (`is` and `as` expressions) when
// `sound-flow-analysis` is enabled.

import 'package:expect/expect.dart';

import '../static_type_helper.dart';

// `<nonNullable> as Null` is known to throw an exception.
testNonNullableAsNull({
  required int intValue,
  required int Function() intFunction,
  required bool true_,
}) {
  {
    // <var> as Null
    Expect.throws(() {
      int? shouldNotBeDemoted = 0;
      if (true_) {
        intValue as Null;
        shouldNotBeDemoted = null; // Unreachable
      }
      shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    });
  }

  {
    // <expr> as Null
    Expect.throws(() {
      int? shouldNotBeDemoted = 0;
      if (true_) {
        intFunction() as Null;
        shouldNotBeDemoted = null; // Unreachable
      }
      shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    });
  }
}

// `<nonNullable> is Null` is known to evaluate to `false`.
testNonNullableIsNull({
  required int intValue,
  required int Function() intFunction,
}) {
  {
    // <var> is Null
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (intValue is Null) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> is Null
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (intFunction() is Null) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }
}

// `<nonNullable> is! Null` is known to evaluate to `true`.
testNonNullableIsNotNull({
  required int intValue,
  required int Function() intFunction,
}) {
  {
    // <var> is! Null
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (intValue is! Null) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> is! Null
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (intFunction() is! Null) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }
}

// `<Null> as <nonNullable>` is known to throw an exception.
testNullAsNonNullable({
  required Null nullValue,
  required Null Function() nullFunction,
  required bool true_,
}) {
  {
    // null as int
    Expect.throws(() {
      int? shouldNotBeDemoted = 0;
      if (true_) {
        null as int;
        shouldNotBeDemoted = null; // Unreachable
      }
      shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    });
  }

  {
    // <var> as int
    Expect.throws(() {
      int? shouldNotBeDemoted = 0;
      if (true_) {
        nullValue as int;
        shouldNotBeDemoted = null; // Unreachable
      }
      shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    });
  }

  {
    // <expr> as int
    Expect.throws(() {
      int? shouldNotBeDemoted = 0;
      if (true_) {
        nullFunction() as int;
        shouldNotBeDemoted = null; // Unreachable
      }
      shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    });
  }
}

// `<Null> is <nonNullable>` is known to evaluate to `false`.
testNullIsNonNullable({
  required Null nullValue,
  required Null Function() nullFunction,
}) {
  {
    // null is int
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (null is int) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <var> is int
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullValue is int) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> is int
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullFunction() is int) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }
}

// `<Null> is! <nonNullable>` is known to evaluate to `true`.
testNullIsNotNonNullable({
  required Null nullValue,
  required Null Function() nullFunction,
}) {
  {
    // null is! int
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (null is! int) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <var> is! int
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullValue is! int) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> is! int
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullFunction() is! int) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }
}

main() {
  testNonNullableAsNull(intValue: 0, intFunction: () => 0, true_: true);
  testNonNullableIsNull(intValue: 0, intFunction: () => 0);
  testNonNullableIsNotNull(intValue: 0, intFunction: () => 0);
  testNullAsNonNullable(nullValue: null, nullFunction: () => null, true_: true);
  testNullIsNonNullable(nullValue: null, nullFunction: () => null);
  testNullIsNotNonNullable(nullValue: null, nullFunction: () => null);
}
