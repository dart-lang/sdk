// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// See https://github.com/dart-lang/sdk/issues/25559

// @dart = 2.9

import "dart:developer";
import "dart:isolate";

import "package:async_helper/async_helper.dart";

main() {
  asyncStart();
  var port;
  port = new RawReceivePort((message) {
    var expando = message as Expando;

    // Sent and received without error.

    port.close();
    asyncEnd();
  });

  var unwrittenKey = new Object();
  var expando = new Expando();
  expando[unwrittenKey] = new UserTag("cant send this");

  port.sendPort.send(expando);

  print(unwrittenKey); // Ensure [unwrittenKey] is live during [send].
}
