// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedObjects=ffi_test_functions

import 'dart:ffi';

class Foo implements Finalizable {}

Future<Foo> bar() => Future.value(Foo());

void main() async {
  await for (final element in Stream<Foo>.fromIterable([await bar()])) {
    print(element);
  }
}
