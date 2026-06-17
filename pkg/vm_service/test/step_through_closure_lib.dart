// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

int codeXYZ(int i) {
  int x() =>
      // some comment here to allow this formatting
      i * i; // LINE_A
  return x();
}

void code() {
  codeXYZ(42);
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: code);
}
