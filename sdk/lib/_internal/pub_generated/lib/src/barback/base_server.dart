library pub.barback.base_server;
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:barback/barback.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:stack_trace/stack_trace.dart';
import '../log.dart' as log;
import '../utils.dart';
import 'asset_environment.dart';
abstract class BaseServer<T> {
  final AssetEnvironment environment;
  final HttpServer _server;
  int get port => _server.port;
  InternetAddress get address => _server.address;
  Uri get url => baseUrlForAddress(_server.address, port);
  Stream<T> get results => _resultsController.stream;
  final _resultsController = new StreamController<T>.broadcast();
  BaseServer(this.environment, this._server) {
    shelf_io.serveRequests(
        Chain.track(_server),
        const shelf.Pipeline().addMiddleware(
            shelf.createMiddleware(
                errorHandler: _handleError)).addMiddleware(
                    shelf.createMiddleware(
                        responseHandler: _disableGzip)).addHandler(handleRequest));
  }
  Future close() {
    return Future.wait([_server.close(), _resultsController.close()]);
  }
  handleRequest(shelf.Request request);
  shelf.Response methodNotAllowed(shelf.Request request) {
    logRequest(request, "405 Method Not Allowed");
    return new shelf.Response(
        405,
        body: "The ${request.method} method is not allowed for ${request.url}.",
        headers: {
      'Allow': 'GET, HEAD'
    });
  }
  shelf.Response notFound(shelf.Request request, {String error,
      AssetId asset}) {
    logRequest(request, "Not Found");
    var body = new StringBuffer();
    body.writeln("""
        <!DOCTYPE html>
        <head>
        <title>404 Not Found</title>
        </head>
        <body>
        <h1>404 Not Found</h1>""");
    if (asset != null) {
      body.writeln(
          "<p>Could not find asset "
              "<code>${HTML_ESCAPE.convert(asset.path)}</code> in package "
              "<code>${HTML_ESCAPE.convert(asset.package)}</code>.</p>");
    }
    if (error != null) {
      body.writeln("<p>Error: ${HTML_ESCAPE.convert(error)}</p>");
    }
    body.writeln("""
        </body>""");
    return new shelf.Response.notFound(body.toString(), headers: {
      'Content-Type': 'text/html; charset=utf-8'
    });
  }
  void logRequest(shelf.Request request, String message) =>
      log.fine("$this ${request.method} ${request.url}\n$message");
  void addResult(T result) {
    _resultsController.add(result);
  }
  void addError(error, [stackTrace]) {
    _resultsController.addError(error, stackTrace);
  }
  _handleError(error, StackTrace stackTrace) {
    _resultsController.addError(error, stackTrace);
    close();
    return new shelf.Response.internalServerError();
  }
  _disableGzip(shelf.Response response) {
    if (!response.headers.containsKey('Content-Encoding')) {
      return response.change(headers: {
        'Content-Encoding': ''
      });
    }
    return response;
  }
}
