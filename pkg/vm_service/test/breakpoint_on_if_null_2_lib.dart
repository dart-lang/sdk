// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

dynamic compareWithMe = 43;

void code() {
  compareWithMe = null;
  foo(42);
}

void foo(dynamic args) {
  if (args == compareWithMe) /* LINE_A */ {
    print('was null');
  }
  if (args != compareWithMe) {
    print('was not null');
  }
  if (args == 42) {
    print('was 42!');
  }
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: code);
}
