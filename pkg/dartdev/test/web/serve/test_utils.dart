// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:isolate';

import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

/// Copies the `test/web/fixtures/hello_web` app into the test sandbox, runs
/// `dart pub get`, and returns its package root.
///
/// `web/main.dart` sets the page title to `greeting` from
/// `lib/greeting.dart` (`'hello'`), so a browser test can check that `main()`
/// ran.
Future<String> createWebApp() async {
  final packageConfig = await loadPackageConfigUri(
    (await Isolate.packageConfig)!,
  );
  final fixture = p.join(
    p.fromUri(packageConfig['dartdev']!.root),
    'test',
    'web',
    'fixtures',
    'hello_web',
  );
  final packageRoot = p.join(d.sandbox, 'hello_web');
  await for (final entity in Directory(fixture).list(recursive: true)) {
    if (entity is! File) continue;
    final relative = p.relative(entity.path, from: fixture);
    // Skip what `dart pub get` writes when the fixture is run in place.
    if (p.split(relative).first == '.dart_tool' || relative == 'pubspec.lock') {
      continue;
    }
    final copy = File(p.join(packageRoot, relative));
    await copy.parent.create(recursive: true);
    await entity.copy(copy.path);
  }
  // The app has no dependencies, so this doesn't need the network.
  final pubGet = await Process.run(Platform.resolvedExecutable, [
    'pub',
    'get',
    '--offline',
  ], workingDirectory: packageRoot);
  expect(pubGet.exitCode, 0, reason: '${pubGet.stdout}\n${pubGet.stderr}');
  return packageRoot;
}
