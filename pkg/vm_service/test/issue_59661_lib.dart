// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'common/test_helper.dart';

class A {
  List list;
  A(this.list) {
    list = [3];
    debugger(); // LINE_CLASS_A
    print(list);
  }
  A.named(this.list) {
    list = [4];
    debugger(); // LINE_CLASS_A_NAMED
    print(list);
  }
  A.named2(this.list) {
    {
      final list = [5];
      debugger(); // LINE_CLASS_A_NAMED2_BREAK_1
      print(list);
    }
    debugger(); // LINE_CLASS_A_NAMED2_BREAK_2
    print(list);
    list = [6];
    debugger(); // LINE_CLASS_A_NAMED2_BREAK_3
    print(list);
  }
  A.noDebugger(this.list);
}

class B extends A {
  B(super.list) : super.noDebugger() {
    list = [7];
    debugger(); // LINE_CLASS_B
    print(list);
  }
}

void code() {
  A([1, 2]);
  A.named([1, 2]);
  A.named2([1, 2]);
  B([1, 2]);
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: code);
}
