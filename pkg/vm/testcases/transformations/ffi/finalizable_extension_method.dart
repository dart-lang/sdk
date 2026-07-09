// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.16

import 'dart:ffi';

class Foo implements Finalizable {}

void main() {
  final foo = Foo();
  foo.bar();
  Object().baz(foo);
}

extension on Finalizable {
  int bar() {
    print('123');
    // Should generate a fence for `this` before returning 4.
    return 4;
  }
}

extension on Object {
  int baz(Foo foo) {
    print('456');
    // Should generate a fence for `foo` before returning 5.
    return 5;
  }
}
