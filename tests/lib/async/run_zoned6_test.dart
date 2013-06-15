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
  // Ensure that `runZoned`'s onError handles synchronous errors but delegates
  // to the top-level when the handler returns false.
  try {
    runZonedExperimental(() { throw 0; },
                        onError: (e) {
                          Expect.equals(0, e);
                          port.close();
                          throw e;  /// 01: runtime error
                        });
  } catch (e) {
    // We should never see an error here.
    if (true)  /// 01: continued
      rethrow;
  }
}
