// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Exercises flow analysis of type tests (`is` and `as` expressions) when
// `sound-flow-analysis` is disabled.

// @dart = 3.8

import 'package:expect/expect.dart';

import '../static_type_helper.dart';

// `<nonNullable> as Null` is not known to throw an exception.
testNonNullableAsNull({
  required int intValue,
  required int Function() intFunction,
  required bool true_,
}) {
  {
    // <var> as Null
    Expect.throws(() {
      int? shouldBeDemoted = 0;
      if (true_) {
        intValue as Null;
        shouldBeDemoted = null; // Reachable
      }
      shouldBeDemoted.expectStaticType<Exactly<int?>>();
    });
  }

  {
    // <expr> as Null
    Expect.throws(() {
      int? shouldBeDemoted = 0;
      if (true_) {
        intFunction() as Null;
        shouldBeDemoted = null; // Reachable
      }
      shouldBeDemoted.expectStaticType<Exactly<int?>>();
    });
  }
}

// `<nonNullable> is Null` is not known to evaluate to `false`.
testNonNullableIsNull({
  required int intValue,
  required int Function() intFunction,
}) {
  {
    // <var> is Null
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (intValue is Null) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }

  {
    // <expr> is Null
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (intFunction() is Null) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }
}

// `<nonNullable> is! Null` is not known to evaluate to `true`.
testNonNullableIsNotNull({
  required int intValue,
  required int Function() intFunction,
}) {
  {
    // <var> is! Null
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (intValue is! Null) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }

  {
    // <expr> is! Null
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (intFunction() is! Null) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }
}

// `<Null> as <nonNullable>` is not known to throw an exception.
testNullAsNonNullable({
  required Null nullValue,
  required Null Function() nullFunction,
  required bool true_,
}) {
  {
    // null as int
    Expect.throws(() {
      int? shouldBeDemoted = 0;
      if (true_) {
        null as int;
        shouldBeDemoted = null; // Reachable
      }
      shouldBeDemoted.expectStaticType<Exactly<int?>>();
    });
  }

  {
    // <var> as int
    Expect.throws(() {
      int? shouldBeDemoted = 0;
      if (true_) {
        nullValue as int;
        shouldBeDemoted = null; // Reachable
      }
      shouldBeDemoted.expectStaticType<Exactly<int?>>();
    });
  }

  {
    // <expr> as int
    Expect.throws(() {
      int? shouldBeDemoted = 0;
      if (true_) {
        nullFunction() as int;
        shouldBeDemoted = null; // Reachable
      }
      shouldBeDemoted.expectStaticType<Exactly<int?>>();
    });
  }
}

// `<Null> is <nonNullable>` is not known to evaluate to `false`.
testNullIsNonNullable({
  required Null nullValue,
  required Null Function() nullFunction,
}) {
  {
    // null is int
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (null is int) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }

  {
    // <var> is int
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (nullValue is int) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }

  {
    // <expr> is int
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (nullFunction() is int) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }
}

// `<Null> is! <nonNullable>` is not known to evaluate to `true`.
testNullIsNotNonNullable({
  required Null nullValue,
  required Null Function() nullFunction,
}) {
  {
    // null is! int
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (null is! int) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }

  {
    // <var> is! int
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (nullValue is! int) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }

  {
    // <expr> is! int
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (nullFunction() is! int) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
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
