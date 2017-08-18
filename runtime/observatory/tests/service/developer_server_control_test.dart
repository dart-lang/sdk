// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'dart:async';
import 'dart:developer';
import 'package:observatory/service_io.dart' as S;
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

int majorVersion;
int minorVersion;
Uri serverUri;

Future<Null> testeeBefore() async {
  print('testee before');
  // First grab the URL where the observatory is listening on and the
  // service protocol version numbers. We expect the URL to be null as
  // the server has not been started yet.
  ServiceProtocolInfo info = await Service.getInfo();
  majorVersion = info.majorVersion;
  minorVersion = info.minorVersion;
  serverUri = info.serverUri;
  expect(info.serverUri, isNull);
  {
    // Now, start the web server and store the URI which is expected to be
    // non NULL in the top level variable.
    ServiceProtocolInfo info = await Service.controlWebServer(enable: true);
    expect(info.majorVersion, equals(majorVersion));
    expect(info.minorVersion, equals(minorVersion));
    expect(info.serverUri, isNotNull);
    serverUri = info.serverUri;
  }
  {
    // Now try starting the web server again, this should just return the
    // existing state without any change (port number does not change).
    ServiceProtocolInfo info = await Service.controlWebServer(enable: true);
    expect(info.majorVersion, equals(majorVersion));
    expect(info.minorVersion, equals(minorVersion));
    expect(info.serverUri, equals(serverUri));
  }
  {
    // Try turning off the web server, this should turn off the server and
    // the Uri returned should be null.
    ServiceProtocolInfo info = await Service.controlWebServer(enable: false);
    expect(info.majorVersion, equals(majorVersion));
    expect(info.minorVersion, equals(minorVersion));
    expect(info.serverUri, isNull);
  }
  {
    // Try turning off the web server again, this should be a nop
    // and the Uri returned should be null.
    ServiceProtocolInfo info = await Service.controlWebServer(enable: false);
    expect(info.majorVersion, equals(majorVersion));
    expect(info.minorVersion, equals(minorVersion));
    expect(info.serverUri, isNull);
  }
  {
    // Start the web server again for the test below.
    ServiceProtocolInfo info = await Service.controlWebServer(enable: true);
    majorVersion = info.majorVersion;
    minorVersion = info.minorVersion;
    serverUri = info.serverUri;
    expect(info.majorVersion, equals(majorVersion));
    expect(info.minorVersion, equals(minorVersion));
    expect(info.serverUri, equals(serverUri));
  }
}

var tests = [
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
