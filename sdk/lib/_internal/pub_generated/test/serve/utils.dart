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
ScheduledProcess _pubServer;
int _adminPort;
final _ports = new Map<String, int>();
Completer _portsCompleter;
WebSocket _webSocket;
Stream _webSocketBroadcastStream;
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
const NOT_SERVED = 1;
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
ScheduledProcess startPubServe({Iterable<String> args, bool createWebDir: true})
    {
  var pubArgs = ["serve", "--port=0", "--force-poll", "--log-admin-url"];
  if (args != null) pubArgs.addAll(args);
  currentSchedule.timeout *= 1.5;
  if (createWebDir) d.dir(appPath, [d.dir("web")]).create();
  return startPub(args: pubArgs);
}
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
  _pubServer.stdout.expect(
      consumeWhile(predicate(_parsePort, 'emits server url')));
  schedule(() {
    expect(_ports, isNot(isEmpty));
    _portsCompleter.complete();
  });
  return _pubServer;
}
final _parsePortRegExp = new RegExp(r"([^ ]+) +on http://localhost:(\d+)");
bool _parseAdminPort(String line) {
  var match = _parsePortRegExp.firstMatch(line);
  if (match == null) return false;
  _adminPort = int.parse(match[2]);
  return true;
}
bool _parsePort(String line) {
  var match = _parsePortRegExp.firstMatch(line);
  if (match == null) return false;
  _ports[match[1]] = int.parse(match[2]);
  return true;
}
void endPubServe() {
  _pubServer.kill();
}
Future<http.Response> scheduleRequest(String urlPath, {String root}) {
  return schedule(() {
    return http.get(_getServerUrlSync(root, urlPath));
  }, "request $urlPath");
}
void requestShouldSucceed(String urlPath, expectation, {String root, headers}) {
  scheduleRequest(urlPath, root: root).then((response) {
    if (expectation != null) expect(response.body, expectation);
    if (headers != null) expect(response.headers, headers);
  });
}
void requestShould404(String urlPath, {String root}) {
  scheduleRequest(urlPath, root: root).then((response) {
    expect(response.statusCode, equals(404));
  });
}
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
void postShould405(String urlPath, {String root}) {
  schedule(() {
    return http.post(_getServerUrlSync(root, urlPath)).then((response) {
      expect(response.statusCode, equals(405));
    });
  }, "request $urlPath");
}
void requestShouldNotConnect(String urlPath, {String root}) {
  schedule(() {
    return expect(
        http.get(_getServerUrlSync(root, urlPath)),
        throwsA(new isInstanceOf<SocketException>()));
  }, "request $urlPath");
}
void waitForBuildSuccess() =>
    _pubServer.stdout.expect(consumeThrough(contains("successfully")));
Future _ensureWebSocket() {
  if (_webSocket != null) return new Future.value();
  expect(_pubServer, isNotNull);
  expect(_adminPort, isNotNull);
  return WebSocket.connect("ws://localhost:$_adminPort").then((socket) {
    _webSocket = socket;
    _webSocketBroadcastStream = _webSocket.map(JSON.decode).asBroadcastStream();
  });
}
void closeWebSocket() {
  schedule(() {
    return _ensureWebSocket().then((_) => _webSocket.close()).then((_) => _webSocket =
        null);
  }, "closing web socket");
}
Future<Map> webSocketRequest(String method, [Map params]) {
  var completer = new Completer();
  schedule(() {
    return Future.wait(
        [_ensureWebSocket(), awaitObject(params)]).then((results) {
      var resolvedParams = results[1];
      chainToCompleter(
          currentSchedule.wrapFuture(_jsonRpcRequest(method, resolvedParams)),
          completer);
    });
  }, "send $method with $params to web socket");
  return completer.future;
}
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
Future expectNotServed(String root) {
  return schedule(() {
    expect(_ports.containsKey(root), isFalse);
  });
}
var _rpcId = 0;
Future<Map> _jsonRpcRequest(String method, [Map params]) {
  var id = _rpcId++;
  var message = {
    "jsonrpc": "2.0",
    "method": method,
    "id": id
  };
  if (params != null) message["params"] = params;
  _webSocket.add(JSON.encode(message));
  return Chain.track(
      _webSocketBroadcastStream.firstWhere(
          (response) => response["id"] == id)).then((value) {
    currentSchedule.addDebugInfo(
        "Web Socket request $method with params $params\n" "Result: $value");
    expect(value["id"], equals(id));
    return value;
  });
}
Future<String> getServerUrl([String root, String path]) =>
    _portsCompleter.future.then((_) => _getServerUrlSync(root, path));
registerServerPort(String root, int port) {
  _ports[root] = port;
}
String _getServerUrlSync([String root, String path]) {
  if (root == null) root = 'web';
  expect(_ports, contains(root));
  var url = "http://localhost:${_ports[root]}";
  if (path != null) url = "$url/$path";
  return url;
}
