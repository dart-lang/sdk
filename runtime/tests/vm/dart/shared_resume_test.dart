// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Verify that ResumeFrame runtime call entry doesn't crash without isolates.
//
// VMOptions=--experimental-shared-data
//

import 'package:dart_internal/isolate_group.dart' show IsolateGroup;
import 'package:expect/expect.dart';

Iterable<int> foo() sync* {
  yield 1;
  throw 42;
}

Iterable<int> bar() sync* {
  yield* foo();
}

@pragma("vm:shared")
int caught = 0;

main() async {
  IsolateGroup.runSync(() {
    final iterator = bar().iterator;
    iterator.moveNext();
    try {
      iterator.moveNext();
    } on int catch (e) {
      caught = e;
    }
  });
  Expect.equals(42, caught);
}
