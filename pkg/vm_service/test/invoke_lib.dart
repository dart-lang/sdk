// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'common/test_helper.dart';

String libraryFunction() => 'foobar1';

class Klass {
  static String classFunction(String x) => 'foobar2$x';
  String instanceFunction(String x, String y) => 'foobar3$x$y';
}

late final Klass instance;

late final String apple;
late final String banana;

void testFunction() {
  instance = Klass();
  apple = 'apple';
  banana = 'banana';
  debugger(); // LINE_A
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testFunction);
}
