// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test file disallows VM from accepting insecure connections to all
// domains and tests that HTTP connections to non-localhost targets fail.
// HTTPS connections and localhost connections should still succeed.

// SharedOptions=-Ddart.library.io.may_insecurely_connect_to_all_domains=false

import "dart:async";
import "dart:io";

import "package:async_helper/async_helper.dart";

import "http_bind_test.dart";

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

Future<void> testWithLoopback() async {
  await testBanHttp("127.0.0.1", (httpClient, uri) async {
    await asyncTest(() async =>
        await httpClient.getUrl(Uri.parse('http://localhost:${uri.port}')));
    await asyncTest(() async =>
        await httpClient.getUrl(Uri.parse('http://127.0.0.1:${uri.port}')));
  });
}

Future<void> testWithIPv6() async {
  if (await supportsIPV6()) {
    await testBanHttp("::1", (httpClient, uri) async {
      await asyncTest(() => httpClient.getUrl(uri));
    });
  }
}

Future<void> testWithHttps() async {
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
    testWithLoopback(),
    testWithIPv6(),
    testWithHttps(),
  ]).then((_) => asyncEnd());
}
