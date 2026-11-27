// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dartdev/src/web/project.dart';
import 'package:dartdev/src/web/serve/ddc_assets.dart';
import 'package:dartdev/src/web/serve/ddc_compiler.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import 'test_utils.dart';

/// Compiles a hello-world app and checks the generated files that start it.
void main() {
  late DdcCompiler compiler;

  setUp(() async {
    final project = await WebProject.find(await createWebApp());
    compiler = await DdcCompiler.start(project);
    addTearDown(compiler.shutdown);
  });

  test('provides every file that starts the app', () async {
    expect(await compiler.compile(), isEmpty);
    final assets = await DdcAssets.load(compiler);
    String file(String path) =>
        utf8.decode(assets.lookupFileByPath(path) ?? fail('No file at $path'));

    // The bootstrap script, which web/index.html loads, loads the others.
    expect(assets.bootstrapPath, 'main.dart.js');
    expect(
      file('main.dart.js'),
      allOf(
        contains('ddc_module_loader.js'),
        contains('dart_stack_trace_mapper.js'),
        contains('dart_sdk.js'),
        contains('main_module.bootstrap.js'),
      ),
    );
    for (final path in [
      'ddc_module_loader.js',
      'dart_stack_trace_mapper.js',
      'dart_sdk.js',
      'dart_sdk.js.map',
      'on_load_end_bootstrap.js',
    ]) {
      expect(file(path), isNotEmpty, reason: path);
    }
    // The main module runs main(), and lists the app's modules for the
    // loader. DWDS finds it by the marker at its start.
    expect(
      file('main_module.bootstrap.js'),
      allOf(
        startsWith('/* ENTRYPOINT_EXTENTION_MARKER */'),
        contains('org-dartlang-app:///web/main.dart'),
        contains('"src":"web/main.dart.lib.js"'),
        contains('"src":"packages/hello_web/greeting.dart.lib.js"'),
      ),
    );
    // The app's modules, at the paths that the main module lists.
    expect(file('web/main.dart.lib.js'), contains('greeting'));
    expect(file('packages/hello_web/greeting.dart.lib.js'), contains('hello'));
    expect(assets.lookupFileByPath('missing.js'), isNull);
  });

  test('the main module loads every compiled module', () async {
    expect(await compiler.compile(), isEmpty);
    final assets = await DdcAssets.load(compiler);
    final mainModule = utf8.decode(
      assets.lookupFileByPath('main_module.bootstrap.js')!,
    );
    // Wrapped in an IIFE so `scripts` doesn't collide with page globals.
    expect(mainModule, contains('(function() {\n  const scripts = '));
    expect(
      mainModule,
      isNot(contains(RegExp(r'^const scripts =', multiLine: true))),
    );
    final scripts =
        jsonDecode(RegExp(r'const scripts = (.*);').firstMatch(mainModule)![1]!)
            as List<Object?>;
    expect(
      scripts,
      unorderedEquals([
        {'src': 'web/main.dart.lib.js', 'id': 'web/main.dart'},
        {
          'src': 'packages/hello_web/greeting.dart.lib.js',
          'id': 'packages/hello_web/greeting.dart',
        },
      ]),
    );
    // The server serves each one at '/<src>'.
    for (final entry in scripts) {
      final src = (entry as Map<String, Object?>)['src'] as String;
      expect(assets.lookupFileByPath(src), isNotNull, reason: src);
    }
  });

  test('serves the dart_sdk.js that the SDK ships', () async {
    final expectedSdkRoot = p.dirname(p.dirname(Platform.resolvedExecutable));
    expect(p.equals(compiler.sdkRoot, expectedSdkRoot), isTrue);
    final assets = await DdcAssets.load(compiler);
    final shippedSdkJs = p.join(
      expectedSdkRoot,
      'lib',
      'dev_compiler',
      'canary',
      'sdk',
      'dart_sdk.js',
    );
    expect(
      assets.lookupFileByPath('dart_sdk.js'),
      File(shippedSdkJs).readAsBytesSync(),
    );
    expect(
      assets.lookupFileByPath('dart_sdk.js.map'),
      File('$shippedSdkJs.map').readAsBytesSync(),
    );
  });

  test('serves the given dart_sdk.js', () async {
    // Like the build's gen/utils/ddc/canary/sdk/ddc/dart_sdk.js.
    await d.dir('ddc', [
      d.file('dart_sdk.js', 'custom dart_sdk.js'),
      d.file('dart_sdk.js.map', 'custom source map'),
    ]).create();
    final assets = await DdcAssets.load(
      compiler,
      sdkJsPath: p.join(d.sandbox, 'ddc', 'dart_sdk.js'),
    );
    expect(
      utf8.decode(assets.lookupFileByPath('dart_sdk.js')!),
      'custom dart_sdk.js',
    );
    expect(
      utf8.decode(assets.lookupFileByPath('dart_sdk.js.map')!),
      'custom source map',
    );
  });

  test('rejects an SDK root that is not a Dart SDK', () async {
    await d.dir('not_an_sdk').create();
    await expectLater(
      DdcCompiler.start(
        compiler.project,
        sdkRoot: p.join(d.sandbox, 'not_an_sdk'),
      ),
      throwsA(
        isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          'Not the root directory of a Dart SDK',
        ),
      ),
    );
  });

  test('reports compile errors', () async {
    final main = File(p.join(compiler.project.webDirectory, 'main.dart'));
    await main.writeAsString('void main() { undefinedFunction(); }');
    expect(
      await compiler.compile(),
      contains(contains("Method not found: 'undefinedFunction'")),
    );
  });

  test(
    'uses a unique temporary directory per session and deletes it on shutdown',
    () async {
      final other = await DdcCompiler.start(compiler.project);
      final otherDir = Directory(other.outputDirectoryPath);
      try {
        expect(
          p.equals(compiler.outputDirectoryPath, other.outputDirectoryPath),
          isFalse,
        );
        expect(otherDir.existsSync(), isTrue);

        // Concurrent sessions on the same project don't clobber each other.
        final results = await Future.wait([
          compiler.compile(),
          other.compile(),
        ]);
        expect(results, [isEmpty, isEmpty]);
        expect(
          Directory(
            p.join(compiler.project.packageRoot, '.dart_tool', 'dart_serve'),
          ).existsSync(),
          isFalse,
        );
      } finally {
        await other.shutdown();
      }
      expect(otherDir.existsSync(), isFalse);
    },
  );

  test('percent-encodes entrypoint names with spaces', () async {
    File(
      p.join(compiler.project.webDirectory, 'my app.dart'),
    ).writeAsStringSync(
      "import 'package:hello_web/greeting.dart';\n"
      'void main() { print(greeting); }\n',
    );
    final spacedProject = await WebProject.find(
      compiler.project.packageRoot,
      entrypoint: 'web/my app.dart',
    );
    final spacedCompiler = await DdcCompiler.start(spacedProject);
    addTearDown(spacedCompiler.shutdown);

    expect(
      spacedCompiler.entrypointUri,
      'org-dartlang-app:///web/my%20app.dart',
    );
    expect(await spacedCompiler.compile(), isEmpty);

    final assets = await DdcAssets.load(spacedCompiler);
    expect(assets.bootstrapPath, 'my%20app.dart.js');
    expect(assets.lookupFileByPath('my%20app.dart.js'), isNotNull);
    expect(assets.lookupFileByPath('my app.dart.js'), isNull);
    expect(
      utf8.decode(assets.lookupFileByPath('main_module.bootstrap.js')!),
      contains('"org-dartlang-app:///web/my%20app.dart"'),
    );
    expect(assets.lookupFileByPath('web/my%20app.dart.lib.js'), isNotNull);
  });
}
