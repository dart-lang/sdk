// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:dartpad/src/dartpad_config.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:tar/tar.dart';

Future<void> main() async {
  final dartSdkRoot = p.dirname(p.dirname(Platform.resolvedExecutable));

  // Locate Flutter
  var flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot == null) {
    try {
      final flutterExecutable = await _resolveFlutterExecutable();
      flutterRoot = Directory(flutterExecutable).parent.parent.path;
    } catch (e) {
      print('Error: FLUTTER_ROOT not set and flutter not found in PATH.');
      exit(1);
    }
  }
  flutterRoot = p.canonicalize(flutterRoot);
  if (!Directory(flutterRoot).existsSync()) {
    print('Flutter SDK not found at $flutterRoot.');
    exit(1);
  }
  final flutterBin = p.join(flutterRoot, 'bin', 'flutter');

  // Find output folder
  final workerPkgUri = await Isolate.resolvePackageUri(
    Uri.parse('package:dartpad_worker/'),
  );
  if (workerPkgUri == null) {
    print('Error: Could not resolve package:dartpad_worker/');
    exit(1);
  }
  final projectRoot = p.dirname(workerPkgUri.toFilePath());
  final flutterAssetDir = p.join(
    projectRoot,
    '.dart_tool',
    'dartpad_worker',
    'asset',
    'flutter',
  );
  final packageDir = p.join(
    projectRoot,
    '.dart_tool',
    'dartpad_worker',
    'packages',
  );

  // Create empty output folders
  final flutterAssetDirectory = Directory(flutterAssetDir);
  if (flutterAssetDirectory.existsSync()) {
    flutterAssetDirectory.deleteSync(recursive: true);
  }
  flutterAssetDirectory.createSync(recursive: true);
  final packageDirectory = Directory(packageDir);
  if (packageDirectory.existsSync()) {
    packageDirectory.deleteSync(recursive: true);
  }
  packageDirectory.createSync(recursive: true);

  print('Using Flutter SDK at: $flutterRoot');
  print('Target asset directory: $flutterAssetDir');

  final tempDir = Directory.systemTemp.createTempSync('dartpad_flutter_setup_');
  try {
    await _setupLocalFlutter(
      _BuildContext(
        dartSdkRoot: dartSdkRoot,
        dartBin: p.join(dartSdkRoot, 'bin', 'dart'),
        dartAotRuntimeBin: p.join(dartSdkRoot, 'bin', 'dartaotruntime'),
        dartDartPadSdk: p.join(dartSdkRoot, '..', 'dartpad'),
        flutterRoot: flutterRoot,
        tempDir: tempDir.path,
        flutterBin: flutterBin,
        projectRoot: projectRoot,
        flutterAssetDir: flutterAssetDir,
        packageDir: packageDir,
      ),
    );
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}

final class _BuildContext {
  final String dartSdkRoot;
  final String dartBin;
  final String dartAotRuntimeBin;
  final String dartDartPadSdk;
  final String flutterRoot;
  final String tempDir;
  final String flutterBin;
  final String projectRoot;
  final String flutterAssetDir;
  final String packageDir;

  _BuildContext({
    required this.dartSdkRoot,
    required this.dartBin,
    required this.dartAotRuntimeBin,
    required this.dartDartPadSdk,
    required this.flutterRoot,
    required this.tempDir,
    required this.flutterBin,
    required this.projectRoot,
    required this.flutterAssetDir,
    required this.packageDir,
  });
}

Future<void> _setupLocalFlutter(_BuildContext ctx) async {
  // 1. Create & Build Dummy App
  print('Creating dummy app...');
  _runSync(ctx.flutterBin, [
    'create',
    'myapp',
    '--empty',
    '--platforms',
    'web',
  ], ctx.tempDir);
  final myappDir = p.join(ctx.tempDir, 'myapp');

  print('Pruning pubspec.yaml...');
  _runSync(ctx.flutterBin, [
    'pub',
    'remove',
    'flutter_test',
    'flutter_lints',
  ], myappDir);

  print('Running flutter pub get...');
  _runSync(ctx.flutterBin, ['pub', 'get'], myappDir);

  print('Building dummy app for web (to harvest assets)...');
  _runSync(ctx.flutterBin, ['build', 'web', '--debug'], myappDir);

  // 2. Scrape Assets (CanvasKit, Fonts)
  print('Scraping assets...');
  final sourceAssetsDir = p.join(myappDir, 'build', 'web', 'assets');
  _copyDir(sourceAssetsDir, p.join(ctx.flutterAssetDir, 'assets'));

  print('Copying flutter.js');
  _copyFile(
    p.join(myappDir, 'build', 'web', 'flutter.js'),
    p.join(ctx.flutterAssetDir, 'flutter.js'),
  );

  print('Scraping CanvasKit...');
  final sourceCanvasKitDir = p.join(myappDir, 'build', 'web', 'canvaskit');
  _copyDir(sourceCanvasKitDir, p.join(ctx.flutterAssetDir, 'canvaskit'));

  // 3. Compile flutter_web.js and flutter_web.dill
  print('Compiling flutter_web.js and flutter_web.dill...');
  final pkgConfigPath = p.join(myappDir, '.dart_tool', 'package_config.json');
  final pkgConfig =
      jsonDecode(File(pkgConfigPath).readAsStringSync())
          as Map<String, dynamic>;

  final compileSources = <String>[];
  for (final pkgEntry in pkgConfig['packages'] as List<dynamic>) {
    final pkg = pkgEntry as Map<String, dynamic>;
    final name = pkg['name'] as String;
    if (name == 'sky_engine' || name == 'myapp') continue;

    var rootUriStr = pkg['rootUri'] as String;
    final rootUri = Uri.parse(rootUriStr);
    final rootPath = rootUri.scheme == 'file'
        ? rootUri.toFilePath()
        : p.normalize(p.join(myappDir, '.dart_tool', rootUriStr));

    final libDir = Directory(p.join(rootPath, pkg['packageUri'] as String));
    if (libDir.existsSync()) {
      final topLevelFiles = libDir
          .listSync(recursive: false)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));
      for (final file in topLevelFiles) {
        final relative = p.relative(file.path, from: libDir.path);
        compileSources.add('package:$name/${p.toUri(relative).path}');
      }
    }
  }

  final snapshotPath = p.join(
    ctx.dartSdkRoot,
    'bin',
    'snapshots',
    'dartdevc.dart.snapshot',
  );
  final outlinePath = p.join(
    ctx.flutterRoot,
    'bin',
    'cache',
    'flutter_web_sdk',
    'kernel',
    'ddc_outline.dill',
  );
  final outputJsPath = p.join(ctx.flutterAssetDir, 'flutter_web.js');
  final outputDillPath = p.join(ctx.tempDir, 'flutter_web.dill');

  _runSync(ctx.dartBin, [
    snapshotPath,
    '-s',
    outlinePath,
    '--modules=ddc',
    '--canary',
    '--module-name=flutter_web',
    '--packages=$pkgConfigPath',
    '-o',
    outputJsPath,
    ...compileSources,
  ], myappDir);

  // We don't want the full dill generated by DDC.
  final fullDillPath = p.setExtension(outputJsPath, '.dill');
  if (File(fullDillPath).existsSync()) {
    File(fullDillPath).deleteSync();
  }

  final kernelWorkerPath = p.join(
    ctx.dartSdkRoot,
    'bin',
    'snapshots',
    'kernel_worker_aot.dart.snapshot',
  );

  _runSync(ctx.dartAotRuntimeBin, [
    kernelWorkerPath,
    '--target',
    'ddc',
    '--summary-only',
    '--packages-file',
    pkgConfigPath,
    '--dart-sdk-summary',
    outlinePath,
    '--output',
    outputDillPath,
    ...compileSources.expand((s) => ['--source', s]),
  ], myappDir);

  // Scrape JS from Flutter Cache
  print('Scraping pre-compiled JS from cache...');
  final webSdkKernel = p.join(
    ctx.flutterRoot,
    'bin',
    'cache',
    'flutter_web_sdk',
    'kernel',
  );
  final canaryJsDir = p.join(webSdkKernel, 'ddcLibraryBundle-canvaskit');
  _copyFile(
    p.join(canaryJsDir, 'dart_sdk.js'),
    p.join(ctx.flutterAssetDir, 'dart_sdk.js'),
  );

  // Synthesize combined sdk.js
  print('Synthesizing sdk.js...');
  File(p.join(ctx.flutterAssetDir, 'sdk.js')).writeAsStringSync(r'''
const scriptUrl = document.currentScript?.src || self.location.href;

// Tell the Flutter engine where to find CanvasKit and assets
self.dartpadFlutterConfiguration = {
  canvasKitBaseUrl: new URL('./canvaskit/', scriptUrl).href,
  assetBase: new URL('./', scriptUrl).href,
};

const flutterJs = new URL('./flutter.js', scriptUrl);
const dartSdkJs = new URL('./dart_sdk.js', scriptUrl);
const flutterWebJs = new URL('./flutter_web.js', scriptUrl);

self.$dartLoader.forceLoadScript(flutterJs, () => null);
self.$dartLoader.forceLoadScript(dartSdkJs, () => null);
self.$dartLoader.forceLoadScript(flutterWebJs, () => null);
''');

  // Copy worker from Dart DartPad SDK.
  print('Copying worker...');
  for (final f in [
    'sandbox.js',
    'ddc_module_loader.js',
    'worker.js',
    'worker.mjs',
    'worker.support.js',
    'worker.wasm',
    'worker.wasm.map',
  ]) {
    _copyFile(p.join(ctx.dartDartPadSdk, f), p.join(ctx.flutterAssetDir, f));
  }

  // Download Dependencies from Pub.dev
  print('Downloading hosted dependencies...');
  final depsJson = _runSync(ctx.flutterBin, [
    'pub',
    'deps',
    '--json',
  ], myappDir);
  await _downloadHostedPackages(depsJson, ctx.packageDir);

  // Build sdk.tar
  print('Building sdk.tar...');
  final tar = tarWritingSink(
    File(p.join(ctx.flutterAssetDir, 'sdk.tar')).openWrite(),
  );

  print('Adding Dart SDK lib...');
  tar.addDirectory(
    target: '/sdk/bin/cache/dart-sdk/lib',
    source: p.join(ctx.flutterRoot, 'bin/cache/dart-sdk/lib'),
    where: (f) =>
        (f.endsWith('.dart') ||
            f.endsWith('.json') ||
            f.contains('${p.separator}_internal${p.separator}')) &&
        !f.endsWith('.dill'),
  );

  print('Adding version and libraries');
  tar.addFile(
    target: '/sdk/bin/cache/flutter.version.json',
    source: p.join(ctx.flutterRoot, 'bin/cache/flutter.version.json'),
  );
  tar.addFile(
    // TODO(jonasfj): Is it weird that we're taking flutters libraries.json and
    //       sticking it into the Dart SDK? I don't think we have a config
    //       option for getting the LSP to pick libraries.json from a path!
    //       But maybe we should have two library.json files, the one we compile
    //       with (which we can configure) and the one we feed to analyzer!
    // TODO(jonasfj): Is this file even needed for anything?
    target: '/sdk/bin/cache/libraries.json',
    source: p.join(ctx.flutterRoot, 'bin/cache/dart-sdk/lib/libraries.json'),
  );
  tar.addFile(
    target: '/sdk/bin/cache/dart-sdk/version',
    source: p.join(ctx.flutterRoot, 'bin', 'cache', 'dart-sdk', 'version'),
  );

  // Add the ddc_outline.dill from Flutter which contains dart:ui
  tar.addFile(
    target: '/sdk/bin/cache/dart-sdk/lib/_internal/ddc_outline.dill',
    source: p.join(
      ctx.flutterRoot,
      'bin',
      'cache',
      'flutter_web_sdk',
      'kernel',
      'ddc_outline.dill',
    ),
  );

  // Add the framework outline dill we just built
  tar.addFile(
    target: '/sdk/bin/cache/flutter_web_sdk/kernel/flutter_web.dill',
    source: outputDillPath,
  );

  // Create dartpad-config.json
  tar.addJsonFile(
    target: DartPadConfig.defaultDartPadConfigPath,
    json: DartPadConfig(
      dartSdkPath: '/sdk/bin/cache/dart-sdk',
      summaryModules: {
        '/sdk/bin/cache/flutter_web_sdk/kernel/flutter_web.dill': 'flutter_web',
      },
      bootstrapCode: kBootstrapFlutterCode,
      flutterSdkPath: '/sdk',
    ),
  );

  // Add SDK packages for analyzer
  print('Adding package:flutter for analysis...');
  tar.addDirectory(
    target: '/sdk/packages/flutter',
    source: p.join(ctx.flutterRoot, 'packages', 'flutter'),
    where: (f) =>
        !f.startsWith('test/') &&
        (f.endsWith('pubspec.yaml') || f.startsWith('lib/')),
  );
  tar.addDirectory(
    target: '/sdk/bin/cache/pkg/sky_engine',
    source: p.join(ctx.flutterRoot, 'bin', 'cache', 'pkg', 'sky_engine'),
    where: (f) =>
        !f.startsWith('test') &&
        (f.endsWith('pubspec.yaml') || f.startsWith('lib/')),
  );

  await tar.close();

  print('\nSuccessfully set up local Flutter assets!');
  print('Run your tests with PubTestServer reporting hasFlutter: true.');
}

String _runSync(String command, List<String> args, String workingDir) {
  final result = Process.runSync(command, args, workingDirectory: workingDir);
  if (result.exitCode != 0) {
    print('Command failed: $command ${args.join(' ')}');
    print('stdout: ${result.stdout}');
    print('stderr: ${result.stderr}');
    throw Exception('Command failed');
  }
  return result.stdout.toString();
}

void _copyFile(String source, String dest) => File(source).copySync(dest);

void _copyDir(String source, String dest) {
  final s = Directory(source);
  if (!s.existsSync()) {
    throw Exception('Expected $source to exist!');
  }
  Directory(dest).createSync(recursive: true);
  for (final entity in s.listSync(recursive: true)) {
    if (entity is File) {
      final relative = p.relative(entity.path, from: source);
      final destFile = File(p.join(dest, relative));
      destFile.parent.createSync(recursive: true);
      entity.copySync(destFile.path);
    }
  }
}

Future<void> _downloadHostedPackages(String depsJson, String dest) async {
  final data = jsonDecode(depsJson) as Map<String, Object?>;
  final packages = data['packages'] as List<Object?>;
  final client = http.Client();
  try {
    for (final pkg in packages) {
      if (pkg is Map && pkg['source'] == 'hosted') {
        final name = pkg['name'] as String;
        final version = pkg['version'] as String;
        final tarballName = '$name-$version.tar.gz';
        final tarballFile = File(p.join(dest, tarballName));

        if (tarballFile.existsSync()) continue;

        print('Downloading $name $version...');
        final url = 'https://pub.dev/api/archives/$tarballName';
        final response = await client.get(Uri.parse(url));
        if (response.statusCode == 200) {
          tarballFile.writeAsBytesSync(response.bodyBytes);
        } else {
          print('Failed to download $name: ${response.statusCode}');
        }
      }
    }
  } finally {
    client.close();
  }
}

extension on StreamSink<TarEntry> {
  void addFile({required String target, required String source}) => add(
    TarEntry.data(
      TarHeader(name: target, mode: 420),
      File(source).readAsBytesSync(),
    ),
  );

  void addTextFile({required String target, required String text}) =>
      add(TarEntry.data(TarHeader(name: target, mode: 420), utf8.encode(text)));

  void addJsonFile({required String target, required Object? json}) =>
      addTextFile(target: target, text: jsonEncode(json));

  void addDirectory({
    required String source,
    required String target,
    bool Function(String path)? where,
  }) {
    final s = Directory(source);
    if (!s.existsSync()) return;
    for (final f in s.listSync(recursive: true).whereType<File>()) {
      final relative = p.relative(f.path, from: source);
      if (where != null && !where(relative)) continue;
      add(
        TarEntry.data(
          TarHeader(name: p.join(target, relative), mode: 420),
          f.readAsBytesSync(),
        ),
      );
    }
  }
}

Future<String> _resolveFlutterExecutable() async {
  final command = Platform.isWindows ? 'where' : 'which';
  final result = await Process.run(command, ['flutter']);
  if (result.exitCode != 0 || result.stdout.toString().trim().isEmpty) {
    throw Exception('Flutter not found in PATH');
  }
  return result.stdout.toString().split('\n').first.trim();
}

const kBootstrapFlutterCode = r'''
import 'dart:ui_web' as ui_web;
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
//import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import '{{entrypoint}}' as entrypoint;

@JS('window')
external JSObject get _window;

@JS('console.error')
external void _consoleError(JSString message);

Future<void> main() async {
  // Disable URL strategy to prevent SecurityError in srcdoc iframes
  ui_web.urlStrategy = null;

  // Capture errors and pipe to console.error
  FlutterError.onError = (details) {
    _consoleError(details.toString().toJS);
  };

  // Mock DWDS indicators to allow Flutter to register hot reload 'reassemble'
  // extension.
  _window[r'$dwdsVersion'] = true.toJS;
  _window[r'$emitRegisterEvent'] = ((String _) {}).toJS;
  await ui_web.bootstrapEngine(
    runApp: () {
      entrypoint.main();
    },
    registerPlugins: () {
      // pluginRegistrant.registerPlugins();
    },
  );
}
''';
