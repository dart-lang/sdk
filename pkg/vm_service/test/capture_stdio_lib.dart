// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'dart:io';

import 'common/test_helper.dart';

void test() {
  debugger();
  print('start');
  debugger();
  print('stdout');

  debugger();
  print('print');

  debugger();
  stderr.write('stderr');
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: test);
}
