// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import "package:async_helper/async_helper.dart";

Future<String> getLocalHostIP() async {
  final interfaces = await NetworkInterface.list(
      includeLoopback: false, type: InternetAddressType.IPv4);
  return interfaces.first.addresses.first.address;
}

Future<void> testBanHttp(String serverHost,
    Future<void> testCode(HttpClient client, Uri uri)) async {
  final httpClient = new HttpClient();
  final server = await HttpServer.bind(serverHost, 0);
  final uri = Uri(scheme: 'http', host: serverHost, port: server.port);
  try {
    await testCode(httpClient, uri);
  } finally {
    httpClient.close(force: true);
    await server.close();
  }
}

main() async {
  await asyncTest(() async {
    final host = await getLocalHostIP();
    // Normal HTTP request succeeds.
    await testBanHttp(host, (httpClient, uri) async {
      await asyncTest(() => httpClient.getUrl(uri));
    });
    // We can ban HTTP explicitly.
    await testBanHttp(host, (httpClient, uri) async {
      asyncExpectThrows(
          () async => await runZoned(() => httpClient.getUrl(uri),
              zoneValues: {#dart.library.io.allow_http: false}),
          (e) => e is StateError);
    });
  });
}
