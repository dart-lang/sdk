// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'common/test_helper.dart';

import 'mixin_break/mixin_break_class1.dart';
import 'mixin_break/mixin_break_class2.dart';

int codeRuns = 0;

void code() {
  if (++codeRuns > 1) {
    print('Calling debugger!');
    debugger(); // LINE_A
  }
  final a = Hello1();
  final b = Hello2();
  a.speak();
  b.speak();

  print('Both now compiled');
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(
    testeeBefore: code,
    testeeConcurrent: code,
  );
}
