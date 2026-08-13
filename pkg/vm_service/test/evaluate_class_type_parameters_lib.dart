// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'common/test_helper.dart';

class A<T> {
  void foo() {
    debugger(); // LINE_A
  }
}

class B<S> extends A<int> {
  void bar() {
    debugger(); // LINE_B
  }
}

void testFunction() {
  final v = B<String>();
  v.bar();
  v.foo();
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testFunction);
}
