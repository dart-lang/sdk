// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/59845.
// Verifies that TFA can propagate non-nullability of a variable down after
// comparison with null which implies that variable is null.

void main() {
  repro(something: 1.0, other: 1.0);
}

void repro({double? something, double? other}) {
  print(
    // Joined data flow after '||' should not be contaminated with
    // inferred null values after 'something == null && other == null'.
    (something == null && other == null) ||
        (something != null && other != null),
  );

  if (something != null) {
    // 'if' should be eliminated.
    print(something);
    print(other!); // '!' should be eliminated.
  }
}
