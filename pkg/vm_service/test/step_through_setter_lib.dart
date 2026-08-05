// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

void code() // LINE_A
{
  final bar = Bar();
  bar.barXYZ = 42;
  fooXYZ = 42;
}

// ignore: unused_element
int _xyz = -1;

set fooXYZ(int i) {
  _xyz = i - 1;
}

class Bar {
  int _xyz = -1;

  set barXYZ(int i) {
    _xyz = i - 1;
  }

  int get barXYZ => _xyz + 1;
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: code);
}
