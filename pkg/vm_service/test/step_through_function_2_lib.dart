// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

void code() {
  final Bar bar = Bar(); // LINE_A
  bar.barXYZ1(42);
  bar.barXYZ2(42);
  fooXYZ1(42);
  fooXYZ2(42);
}

// ignore: unused_element
int _xyz = -1;

void fooXYZ1(int i) {
  _xyz = i - 1;
}

void fooXYZ2(int i) {
  _xyz = i;
}

class Bar {
  int _xyz = -1;

  void barXYZ1(int i) {
    _xyz = i - 1;
  }

  void barXYZ2(int i) {
    _xyz = i;
  }

  int get barXYZ => _xyz + 1;
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: code);
}
