// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// See https://github.com/dart-lang/sdk/issues/25559

// @dart = 2.9

import "dart:isolate";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

main() {
  asyncStart();
  var port;
  port = new RawReceivePort((message) {
    var expando1 = message[0] as Expando;
    var expando2 = message[1] as Expando;
    var expando3 = message[2] as Expando;
    var key1 = message[3];

    var key2 = expando1[key1];
    Expect.isNotNull(key2);
    var key3 = expando2[key2];
    Expect.isNotNull(key3);
    var value = expando3[key3];
    Expect.equals(value, "value");

    port.close();
    asyncEnd();
  });

  var key1 = new Object();
  var key2 = new Object();
  var key3 = new Object();
  var expando1 = new Expando();
  var expando2 = new Expando();
  var expando3 = new Expando();
  expando1[key1] = key2;
  expando2[key2] = key3;
  expando3[key3] = "value";

  // key1 is placed after expando1 so that its reachability is uncertain when
  // expando1 is first encountered.
  var message = <dynamic>[expando1, expando2, expando3, key1];
  port.sendPort.send(message);
}
