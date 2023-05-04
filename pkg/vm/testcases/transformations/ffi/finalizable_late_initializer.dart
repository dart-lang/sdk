// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.16

import 'dart:ffi';

class Foo implements Finalizable {}

void main() {
  late final foo = Foo();
  () {
    print(foo);
  }();

  late final foo2 = Foo();
  if (DateTime.now().millisecond % 2 == 0) {
    print(foo2);
  }
  // The fence for foo2 should not trigger evaluation of foo2's initializer.
}
