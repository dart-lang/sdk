// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'dart:async';
import 'dart:developer';
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

Future<Null> testeeBefore() async {
  print('testee before');
  print(await Service.getInfo());
  // Start the web server.
  ServiceProtocolInfo info = await Service.controlWebServer(enable: true);
  print(info);
}

var tests = [
(Isolate isolate) async {
  await isolate.reload();
  // Just getting here means that the testee enabled the service protocol
  // web server.
  expect(true, true);
}
];

main(args) => runIsolateTests(args,
                              tests,
                              testeeBefore: testeeBefore,
                              // the testee is responsible for starting the
                              // web server.
                              testeeControlsServer: true);
