// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
library;

import 'package:dartpad/dartpad.dart';
import 'package:test/test.dart' show TestOn;

import 'dart/all_worker_tests.dart' as all_dart_worker_tests;
import 'flutter/all_worker_tests.dart' as all_flutter_worker_tests;
import 'worker_harness.dart';

void main() {
  // Override [createWorker] such that the worker is actually launched in a
  // Web Worker. This is not as easy to debug as the default [createWorker]
  // implementation, but it ensures that we exercise all the worker tests with
  // the worker actually in a Web Worker.
  createWorker = (server, sdkPath) async {
    printOnFailure('creating dartpad');
    final sdk = DartPadSdk(assetBaseUrl: server.baseUrl.resolve('$sdkPath/'));
    return await sdk.dedicatedWorker(pubHostedUrl: server.baseUrl);
  };

  final testFiles = [
    ...all_flutter_worker_tests.testFiles,
    ...all_dart_worker_tests.testFiles,
  ];

  for (final (file, m) in testFiles) {
    group(file, m);
  }
}
