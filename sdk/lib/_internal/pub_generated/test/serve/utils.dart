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
import 'package:stack_trace/stack_trace.dart';

import '../../lib/src/utils.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';

/// The pub process running "pub serve".
ScheduledProcess _pubServer;

/// The ephemeral port assign to the running admin server.
int _adminPort;

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

/// The code for a lazy version of [REWRITE_TRANSFORMER].
const LAZY_TRANSFORMER = """
import 'dart:async';

import 'package:barback/barback.dart';

class LazyRewriteTransformer extends Transformer implements LazyTransformer {
  LazyRewriteTransformer.asPlugin();

  String get allowedExtensions => '.txt';

  Future apply(Transform transform) {
    transform.logger.info('Rewriting \${transform.primaryInput.id}.');
    return transform.primaryInput.readAsString().then((contents) {
      var id = transform.primaryInput.id.changeExtension(".out");
      transform.addOutput(new Asset.fromString(id, "\$contents.out"));
    });
  }

  Future declareOutputs(DeclaringTransform transform) {
    transform.declareOutput(transform.primaryId.changeExtension(".out"));
    return new Future.value();
  }
}
""";

/// The web socket error code for a directory not being served.
const NOT_SERVED = 1;

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
///
/// This transformer takes one configuration field: "addition". This is
/// concatenated to its TOKEN value before adding it to the output library.
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

import 'dart:io';

const TOKEN = "$id";

final _tokenRegExp = new RegExp(r'^const TOKEN = "(.*?)";\$', multiLine: true);

class DartTransformer extends Transformer {
  final BarbackSettings _settings;

  DartTransformer.asPlugin(this._settings);

  String get allowedExtensions => '.dart';

  Future apply(Transform transform) {
    return transform.primaryInput.readAsString().then((contents) {
      transform.addOutput(new Asset.fromString(transform.primaryInput.id,
          contents.replaceAllMapped(_tokenRegExp, (match) {
        var token = TOKEN;
        var addition = _settings.configuration["addition"];
        if (addition != null) token += addition;
        return 'const TOKEN = "(\${match[1]}, \$token)";';
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
ScheduledProcess startPubServe({Iterable<String> args, bool createWebDir: true})
    {
  var pubArgs = ["serve", "--port=0", // Use port 0 to get an ephemeral port.
    "--force-poll", "--log-admin-url"];

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
    _pubServer.stdout.expect(
        consumeThrough(
            anyOf(["Got dependencies!", matches(new RegExp(r"^Changed \d+ dependenc"))])));
  }

  _pubServer.stdout.expect(startsWith("Loading source assets..."));
  _pubServer.stdout.expect(consumeWhile(matches("Loading .* transformers...")));

  _pubServer.stdout.expect(predicate(_parseAdminPort));

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
final _parsePortRegExp = new RegExp(r"([^ ]+) +on http://localhost:(\d+)");

/// Parses the port number from the "Running admin server on localhost:1234"
/// line printed by pub serve.
bool _parseAdminPort(String line) {
  var match = _parsePortRegExp.firstMatch(line);
  if (match == null) return false;
  _adminPort = int.parse(match[2]);
  return true;
}

/// Parses the port number from the "Serving blah on localhost:1234" line
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
/// invokes [callback] with the response.
///
/// [root] indicates which server should be accessed, and defaults to "web".
Future<http.Response> scheduleRequest(String urlPath, {String root}) {
  return schedule(() {
    return http.get(_getServerUrlSync(root, urlPath));
  }, "request $urlPath");
}

/// Schedules an HTTP request to the running pub server with [urlPath] and
/// verifies that it responds with a body that matches [expectation].
///
/// [expectation] may either be a [Matcher] or a string to match an exact body.
/// [root] indicates which server should be accessed, and defaults to "web".
/// [headers] may be either a [Matcher] or a map to match an exact headers map.
void requestShouldSucceed(String urlPath, expectation, {String root, headers}) {
  scheduleRequest(urlPath, root: root).then((response) {
    if (expectation != null) expect(response.body, expectation);
    if (headers != null) expect(response.headers, headers);
  });
}

/// Schedules an HTTP request to the running pub server with [urlPath] and
/// verifies that it responds with a 404.
///
/// [root] indicates which server should be accessed, and defaults to "web".
void requestShould404(String urlPath, {String root}) {
  scheduleRequest(urlPath, root: root).then((response) {
    expect(response.statusCode, equals(404));
  });
}

/// Schedules an HTTP request to the running pub server with [urlPath] and
/// verifies that it responds with a redirect to the given [redirectTarget].
///
/// [redirectTarget] may be either a [Matcher] or a string to match an exact
/// URL. [root] indicates which server should be accessed, and defaults to
/// "web".
void requestShouldRedirect(String urlPath, redirectTarget, {String root}) {
  schedule(() {
    var request =
        new http.Request("GET", Uri.parse(_getServerUrlSync(root, urlPath)));
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

/// Schedules an HTTP request to the (theoretically) running pub server with
/// [urlPath] and verifies that it cannot be connected to.
///
/// [root] indicates which server should be accessed, and defaults to "web".
void requestShouldNotConnect(String urlPath, {String root}) {
  schedule(() {
    return expect(
        http.get(_getServerUrlSync(root, urlPath)),
        throwsA(new isInstanceOf<SocketException>()));
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
  expect(_adminPort, isNotNull);

  return WebSocket.connect("ws://localhost:$_adminPort").then((socket) {
    _webSocket = socket;
    // TODO(rnystrom): Works around #13913.
    _webSocketBroadcastStream = _webSocket.map(JSON.decode).asBroadcastStream();
  });
}

/// Schedules closing the web socket connection to the currently-running pub
/// serve.
void closeWebSocket() {
  schedule(() {
    return _ensureWebSocket().then((_) => _webSocket.close()).then((_) => _webSocket =
        null);
  }, "closing web socket");
}

/// Sends a JSON RPC 2.0 request to the running pub serve's web socket
/// connection.
///
/// This calls a method named [method] with the given [params] (or no
/// parameters, if it's not passed). [params] may contain Futures, in which case
/// this will wait until they've completed before sending the request.
///
/// This schedules the request, but doesn't block the schedule on the response.
/// It returns the response as a [Future].
Future<Map> webSocketRequest(String method, [Map params]) {
  var completer = new Completer();
  schedule(() {
    return Future.wait(
        [_ensureWebSocket(), awaitObject(params),]).then((results) {
      var resolvedParams = results[1];
      chainToCompleter(
          currentSchedule.wrapFuture(_jsonRpcRequest(method, resolvedParams)),
          completer);
    });
  }, "send $method with $params to web socket");
  return completer.future;
}

/// Sends a JSON RPC 2.0 request to the running pub serve's web socket
/// connection, waits for a reply, then verifies the result.
///
/// This calls a method named [method] with the given [params]. [params] may
/// contain Futures, in which case this will wait until they've completed before
/// sending the request.
///
/// The result is validated using [result], which may be a [Matcher] or a [Map]
/// containing [Matcher]s and [Future]s. This will wait until any futures are
/// completed before sending the request.
///
/// Returns a [Future] that completes to the call's result.
Future<Map> expectWebSocketResult(String method, Map params, result) {
  return schedule(() {
    return Future.wait(
        [webSocketRequest(method, params), awaitObject(result)]).then((results) {
      var response = results[0];
      var resolvedResult = results[1];
      expect(response["result"], resolvedResult);
      return response["result"];
    });
  }, "send $method with $params to web socket and expect $result");
}

/// Sends a JSON RPC 2.0 request to the running pub serve's web socket
/// connection, waits for a reply, then verifies the error response.
///
/// This calls a method named [method] with the given [params]. [params] may
/// contain Futures, in which case this will wait until they've completed before
/// sending the request.
///
/// The error response is validated using [errorCode] and [errorMessage]. Both
/// of these must be provided. The error code is checked against [errorCode] and
/// the error message is checked against [errorMessage]. Either of these may be
/// matchers.
///
/// If [data] is provided, it is a JSON value or matcher used to validate the
/// "data" value of the error response.
///
/// Returns a [Future] that completes to the error's [data] field.
Future expectWebSocketError(String method, Map params, errorCode, errorMessage,
    {data}) {
  return schedule(() {
    return webSocketRequest(method, params).then((response) {
      expect(response["error"]["code"], errorCode);
      expect(response["error"]["message"], errorMessage);

      if (data != null) {
        expect(response["error"]["data"], data);
      }

      return response["error"]["data"];
    });
  }, "send $method with $params to web socket and expect error $errorCode");
}

/// Validates that [root] was not bound to a port when pub serve started.
Future expectNotServed(String root) {
  return schedule(() {
    expect(_ports.containsKey(root), isFalse);
  });
}

/// The next id to use for a JSON-RPC 2.0 request.
var _rpcId = 0;

/// Sends a JSON-RPC 2.0 request calling [method] with [params].
///
/// Returns the response object.
Future<Map> _jsonRpcRequest(String method, [Map params]) {
  var id = _rpcId++;
  var message = {
    "jsonrpc": "2.0",
    "method": method,
    "id": id
  };
  if (params != null) message["params"] = params;
  _webSocket.add(JSON.encode(message));

  return _webSocketBroadcastStream.firstWhere(
      (response) => response["id"] == id).then((value) {
    currentSchedule.addDebugInfo(
        "Web Socket request $method with params $params\n" "Result: $value");

    expect(value["id"], equals(id));
    return value;
  });
}

/// Returns a [Future] that completes to a URL string for the server serving
/// [path] from [root].
///
/// If [root] is omitted, defaults to "web". If [path] is omitted, no path is
/// included. The Future will complete once the server is up and running and
/// the bound ports are known.
Future<String> getServerUrl([String root, String path]) =>
    _portsCompleter.future.then((_) => _getServerUrlSync(root, path));

/// Records that [root] has been bound to [port].
///
/// Used for testing the Web Socket API for binding new root directories to
/// ports after pub serve has been started.
registerServerPort(String root, int port) {
  _ports[root] = port;
}

/// Returns a URL string for the server serving [path] from [root].
///
/// If [root] is omitted, defaults to "web". If [path] is omitted, no path is
/// included. Unlike [getServerUrl], this should only be called after the ports
/// are known.
String _getServerUrlSync([String root, String path]) {
  if (root == null) root = 'web';
  expect(_ports, contains(root));
  var url = "http://localhost:${_ports[root]}";
  if (path != null) url = "$url/$path";
  return url;
}

