// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'common/test_helper.dart';

void testFunction() {
  final x = Foo(42);
  x.printFoo();
}

extension type Foo(int value) {
  void printFoo() {
    debugger();
    print("This foos value is '$value'");
  }

  int otherCall() {
    return value * 2;
  }
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testFunction);
}
