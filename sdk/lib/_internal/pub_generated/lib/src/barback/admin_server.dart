library pub.barback.admin_server;
import 'dart:async';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import '../io.dart';
import '../log.dart' as log;
import 'asset_environment.dart';
import 'base_server.dart';
import 'web_socket_api.dart';
class AdminServer extends BaseServer {
  final _webSockets = new Set<CompatibleWebSocket>();
  shelf.Handler _handler;
  static Future<AdminServer> bind(AssetEnvironment environment, String host,
      int port) {
    return bindServer(host, port).then((server) {
      log.fine('Bound admin server to $host:$port.');
      return new AdminServer._(environment, server);
    });
  }
  AdminServer._(AssetEnvironment environment, HttpServer server)
      : super(environment, server) {
    _handler = new shelf.Cascade().add(
        webSocketHandler(_handleWebSocket)).add(_handleHttp).handler;
  }
  Future close() {
    var futures = [super.close()];
    futures.addAll(_webSockets.map((socket) => socket.close()));
    return Future.wait(futures);
  }
  handleRequest(shelf.Request request) => _handler(request);
  _handleHttp(shelf.Request request) {
    logRequest(request, "501 Not Implemented");
    return new shelf.Response(
        501,
        body: "Currently this server only accepts Web Socket connections.");
  }
  void _handleWebSocket(CompatibleWebSocket socket) {
    _webSockets.add(socket);
    var api = new WebSocketApi(socket, environment);
    api.listen().whenComplete(
        () => _webSockets.remove(api)).catchError(addError);
  }
}
