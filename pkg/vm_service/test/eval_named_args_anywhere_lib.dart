// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: unused_element

import 'dart:developer';
import 'common/test_helper.dart';

int foo(int a, {required int b}) {
  return a - b;
}

class _MyClass {
  int foo(int a, {required int b}) {
    return a - b;
  }

  static int baz(int a, {required int b}) {
    return a - b;
  }
}

void testFunction() {
  debugger();
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testFunction);
}
