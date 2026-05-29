// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Skip('Only used by CI')
library;

import 'dart:io';
import 'dart:isolate';

import 'package:test/src/executable.dart' as test;
import 'package:test/test.dart';

/// Entry point for CI test runner.
///
/// This runs `dart test` the same way we would run tests locally. This is the
/// only test that CI runs. This is because we want to use `dart test` as
/// test-runner, because it knows how to compile and run tests in the browser.
///
/// See also `dart_test.yaml` for details on this setup.
void main() async {
  // Resolve the package root directory (pkg/dartpad_worker)
  final pkgRoot = Isolate.resolvePackageUriSync(
    Uri.parse('package:dartpad_worker/'),
  )?.resolve('..').toFilePath();
  if (pkgRoot == null) {
    stderr.writeln('Error: Could not resolve package:dartpad_worker/');
    exit(1);
  }
  Directory.current = pkgRoot;

  await test.main([
    // We limit the number of tests we actually run in CI to keep performance
    // reasonable. Notably, we avoid tests that compile the entire worker, and
    // instead run integration tests that loads the pre-compiled WASM worker.
    'test/asset_server/',
    'test/test_worker_integration.dart',
    'test/dart/integration/',
    'test/resource_provider/',
    // We only test on chrome, because that is what we care about.
    // Running these tests on VM is more about ease of debugging than making
    // sure it all works there.
    '--platform=chrome',
  ]);
}
