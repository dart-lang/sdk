// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

import "package:expect/expect.dart";

import "dart:async";
import "dart:io";

testEmptyProtocol() {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((request) {
      WebSocketTransformer.upgrade(request).then((websocket) {
        websocket.close();
      });
    });
    WebSocket.connect("ws://127.0.0.1:${server.port}/", protocols: []).then((
      client,
    ) {
      Expect.isNull(client.protocol);
      client.close();
      server.close();
    });
  });
}

testProtocol(List<String> protocols, String used) {
  selector(List<String> receivedProtocols) {
    Expect.listEquals(protocols, receivedProtocols);
    return used;
  }

  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((request) {
      WebSocketTransformer.upgrade(request, protocolSelector: selector).then((
        websocket,
      ) {
        Expect.equals(used, websocket.protocol);
        websocket.close();
      });
    });
    WebSocket.connect(
      "ws://127.0.0.1:${server.port}/",
      protocols: protocols,
    ).then((client) {
      Expect.equals(used, client.protocol);
      client.close();
      server.close();
    });
  });
}

testProtocolHandler() {
  // Test throwing an error.
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((request) {
      selector(List<String> receivedProtocols) {
        throw "error";
      }

      WebSocketTransformer.upgrade(request, protocolSelector: selector).then(
        (websocket) {
          Expect.fail('error expected');
        },
        onError: (error) {
          Expect.equals('error', error);
        },
      );
    });
    WebSocket.connect(
      "ws://127.0.0.1:${server.port}/",
      protocols: ["v1.example.com"],
    ).then(
      (client) {
        Expect.fail('error expected');
      },
      onError: (error) {
        server.close();
      },
    );
  });

  // Test returning another protocol.
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((request) {
      selector(List<String> receivedProtocols) => "v2.example.com";
      WebSocketTransformer.upgrade(request, protocolSelector: selector).then(
        (websocket) {
          Expect.fail('error expected');
        },
        onError: (error) {
          Expect.isTrue(error is WebSocketException);
        },
      );
    });
    WebSocket.connect(
      "ws://127.0.0.1:${server.port}/",
      protocols: ["v1.example.com"],
    ).then(
      (client) {
        Expect.fail('error expected');
      },
      onError: (error) {
        server.close();
      },
    );
  });
}

Future<void> testBadUpgradeResponse() async {
  for (final response in [
    "HTTP/1.1 101 Switching Protocols\r\n"
        "Connection: Upgrade\r\n\r\n",
    "HTTP/1.1 101 Switching Protocols\r\n"
        "Connection: Upgrade\r\n"
        "Upgrade: websocket\r\n"
        "Upgrade: websocket\r\n\r\n",
    "HTTP/1.1 101 Switching Protocols\r\n"
        "Connection: Upgrade\r\n"
        "Upgrade: websocket\r\n"
        "Sec-WebSocket-Accept: !!!not-base64!!!\r\n\r\n",
    "HTTP/1.1 101 Switching Protocols\r\n"
        "Connection: Upgrade\r\n"
        "Upgrade: websocket\r\n"
        "Sec-WebSocket-Accept: aGVsbG8=\r\n"
        "Sec-WebSocket-Accept: aGVsbG8=\r\n\r\n",
  ]) {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final accepted = <Socket>[];
    server.listen((socket) {
      accepted.add(socket);
      final request = StringBuffer();
      var sent = false;
      socket.listen((chunk) {
        request.write(String.fromCharCodes(chunk));
        if (!sent && request.toString().contains("\r\n\r\n")) {
          sent = true;
          socket.add(response.codeUnits);
        }
      });
    });
    final client = HttpClient();
    try {
      await WebSocket.connect(
        "ws://127.0.0.1:${server.port}/",
        customClient: client,
      );
      Expect.fail("Connected despite malformed upgrade response");
    } on WebSocketException {
      // Expected.
    } finally {
      client.close(force: true);
      for (final socket in accepted) {
        socket.destroy();
      }
      await server.close();
    }
  }
}

void main() async {
  testEmptyProtocol();
  testProtocol(["v1.example.com", "v2.example.com"], "v1.example.com");
  testProtocol(["v1.example.com", "v2.example.com"], "v2.example.com");
  testProtocolHandler();
  await testBadUpgradeResponse();
}
