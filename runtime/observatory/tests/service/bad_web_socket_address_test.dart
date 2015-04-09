// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--compile-all --error_on_bad_type --error_on_bad_override --checked

import "package:observatory/service_io.dart";
import 'package:unittest/unittest.dart';

void testBadWebSocket() {
  var vm = new WebSocketVM(new WebSocketVMTarget('ws://karatekid/ws'));
  vm.load().catchError(expectAsync((error) {
        expect(error is ServiceException, isTrue);
      }));
}

main() {
  test('bad web socket address', testBadWebSocket);
}

