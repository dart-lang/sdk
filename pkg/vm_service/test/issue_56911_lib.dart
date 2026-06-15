// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'common/test_helper.dart';

extension type ExtensionType._(String s) {
  ExtensionType(int i) : this._('$i');
  int get value => s.codeUnitAt(0);
}

void code() {
  final list = [ExtensionType(0)];
  debugger(); // LINE_A
  print(list.single.value);
  // ignore: avoid_function_literals_in_foreach_calls
  list.forEach((ExtensionType input) {
    debugger(); // LINE_B
    print(input.value);
  });
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: code);
}
