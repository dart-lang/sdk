// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';
import 'dart:io' as io;
import 'package:expect/expect.dart';
import 'package:observatory/service_io.dart' as S;
import 'package:test/test.dart';
import 'test_helper.dart';

Future<Null> testeeBefore() async {
  print('testee before');
  print(await Service.getInfo());
  // Start the web server.
  ServiceProtocolInfo info = await Service.controlWebServer(enable: true);
  Expect.isNotNull(info.serverUri);
  // Ensure that we have the auth token in the path segments.
  Expect.isTrue(info.serverUri!.pathSegments.length > 1);
  // Sanity check the length of the auth token.
  Expect.isTrue(info.serverUri!.pathSegments[0].length > 8);

  // Try connecting to the server without the auth token, it should throw
  // an exception.
  var port = info.serverUri!.port;
  var url = Uri.parse('http://localhost:$port');
  var httpClient = new io.HttpClient();
  try {
    var request = await httpClient.getUrl(url);
    fail('expected exception');
  } catch (e) {
    // Expected
  }

  // Try connecting to the server with the auth token, it should succeed.
  try {
    var request = await httpClient.getUrl(info.serverUri!);
  } catch (e) {
    fail('could not connect');
  }
}

var tests = <IsolateTest>[
  (S.Isolate isolate) async {
    await isolate.reload();
    // Just getting here means that the testee enabled the service protocol
    // web server.
  }
];

main(args) => runIsolateTests(args, tests,
    testeeBefore: testeeBefore,
    // the testee is responsible for starting the
    // web server.
    testeeControlsServer: true);
