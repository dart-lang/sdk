// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test should not cause a stack overflow.

// The _propagateToListeners function in future_impl.dart
// was getting called recursively for this code.
// It was changed to an explicit stack for pending completions
// instead of using the run-time stack.

int level = 0;

Future<void> test(int count) async {
  try {
    print(level++);
    if (count == 0) return;
    return await test(count - 1);
  } finally {
    level--;
  }
}

main() {
  test(4000);
}
