// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test where a pattern does and does not create a context type that leads to
/// int-to-double conversion.

import "package:expect/expect.dart";

main() {
  // Coerce value on pattern variable declaration.
  var (double d) = 123;
  Expect.type<double>(d);
  Expect.equals(123.0, d);

  // Coerce value on pattern assignment.
  (d) = 234;
  Expect.type<double>(d);
  Expect.equals(234.0, d);

  // Coerce relational right operand. Would be compile error if not coerced.
  if (DoubleComparer(12.34) case > 345) {
    Expect.fail('Should not have matched.');
  }

  if (DoubleComparer(12.34) case > 3) {
    // OK.
  } else {
    Expect.fail('Should have matched.');
  }

  // No coercion on if-case value. There should be no context type on the value
  // from the pattern, and thus `[123]` should be inferred as `<int>[123]`,
  // which is not matched by `List<double> _`.
  if ([123] case List<double> _) {
    Expect.fail('Should not have matched.');
  } else {
    // OK.
  }

  // No coercion on switch statement value.
  switch ([123]) {
    case List<double> _:
      Expect.fail('Should not have matched.');
    default:
    // OK.
  }

  // No coercion on switch expression value.
  var result = switch ([123]) { List<double> _ => 'wrong', _ => 'ok' };
  Expect.equals('ok', result);
}

class DoubleComparer {
  final double _value;

  DoubleComparer(this._value);

  bool operator >(double d) => _value > d;
}
