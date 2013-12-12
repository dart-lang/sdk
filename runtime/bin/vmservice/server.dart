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
      onMessage(seq, new Message.fromMap(map));
    } else {
      socket.close(BINARY_MESSAGE_ERROR_CODE, 'message must be a string.');
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
  static ContentType jsonContentType = ContentType.parse('application/json');
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
  String defaultPath = '/index.html';
  int port;

  final VMService service;
  HttpServer _server;

  Server(this.service, this.port);

  void _requestHandler(HttpRequest request) {
    // Allow cross origin requests.
    request.response.headers.add('Access-Control-Allow-Origin', '*');

    final String path =
          request.uri.path == '/' ? defaultPath : request.uri.path;

    var resource = Resource.resources[path];
    if (resource != null) {
      // Serving up a static resource (e.g. .css, .html, .png).
      request.response.headers.contentType =
          ContentType.parse(resource.mimeType);
      request.response.add(resource.data);
      request.response.close();
      return;
    }

    if (path == WEBSOCKET_PATH) {
      WebSocketTransformer.upgrade(request).then((WebSocket webSocket) {
        new WebSocketClient(webSocket, service);
      });
      return;
    }

    var message = new Message.fromUri(request.uri);
    var client = new HttpRequestClient(request, service);
    client.onMessage(null, message);
  }

  Future startServer() {
    return HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, port).then((s) {
      // Only display message when port is automatically selected.
      var display_message = (port == 0);
      // Retrieve port.
      port = s.port;
      _server = s;
      _server.listen(_requestHandler);
      if (display_message) {
        print('VMService listening on port $port');
      }
      return s;
    });
  }
}
