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

Future<void> testWithHostname() async {
  final httpClient = new HttpClient();
  final uri = Uri(scheme: 'http', host: 'domain.invalid', port: 12345);
  asyncExpectThrows(
      () async => await httpClient.getUrl(uri),
      (e) =>
          e is StateError &&
          e.message.contains("Insecure HTTP is not allowed by platform"));
}

main() {
  asyncStart();
  testWithHostname().then((_) => asyncEnd());
}
