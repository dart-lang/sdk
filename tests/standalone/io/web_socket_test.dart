// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

#import("dart:io");

void testRequestResponseClientCloses(
    int totalConnections, int closeStatus, String closeReason) {
  HttpServer server = new HttpServer();
  HttpClient client = new HttpClient();

  server.listen("127.0.0.1", 0, totalConnections);

  // Create a web socket handler and set is as the HTTP server default
  // handler.
  WebSocketHandler wsHandler = new WebSocketHandler();
  wsHandler.onOpen = (WebSocketConnection conn) {
    var count = 0;
    conn.onMessage = (Object message) => conn.send(message);
    conn.onClosed = (status, reason) {
      Expect.equals(closeStatus, status);
      Expect.equals(closeReason, reason);
    };
  };
  server.defaultRequestHandler = wsHandler.onRequest;

  int closeCount = 0;
  String messageText = "Hello, world!";
  for (int i = 0; i < totalConnections; i++) {
    int messageCount = 0;
    HttpClientConnection conn = client.get("127.0.0.1", server.port, "/");
    WebSocketClientConnection wsconn = new WebSocketClientConnection(conn);
    wsconn.onOpen = () => wsconn.send(messageText);
    wsconn.onMessage = (message) {
      messageCount++;
      if (messageCount < 10) {
        Expect.equals(messageText, message);
        wsconn.send(message);
      } else {
        wsconn.close(closeStatus, closeReason);
      }
    };
    wsconn.onClosed = (status, reason) {
      Expect.equals(closeStatus, status);
      Expect.isNull(reason);
      closeCount++;
      if (closeCount == totalConnections) {
        client.shutdown();
        server.close();
      }
    };
  }
}


void testRequestResponseServerCloses(
    int totalConnections, int closeStatus, String closeReason) {
  HttpServer server = new HttpServer();
  HttpClient client = new HttpClient();

  server.listen("127.0.0.1", 0, totalConnections);

  // Create a web socket handler and set is as the HTTP server default
  // handler.
  int closeCount = 0;
  WebSocketHandler wsHandler = new WebSocketHandler();
  wsHandler.onOpen = (WebSocketConnection conn) {
    String messageText = "Hello, world!";
    int messageCount = 0;
    conn.onMessage = (Object message) {
      messageCount++;
      if (messageCount < 10) {
        Expect.equals(messageText, message);
        conn.send(message);
      } else {
        conn.close(closeStatus, closeReason);
      }
    };
    conn.onClosed = (status, reason) {
      Expect.equals(closeStatus, status);
      Expect.isNull(reason);
      closeCount++;
      if (closeCount == totalConnections) {
        client.shutdown();
        server.close();
      }
    };
    conn.send(messageText);
  };
  server.defaultRequestHandler = wsHandler.onRequest;

  for (int i = 0; i < totalConnections; i++) {
    HttpClientConnection conn = client.get("127.0.0.1", server.port, "/");
    WebSocketClientConnection wsconn = new WebSocketClientConnection(conn);
    wsconn.onMessage = (message) => wsconn.send(message);
    wsconn.onClosed = (status, reason) {
      Expect.equals(closeStatus, status);
      Expect.equals(closeReason, reason);
    };
  }
}


void testMessageLength(int messageLength) {
  HttpServer server = new HttpServer();
  HttpClient client = new HttpClient();

  server.listen("127.0.0.1", 0, 1);

  // Create a web socket handler and set is as the HTTP server default
  // handler.
  String originalMessage = "";
  for (int i = 0; i < messageLength; i++) originalMessage += "${i % 10}";
  WebSocketHandler wsHandler = new WebSocketHandler();
  wsHandler.onOpen = (WebSocketConnection conn) {
    conn.onMessage = (Object message) {
      Expect.equals(originalMessage, message);
      conn.send(message);
    };
    conn.onClosed = (status, reason) {
    };
  };
  server.defaultRequestHandler = wsHandler.onRequest;

  HttpClientConnection conn = client.get("127.0.0.1", server.port, "/");
  WebSocketClientConnection wsconn = new WebSocketClientConnection(conn);
  wsconn.onMessage = (message) {
    Expect.equals(originalMessage, message);
    wsconn.close();
  };
  wsconn.onClosed = (status, reason) {
    server.close();
  };
  wsconn.onOpen = () {
    wsconn.send(originalMessage);
  };
}


void testNoUpgrade() {
  HttpServer server = new HttpServer();
  HttpClient client = new HttpClient();

  server.listen("127.0.0.1", 0, 5);

  // Create a server which always responds with a redirect.
  server.defaultRequestHandler = (request, response) {
    response.statusCode = HttpStatus.MOVED_PERMANENTLY;
    response.outputStream.close();
  };

  HttpClientConnection conn = client.get("127.0.0.1", server.port, "/");
  conn.followRedirects = false;
  WebSocketClientConnection wsconn = new WebSocketClientConnection(conn);
  wsconn.onNoUpgrade = (response) {
    Expect.equals(HttpStatus.MOVED_PERMANENTLY, response.statusCode);
    client.shutdown();
    server.close();
  };
}


void testUsePOST() {
  HttpServer server = new HttpServer();
  HttpClient client = new HttpClient();

  server.listen("127.0.0.1", 0, 5);

  // Create a web socket handler and set is as the HTTP server default
  // handler.
  int closeCount = 0;
  WebSocketHandler wsHandler = new WebSocketHandler();
  wsHandler.onOpen = (WebSocketConnection conn) {
    Expect.fail("No connection expected");
  };
  server.defaultRequestHandler = wsHandler.onRequest;

  HttpClientConnection conn = client.post("127.0.0.1", server.port, "/");
  WebSocketClientConnection wsconn = new WebSocketClientConnection(conn);
  wsconn.onNoUpgrade = (response) {
    Expect.equals(HttpStatus.BAD_REQUEST, response.statusCode);
    client.shutdown();
    server.close();
  };
}


class WebSocketInfo {
  int messageCount = 0;
}


void testHashCode(int totalConnections) {
  HttpServer server = new HttpServer();
  HttpClient client = new HttpClient();
  Map connections = new Map();

  server.listen("127.0.0.1", 0, totalConnections);

  void handleMessage(conn, message) {
    var info = connections[conn];
    Expect.isNotNull(info);
    info.messageCount++;
    if (info.messageCount < 10) {
      conn.send(message);
    } else {
      conn.close();
    }
  }

  // Create a web socket handler and set is as the HTTP server default
  // handler.
  int closeCount = 0;
  WebSocketHandler wsHandler = new WebSocketHandler();
  wsHandler.onOpen = (WebSocketConnection conn) {
    connections[conn] = new WebSocketInfo();
    String messageText = "Hello, world!";
    conn.onMessage = (Object message) {
      handleMessage(conn, message);
    };
    conn.onClosed = (status, reason) {
      closeCount++;
      var info = connections[conn];
      Expect.equals(10, info.messageCount);
      if (closeCount == totalConnections) {
        client.shutdown();
        server.close();
      }
    };
    conn.send(messageText);
  };
  server.defaultRequestHandler = wsHandler.onRequest;

  for (int i = 0; i < totalConnections; i++) {
    HttpClientConnection conn = client.get("127.0.0.1", server.port, "/");
    WebSocketClientConnection wsconn = new WebSocketClientConnection(conn);
    wsconn.onMessage = (message) => wsconn.send(message);
  }
}


void testW3CInterface(
    int totalConnections, int closeStatus, String closeReason) {
  HttpServer server = new HttpServer();

  server.listen("127.0.0.1", 0, totalConnections);

  // Create a web socket handler and set is as the HTTP server default
  // handler.
  int closeCount = 0;
  WebSocketHandler wsHandler = new WebSocketHandler();
  wsHandler.onOpen = (WebSocketConnection conn) {
    String messageText = "Hello, world!";
    int messageCount = 0;
    conn.onMessage = (Object message) {
      messageCount++;
      if (messageCount < 10) {
        Expect.equals(messageText, message);
        conn.send(message);
      } else {
        conn.close(closeStatus, closeReason);
      }
    };
    conn.onClosed = (status, reason) {
      Expect.equals(closeStatus, status);
      Expect.isNull(reason);
      closeCount++;
      if (closeCount == totalConnections) {
        server.close();
      }
    };
    conn.send(messageText);
  };
  server.defaultRequestHandler = wsHandler.onRequest;

  void webSocketConnection() {
    bool onopenCalled = false;
    int onmessageCalled = 0;
    bool oncloseCalled = false;

    var websocket = new WebSocket("ws://127.0.0.1:${server.port}");
    Expect.equals(WebSocket.CONNECTING, websocket.readyState);
    websocket.onopen = () {
      Expect.isFalse(onopenCalled);
      Expect.equals(0, onmessageCalled);
      Expect.isFalse(oncloseCalled);
      onopenCalled = true;
      Expect.equals(WebSocket.OPEN, websocket.readyState);
    };
    websocket.onmessage = (event) {
      onmessageCalled++;
      Expect.isTrue(onopenCalled);
      Expect.isFalse(oncloseCalled);
      Expect.equals(WebSocket.OPEN, websocket.readyState);
      websocket.send(event.data);
    };
    websocket.onclose = (event) {
      Expect.isTrue(onopenCalled);
      Expect.equals(10, onmessageCalled);
      Expect.isFalse(oncloseCalled);
      oncloseCalled = true;
      Expect.isTrue(event.wasClean);
      Expect.equals(3002, event.code);
      Expect.equals("Got tired", event.reason);
      Expect.equals(WebSocket.CLOSED, websocket.readyState);
    };
  }

  for (int i = 0; i < totalConnections; i++) {
    webSocketConnection();
  }
}


main() {
  testRequestResponseClientCloses(2, null, null);
  testRequestResponseClientCloses(2, 3001, null);
  testRequestResponseClientCloses(2, 3002, "Got tired");
  testRequestResponseServerCloses(2, null, null);
  testRequestResponseServerCloses(2, 3001, null);
  testRequestResponseServerCloses(2, 3002, "Got tired");
  testMessageLength(125);
  testMessageLength(126);
  testMessageLength(127);
  testMessageLength(65535);
  testMessageLength(65536);
  testNoUpgrade();
  testUsePOST();
  testHashCode(2);

  testW3CInterface(2, 3002, "Got tired");
}
