// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:async';
import 'dart:isolate';

main() {
  // We keep a ReceivePort open until all tests are done. This way the VM will
  // hang if the callbacks are not invoked and the test will time out.
  var port = new ReceivePort();
  // Ensure that `runZoned` is done when a synchronous call throws.
  bool sawException = false;
  try {
    runZonedExperimental(() { throw 0; },
                         onDone: () {
                           // onDone is executed synchronously.
                           Expect.isFalse(sawException);
                           port.close();
                         });
  } catch (e) {
    sawException = true;
  }
  Expect.isTrue(sawException);
}
