// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of vmservice_io;

class WebSocketClient extends Client {
  static const int PARSE_ERROR_CODE = 4000;
  static const int BINARY_MESSAGE_ERROR_CODE = 4001;
  static const int NOT_MAP_ERROR_CODE = 4002;
  final WebSocket socket;

  WebSocketClient(this.socket, service) : super(service) {
    socket.listen((message) => onWebSocketMessage(message));
    socket.done.then((_) => close());
  }

  void onWebSocketMessage(message) {
    if (message is String) {
      var map;
      try {
        map = JSON.decode(message);
      } catch (e) {
        socket.close(PARSE_ERROR_CODE, 'Message parse error: $e');
        return;
      }
      if (map is! Map) {
        socket.close(NOT_MAP_ERROR_CODE, 'Message must be a JSON map.');
        return;
      }
      var seq = map['seq'];
      onMessage(seq, new Message.fromUri(Uri.parse(map['request'])));
    } else {
      socket.close(BINARY_MESSAGE_ERROR_CODE, 'Message must be a string.');
    }
  }

  void post(var seq, String response) {
    try {
      Map map = {
        'seq': seq,
        'response': response
      };
      socket.add(JSON.encode(map));
    } catch (_) {
      // Error posting over WebSocket.
    }
  }

  dynamic toJson() {
    Map map = super.toJson();
    map['type'] = 'WebSocketClient';
    map['socket'] = '$socket';
    return map;
  }
}


class HttpRequestClient extends Client {
  static ContentType jsonContentType =
      new ContentType("application", "json", charset: "utf-8");
  final HttpRequest request;

  HttpRequestClient(this.request, service) : super(service);

  void post(var seq, String response) {
    request.response..headers.contentType = jsonContentType
                    ..write(response)
                    ..close();
    close();
  }

  dynamic toJson() {
    Map map = super.toJson();
    map['type'] = 'HttpRequestClient';
    map['request'] = '$request';
    return map;
  }
}

class Server {
  static const WEBSOCKET_PATH = '/ws';
  String observatoryPath = '/index.html';
  final String ip;
  int port;

  final VMService service;
  HttpServer _server;

  Server(this.service, this.ip, this.port);

  bool _shouldServeObservatory(HttpRequest request) {
    if (request.headers['Observatory-Version'] != null) {
      // Request is already coming from Observatory.
      return false;
    }
    // TODO(johnmccutchan): Test with obscure browsers.
    if (request.headers.value(HttpHeaders.USER_AGENT).contains('Mozilla')) {
      // Request is coming from a browser but not Observatory application.
      // Serve Observatory and let the Observatory make the real request.
      return true;
    }
    // All other user agents are assumed to be textual.
    return false;
  }

  void _requestHandler(HttpRequest request) {
    // Allow cross origin requests with 'observatory' header.
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Headers',
                                 'Observatory-Version');

    if (request.method != 'GET') {
      // Not a GET request. Do nothing.
      request.response.close();
      return;
    }

    final String path =
          request.uri.path == '/' ? observatoryPath : request.uri.path;

    if (path == WEBSOCKET_PATH) {
      WebSocketTransformer.upgrade(request).then((WebSocket webSocket) {
        new WebSocketClient(webSocket, service);
      });
      return;
    }

    var resource = Resource.resources[path];
    if (resource == null && _shouldServeObservatory(request)) {
      resource = Resource.resources[observatoryPath];
      assert(resource != null);
    }
    if (resource != null) {
      // Serving up a static resource (e.g. .css, .html, .png).
      request.response.headers.contentType =
          ContentType.parse(resource.mimeType);
      request.response.add(resource.data);
      request.response.close();
      return;
    }
    var message = new Message.fromUri(request.uri);
    var client = new HttpRequestClient(request, service);
    client.onMessage(null, message);
  }

  Future startServer() {
    return HttpServer.bind(ip, port).then((s) {
      // Only display message when port is automatically selected.
      var display_message = (ip != '127.0.0.1' || port != 8181);
      // Retrieve port.
      port = s.port;
      _server = s;
      _server.listen(_requestHandler);
      if (display_message) {
        print('Observatory listening on http://$ip:$port');
      }
      return s;
    });
  }
}
