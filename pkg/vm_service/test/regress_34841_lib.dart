// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'common/test_helper.dart';
import 'regress_34841_lib_helper.dart';

class Bar extends Object with Foo {}

void testFunction() {
  final bar = Bar();
  print(bar.foo);
  print(bar.baz());
  debugger(); // LINE_A
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testFunction);
}
