// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing typed data.

// Library tag to be able to run in html test framework.
library TypedDataIsolateTest;

import 'dart:io';
import 'dart:isolate';
import 'package:async_helper/async_helper.dart';

second(message) {
  var data = message[0];
  var replyTo = message[1];
  print('got data');
  print(data);
  print('printed data');
  replyTo.send('OK');
}

main() {
  asyncStart();
  new File(Platform.script.toFilePath()).readAsBytes().then((List<int> data) {
    var response = new ReceivePort();
    var remote = Isolate.spawn(second, [data, response.sendPort]);
    response.first.then((reply) {
      print('got reply');
      asyncEnd();
    });
  });
}
