// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'common/test_helper.dart';

int globalVar = 100;

class MyClass {
  /* OFFSET_START */ static void myFunction(int value) {
    if (value /* OFFSET_COMPARE */ < 0) {
      /* OFFSET_PRINT_NEGATIVE */ print('negative');
    } else {
      /* OFFSET_PRINT_POSITIVE */ print('positive');
    }
    /* OFFSET_DEBUGGER */ debugger(); // LINE_A
    /* OFFSET_END */
  }

  static void otherFunction(int value) {
    if (value < 0) {
      print('otherFunction <');
    } else {
      print('otherFunction >=');
    }
  }
}

void testFunction() {
  MyClass.otherFunction(-100);
  MyClass.myFunction(10000);
}

class MyConstClass {
  const MyConstClass();
  static const MyConstClass instance = MyConstClass();

  void foo() {
    debugger(); // LINE_B
  }
}

void testFunction2() {
  MyConstClass.instance.foo();
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testFunction);
}
