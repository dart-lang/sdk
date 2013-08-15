// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:scheduled_test/scheduled_process.dart';
import 'package:scheduled_test/scheduled_test.dart';

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

/// Reads lines from pub serve's stdout until it prints the build success
/// message.
///
/// The schedule will not proceed until the output is found. If not found, it
/// will eventually time out.
void waitForBuildSuccess() {
  nextLine() {
    return _pubServer.nextLine().then((line) {
      if (line.contains("successfully")) return;

      // This line wasn't it, so ignore it and keep trying.
      return nextLine();
    });
  }

  schedule(nextLine);
}

/// Returns a [Future] that completes after pumping the event queue [times]
/// times. By default, this should pump the event queue enough times to allow
/// any code to run, as long as it's not waiting on some external event.
Future _pumpEventQueue([int times=20]) {
  if (times == 0) return new Future.value();
  // We use a delayed future to allow runAsync events to finish. The
  // Future.value or Future() constructors use runAsync themselves and would
  // therefore not wait for runAsync callbacks that are scheduled after invoking
  // this method.
  return new Future.delayed(Duration.ZERO, () => _pumpEventQueue(times - 1));
}