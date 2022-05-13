// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.16

import 'dart:ffi';

class Foo implements Finalizable {}

void main() {
  late Foo foo;
  // Generates a reachability fence between the constructor call and assignment.
  // That reachability fence should not trigger a late initialization error.
  foo = Foo();
  print(foo);
}
