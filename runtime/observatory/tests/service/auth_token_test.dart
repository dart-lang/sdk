// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';
import 'dart:io' as io;
import 'package:observatory/service_io.dart' as S;
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

Future<Null> testeeBefore() async {
  print('testee before');
  print(await Service.getInfo());
  // Start the web server.
  ServiceProtocolInfo info = await Service.controlWebServer(enable: true);
  expect(info.serverUri, isNotNull);
  // Ensure that we have the auth token in the path segments.
  expect(info.serverUri.pathSegments.length, greaterThan(1));
  // Sanity check the length of the auth token.
  expect(info.serverUri.pathSegments[0].length, greaterThan(8));

  // Try connecting to the server without the auth token, it should throw
  // an exception.
  var port = info.serverUri.port;
  var url = Uri.parse('http://localhost:$port');
  var httpClient = new io.HttpClient();
  try {
    var request = await httpClient.getUrl(url);
    expect(true, false);
  } catch (e) {
    expect(true, true);
  }

  // Try connecting to the server with the auth token, it should succeed.
  try {
    var request = await httpClient.getUrl(info.serverUri);
    expect(true, true);
  } catch (e) {
    expect(true, false);
  }
}

var tests = <IsolateTest>[
  (S.Isolate isolate) async {
    await isolate.reload();
    // Just getting here means that the testee enabled the service protocol
    // web server.
    expect(true, true);
  }
];

main(args) => runIsolateTests(args, tests,
    testeeBefore: testeeBefore,
    // the testee is responsible for starting the
    // web server.
    testeeControlsServer: true);
