// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

class E {
  int x = 0;
}

void testeeMain() {
  // In https://dartbug.com/56932, it was brought up that requesting a
  // breakpoint on line A below used to result in a breakpoint getting set on
  // the next line, but after we made some changes to breakpoint resolution
  // (https://github.com/dart-lang/sdk/commit/cdacfd80f1f5e2940056dbc32e9a8faaf1928db1),
  // requesting a breakpoint line A resulted in no breakpoint getting set. After
  // having a discussion on that issue, we decided to mark the `=` tokens within
  // assignment statements as locations where breakpoints can be set, and this
  // test ensures that the marking is happening correctly.
  var a = // LINE_A
      123;
  late var b = // LINE_B
      123;
  final c = // LINE_C
      123;
  late final d = // LINE_D
      123;
  a = // LINE_E
      456;
  b = // LINE_F
      456;
  final e = E();
  e.x = // LINE_G
      123;

  print(a);
  print(b);
  print(c);
  print(d);
  print(e);
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testeeMain);
}
