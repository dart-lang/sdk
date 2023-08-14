// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that a unary pattern or a relational pattern may appear inside a unary
// pattern as long as there are parentheses.

import 'package:expect/expect.dart';

test_cast_insideCast(x) {
  switch (x) {
    case (_ as int) as num:
      break;
    default:
      Expect.fail('failed to match');
  }
}

test_cast_insideNullAssert(x) {
  switch (x) {
    case (_ as int)!:
      break;
    default:
      Expect.fail('failed to match');
  }
}

test_cast_insideNullCheck(x) {
  switch (x) {
    case (_ as int?)?:
      break;
    default:
      Expect.fail('failed to match');
  }
}

test_nullAssert_insideCast(x) {
  switch (x) {
    case (_!) as num?:
      break;
    default:
      Expect.fail('failed to match');
  }
}

test_nullAssert_insideNullAssert(x) {
  switch (x) {
    case (_!)!:
      break;
    default:
      Expect.fail('failed to match');
  }
}

test_nullAssert_insideNullCheck(x) {
  switch (x) {
    case (_!)?:
      break;
    default:
      Expect.fail('failed to match');
  }
}

test_nullCheck_insideCast(x) {
  switch (x) {
    case (_?) as num?:
      break;
    default:
      Expect.fail('failed to match');
  }
}

test_nullCheck_insideNullAssert(x) {
  switch (x) {
    case (_?)!:
      break;
    default:
      Expect.fail('failed to match');
  }
}

test_nullCheck_insideNullCheck(x) {
  switch (x) {
    case (_?)?:
      break;
    default:
      Expect.fail('failed to match');
  }
}

test_relational_insideNullCheck_equal(x) {
  switch (x) {
    case (== 1)?:
      break;
    default:
      Expect.fail('failed to match');
  }
}

test_relational_insideNullCheck_greaterThan(x) {
  switch (x) {
    case (> 1)?:
      break;
    default:
      Expect.fail('failed to match');
  }
}

main() {
  test_cast_insideCast(0);
  test_cast_insideNullAssert(0);
  test_cast_insideNullCheck(0);
  test_nullAssert_insideCast(0);
  test_nullAssert_insideNullAssert(0);
  test_nullAssert_insideNullCheck(0);
  test_nullCheck_insideCast(0);
  test_nullCheck_insideNullAssert(0);
  test_nullCheck_insideNullCheck(0);
  test_relational_insideNullCheck_equal(1);
  test_relational_insideNullCheck_greaterThan(2);
}
