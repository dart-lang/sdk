// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

class Class2 {
  int operator [](int index) => index;

  int code() {
    this[42];
    return this[42];
  }
}

class Class3 extends Class2 {
  @override
  int code() {
    super[42]; // LINE_A
    return super[42];
  }
}

void code() {
  final c = Class3();
  c[42];
  c.code();
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: code);
}
