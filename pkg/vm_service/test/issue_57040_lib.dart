// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'common/test_helper.dart';

extension on String? {
  bool get isNullOrEmpty {
    final str = this;
    return str == null || str.isEmpty;
  }
}

void code() {
  String? str = 'hello';
  debugger(); // LINE_A
  print(str.isNullOrEmpty);
  str = null;
  debugger(); // LINE_B
  print(str.isNullOrEmpty);
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: code);
}
