// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

import "dart:async";
import "dart:convert";
import "dart:io";
import "dart:typed_data";
import "dart:math";

import "package:async_helper/async_helper.dart";
import "package:crypto/crypto.dart";
import "package:expect/expect.dart";
import "package:path/path.dart";

const WEB_SOCKET_GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";

const String HOST_NAME = 'localhost';

String localFile(path) => Platform.script.resolve(path).toFilePath();

SecurityContext serverContext = new SecurityContext()
  ..useCertificateChain(localFile('certificates/server_chain.pem'))
  ..usePrivateKey(localFile('certificates/server_key.pem'),
                  password: 'dartdart');

class SecurityConfiguration {
  final bool secure;

  SecurityConfiguration({bool this.secure});

  Future<HttpServer> createServer({int backlog: 0}) =>
      secure ? HttpServer.bindSecure(HOST_NAME,
          0,
          serverContext,
          backlog: backlog)
          : HttpServer.bind(HOST_NAME,
          0,
          backlog: backlog);

  Future<WebSocket> createClient(int port) =>
      // TODO(whesse): Add client context argument to WebSocket.connect
      WebSocket.connect('${secure ? "wss" : "ws"}://$HOST_NAME:$port/');

  Future<HttpClientResponse> createWebsocket(String url, String headerValue) {
    HttpClient _httpClient = new HttpClient();
    Uri uri = Uri.parse(url);

    Random random = new Random();
    // Generate 16 random bytes.
    Uint8List nonceData = new Uint8List(16);
    for (int i = 0; i < 16; i++) {
      nonceData[i] = random.nextInt(256);
    }
    String nonce = CryptoUtils.bytesToBase64(nonceData);

    uri = new Uri(
        scheme: uri.scheme == "wss" ? "https" : "http",
        userInfo: uri.userInfo,
        host: uri.host,
        port: uri.port,
        path: uri.path,
        query: uri.query,
        fragment: uri.fragment);
    return _httpClient.openUrl("GET", uri).then((request) {
      if (uri.userInfo != null && !uri.userInfo.isEmpty) {
        // If the URL contains user information use that for basic
        // authorization.
        String auth = CryptoUtils.bytesToBase64(UTF8.encode(uri.userInfo));
        request.headers.set(HttpHeaders.AUTHORIZATION, "Basic $auth");
      }
      // Setup the initial handshake.
      request.headers
        ..set(HttpHeaders.CONNECTION, "Upgrade")
        ..set(HttpHeaders.UPGRADE, "websocket")
        ..set("Sec-WebSocket-Key", nonce)
        ..set("Cache-Control", "no-cache")
        ..set("Sec-WebSocket-Version", "13")
        ..set("Sec-WebSocket-Extensions", headerValue);

      return request.close();
    });
  }

  void testCompressionSupport({server: false,
        client: false,
        contextTakeover: false}) {
    asyncStart();

    var clientOptions = new CompressionOptions(
        enabled: client,
        serverNoContextTakeover: contextTakeover,
        clientNoContextTakeover: contextTakeover);
    var serverOptions = new CompressionOptions(
        enabled: server,
        serverNoContextTakeover: contextTakeover,
        clientNoContextTakeover: contextTakeover);

    createServer().then((server) {
      server.listen((request) {
        Expect.isTrue(WebSocketTransformer.isUpgradeRequest(request));
        WebSocketTransformer.upgrade(request, compression: serverOptions)
                            .then((webSocket) {
            webSocket.listen((message) {
              Expect.equals("Hello World", message);

              webSocket.add(message);
              webSocket.close();
            });
            webSocket.add("Hello World");
        });
      });

      var url = '${secure ? "wss" : "ws"}://$HOST_NAME:${server.port}/';
      WebSocket.connect(url, compression: clientOptions).then((websocket) {
        var future = websocket.listen((message) {
          Expect.equals("Hello World", message);
        }).asFuture();
        websocket.add("Hello World");
        return future;
      }).then((_) {
        server.close();
        asyncEnd();
      });
    });
  }

  void testCompressionHeaders() {
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
            ..headers.add("Sec-WebSocket-Accept", accept)
            ..headers.add("Sec-WebSocket-Extensions",
              "permessage-deflate;"
              // Test quoted values and space padded =
              'server_max_window_bits="10"; client_max_window_bits = 12'
              'client_no_context_takeover; server_no_context_takeover');
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

  void testReturnHeaders(String headerValue, String expected) {
    asyncStart();
    createServer().then((server) {
      server.listen((request) {
        // Stuff
        Expect.isTrue(WebSocketTransformer.isUpgradeRequest(request));
        WebSocketTransformer.upgrade(request).then((webSocket) {
            webSocket.listen((message) {
              Expect.equals("Hello World", message);

              webSocket.add(message);
              webSocket.close();
            });
        });
      });

      var url = '${secure ? "wss" : "ws"}://$HOST_NAME:${server.port}/';
      createWebsocket(url, headerValue)
        .then((HttpClientResponse response) {
          Expect.equals(response.statusCode, HttpStatus.SWITCHING_PROTOCOLS);
          print(response.headers.value('Sec-WebSocket-Extensions'));
          Expect.equals(response.headers.value("Sec-WebSocket-Extensions"),
            expected);

          String accept = response.headers.value("Sec-WebSocket-Accept");
          Expect.isNotNull(accept);

          var protocol = response.headers.value('Sec-WebSocket-Protocol');
          return response.detachSocket().then((socket) =>
              new WebSocket.fromUpgradedSocket(
                  socket, protocol: protocol, serverSide: false));
        }).then((websocket) {
          var future = websocket.listen((message) {
            Expect.equals("Hello", message);
            websocket.close();
          }).asFuture();
          websocket.add("Hello World");
          return future;
        }).then((_) {
          server.close();
          asyncEnd();
        });
    }); // End createServer
  }

  void runTests() {
    // No compression or takeover
    testCompressionSupport();
    // compression no takeover
    testCompressionSupport(server: true, client: true);
    // compression and context takeover.
    testCompressionSupport(server: true, client: true, contextTakeover: true);
    // Compression on client but not server. No take over
    testCompressionSupport(client: true);
    // Compression on server but not client.
    testCompressionSupport(server: true);

    testCompressionHeaders();
    // Chrome headers
    testReturnHeaders('permessage-deflate; client_max_window_bits',
                      "permessage-deflate; client_max_window_bits=15");
    // Firefox headers
    testReturnHeaders('permessage-deflate',
                      "permessage-deflate; client_max_window_bits=15");
    // Ensure max_window_bits resize appropriately.
    testReturnHeaders('permessage-deflate; server_max_window_bits=10',
                      "permessage-deflate;" 
                      " server_max_window_bits=10;"
                      " client_max_window_bits=10");
  }
}

main() {
  new SecurityConfiguration(secure: false).runTests();
  // TODO(whesse): Make WebSocket.connect() take an optional context: parameter.
  // new SecurityConfiguration(secure: true).runTests();
}
