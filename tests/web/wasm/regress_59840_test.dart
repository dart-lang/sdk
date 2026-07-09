// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  test(something: 1.0, other: 1.0);
}

void test({double? something, double? other}) {
  // This asserts prevents the null check below from being removed.
  assert(
    (something == null && other == null) ||
        (something != null && other != null),
  );

  if (something != null) {
    print(something);
    // With assertions 'other' will be an unboxed double. Ensure there is no
    // null check added.
    print(other!);
  }
}
