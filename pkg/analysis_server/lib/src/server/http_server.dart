// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analysis_server/src/socket_server.dart';
import 'package:analysis_server/src/status/diagnostics.dart';

/// Instances of the class [AbstractHttpHandler] handle HTTP requests.
abstract class AbstractHttpHandler {
  /// Handle a GET request received by the HTTP server.
  void handleGetRequest(HttpRequest request);

  /// Handle a POST request received by the HTTP server.
  void handlePostRequest(HttpRequest request);

  /// Handle a request to upgrade to a WebSocket.
  void handleWebSocketRequest(HttpRequest request);
}

/// Instances of the class [HttpServer] implement a simple HTTP server. The
/// server:
///
/// - listens for an UPGRADE request in order to start an analysis server
/// - serves diagnostic information as html pages
class HttpAnalysisServer {
  /// Number of lines of print output to capture.
  static const int _maxPrintBufferLength = 1000;

  /// An object that can handle either a WebSocket connection or a connection
  /// to the client over stdio.
  final AbstractSocketServer _socketServer;

  /// An object that can handle HTTP requests.
  late final AbstractHttpHandler _httpHandler = DiagnosticsSite(
    _socketServer,
    _printBuffer,
  );

  /// Future that is completed with the HTTP server once it is running.
  Future<HttpServer>? _serverFuture;

  /// Last PRINT_BUFFER_LENGTH lines printed.
  final List<String> _printBuffer = <String>[];

  /// Initialize a newly created HTTP server.
  new(this._socketServer);

  /// Return the port this server is bound to.
  Future<int?> get boundPort async {
    return (await _serverFuture)?.port;
  }

  void close() {
    _serverFuture?.then((HttpServer server) {
      server.close();
    });
  }

  /// Record that the given line was printed out by the analysis server.
  void recordPrint(String line) {
    _printBuffer.add(line);
    if (_printBuffer.length > _maxPrintBufferLength) {
      _printBuffer.removeRange(0, _printBuffer.length - _maxPrintBufferLength);
    }
  }

  /// Begin serving HTTP requests over the given port.
  Future<int?> serveHttp([int? initialPort]) async {
    if (_serverFuture != null) {
      return boundPort;
    }

    try {
      _serverFuture = HttpServer.bind(
        InternetAddress.loopbackIPv4,
        initialPort ?? 0,
      );

      var server = (await _serverFuture)!;
      _handleServer(server);
      return server.port;
    } catch (ignore) {
      // If we can't bind to the specified port, don't remember the broken
      // server.
      _serverFuture = null;

      return null;
    }
  }

  /// Attach a listener to a newly created HTTP server.
  void _handleServer(HttpServer httpServer) {
    httpServer.listen((HttpRequest request) {
      if (!_validateRequest(request, httpServer)) {
        return;
      }

      if (WebSocketTransformer.isUpgradeRequest(request)) {
        _httpHandler.handleWebSocketRequest(request);
      } else if (request.method == 'GET') {
        _httpHandler.handleGetRequest(request);
      } else if (request.method == 'POST') {
        _httpHandler.handlePostRequest(request);
      } else {
        _returnUnknownRequest(request);
      }
    });
  }

  /// Whether [origin] is an allowed origin for requests to [httpServer].
  bool _isAllowedOrigin(String origin, HttpServer httpServer) {
    Uri uri;
    try {
      uri = Uri.parse(origin);
    } catch (_) {
      return false;
    }

    var host = uri.host;
    // Loopback is always allowed.
    if (host == 'localhost' ||
        host == InternetAddress.loopbackIPv4.address ||
        host == InternetAddress.loopbackIPv6.address) {
      return true;
    }

    if (uri.port == httpServer.port &&
        (host == httpServer.address.address ||
            host == httpServer.address.host)) {
      return true;
    }

    return false;
  }

  /// Return a 403 Forbidden error in response to a request with an invalid
  /// `Host` or `Origin` header.
  void _returnForbiddenRequest(HttpRequest request, String message) {
    var response = request.response;
    response.statusCode = HttpStatus.forbidden;
    response.headers.contentType = ContentType.text;
    response.write(message);
    response.close();
  }

  /// Return an error in response to an unrecognized request received by the
  /// HTTP server.
  void _returnUnknownRequest(HttpRequest request) {
    var response = request.response;
    response.statusCode = HttpStatus.notFound;
    response.headers.contentType = ContentType.text;
    response.write('Not found');
    response.close();
  }

  /// Validates the `Host` and `Origin` headers of [request] to prevent
  /// DNS-rebinding and cross-site request forgery (CSRF) attacks.
  ///
  /// If the headers are invalid, a 403 Forbidden response is written to
  /// [request] and `false` is returned.
  bool _validateRequest(HttpRequest request, HttpServer httpServer) {
    // Validate Host header first to prevent DNS rebinding.
    var hostHeaders = request.headers[HttpHeaders.hostHeader];
    if (hostHeaders == null ||
        hostHeaders.length != 1 ||
        !_isAllowedOrigin('http://${hostHeaders.single}', httpServer)) {
      _returnForbiddenRequest(request, 'forbidden host');
      return false;
    }

    // Check the Origin header for cross-origin requests.
    var origins = [
      ...?request.headers['Sec-WebSocket-Origin'],
      ...?request.headers['Origin'],
    ];
    if (origins.any((origin) => !_isAllowedOrigin(origin, httpServer))) {
      _returnForbiddenRequest(request, 'forbidden origin');
      return false;
    }

    return true;
  }
}
