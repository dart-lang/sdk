// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

// SharedOptions=--enable-experiment=non-nullable

// Test that Object.operator==(Object o) is the signature of ==, but that we can
// still compare nullable values to Object.
//
// This is because a == b is essentially sugar for
//
// ```
// identical(a, null) || identical (b, null)
//   ? identical(a, b)
//   : a.operator==(b);
// ```
//
// It should not be required to handle `null` inside the implementation of
// operator==, but it should not be an error to "assign null" to the parameter
// of the comparison operator.
main() {
  Object o = 0;
  // Valid comparison.
  o == null;

  // Caveat: it is NOT that the argument is promoted to non-null. Otherwise,
  // types which we can't cleanly promote, such as FutureOr<int?>, would not be
  // assignable in comparisons.
  FutureOr<int?> foInt;

  // Valid comparison.
  o == foInt;
}

class C {
  // Valid override
  @override
  bool operator==(Object other) => identical(other, this);
}
