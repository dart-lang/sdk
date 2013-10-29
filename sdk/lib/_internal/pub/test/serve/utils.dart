// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:scheduled_test/scheduled_process.dart';
import 'package:scheduled_test/scheduled_test.dart';

import '../test_pub.dart';

/// The pub process running "pub serve".
ScheduledProcess _pubServer;

/// The ephemeral port assigned to the running server.
int _port;

/// The web socket connection to the running pub process, or `null` if no
/// connection has been made.
WebSocket _webSocket;
Stream _webSocketBroadcastStream;

/// The code for a transformer that renames ".txt" files to ".out" and adds a
/// ".out" suffix.
const REWRITE_TRANSFORMER = """
import 'dart:async';

import 'package:barback/barback.dart';

class RewriteTransformer extends Transformer {
  RewriteTransformer.asPlugin();

  String get allowedExtensions => '.txt';

  Future apply(Transform transform) {
    return transform.primaryInput.readAsString().then((contents) {
      var id = transform.primaryInput.id.changeExtension(".out");
      transform.addOutput(new Asset.fromString(id, "\$contents.out"));
    });
  }
}
""";

/// Returns the source code for a Dart library defining a Transformer that
/// rewrites Dart files.
///
/// The transformer defines a constant named TOKEN whose value is [id]. When the
/// transformer transforms another Dart file, it will look for a "TOKEN"
/// constant definition there and modify it to include *this* transformer's
/// TOKEN value as well.
///
/// If [import] is passed, it should be the name of a package that defines its
/// own TOKEN constant. The primary library of that package will be imported
/// here and its TOKEN value will be added to this library's.
String dartTransformer(String id, {String import}) {
  if (import != null) {
    id = '$id imports \${$import.TOKEN}';
    import = 'import "package:$import/$import.dart" as $import;';
  } else {
    import = '';
  }

  return """
import 'dart:async';

import 'package:barback/barback.dart';
$import

const TOKEN = "$id";

final _tokenRegExp = new RegExp(r'^const TOKEN = "(.*?)";\$', multiLine: true);

class DartTransformer extends Transformer {
  DartTransformer.asPlugin();

  String get allowedExtensions => '.dart';

  Future apply(Transform transform) {
    return transform.primaryInput.readAsString().then((contents) {
      transform.addOutput(new Asset.fromString(transform.primaryInput.id,
          contents.replaceAllMapped(_tokenRegExp, (match) {
        return 'const TOKEN = "(\${match[1]}, \$TOKEN)";';
      })));
    });
  }
}
""";
}

/// Schedules starting the "pub serve" process.
///
/// If [shouldGetFirst] is `true`, validates that pub get is run first. If
/// [dart2js] is `false`, does not compile Dart entrypoints in "web" to
/// JavaScript.
///
/// Returns the `pub serve` process.
ScheduledProcess startPubServe({bool shouldGetFirst: false,
    Iterable<String> args}) {
  // Use port 0 to get an ephemeral port.
  var pubArgs = ["serve", "--port=0", "--hostname=127.0.0.1"];

  if (args != null) pubArgs.addAll(args);

  // Dart2js can take a long time to compile dart code, so we increase the
  // timeout to cope with that.
  currentSchedule.timeout = new Duration(seconds: 15);

  _pubServer = startPub(args: pubArgs);

  currentSchedule.onComplete.schedule(() {
    if (_webSocket != null) {
      _webSocket.close();
      _webSocket = null;
      _webSocketBroadcastStream = null;
    }
  });

  if (shouldGetFirst) {
    expect(_pubServer.nextLine(),
        completion(anyOf(
             startsWith("Your pubspec has changed"),
             startsWith("You don't have a lockfile"))));
    expect(_pubServer.nextLine(),
        completion(startsWith("Resolving dependencies...")));
    expect(_pubServer.nextLine(),
        completion(equals("Got dependencies!")));
  }

  expect(_pubServer.nextLine().then(_parsePort), completes);
  return _pubServer;
}

/// Parses the port number from the "Serving blah on 127.0.0.1:1234" line
/// printed by pub serve.
void _parsePort(String line) {
  var match = new RegExp(r"127\.0\.0\.1:(\d+)").firstMatch(line);
  assert(match != null);
  _port = int.parse(match[1]);
}

void endPubServe() {
  _pubServer.kill();
}

/// Schedules an HTTP request to the running pub server with [urlPath] and
/// verifies that it responds with a body that matches [expectation].
///
/// [expectation] may either be a [Matcher] or a string to match an exact body.
void requestShouldSucceed(String urlPath, expectation) {
  schedule(() {
    return http.get("http://127.0.0.1:$_port/$urlPath").then((response) {
      expect(response.body, expectation);
    });
  }, "request $urlPath");
}

/// Schedules an HTTP request to the running pub server with [urlPath] and
/// verifies that it responds with a 404.
void requestShould404(String urlPath) {
  schedule(() {
    return http.get("http://127.0.0.1:$_port/$urlPath").then((response) {
      expect(response.statusCode, equals(404));
    });
  }, "request $urlPath");
}

/// Schedules an HTTP POST to the running pub server with [urlPath] and verifies
/// that it responds with a 405.
void postShould405(String urlPath) {
  schedule(() {
    return http.post("http://127.0.0.1:$_port/$urlPath").then((response) {
      expect(response.statusCode, equals(405));
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

/// Schedules opening a web socket connection to the currently running pub
/// serve.
Future _ensureWebSocket() {
  // Use the existing one if already connected.
  if (_webSocket != null) return new Future.value();

  // Server should already be running.
  assert(_pubServer != null);
  assert(_port != null);

  return WebSocket.connect("ws://127.0.0.1:$_port").then((socket) {
    _webSocket = socket;
    // TODO(rnystrom): Works around #13913.
    _webSocketBroadcastStream = _webSocket.asBroadcastStream();
  });
}

/// Sends [request] (an arbitrary JSON object) to the running pub serve's web
/// socket connection, waits for a reply, then verifies that the reply matches
/// [expectation].
///
/// If [encodeRequest] is `false`, then [request] will be sent as-is over the
/// socket. It omitted, request is JSON encoded to a string first.
void webSocketShouldReply(request, expectation, {bool encodeRequest: true}) {
  schedule(() => _ensureWebSocket().then((_) {
    if (encodeRequest) request = JSON.encode(request);
    _webSocket.add(request);
    return _webSocketBroadcastStream.first.then((value) {
      expect(JSON.decode(value), expectation);
    });
  }), "send $request to web socket and expect reply that $expectation");
}