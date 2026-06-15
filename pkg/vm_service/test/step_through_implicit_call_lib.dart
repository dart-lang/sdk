// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: unnecessary_parenthesis

import 'common/test_helper.dart';

int _fooCallNumber = 0;
void foo() {
  ++_fooCallNumber;
  print('Foo call #$_fooCallNumber!');
}

void code() {
  foo(); // LINE_A
  (foo)();
  final a = [foo];
  a[0]();
  (a[0])();
  final b = [
    [foo, foo],
  ];
  b[0][1]();
  (b[0][1])();
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: code);
}
