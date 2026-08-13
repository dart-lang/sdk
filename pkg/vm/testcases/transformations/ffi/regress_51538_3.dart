// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedObjects=ffi_test_functions

import 'dart:ffi';

class Foo implements Finalizable {}

Future<bool> hasMore() async => false;

Future<Foo> nextElement() => Future.value(Foo());

void main() async {
  for (var element = Foo(); await hasMore(); element = await nextElement()) {
    print(element);
  }
}
