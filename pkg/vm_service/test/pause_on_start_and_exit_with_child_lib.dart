// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate' as isolate;

import 'common/test_helper.dart';

void child(message) {
  print('Child got initial message');
  message.send(null);
}

void testMain() {
  final port = isolate.RawReceivePort();
  port.handler = (message) {
    print('Parent got response');
    port.close();
  };

  isolate.Isolate.spawn(child, port.sendPort);
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
