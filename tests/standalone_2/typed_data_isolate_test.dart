// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Dart test program for testing typed data.

// Library tag to be able to run in html test framework.
library TypedDataIsolateTest;

import 'dart:io';
import 'dart:isolate';
import 'package:async_helper/async_helper.dart';
import "package:expect/expect.dart";

second(message) {
  var data = message[0];
  var replyTo = message[1];
  try {
    print('got data');
    var rdata = new File(Platform.script.toFilePath()).readAsBytesSync();
    Expect.equals(data.length, rdata.length);
    for (int i = 0; i < data.length; i++) {
      Expect.equals(data[i], rdata[i]);
    }
    print('validated received data');
    replyTo.send('OK');
  } catch (e) {
    replyTo.send('Not OK');
  }
}

main() {
  var result = true;
  asyncStart();
  new File(Platform.script.toFilePath()).readAsBytes().then((List<int> data) {
    var response = new ReceivePort();
    var remote = Isolate.spawn(second, [data, response.sendPort]);
    response.first.then((reply) {
      print('got reply');
      result = (reply == 'OK');
      asyncEnd();
      Expect.isTrue(result);
    });
  });
}
