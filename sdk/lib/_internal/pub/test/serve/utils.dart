// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:scheduled_test/scheduled_process.dart';
import 'package:scheduled_test/scheduled_test.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';

/// The pub process running "pub serve".
ScheduledProcess _pubServer;

/// The ephemeral port assigned to the running server.
int _port;

/// Schedules starting the "pub serve" process.
///
/// If [shouldInstallFirst] is `true`, validates that pub install is run first.
void startPubServe({bool shouldInstallFirst: false}) {
  // Use port 0 to get an ephemeral port.
  _pubServer = startPub(args: ["serve", "--port=0"]);

  if (shouldInstallFirst) {
    expect(_pubServer.nextLine(),
        completion(startsWith("Dependencies have changed")));
    expect(_pubServer.nextLine(),
        completion(startsWith("Resolving dependencies...")));
    expect(_pubServer.nextLine(),
        completion(equals("Dependencies installed!")));
  }

  expect(_pubServer.nextLine().then(_parsePort), completes);
}

/// Parses the port number from the "Serving blah on localhost:1234" line
/// printed by pub serve.
void _parsePort(String line) {
  var match = new RegExp(r"localhost:(\d+)").firstMatch(line);
  assert(match != null);
  _port = int.parse(match[1]);
}

void endPubServe() {
  _pubServer.kill();
}

/// Schedules an HTTP request to the running pub server with [urlPath] and
/// verifies that it responds with [expected].
void requestShouldSucceed(String urlPath, String expected) {
  schedule(() {
    return http.get("http://localhost:$_port/$urlPath").then((response) {
      expect(response.body, equals(expected));
    });
  }, "request $urlPath");
}

/// Schedules an HTTP request to the running pub server with [urlPath] and
/// verifies that it responds with a 404.
void requestShould404(String urlPath) {
  schedule(() {
    return http.get("http://localhost:$_port/$urlPath").then((response) {
      expect(response.statusCode, equals(404));
    });
  }, "request $urlPath");
}