// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analysis_server/src/server/http_server.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../analysis_server_base.dart';
import '../status/test_socket_server.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(HttpAnalysisServerTest);
  });
}

@reflectiveTest
class HttpAnalysisServerTest extends PubPackageAnalysisServerTest {
  late HttpAnalysisServer httpServer;
  late Uri serverUri;
  late HttpClient client;

  @override
  void setUp() {
    super.setUp();
    httpServer = HttpAnalysisServer(TestSocketServer(server));
    client = HttpClient();
  }

  @override
  Future<void> tearDown() async {
    client.close(force: true);
    httpServer.close();
    await super.tearDown();
  }

  Future<void> test_get_allowsLoopbackHostAndOrigin() async {
    await _startServer();

    var request = await client.getUrl(serverUri.resolve('/status'));
    request.headers.set(HttpHeaders.hostHeader, 'localhost');
    request.headers.set('Origin', 'http://localhost');
    var response = await request.close();
    expect(response.statusCode, HttpStatus.ok);
    await response.drain<void>();
  }

  Future<void> test_get_allowsMatchingHost() async {
    await _startServer();

    var request = await client.getUrl(serverUri.resolve('/status'));
    var response = await request.close();
    expect(response.statusCode, HttpStatus.ok);
    await response.drain<void>();
  }

  Future<void> test_get_forbidsInvalidHost() async {
    await _startServer();

    var request = await client.getUrl(serverUri.resolve('/status'));
    request.headers.set(
      HttpHeaders.hostHeader,
      'evil.example.com:${serverUri.port}',
    );
    var response = await request.close();
    expect(response.statusCode, HttpStatus.forbidden);
    await response.drain<void>();
  }

  Future<void> test_get_forbidsInvalidOrigin() async {
    await _startServer();

    var request = await client.getUrl(serverUri.resolve('/status'));
    request.headers.set('Origin', 'http://evil.example.com');
    var response = await request.close();
    expect(response.statusCode, HttpStatus.forbidden);
    await response.drain<void>();
  }

  Future<void> test_post_allowsValidOrigin() async {
    await _startServer();

    var request =
        await client.postUrl(
            serverUri.resolve('/session-log?capture-entries=true'),
          )
          ..followRedirects = false
          ..headers.set('Origin', serverUri.origin);
    var response = await request.close();
    expect(response.statusCode, HttpStatus.movedTemporarily);
    await response.drain<void>();
  }

  Future<void> test_post_forbidsInvalidHost() async {
    await _startServer();

    var request =
        await client.postUrl(
            serverUri.resolve('/session-log?capture-entries=true'),
          )
          ..followRedirects = false
          ..headers.set(HttpHeaders.hostHeader, 'evil.example.com');
    var response = await request.close();
    expect(response.statusCode, HttpStatus.forbidden);
    await response.drain<void>();
  }

  Future<void> test_post_forbidsInvalidOrigin() async {
    await _startServer();

    var request =
        await client.postUrl(
            serverUri.resolve('/session-log?capture-entries=true'),
          )
          ..followRedirects = false
          ..headers.set('Origin', 'http://evil.example.com');
    var response = await request.close();
    expect(response.statusCode, HttpStatus.forbidden);
    await response.drain<void>();
  }

  Future<void> test_post_forbidsNullOrigin() async {
    await _startServer();

    var request =
        await client.postUrl(
            serverUri.resolve('/session-log?capture-entries=true'),
          )
          ..followRedirects = false
          ..headers.set('Origin', 'null');
    var response = await request.close();
    expect(response.statusCode, HttpStatus.forbidden);
    await response.drain<void>();
  }

  Future<void> test_webSocket_allowsLoopbackOrigin() async {
    await _startServer();

    var wsUri = serverUri
        .replace(scheme: 'ws', path: '/analysis-performance-log')
        .toString();
    var ws = await WebSocket.connect(
      wsUri,
      headers: {'Origin': 'http://localhost:${serverUri.port}'},
    );
    await ws.close();
  }

  Future<void> test_webSocket_forbidsInvalidHost() async {
    await _startServer();

    var wsUri = serverUri
        .replace(scheme: 'ws', path: '/analysis-performance-log')
        .toString();
    await expectLater(
      WebSocket.connect(
        wsUri,
        headers: {
          HttpHeaders.hostHeader: 'evil.example.com:${serverUri.port}',
          'Origin': 'http://evil.example.com:${serverUri.port}',
        },
      ),
      throwsA(isA<WebSocketException>()),
    );
  }

  Future<void> test_webSocket_forbidsInvalidOrigin() async {
    await _startServer();

    var wsUri = serverUri
        .replace(scheme: 'ws', path: '/analysis-performance-log')
        .toString();
    await expectLater(
      WebSocket.connect(wsUri, headers: {'Origin': 'http://evil.example.com'}),
      throwsA(isA<WebSocketException>()),
    );
  }

  Future<void> _startServer() async {
    var port = (await httpServer.serveHttp())!;
    serverUri = Uri.parse('http://127.0.0.1:$port');
  }
}
