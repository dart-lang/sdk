// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'common/test_helper.dart';

class Foo {
  Foo() {
    print('Foo');
  }
}

class Bar {
  Bar() {
    print('Bar');
  }
}

void test() {
  final List l = <Object>[];
  debugger(); // LINE_A
  // Toggled on for Foo.
  // Traced allocation.
  l.add(Foo());
  // Untraced allocation.
  l.add(Bar());
  // Toggled on for Bar.
  debugger(); // LINE_B
  // Traced allocation.
  l.add(Bar());
  debugger(); // LINE_C
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: test);
}
