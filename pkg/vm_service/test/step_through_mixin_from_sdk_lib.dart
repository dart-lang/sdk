// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'common/test_helper.dart';

void code() {
  final foo = Foo(); // LINE_A
  if (foo.contains(43)) {
    print('Contains 43!');
  } else {
    print("Doesn't contain 43!");
  }
}

class Foo extends Object with ListMixin<int> {
  @override
  int length = 1;

  @override
  int operator [](int index) {
    return 42;
  }

  @override
  void operator []=(int index, int value) {}
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: code);
}
