// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:dartdev/src/web/serve/dart_sources.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

/// Creates a small app, two packages and an SDK in the test sandbox, and
/// returns the [DartSources] that serves them.
///
/// Built in code rather than checked in, because it needs files that can't be
/// committed or that differ per machine: a `.git` directory, dotfiles, and a
/// package config with absolute paths. Each file's contents is its name
/// (`sub/<name>` for the files in `web/sub/`), so tests can check which file
/// was served.
///
/// - `app/`: the app's package (`packageUri: lib/`), with `web/` (including
///   `my file.dart`, `.env`, `.git/` and `.well-known/`), `lib/`, and
///   `secret.dart` outside both.
/// - `cache/dep/`: a dependency with `lib/src/impl.dart`.
/// - `cache/root_pkg/` (`packageUri: .`) and `cache/omitted_pkg/` (no
///   `packageUri`): packages whose package root is the whole package.
/// - `sdk/lib/core/core.dart`: the SDK's libraries.
Future<DartSources> createServeProject() async {
  d.FileDescriptor file(String name) => d.file(name, name);
  await d.dir('app', [
    d.dir('web', [
      file('index.html'),
      file('style.css'),
      file('main.dart'),
      file('my file.dart'),
      file('.env'),
      file('.hidden.dart'),
      d.dir('.git', [file('config')]),
      d.dir('.well-known', [file('assetlinks.json')]),
      d.dir('sub', [
        d.file('index.html', 'sub/index.html'),
        d.file('nested.dart', 'sub/nested.dart'),
      ]),
    ]),
    d.dir('lib', [file('greeting.dart'), file('my lib.dart')]),
    file('secret.dart'),
  ]).create();
  await d.dir('cache', [
    d.dir('dep', [
      d.dir('lib', [
        d.dir('src', [file('impl.dart')]),
      ]),
    ]),
    d.dir('root_pkg', [
      d.dir('bin', [file('server.dart')]),
      d.dir('lib', [file('inside.dart')]),
    ]),
    d.dir('omitted_pkg', [
      d.dir('tool', [file('gen.dart')]),
    ]),
  ]).create();
  await d.dir('sdk', [
    d.dir('lib', [
      d.dir('core', [file('core.dart')]),
    ]),
  ]).create();
  String rootUri(List<String> path) =>
      p.toUri(p.joinAll([d.sandbox, ...path])).toString();
  final packageConfig = PackageConfig.parseBytes(
    utf8.encode(
      jsonEncode({
        'configVersion': 2,
        'packages': [
          {
            'name': 'app',
            'rootUri': rootUri(['app']),
            'packageUri': 'lib/',
          },
          {
            'name': 'dep',
            'rootUri': rootUri(['cache', 'dep']),
            'packageUri': 'lib/',
          },
          {
            'name': 'root_pkg',
            'rootUri': rootUri(['cache', 'root_pkg']),
            'packageUri': '.',
          },
          {
            'name': 'omitted_pkg',
            'rootUri': rootUri(['cache', 'omitted_pkg']),
          },
        ],
      }),
    ),
    p.toUri(p.join(d.sandbox, 'app', '.dart_tool', 'package_config.json')),
  );
  return DartSources(
    webDirectory: p.join(d.sandbox, 'app', 'web'),
    packageConfig: packageConfig,
    sdkRoot: p.join(d.sandbox, 'sdk'),
  );
}

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
