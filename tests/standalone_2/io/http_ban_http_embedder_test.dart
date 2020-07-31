// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=-Ddart.library.io.allow_http=false

import 'dart:async';
import 'dart:io';

import "package:async_helper/async_helper.dart";

import 'http_ban_http_normal_test.dart';
import 'http_bind_test.dart';

Future<void> testWithHostname() async {
  await testBanHttp(await getLocalHostIP(), (httpClient, httpUri) async {
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
  });
}

Future<void> testWithLoopback() async {
  await testBanHttp("127.0.0.1", (httpClient, uri) async {
    await asyncTest(
        () => httpClient.getUrl(Uri.parse('http://localhost:${uri.port}')));
    await asyncTest(
        () => httpClient.getUrl(Uri.parse('http://127.0.0.1:${uri.port}')));
  });
}

Future<void> testWithIPv6() async {
  if (await supportsIPV6()) {
    await testBanHttp("::1", (httpClient, uri) async {
      await asyncTest(() => httpClient.getUrl(uri));
    });
  }
}

Future<void> testWithHTTPS() async {
  await testBanHttp(await getLocalHostIP(), (httpClient, uri) async {
    asyncExpectThrows(
        () => httpClient.getUrl(Uri(
              scheme: 'https',
              host: uri.host,
              port: uri.port,
            )),
        (e) => e is SocketException || e is HandshakeException);
  });
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
