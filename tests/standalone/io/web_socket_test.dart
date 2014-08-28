// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

import "dart:async";
import "dart:io";
import "dart:typed_data";

import "package:async_helper/async_helper.dart";
import "package:crypto/crypto.dart";
import "package:expect/expect.dart";
import "package:path/path.dart";

const WEB_SOCKET_GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";

const String CERT_NAME = 'localhost_cert';
const String HOST_NAME = 'localhost';

/**
 * A SecurityConfiguration lets us run the tests over HTTP or HTTPS.
 */
class SecurityConfiguration {
  final bool secure;

  SecurityConfiguration({bool this.secure});

  Future<HttpServer> createServer({int backlog: 0}) =>
      secure ? HttpServer.bindSecure(HOST_NAME,
                                     0,
                                     backlog: backlog,
                                     certificateName: CERT_NAME)
             : HttpServer.bind(HOST_NAME,
                               0,
                               backlog: backlog);

  Future<WebSocket> createClient(int port) =>
    WebSocket.connect('${secure ? "wss" : "ws"}://$HOST_NAME:$port/');

  void testRequestResponseClientCloses(int totalConnections,
                                       int closeStatus,
                                       String closeReason,
                                       int numberOfMessages) {
    assert (numberOfMessages >= 1);

    asyncStart();
    createServer().then((server) {
      server.transform(new WebSocketTransformer()).listen((webSocket) {
        asyncStart();
        webSocket.listen(
            webSocket.add,
            onDone: () {
              Expect.equals(closeStatus == null
                            ? WebSocketStatus.NO_STATUS_RECEIVED
                            : closeStatus, webSocket.closeCode);
              Expect.equals(
                  closeReason == null ? ""
                                      : closeReason, webSocket.closeReason);
              asyncEnd();
            });
        }, onDone: () {
          asyncEnd();
        });

      int closeCount = 0;
      String messageText = "Hello, world!";
      for (int i = 0; i < totalConnections; i++) {
        asyncStart();
        createClient(server.port).then((webSocket) {
          webSocket.add(messageText);
          webSocket.listen(
              (message) {
                numberOfMessages--;
                Expect.equals(messageText, message);

                if (numberOfMessages > 0) {
                  webSocket.add(message);
                } else {
                  webSocket.close(closeStatus, closeReason);
                }
              },
              onDone: () {
                Expect.equals(closeStatus == null
                              ? WebSocketStatus.NO_STATUS_RECEIVED
                              : closeStatus, webSocket.closeCode);
                Expect.equals("", webSocket.closeReason);
                closeCount++;
                if (closeCount == totalConnections) {
                  server.close();
                }
                asyncEnd();
              });
          });
      }
    });
  }

  void testRequestResponseServerCloses(int totalConnections,
                                       int closeStatus,
                                       String closeReason) {
    createServer().then((server) {
      int closeCount = 0;
      server.transform(new WebSocketTransformer()).listen((webSocket) {
        String messageText = "Hello, world!";
        int messageCount = 0;
        webSocket.listen(
            (message) {
              messageCount++;
              if (messageCount < 10) {
                Expect.equals(messageText, message);
                webSocket.add(message);
              } else {
                webSocket.close(closeStatus, closeReason);
              }
            },
            onDone: () {
              Expect.equals(closeStatus == null
                            ? WebSocketStatus.NO_STATUS_RECEIVED
                            : closeStatus, webSocket.closeCode);
              Expect.equals("", webSocket.closeReason);
              closeCount++;
              if (closeCount == totalConnections) {
                server.close();
              }
            });
        webSocket.add(messageText);
      });

      for (int i = 0; i < totalConnections; i++) {
        createClient(server.port).then((webSocket) {
            webSocket.listen(
                webSocket.add,
                onDone: () {
                  Expect.equals(closeStatus == null
                                ? WebSocketStatus.NO_STATUS_RECEIVED
                                : closeStatus, webSocket.closeCode);
                  Expect.equals(closeReason == null
                                ? ""
                                : closeReason, webSocket.closeReason);
                });
            });
      }
    });
  }


  void testMessageLength(int messageLength) {
    createServer().then((server) {
      Uint8List originalMessage = new Uint8List(messageLength);
      server.transform(new WebSocketTransformer()).listen((webSocket) {
        webSocket.listen(
            (message) {
              Expect.listEquals(originalMessage, message);
              webSocket.add(message);
            });
      });

      createClient(server.port).then((webSocket) {
        webSocket.listen(
            (message) {
              Expect.listEquals(originalMessage, message);
              webSocket.close();
            },
            onDone: server.close);
        webSocket.add(originalMessage);
      });
    });
  }


  void testDoubleCloseClient() {
    createServer().then((server) {
      server.transform(new WebSocketTransformer()).listen((webSocket) {
        server.close();
        webSocket.listen((_) { }, onDone: webSocket.close);
      });

      createClient(server.port).then((webSocket) {
          webSocket.listen((_) { }, onDone: webSocket.close);
          webSocket.close();
        });
    });
  }


  void testDoubleCloseServer() {
    createServer().then((server) {
      server.transform(new WebSocketTransformer()).listen((webSocket) {
        server.close();
        webSocket.listen((_) { }, onDone: webSocket.close);
        webSocket.close();
      });

      createClient(server.port).then((webSocket) {
          webSocket.listen((_) { }, onDone: webSocket.close);
        });
    });
  }


  void testImmediateCloseServer() {
    createServer().then((server) {
      server.listen((request) {
        WebSocketTransformer.upgrade(request)
            .then((webSocket) {
              webSocket.close();
              webSocket.listen(
                  (_) { Expect.fail("Unexpected message"); },
                  onDone: server.close);
            });
      });

      createClient(server.port).then((webSocket) {
          webSocket.listen(
              (_) { Expect.fail("Unexpected message"); },
              onDone: webSocket.close);
        });
    });
  }


  void testImmediateCloseClient() {
    createServer().then((server) {
      server.listen((request) {
        WebSocketTransformer.upgrade(request)
            .then((webSocket) {
              webSocket.listen(
                  (_) { Expect.fail("Unexpected message"); },
                  onDone: () {
                server.close();
                webSocket.close();
              });
            });
      });

      createClient(server.port).then((webSocket) {
          webSocket.close();
          webSocket.listen(
              (_) { Expect.fail("Unexpected message"); },
              onDone: webSocket.close);
        });
    });
  }


  void testNoUpgrade() {
    createServer().then((server) {
      // Create a server which always responds with NOT_FOUND.
      server.listen((request) {
        request.response.statusCode = HttpStatus.NOT_FOUND;
        request.response.close();
      });

      createClient(server.port).catchError((error) {
        server.close();
      });
    });
  }


  void testUsePOST() {
    asyncStart();
    createServer().then((server) {
      server.transform(new WebSocketTransformer()).listen((webSocket) {
        Expect.fail("No connection expected");
      }, onError: (e) {
        asyncEnd();
      });

      HttpClient client = new HttpClient();
      client.postUrl(Uri.parse(
          "${secure ? 'https:' : 'http:'}//$HOST_NAME:${server.port}/"))
        .then((request) => request.close())
        .then((response) {
          Expect.equals(HttpStatus.BAD_REQUEST, response.statusCode);
          client.close();
          server.close();
        });
    });
  }

  void testConnections(int totalConnections,
                       int closeStatus,
                       String closeReason) {
    createServer().then((server) {
      int closeCount = 0;
      server.transform(new WebSocketTransformer()).listen((webSocket) {
        String messageText = "Hello, world!";
        int messageCount = 0;
        webSocket.listen(
            (message) {
              messageCount++;
              if (messageCount < 10) {
                Expect.equals(messageText, message);
                webSocket.add(message);
              } else {
                webSocket.close(closeStatus, closeReason);
              }
            },
            onDone: () {
              Expect.equals(closeStatus, webSocket.closeCode);
              Expect.equals("", webSocket.closeReason);
              closeCount++;
              if (closeCount == totalConnections) {
                server.close();
              }
            });
        webSocket.add(messageText);
      });

      void webSocketConnection() {
        bool onopenCalled = false;
        int onmessageCalled = 0;
        bool oncloseCalled = false;

        createClient(server.port).then((webSocket) {
          Expect.isFalse(onopenCalled);
          Expect.equals(0, onmessageCalled);
          Expect.isFalse(oncloseCalled);
          onopenCalled = true;
          Expect.equals(WebSocket.OPEN, webSocket.readyState);
          webSocket.listen(
              (message) {
                onmessageCalled++;
                Expect.isTrue(onopenCalled);
                Expect.isFalse(oncloseCalled);
                Expect.equals(WebSocket.OPEN, webSocket.readyState);
                webSocket.add(message);
              },
              onDone: () {
                Expect.isTrue(onopenCalled);
                Expect.equals(10, onmessageCalled);
                Expect.isFalse(oncloseCalled);
                oncloseCalled = true;
                Expect.equals(3002, webSocket.closeCode);
                Expect.equals("Got tired", webSocket.closeReason);
                Expect.equals(WebSocket.CLOSED, webSocket.readyState);
              });
        });
      }

      for (int i = 0; i < totalConnections; i++) {
        webSocketConnection();
      }
    });
  }

  testIndividualUpgrade(int connections) {
    createServer().then((server) {
      server.listen((request) {
          if (WebSocketTransformer.isUpgradeRequest(request)) {
            WebSocketTransformer.upgrade(request).then((webSocket) {
                webSocket.listen((_) { webSocket.close(); });
                webSocket.add("Hello");
            });
          } else {
            Expect.isFalse(WebSocketTransformer.isUpgradeRequest(request));
            request.response.statusCode = HttpStatus.OK;
            request.response.close();
          }
      });

      var futures = [];

      var wsProtocol = '${secure ? "wss" : "ws"}';
      var baseWsUrl = '$wsProtocol://$HOST_NAME:${server.port}/';
      var httpProtocol = '${secure ? "https" : "http"}';
      var baseHttpUrl = '$httpProtocol://$HOST_NAME:${server.port}/';
      HttpClient client = new HttpClient();

      for (int i = 0; i < connections; i++) {
        var completer = new Completer();
        futures.add(completer.future);
        WebSocket.connect('${baseWsUrl}')
            .then((websocket) {
                websocket.listen((_) { websocket.close(); },
                               onDone: completer.complete);
            });

        futures.add(client.openUrl("GET", Uri.parse('${baseHttpUrl}'))
             .then((request) => request.close())
             .then((response) {
               response.listen((_) { });
               Expect.equals(HttpStatus.OK, response.statusCode);
               }));
      }

      Future.wait(futures).then((_) {
        server.close();
        client.close();
      });
    });
  }

  testFromUpgradedSocket() {
    asyncStart();
    createServer().then((server) {
      server.listen((request) {
        Expect.equals('Upgrade', request.headers.value(HttpHeaders.CONNECTION));
        Expect.equals('websocket', request.headers.value(HttpHeaders.UPGRADE));

        var key = request.headers.value('Sec-WebSocket-Key');
        var sha1 = new SHA1()..add("$key$WEB_SOCKET_GUID".codeUnits);
        var accept = CryptoUtils.bytesToBase64(sha1.close());
        request.response
            ..statusCode = HttpStatus.SWITCHING_PROTOCOLS
            ..headers.add(HttpHeaders.CONNECTION, "Upgrade")
            ..headers.add(HttpHeaders.UPGRADE, "websocket")
            ..headers.add("Sec-WebSocket-Accept", accept);
        request.response.contentLength = 0;
        request.response.detachSocket().then((socket) {
          return new WebSocket.fromUpgradedSocket(socket, serverSide: true);
        }).then((websocket) {
          websocket.add("Hello");
          websocket.close();
          asyncEnd();
        });
      });

      var url = '${secure ? "wss" : "ws"}://$HOST_NAME:${server.port}/';

      WebSocket.connect(url).then((websocket) {
        return websocket.listen((message) {
          Expect.equals("Hello", message);
          websocket.close();
        }).asFuture();
      }).then((_) => server.close());
    });
  }

  void runTests() {
    testRequestResponseClientCloses(2, null, null, 1);
    testRequestResponseClientCloses(2, 3001, null, 2);
    testRequestResponseClientCloses(2, 3002, "Got tired", 3);
    testRequestResponseServerCloses(2, null, null);
    testRequestResponseServerCloses(2, 3001, null);
    testRequestResponseServerCloses(2, 3002, "Got tired");
    testMessageLength(125);
    testMessageLength(126);
    testMessageLength(127);
    testMessageLength(65535);
    testMessageLength(65536);
    testDoubleCloseClient();
    testDoubleCloseServer();
    testImmediateCloseServer();
    testImmediateCloseClient();
    testNoUpgrade();
    testUsePOST();
    testConnections(10, 3002, "Got tired");
    testIndividualUpgrade(5);
    testFromUpgradedSocket();
  }
}


void initializeSSL() {
  var testPkcertDatabase = Platform.script.resolve('pkcert').toFilePath();
  SecureSocket.initialize(database: testPkcertDatabase,
                          password: "dartdart");
}


main() {
  new SecurityConfiguration(secure: false).runTests();
  initializeSSL();
  new SecurityConfiguration(secure: true).runTests();
}
