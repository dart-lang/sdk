// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library shelf_web_socket.web_socket_handler;

import 'dart:convert';

import 'package:http_parser/http_parser.dart';
import 'package:shelf/shelf.dart';

/// A class that exposes a handler for upgrading WebSocket requests.
class WebSocketHandler {
  /// The function to call when a request is upgraded.
  final Function _onConnection;

  /// The set of protocols the user supports, or `null`.
  final Set<String> _protocols;

  /// The set of allowed browser origin connections, or `null`..
  final Set<String> _allowedOrigins;

  WebSocketHandler(this._onConnection, this._protocols, this._allowedOrigins);

  /// The [Handler].
  Response handle(Request request) {
    if (request.method != 'GET') return _notFound();

    var connection = request.headers['Connection'];
    if (connection == null) return _notFound();
    var tokens = connection.toLowerCase().split(',')
        .map((token) => token.trim());
    if (!tokens.contains('upgrade')) return _notFound();

    var upgrade = request.headers['Upgrade'];
    if (upgrade == null) return _notFound();
    if (upgrade.toLowerCase() != 'websocket') return _notFound();

    var version = request.headers['Sec-WebSocket-Version'];
    if (version == null) {
      return _badRequest('missing Sec-WebSocket-Version header.');
    } else if (version != '13') {
      return _notFound();
    }

    if (request.protocolVersion != '1.1') {
      return _badRequest('unexpected HTTP version '
          '"${request.protocolVersion}".');
    }

    var key = request.headers['Sec-WebSocket-Key'];
    if (key == null) return _badRequest('missing Sec-WebSocket-Key header.');

    if (!request.canHijack) {
      throw new ArgumentError("webSocketHandler may only be used with a server "
          "that supports request hijacking.");
    }

    // The Origin header is always set by browser connections. By filtering out
    // unexpected origins, we ensure that malicious JavaScript is unable to fake
    // a WebSocket handshake.
    var origin = request.headers['Origin'];
    if (origin != null && _allowedOrigins != null &&
        !_allowedOrigins.contains(origin.toLowerCase())) {
      return _forbidden('invalid origin "$origin".');
    }

    var protocol = _chooseProtocol(request);
    request.hijack((stream, byteSink) {
      var sink = UTF8.encoder.startChunkedConversion(byteSink);
      sink.add(
          "HTTP/1.1 101 Switching Protocols\r\n"
          "Upgrade: websocket\r\n"
          "Connection: Upgrade\r\n"
          "Sec-WebSocket-Accept: ${CompatibleWebSocket.signKey(key)}\r\n");
      if (protocol != null) sink.add("Sec-WebSocket-Protocol: $protocol\r\n");
      sink.add("\r\n");

      _onConnection(new CompatibleWebSocket(stream, sink: byteSink), protocol);
    });

    // [request.hijack] is guaranteed to throw a [HijackException], so we'll
    // never get here.
    assert(false);
    return null;
  }

  /// Selects a subprotocol to use for the given connection.
  ///
  /// If no matching protocol can be found, returns `null`.
  String _chooseProtocol(Request request) {
    var protocols = request.headers['Sec-WebSocket-Protocol'];
    if (protocols == null) return null;
    for (var protocol in protocols.split(',')) {
      protocol = protocol.trim();
      if (_protocols.contains(protocol)) return protocol;
    }
    return null;
  }

  /// Returns a 404 Not Found response.
  Response _notFound() => _htmlResponse(404, "404 Not Found",
      "Only WebSocket connections are supported.");

  /// Returns a 400 Bad Request response.
  ///
  /// [message] will be HTML-escaped before being included in the response body.
  Response _badRequest(String message) => _htmlResponse(400, "400 Bad Request",
      "Invalid WebSocket upgrade request: $message");

  /// Returns a 403 Forbidden response.
  ///
  /// [message] will be HTML-escaped before being included in the response body.
  Response _forbidden(String message) => _htmlResponse(403, "403 Forbidden",
      "WebSocket upgrade refused: $message");

  /// Creates an HTTP response with the given [statusCode] and an HTML body with
  /// [title] and [message].
  ///
  /// [title] and [message] will be automatically HTML-escaped.
  Response _htmlResponse(int statusCode, String title, String message) {
    title = HTML_ESCAPE.convert(title);
    message = HTML_ESCAPE.convert(message);
    return new Response(statusCode, body: """
      <!doctype html>
      <html>
        <head><title>$title</title></head>
        <body>
          <h1>$title</h1>
          <p>$message</p>
        </body>
      </html>
    """, headers: {'content-type': 'text/html'});
  }
}
