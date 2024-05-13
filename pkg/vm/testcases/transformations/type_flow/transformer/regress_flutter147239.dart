// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/flutter/flutter/issues/147239.
// Verifies that TFA doesn't crash when creating a field guard summary
// for a field which has initializer with closure and captured receiver.

class Foo<T> {
  late final aField = () {
    return <T>[];
  };
}

main() {
  print(Foo<String>().aField);
}
