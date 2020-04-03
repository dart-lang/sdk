// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import "package:async_helper/async_helper.dart";

Future<void> testDefaultBehavior() async {
  final httpClient = new HttpClient();
  final server = await HttpServer.bind(Platform.localHostname, 0);
  final uri =
      Uri(scheme: 'http', host: Platform.localHostname, port: server.port);
  // Normal HTTP request succeeds.
  await asyncTest(() => httpClient.getUrl(uri));
  // We can ban HTTP explicitly.
  asyncExpectThrows(
      () async => await runZoned(() => httpClient.getUrl(uri),
          zoneValues: {#dart.library.io.allow_http: false}),
      (e) => e is StateError);
  await server.close();
}

main() async {
  await asyncTest(() => testDefaultBehavior());
}
