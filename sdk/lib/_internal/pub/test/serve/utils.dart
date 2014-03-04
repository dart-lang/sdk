// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:scheduled_test/scheduled_process.dart';
import 'package:scheduled_test/scheduled_stream.dart';
import 'package:scheduled_test/scheduled_test.dart';

import '../../lib/src/utils.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';

/// The pub process running "pub serve".
ScheduledProcess _pubServer;

/// The ephemeral ports assigned to the running servers, associated with the
/// directories they're serving.
final _ports = new Map<String, int>();

/// A completer that completes when the server has been started and the served
/// ports are known.
Completer _portsCompleter;

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

/// Schedules starting the `pub serve` process.
///
/// Unlike [pubServe], this doesn't determine the port number of the server, and
/// so may be used to test for errors in the initialization process.
///
/// Returns the `pub serve` process.
ScheduledProcess startPubServe({Iterable<String> args,
    bool createWebDir: true}) {
  // Use port 0 to get an ephemeral port.
  var pubArgs = ["serve", "--port=0", "--hostname=127.0.0.1", "--force-poll"];

  if (args != null) pubArgs.addAll(args);

  // Dart2js can take a long time to compile dart code, so we increase the
  // timeout to cope with that.
  currentSchedule.timeout *= 1.5;

  if (createWebDir) d.dir(appPath, [d.dir("web")]).create();
  return startPub(args: pubArgs);
}

/// Schedules starting the "pub serve" process and records its port number for
/// future requests.
///
/// If [shouldGetFirst] is `true`, validates that pub get is run first.
///
/// If [createWebDir] is `true`, creates a `web/` directory if one doesn't exist
/// so pub doesn't complain about having nothing to serve.
///
/// Returns the `pub serve` process.
ScheduledProcess pubServe({bool shouldGetFirst: false, bool createWebDir: true,
    Iterable<String> args}) {
  _pubServer = startPubServe(args: args, createWebDir: createWebDir);
  _portsCompleter = new Completer();

  currentSchedule.onComplete.schedule(() {
    _portsCompleter = null;
    _ports.clear();

    if (_webSocket != null) {
      _webSocket.close();
      _webSocket = null;
      _webSocketBroadcastStream = null;
    }
  });

  if (shouldGetFirst) {
    _pubServer.stdout.expect(consumeThrough("Got dependencies!"));
  }

  // The server should emit one or more ports.
  _pubServer.stdout.expect(
      consumeWhile(predicate(_parsePort, 'emits server url')));
  schedule(() {
    expect(_ports, isNot(isEmpty));
    _portsCompleter.complete();
  });

  return _pubServer;
}

/// The regular expression for parsing pub's output line describing the URL for
/// the server.
final _parsePortRegExp = new RegExp(r"([^ ]+) +on http://127\.0\.0\.1:(\d+)");

/// Parses the port number from the "Serving blah on 127.0.0.1:1234" line
/// printed by pub serve.
bool _parsePort(String line) {
  var match = _parsePortRegExp.firstMatch(line);
  if (match == null) return false;
  _ports[match[1]] = int.parse(match[2]);
  return true;
}

void endPubServe() {
  _pubServer.kill();
}

/// Schedules an HTTP request to the running pub server with [urlPath] and
/// verifies that it responds with a body that matches [expectation].
///
/// [expectation] may either be a [Matcher] or a string to match an exact body.
/// [root] indicates which server should be accessed, and defaults to "web".
/// [headers] may be either a [Matcher] or a map to match an exact headers map.
void requestShouldSucceed(String urlPath, expectation, {String root, headers}) {
  schedule(() {
    return http.get(_getServerUrlSync(root, urlPath)).then((response) {
      if (expectation != null) expect(response.body, expectation);
      if (headers != null) expect(response.headers, headers);
    });
  }, "request $urlPath");
}

/// Schedules an HTTP request to the running pub server with [urlPath] and
/// verifies that it responds with a 404.
///
/// [root] indicates which server should be accessed, and defaults to "web".
void requestShould404(String urlPath, {String root}) {
  schedule(() {
    return http.get(_getServerUrlSync(root, urlPath)).then((response) {
      expect(response.statusCode, equals(404));
    });
  }, "request $urlPath");
}

/// Schedules an HTTP request to the running pub server with [urlPath] and
/// verifies that it responds with a redirect to the given [redirectTarget].
///
/// [redirectTarget] may be either a [Matcher] or a string to match an exact
/// URL. [root] indicates which server should be accessed, and defaults to
/// "web".
void requestShouldRedirect(String urlPath, redirectTarget, {String root}) {
  schedule(() {
    var request = new http.Request("GET",
        Uri.parse(_getServerUrlSync(root, urlPath)));
    request.followRedirects = false;
    return request.send().then((response) {
      expect(response.statusCode ~/ 100, equals(3));

      expect(response.headers, containsPair('location', redirectTarget));
    });
  }, "request $urlPath");
}

/// Schedules an HTTP POST to the running pub server with [urlPath] and verifies
/// that it responds with a 405.
///
/// [root] indicates which server should be accessed, and defaults to "web".
void postShould405(String urlPath, {String root}) {
  schedule(() {
    return http.post(_getServerUrlSync(root, urlPath)).then((response) {
      expect(response.statusCode, equals(405));
    });
  }, "request $urlPath");
}

/// Reads lines from pub serve's stdout until it prints the build success
/// message.
///
/// The schedule will not proceed until the output is found. If not found, it
/// will eventually time out.
void waitForBuildSuccess() =>
  _pubServer.stdout.expect(consumeThrough(contains("successfully")));

/// Schedules opening a web socket connection to the currently running pub
/// serve.
Future _ensureWebSocket() {
  // Use the existing one if already connected.
  if (_webSocket != null) return new Future.value();

  // Server should already be running.
  expect(_pubServer, isNotNull);
  expect(_ports, isNot(isEmpty));

  // TODO(nweiz): once we have a separate port for a web interface into the
  // server, use that port for the websocket interface.
  var port = _ports.values.first;
  return WebSocket.connect("ws://127.0.0.1:$port").then((socket) {
    _webSocket = socket;
    // TODO(rnystrom): Works around #13913.
    _webSocketBroadcastStream = _webSocket.asBroadcastStream();
  });
}

/// Sends [request] (an arbitrary JSON object) to the running pub serve's web
/// socket connection, waits for a reply, then verifies that the reply is
/// either equal to [replyEquals] or matches [replyMatches].
///
/// Only one of [replyEquals] or [replyMatches] may be provided.
///
/// [request] and [replyMatches] may contain futures, in which case this will
/// wait until they've completed before matching.
///
/// If [encodeRequest] is `false`, then [request] will be sent as-is over the
/// socket. It omitted, request is JSON encoded to a string first.
void expectWebSocketCall(request, {Map replyEquals, replyMatches,
    bool encodeRequest: true}) {
  assert((replyEquals == null) != (replyMatches == null));

  schedule(() => _ensureWebSocket().then((_) {
    var matcherFuture;
    if (replyMatches != null) {
      matcherFuture = new Future.value(replyMatches);
    } else {
      matcherFuture = awaitObject(replyEquals).then((reply) => equals(reply));
    }

    return matcherFuture.then((matcher) {
      return awaitObject(request).then((completeRequest) {
        if (encodeRequest) completeRequest = JSON.encode(completeRequest);
        _webSocket.add(completeRequest);

        return _webSocketBroadcastStream.first.then((value) {
          expect(JSON.decode(value), matcher);
        });
      });
    });
  }), "send $request to web socket and expect reply $replyEquals");
}

/// Returns a [Future] that completes to a URL string for the server serving
/// [path] from [root].
///
/// If [root] is omitted, defaults to "web". If [path] is omitted, no path is
/// included. The Future will complete once the server is up and running and
/// the bound ports are known.
Future<String> getServerUrl([String root, String path]) =>
    _portsCompleter.future.then((_) => _getServerUrlSync(root, path));

/// Returns a URL string for the server serving [path] from [root].
///
/// If [root] is omitted, defaults to "web". If [path] is omitted, no path is
/// included. Unlike [getServerUrl], this should only be called after the ports
/// are known.
String _getServerUrlSync([String root, String path]) {
  if (root == null) root = 'web';
  expect(_ports, contains(root));
  var url = "http://127.0.0.1:${_ports[root]}";
  if (path != null) url = "$url/$path";
  return url;
}

