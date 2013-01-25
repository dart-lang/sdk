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


class WebSocketInfo {
  int messageCount = 0;
}


/**
 * A SecurityConfiguration lets us run the tests over HTTP or HTTPS.
 */
class SecurityConfiguration {
  final bool secure;
  HttpClient client;

  SecurityConfiguration({bool this.secure}) : client = new HttpClient();

  HttpServer createServer({int backlog}) {
    HttpServer server = secure ? new HttpsServer() : new HttpServer();
    server.listen(SERVER_ADDRESS,
                  0,
                  backlog: backlog,
                  certificate_name: "CN=$HOST_NAME");
    return server;
  }

  WebSocketClientConnection createClient(int port,
                                         {bool followRedirects,
                                          String method: "GET"}) {
    HttpClientConnection conn = client.openUrl(method, Uri.parse(
        '${secure ? "https" : "http"}://$HOST_NAME:$port/'));
    if (followRedirects != null) {
      conn.followRedirects = followRedirects;
    }
    return new WebSocketClientConnection(conn);
  }

  void testRequestResponseClientCloses(
      int totalConnections, int closeStatus, String closeReason) {
    HttpServer server = createServer(backlog: totalConnections);
    HttpClient client = new HttpClient();

    // Make a web socket handler and set it as the HTTP server default handler.
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
      WebSocketClientConnection wsconn = createClient(server.port);
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
        }
      };
    }
  }


  void testRequestResponseServerCloses(
      int totalConnections, int closeStatus, String closeReason) {
    ReceivePort keepAlive = new ReceivePort();
    HttpServer server = createServer(backlog: totalConnections);

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
          keepAlive.close();
      }
      };
      conn.send(messageText);
    };
    server.defaultRequestHandler = wsHandler.onRequest;

    for (int i = 0; i < totalConnections; i++) {
      WebSocketClientConnection wsconn = createClient(server.port);
      wsconn.onMessage = (message) => wsconn.send(message);
      wsconn.onClosed = (status, reason) {
        Expect.equals(closeStatus == null
                      ? WebSocketStatus.NO_STATUS_RECEIVED
                      : closeStatus, status);
        Expect.equals(closeReason == null ? "" : closeReason, reason);
      };
    }
  }


  void testMessageLength(int messageLength) {
    HttpServer server = createServer(backlog: 1);
    bool serverReceivedMessage = false;
    bool clientReceivedMessage = false;

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

    WebSocketClientConnection wsconn = createClient(server.port);
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
    };
    wsconn.onOpen = () {
      wsconn.send(originalMessage);
    };
  }


  void testNoUpgrade() {
    HttpServer server = createServer(backlog: 5);

    // Create a server which always responds with a redirect.
    server.defaultRequestHandler = (request, response) {
      response.statusCode = HttpStatus.MOVED_PERMANENTLY;
      response.outputStream.close();
    };

    WebSocketClientConnection wsconn = createClient(server.port,
                                                    followRedirects: false);
    wsconn.onNoUpgrade = (response) {
      Expect.equals(HttpStatus.MOVED_PERMANENTLY, response.statusCode);
      client.shutdown();
      server.close();
    };
  }


  void testUsePOST() {
    HttpServer server = createServer(backlog: 5);

    // Create a web socket handler and set is as the HTTP server default
    // handler.
    int closeCount = 0;
    WebSocketHandler wsHandler = new WebSocketHandler();
    wsHandler.onOpen = (WebSocketConnection conn) {
      Expect.fail("No connection expected");
    };
    server.defaultRequestHandler = wsHandler.onRequest;

    WebSocketClientConnection wsconn = createClient(server.port,
                                                    method: "POST");
    wsconn.onNoUpgrade = (response) {
      Expect.equals(HttpStatus.BAD_REQUEST, response.statusCode);
      client.shutdown();
      server.close();
    };
  }


  void testHashCode(int totalConnections) {
    ReceivePort keepAlive = new ReceivePort();
    HttpServer server = createServer(backlog: totalConnections);
    Map connections = new Map();

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
          keepAlive.close();
        }
      };
      conn.send(messageText);
    };
    server.defaultRequestHandler = wsHandler.onRequest;

    for (int i = 0; i < totalConnections; i++) {
      WebSocketClientConnection wsconn = createClient(server.port);
      wsconn.onMessage = (message) => wsconn.send(message);
    }
  }


  void testW3CInterface(
      int totalConnections, int closeStatus, String closeReason) {
    HttpServer server = createServer(backlog: totalConnections);

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
        Expect.equals("", reason);
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
      };
    }

    for (int i = 0; i < totalConnections; i++) {
      webSocketConnection();
    }
  }


  runTests() {
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
}


void initializeSSL() {
  var testPkcertDatabase =
      new Path(new Options().script).directoryPath.append("pkcert/");
  SecureSocket.initialize(database: testPkcertDatabase.toNativePath(),
                          password: "dartdart");
}


main() {
  new SecurityConfiguration(secure: false).runTests();
  initializeSSL();
  new SecurityConfiguration(secure: true).runTests();
}
