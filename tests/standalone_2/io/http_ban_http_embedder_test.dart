// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=-Ddart.library.io.allow_http=false

import 'dart:async';
import 'dart:io';

import "package:async_helper/async_helper.dart";

Future<void> testWithHostname() async {
  final httpClient = new HttpClient();
  final server = await HttpServer.bind(Platform.localHostname, 0);
  final httpUri =
      Uri(scheme: 'http', host: Platform.localHostname, port: server.port);

  asyncExpectThrows(
      () async => await httpClient.getUrl(httpUri), (e) => e is StateError);
  asyncExpectThrows(
      () async => await runZoned(() => httpClient.getUrl(httpUri),
          zoneValues: {#dart.library.io.allow_http: 'foo'}),
      (e) => e is StateError);
  asyncExpectThrows(
      () async => await runZoned(() => httpClient.getUrl(httpUri),
          zoneValues: {#dart.library.io.allow_http: false}),
      (e) => e is StateError);
  await asyncTest(() => runZoned(() => httpClient.getUrl(httpUri),
      zoneValues: {#dart.library.io.allow_http: true}));
  await server.close();
}

Future<void> testWithLoopback() async {
  final httpClient = new HttpClient();
  final server = await HttpServer.bind("127.0.0.1", 0);
  await asyncTest(
      () => httpClient.getUrl(Uri.parse('http://localhost:${server.port}')));
  await asyncTest(
      () => httpClient.getUrl(Uri.parse('http://127.0.0.1:${server.port}')));
  await server.close();
}

Future<void> testWithIPv6() async {
  final httpClient = new HttpClient();
  HttpServer server;
  try {
    server = await HttpServer.bind("::1", 0);
  } catch (e) {
    // Ignore, IPv6 not supported.
    return;
  }
  await asyncTest(
      () => httpClient.getUrl(Uri.parse('http://[::1]:${server.port}')));
  await server.close();
}

Future<void> testWithHTTPS() async {
  final httpClient = new HttpClient();
  final server = await HttpServer.bind(Platform.localHostname, 0);
  // Terminate connection upon handshake causing a SocketException or
  // HandshakeException
  server.listen((request) {
    request.listen((_) {}, onDone: () {
      request.response.close();
    });
  });
  asyncExpectThrows(
      () => httpClient.getUrl(Uri(
            scheme: 'https',
            host: Platform.localHostname,
            port: server.port,
          )),
      (e) => e is SocketException || e is HandshakeException);
  await server.close();
}

main() {
  asyncStart();
  Future.wait(<Future>[
    testWithHostname(),
    testWithLoopback(),
    testWithIPv6(),
    testWithHTTPS(),
  ]).then((_) => asyncEnd());
}
