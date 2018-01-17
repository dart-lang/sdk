// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'package:logging/logging.dart';
import "package:observatory/service_io.dart";
import 'package:unittest/unittest.dart';

void testBadWebSocket() {
  var vm = new WebSocketVM(new WebSocketVMTarget('ws://karatekid/ws'));
  vm.load().then<dynamic>((_) => null).catchError(expectAsync((error) {
    expect(error, new isInstanceOf<NetworkRpcException>());
  }));
}

main() {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });

  test('bad web socket address', testBadWebSocket);
}
