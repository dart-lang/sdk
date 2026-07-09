// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  print(another());
}

Iterable<Object?> another() sync* {
  for (int i = 0; i < 1; i++) {
    // Add another scope
    yield Object();
  }
  // Declare i before the closure.
  int i = 23;
  yield test(() => [1]);
  // Use i after the closure.
  print(i);
}

Object? test(Iterable<Object?> Function() f) {
  return f();
}
