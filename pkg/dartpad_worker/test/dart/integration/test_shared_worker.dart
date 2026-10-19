// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
library;

import 'dart:async';

import 'package:dartpad/dartpad.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

import '../../asset_server/asset_server_client.dart';
import '../../integration_harness.dart';

void main() => test('sharedWorker', () async {
  final server = await AssetServerClient.spawnHybrid();
  final sdk = DartPadSdk(assetBaseUrl: server.baseUrl.resolve('dart/'));
  final sharedWorkerUrl = Uri.parse(
    'packages/dartpad/src/asset/shared-worker.js',
  );

  final abort = Completer<void>();
  final abortedWorker = sdk.sharedWorker(
    sharedWorkerUrl,
    pubHostedUrl: server.baseUrl,
    abort: abort,
  );
  abort.complete();
  await check(abortedWorker).throws<StateError>();

  final shared1 = await sdk.sharedWorker(
    sharedWorkerUrl,
    pubHostedUrl: server.baseUrl,
  );
  addTearDown(shared1.close);
  final shared2 = await sdk.sharedWorker(
    sharedWorkerUrl,
    pubHostedUrl: server.baseUrl,
    closeOnPageHide: false,
  );
  addTearDown(shared2.close);
  final sws1 = await shared1.createWorkspace();
  final sws2 = await shared2.createWorkspace();
  await sws1.writeFileFromText('shared.txt', 'from session 1');
  check(
    await sws2.readFileAsText('${sws1.workspaceFolder}/shared.txt'),
  ).equals('from session 1');

  web.window.dispatchEvent(web.PageTransitionEvent('pagehide'));
  await shared1.done;
  while (await sws2.fileExist('${sws1.workspaceFolder}/shared.txt')) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  await shared2.close();
});
