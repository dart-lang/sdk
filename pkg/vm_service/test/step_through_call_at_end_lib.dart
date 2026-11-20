// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

void code() {
  callMember(); // LINE_A
} // LINE_B

void callMember() /* LINE_C */ {
  callClosure(); // LINE_D
} // LINE_E

void callClosure() /* LINE_F */ {
  void closure() /* LINE_G */ {
    helper(); // LINE_H
  } // LINE_I

  closure(); // LINE_J
} // LINE_K

void helper() /* LINE_L */ {
  print('helper'); // LINE_M
} // LINE_N

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: code);
}
