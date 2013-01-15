// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

import "dart:async";
import "dart:io";
import "dart:isolate";
import "dart:scalarlist";
import "dart:uri";

const SERVER_ADDRESS = "127.0.0.1";
const HOST_NAME = "localhost";

// We will run the tests once over HTTP and once over HTTPS.
bool secure = false;

Future testRequestResponseClientCloses(
    int totalConnections, int closeStatus, String closeReason) {
  Completer done = new Completer();
  HttpServer server = secure ? new HttpsServer() : new HttpServer();
  HttpClient client = new HttpClient();

  server.listen(SERVER_ADDRESS,
                0,
                backlog: totalConnections,
                certificate_name: "CN=$HOST_NAME");

  // Create a web socket handler and set it as the HTTP server default handler.
  WebSocketHandler wsHandler = new WebSocketHandler();
  wsHandler.onOpen = (WebSocketConnection conn) {
    var count = 0;
    conn.onMessage = (Object message) => conn.send(message);
    conn.onClosed = (status, reason) {
      Expect.equals(closeStatus == null
                    ? WebSocketStatus.NO_STATUS_RECEIVED
                    : closeStatus, status);
      Expect.equals(closeReason == null ? "" : closeReason, reason);
    };
  };
  server.defaultRequestHandler = wsHandler.onRequest;

  int closeCount = 0;
  String messageText = "Hello, world!";
  for (int i = 0; i < totalConnections; i++) {
    int messageCount = 0;
    HttpClientConnection conn = client.getUrl(new Uri.fromString(
        '${secure ? "https" : "http"}://$HOST_NAME:${server.port}/'));
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
      Expect.equals(closeStatus == null
                    ? WebSocketStatus.NO_STATUS_RECEIVED
                    : closeStatus, status);
      Expect.equals("", reason);
      closeCount++;
      if (closeCount == totalConnections) {
        client.shutdown();
        server.close();
        done.complete(null);
      }
    };
  }
  return done.future;
}


Future testRequestResponseServerCloses(
    int totalConnections, int closeStatus, String closeReason) {
  Completer done = new Completer();
  HttpServer server = secure ? new HttpsServer() : new HttpServer();
  HttpClient client = new HttpClient();

  server.listen(SERVER_ADDRESS,
                0,
                backlog: totalConnections,
                certificate_name: "CN=$HOST_NAME");

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
      Expect.equals(closeStatus == null
                    ? WebSocketStatus.NO_STATUS_RECEIVED
                    : closeStatus, status);
      Expect.equals("", reason);
      closeCount++;
      if (closeCount == totalConnections) {
        client.shutdown();
        server.close();
        done.complete(null);
      }
    };
    conn.send(messageText);
  };
  server.defaultRequestHandler = wsHandler.onRequest;

  for (int i = 0; i < totalConnections; i++) {
    HttpClientConnection conn = client.getUrl(new Uri.fromString(
        '${secure ? "https" : "http"}://$HOST_NAME:${server.port}/'));
    WebSocketClientConnection wsconn = new WebSocketClientConnection(conn);
    wsconn.onMessage = (message) => wsconn.send(message);
    wsconn.onClosed = (status, reason) {
      Expect.equals(closeStatus == null
                    ? WebSocketStatus.NO_STATUS_RECEIVED
                    : closeStatus, status);
      Expect.equals(closeReason == null ? "" : closeReason, reason);
    };
  }
  return done.future;
}


Future testMessageLength(int messageLength) {
  Completer done = new Completer();
  HttpServer server = secure ? new HttpsServer() : new HttpServer();
  HttpClient client = new HttpClient();
  bool serverReceivedMessage = false;
  bool clientReceivedMessage = false;

  server.listen(SERVER_ADDRESS,
                0,
                backlog: 1,
                certificate_name: "CN=$HOST_NAME");

  // Create a web socket handler and set is as the HTTP server default
  // handler.
  Uint8List originalMessage = new Uint8List(messageLength);
  WebSocketHandler wsHandler = new WebSocketHandler();
  wsHandler.onOpen = (WebSocketConnection conn) {
    conn.onMessage = (Object message) {
      serverReceivedMessage = true;
      Expect.listEquals(originalMessage, message);
      conn.send(message);
    };
    conn.onClosed = (status, reason) {
    };
  };
  server.defaultRequestHandler = wsHandler.onRequest;

  HttpClientConnection conn = client.getUrl(new Uri.fromString(
      '${secure ? "https" : "http"}://$HOST_NAME:${server.port}/'));
  WebSocketClientConnection wsconn = new WebSocketClientConnection(conn);
  wsconn.onMessage = (message) {
    clientReceivedMessage = true;
    Expect.listEquals(originalMessage, message);
    wsconn.close();
  };
  wsconn.onClosed = (status, reason) {
    Expect.isTrue(serverReceivedMessage);
    Expect.isTrue(clientReceivedMessage);
    client.shutdown();
    server.close();
    done.complete(null);
  };
  wsconn.onOpen = () {
    wsconn.send(originalMessage);
  };
  return done.future;
}


Future testNoUpgrade() {
  Completer done = new Completer();
  HttpServer server = secure ? new HttpsServer() : new HttpServer();
  HttpClient client = new HttpClient();

  server.listen(SERVER_ADDRESS,
                0,
                backlog: 5,
                certificate_name: "CN=$HOST_NAME");

  // Create a server which always responds with a redirect.
  server.defaultRequestHandler = (request, response) {
    response.statusCode = HttpStatus.MOVED_PERMANENTLY;
    response.outputStream.close();
  };

  HttpClientConnection conn = client.getUrl(new Uri.fromString(
      '${secure ? "https" : "http"}://$HOST_NAME:${server.port}/'));
  conn.followRedirects = false;
  WebSocketClientConnection wsconn = new WebSocketClientConnection(conn);
  wsconn.onNoUpgrade = (response) {
    Expect.equals(HttpStatus.MOVED_PERMANENTLY, response.statusCode);
    client.shutdown();
    server.close();
    done.complete(null);
  };
  return done.future;
}


Future testUsePOST() {
  Completer done = new Completer();
  HttpServer server = secure ? new HttpsServer() : new HttpServer();
  HttpClient client = new HttpClient();

  server.listen(SERVER_ADDRESS,
                0,
                backlog: 5,
                certificate_name: "CN=$HOST_NAME");

  // Create a web socket handler and set is as the HTTP server default
  // handler.
  int closeCount = 0;
  WebSocketHandler wsHandler = new WebSocketHandler();
  wsHandler.onOpen = (WebSocketConnection conn) {
    Expect.fail("No connection expected");
  };
  server.defaultRequestHandler = wsHandler.onRequest;

  HttpClientConnection conn = client.postUrl(new Uri.fromString(
      '${secure ? "https" : "http"}://$HOST_NAME:${server.port}/'));
  WebSocketClientConnection wsconn = new WebSocketClientConnection(conn);
  wsconn.onNoUpgrade = (response) {
    Expect.equals(HttpStatus.BAD_REQUEST, response.statusCode);
    client.shutdown();
    server.close();
    done.complete(null);
  };
  return done.future;
}


class WebSocketInfo {
  int messageCount = 0;
}


Future testHashCode(int totalConnections) {
  Completer done = new Completer();
  HttpServer server = secure ? new HttpsServer() : new HttpServer();
  HttpClient client = new HttpClient();
  Map connections = new Map();

  server.listen(SERVER_ADDRESS,
                0,
                backlog: totalConnections,
                certificate_name: "CN=$HOST_NAME");

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
        done.complete();
      }
    };
    conn.send(messageText);
  };
  server.defaultRequestHandler = wsHandler.onRequest;

  for (int i = 0; i < totalConnections; i++) {
    HttpClientConnection conn = client.getUrl(new Uri.fromString(
        '${secure ? "https" : "http"}://$HOST_NAME:${server.port}/'));
    WebSocketClientConnection wsconn = new WebSocketClientConnection(conn);
    wsconn.onMessage = (message) => wsconn.send(message);
  }
  return done.future;
}


Future testW3CInterface(
    int totalConnections, int closeStatus, String closeReason) {
  List<Future> tasks = [];
  HttpServer server = secure ? new HttpsServer() : new HttpServer();

  server.listen(SERVER_ADDRESS,
                0,
                backlog: totalConnections,
                certificate_name: "CN=$HOST_NAME");

  // Create a web socket handler and set is as the HTTP server default
  // handler.
  int closeCount = 0;
  WebSocketHandler wsHandler = new WebSocketHandler();
  Completer serverDone = new Completer();
  tasks.add(serverDone.future);
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
      Expect.equals("", reason);
      closeCount++;
      if (closeCount == totalConnections) {
        server.close();
        serverDone.complete(null);
      }
    };
    conn.send(messageText);
  };
  server.defaultRequestHandler = wsHandler.onRequest;

  void webSocketConnection() {
    Completer clientDone = new Completer();
    tasks.add(clientDone.future);
    bool onopenCalled = false;
    int onmessageCalled = 0;
    bool oncloseCalled = false;

    var websocket =
        new WebSocket('${secure ? "wss" : "ws"}://$HOST_NAME:${server.port}');
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
      clientDone.complete(null);
    };
  }

  for (int i = 0; i < totalConnections; i++) {
    webSocketConnection();
  }
  return Future.wait(tasks);
}


void InitializeSSL() {
  var testPkcertDatabase =
      new Path(new Options().script).directoryPath.append("pkcert/");
  SecureSocket.initialize(database: testPkcertDatabase.toNativePath(),
                          password: "dartdart");
}


Future runTests() =>
  testRequestResponseClientCloses(2, null, null).then((_) =>
  testRequestResponseClientCloses(2, 3001, null)).then((_) =>
  testRequestResponseClientCloses(2, 3002, "Got tired")).then((_) =>
  testRequestResponseServerCloses(2, null, null)).then((_) =>
  testRequestResponseServerCloses(2, 3001, null)).then((_) =>
  testRequestResponseServerCloses(2, 3002, "Got tired")).then((_) =>
  testMessageLength(125)).then((_) =>
  testMessageLength(126)).then((_) =>
  testMessageLength(127)).then((_) =>
  testMessageLength(65535)).then((_) =>
  testMessageLength(65536)).then((_) =>
  testNoUpgrade()).then((_) =>
  testUsePOST()).then((_) =>
  testHashCode(2)).then((_) =>
  testW3CInterface(2, 3002, "Got tired"));


main() {
  ReceivePort keepAlive = new ReceivePort();
  runTests().then((_) {
    InitializeSSL();
    secure = true;
  }).then((_) =>
    runTests()).then((_) {
    keepAlive.close();
  });
}
