// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore: unused_import, multiple_combinators
import 'dart:isolate' show Isolate, SendPort hide Capability;

import 'common/test_helper.dart';

// ignore: multiple_combinators
export 'dart:io' show Socket hide SecureSocket;

void testMain() {}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
