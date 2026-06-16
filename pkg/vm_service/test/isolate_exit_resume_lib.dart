// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate' as iso;

import 'common/test_helper.dart';

Future<void> _compute() async {
  iso.ReceivePort();
  print('compute is done');
}

Future<void> testMain() async {
  await iso.Isolate.run(_compute);
  print('Done');
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
