// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

class TestQueryParamAddingHttpClient implements HttpClient {
  Map<String, String> _queryParams;
  final _client = HttpClient();

  TestQueryParamAddingHttpClient(this._queryParams);

  set userAgent(String? agent) => _client.userAgent = agent;
  String? get userAgent => _client.userAgent;

  Future<HttpClientRequest> openUrl(String method, Uri url) {
    return _client.openUrl(method, url.replace(queryParameters: _queryParams));
  }

  void close({bool force = false}) => _client.close(force: force);

  dynamic noSuchMethod(Invocation invocation) {
    throw UnsupportedError(invocation.memberName.toString());
  }
}

Future<void> testZoneHttpClientUsedInWebSocket() async {
  final server = await HttpServer.bind("localhost", 0);
  String? recordedUserAgent;
  Map<String, String>? recordedQueryParameters;

  server.forEach((request) {
    recordedUserAgent = request.headers.value(HttpHeaders.userAgentHeader);
    recordedQueryParameters = request.uri.queryParameters;
    WebSocketTransformer.upgrade(request)
        .then((webSocket) => webSocket.close());
  });

  WebSocket.userAgent = 'Agent Smith';

  final client1 = TestQueryParamAddingHttpClient({"test": "1"});
  client1.userAgent = "ZoneAgent1";
  await HttpOverrides.runZoned(
    () async {
      final webSocket =
          await WebSocket.connect("ws://localhost:${server.port}");
      await webSocket.close();
    },
    createHttpClient: (c) => client1,
  );
  Expect.equals("Agent Smith", recordedUserAgent);
  Expect.mapEquals({"test": "1"}, recordedQueryParameters!);

  // The `HttpClient` used by `WebSocket` used to be static, so it is worth
  // testing that the value used in the first execution is not reused.
  final client2 = TestQueryParamAddingHttpClient({"test": "2"});
  WebSocket.userAgent = 'Agent X';
  client2.userAgent = "ZoneAgent2";
  await HttpOverrides.runZoned(
    () async {
      final webSocket =
          await WebSocket.connect("ws://localhost:${server.port}");
      await webSocket.close();
    },
    createHttpClient: (c) => client2,
  );
  Expect.equals("Agent X", recordedUserAgent);
  Expect.mapEquals({"test": "2"}, recordedQueryParameters!);

  client1.close();
  client2.close();
  server.close();
}

main() async {
  asyncStart();
  await testZoneHttpClientUsedInWebSocket();
  asyncEnd();
}
