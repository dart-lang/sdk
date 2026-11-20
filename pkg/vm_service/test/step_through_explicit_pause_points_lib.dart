// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

int value() /* LINE_A */ {
  return 1; // LINE_B
}

void callClosure(void Function() g) /* LINE_C */ {
  g(); // LINE_D
} // LINE_E

Iterable<int> gen() sync* /* LINE_F */ {
  yield value(); // LINE_G
} // LINE_H

void code() {
  print('start'); // LINE_I
  callClosure(() /* LINE_J */ {
    print('argument'); // LINE_K
  }); // LINE_L
  // ignore: prefer_function_declarations_over_variables
  final closure = () /* LINE_M */ {
    print('variable'); // LINE_N
  }; // LINE_O
  closure(); // LINE_P
  for (final x in [1, 2]) /* LINE_Q */ {
    print(x); // LINE_R
  }
  for (final y in gen()) /* LINE_S */ {
    print(y); // LINE_T
  }
} // LINE_U

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: code);
}
