// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'common/test_helper.dart';

// ignore_for_file: dead_code

class Class {
  void method() {
    print('hit');
  }

  void missed() {
    print('miss');
  }
}

void unusedFunction() {
  print('miss');
}

void testFunction() {
  if (true) {
    print('hit');
    Class().method();
  } else {
    print('miss');
    unusedFunction();
  }
  debugger();
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testFunction);
}
