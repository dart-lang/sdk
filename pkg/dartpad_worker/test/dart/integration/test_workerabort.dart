// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
library;

import 'dart:async';

import 'package:dartpad/dartpad.dart';
import 'package:test/test.dart';

import '../../asset_server/asset_server_client.dart';
import '../../integration_harness.dart';

void main() {
  test('dedicatedWorker abort', () async {
    final server = await AssetServerClient.spawnHybrid(stayAlive: false);
    final sdk = DartPadSdk(assetBaseUrl: server.baseUrl.resolve('dart/'));

    final abort = Completer<void>();
    final abortedWorker = sdk.dedicatedWorker(
      pubHostedUrl: server.baseUrl,
      abort: abort,
    );
    abort.complete();
    await check(abortedWorker).throws<StateError>();
  });
}
