// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

void code() {
  final a = getA();
  final b = getB();

  print('Hello, World!'); // LINE_A
  print('a: $a; b: $b');
  print('Goodbye, world!');
}

bool getA() => true;
int getB() => 42;

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: code);
}
