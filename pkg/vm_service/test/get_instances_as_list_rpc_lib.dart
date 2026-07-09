// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'common/test_helper.dart';

class Class {}

class Subclass extends Class {}

class Implementor implements Class {}

late final Class aClass;
late final Subclass aSubclass;
late final Implementor anImplementor;

void testMain() {
  debugger(); // LINE_A
  final _ = 1;

  aClass = Class();
  aSubclass = Subclass();
  anImplementor = Implementor();
  debugger(); // LINE_B
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
