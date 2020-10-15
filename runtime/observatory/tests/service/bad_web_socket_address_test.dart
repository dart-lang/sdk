// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:logging/logging.dart';
import "package:observatory/service_io.dart";
import 'package:test/test.dart';

void testBadWebSocket() async {
  var vm = new WebSocketVM(new WebSocketVMTarget('ws://karatekid/ws'));

  dynamic error;
  try {
    await vm.load();
  } catch (e) {
    error = e;
  }
  expect(error, isA<NetworkRpcException>());
}

main() async {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });

  test('bad web socket address', testBadWebSocket);
}
