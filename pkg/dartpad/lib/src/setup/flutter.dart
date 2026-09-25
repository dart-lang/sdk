// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:args/command_runner.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:tar/tar.dart';
import 'package:yaml/yaml.dart';

import '../dartpad_config.dart';
import 'dart.dart';

/// Command to build a DartPad SDK for Flutter.
final class SetupFlutterCommand extends Command<void> {
  @override
  final String name = 'flutter';

  @override
  final String description = 'Build a DartPad SDK for Flutter.';

  SetupFlutterCommand() {
    argParser
      ..addOption(
        'output',
        abbr: 'o',
        mandatory: true,
        valueHelp: 'dir',
        help: 'Output directory for the Flutter DartPad SDK.',
      )
      ..addOption(
        'flutter-root',
        valueHelp: 'dir',
        help:
            'Path to an existing Flutter SDK checkout/installation '
            '(defaults to \$FLUTTER_ROOT or `flutter` on PATH).',
      )
      ..addOption(
        'channel',
        abbr: 'c',
        allowed: ['master', 'main', 'beta', 'stable'],
        help:
            'Clone Flutter (<channel>) into a temporary directory and build '
            'from that checkout (mutually exclusive with --flutter-root).',
      )
      ..addFlag(
        'use-cdn',
        defaultsTo: true,
        help:
            'Use CanvasKit from Google CDN instead of bundling canvaskit/ locally.',
      )
      ..addOption(
        'dartpad-sdk',
        valueHelp: 'dir',
        help:
            'Path to a locally built DartPad SDK for Dart (e.g. out/ReleaseX64/dartpad). '
            'When omitted, downloads the matching dartpad.zip from gs://dart-archive '
            'for <flutter>/bin/cache/dart-sdk/revision.',
      )
      ..addOption(
        'web-sdk',
        allowed: ['copy', 'build'],
        defaultsTo: 'copy',
        help:
            'Copy or build `ddc_outline.dill` + `dart_sdk.js` from Flutter '
            'SDK.',
      )
      ..addOption(
        'bootstrap-code-path',
        valueHelp: 'file',
        help: 'Path to a file containing custom Flutter bootstrap code.',
      );
  }

  @override
  Future<void> run() async {
    final results = argResults!;
    final outputDir = p.normalize(p.absolute(results.option('output')!));
    var flutterRoot = switch (results.option('flutter-root')) {
      final path? => p.normalize(p.absolute(path)),
      null => null,
    };
    final channel = results.option('channel');
    final useCdn = results.flag('use-cdn');
    final localDartPadSdk = switch (results.option('dartpad-sdk')) {
      final path? => p.normalize(p.absolute(path)),
      null => null,
    };
    final webSdkOption = results.option('web-sdk')!;
    final bootstrapCodePath = switch (results.option('bootstrap-code-path')) {
      final path? => p.normalize(p.absolute(path)),
      null => null,
    };

    final outDir = Directory(outputDir);
    if (outDir.existsSync() && outDir.listSync().isNotEmpty) {
      usageException(
        'Output directory "$outputDir" already exists and is not empty.',
      );
    }

    if (flutterRoot != null && channel != null) {
      usageException('Cannot specify both --flutter-root and --channel.');
    }

    String? bootstrapCode;
    if (bootstrapCodePath != null) {
      final file = File(bootstrapCodePath);
      if (!file.existsSync()) {
        usageException('Bootstrap code file not found at $bootstrapCodePath');
      }
      bootstrapCode = file.readAsStringSync();
    }

    final tempDir = Directory.systemTemp.createTempSync(
      'dartpad_flutter_setup_',
    );
    try {
      if (channel != null) {
        flutterRoot = p.join(tempDir.path, 'flutter_sdk');
        print('Cloning Flutter ($channel) into $flutterRoot...');
        _runSync('git', [
          'clone',
          '--depth',
          '1',
          '-b',
          channel,
          'https://github.com/flutter/flutter.git',
          flutterRoot,
        ], tempDir.path);
      } else {
        if (flutterRoot == null &&
            Platform.environment['FLUTTER_ROOT'] != null) {
          flutterRoot = p.normalize(
            p.absolute(Platform.environment['FLUTTER_ROOT']!),
          );
        }
        if (flutterRoot == null) {
          try {
            final flutterExecutable = await _resolveFlutterExecutable();
            flutterRoot = p.normalize(
              Directory(flutterExecutable).parent.parent.path,
            );
          } on Object {
            usageException(
              'FLUTTER_ROOT not set, `flutter` not found in PATH, '
              'and neither --flutter-root nor --channel was provided.',
            );
          }
        }
      }

      if (!Directory(flutterRoot).existsSync()) {
        usageException('Flutter SDK not found at $flutterRoot');
      }
      outDir.createSync(recursive: true);
      print('Using Flutter SDK at: $flutterRoot');

      final flutterBin = p.join(
        flutterRoot,
        'bin',
        Platform.isWindows ? 'flutter.bat' : 'flutter',
      );

      // 1. Create and build dummy app to ensure Flutter cache is populated
      //    and harvest web assets + package_config.json.
      final myappDir = p.join(tempDir.path, 'myapp');
      print('Creating dummy app...');
      _runSync(flutterBin, [
        'create',
        'myapp',
        '--empty',
        '--platforms',
        'web',
      ], tempDir.path);

      print('Pruning pubspec.yaml...');
      _runSync(flutterBin, ['pub', 'remove', 'flutter_lints'], myappDir);

      for (final sdkPkg in [
        'flutter_web_plugins',
        'flutter_localizations',
        'integration_test',
      ]) {
        print('Adding $sdkPkg dependency...');
        _runSync(flutterBin, ['pub', 'add', sdkPkg, '--sdk=flutter'], myappDir);
      }

      print('Adding material_ui and cupertino_ui dependencies...');
      _runSync(flutterBin, [
        'pub',
        'add',
        'material_ui',
        'cupertino_ui',
      ], myappDir);

      print('Running flutter pub get...');
      _runSync(flutterBin, ['pub', 'get'], myappDir);

      print('Building dummy app for web (to harvest assets)...');
      _runSync(flutterBin, ['build', 'web', '--debug'], myappDir);

      // Resolve Dart SDK and DartPad SDK for Dart (either local or downloaded
      // from gs://dart-archive matching <flutter>/bin/cache/dart-sdk/revision).
      final String dartSdkRoot;
      final String dartDartPadSdk;
      if (localDartPadSdk != null) {
        if (!Directory(localDartPadSdk).existsSync()) {
          throw StateError(
            'Local DartPad SDK directory not found at $localDartPadSdk',
          );
        }
        dartDartPadSdk = localDartPadSdk;
        final siblingDartSdk = p.normalize(
          p.join(localDartPadSdk, '..', 'dart-sdk'),
        );
        dartSdkRoot = Directory(siblingDartSdk).existsSync()
            ? siblingDartSdk
            : p.dirname(p.dirname(Platform.resolvedExecutable));
      } else {
        dartSdkRoot = p.join(flutterRoot, 'bin', 'cache', 'dart-sdk');
        final revisionFile = File(p.join(dartSdkRoot, 'revision'));
        final versionFile = File(p.join(dartSdkRoot, 'version'));
        if (!revisionFile.existsSync() || !versionFile.existsSync()) {
          throw StateError(
            'Expected ${revisionFile.path} and ${versionFile.path} to exist.',
          );
        }
        final dartRevision = revisionFile.readAsStringSync().trim();
        final dartVersion = versionFile.readAsStringSync().trim();
        final dartChannel = inferDartChannelFromVersion(dartVersion);
        final zipUrl = resolveDartPadZipUrl(
          channel: dartChannel,
          revision: dartRevision,
        );
        dartDartPadSdk = p.join(tempDir.path, 'dart_dartpad_sdk');
        print(
          'Downloading matching dartpad.zip for Flutter Dart SDK '
          '$dartVersion ($dartRevision on channel $dartChannel)...',
        );
        await downloadAndExtractDartPadZip(zipUrl, dartDartPadSdk);
      }

      final dartBin = p.join(
        dartSdkRoot,
        'bin',
        Platform.isWindows ? 'dart.exe' : 'dart',
      );
      final dartAotRuntimeBin = p.join(
        dartSdkRoot,
        'bin',
        Platform.isWindows ? 'dartaotruntime.exe' : 'dartaotruntime',
      );

      final packageRoot = await _resolveDartPadPackageRoot();
      final assetDir = p.join(packageRoot, 'asset');

      await _buildFlutterDartPadSdk(
        _BuildContext(
          dartSdkRoot: dartSdkRoot,
          dartDartPadSdk: dartDartPadSdk,
          flutterRoot: flutterRoot,
          tempDir: tempDir.path,
          myappDir: myappDir,
          flutterBin: flutterBin,
          dartBin: dartBin,
          dartAotRuntimeBin: dartAotRuntimeBin,
          flutterAssetDir: outputDir,
          assetDir: assetDir,
          bootstrapCode: bootstrapCode,
          buildWebSdk: webSdkOption == 'build',
          useCdn: useCdn,
        ),
      );
    } finally {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    }
  }
}

/// Infers the `gs://dart-archive` channel (`main`, `dev`, `beta`, `stable`)
/// from a Dart SDK version string (e.g. from `bin/cache/dart-sdk/version`).
String inferDartChannelFromVersion(String version) {
  final v = version.trim();
  if (v.contains('-edge.')) return 'main';
  if (v.endsWith('.dev')) return 'dev';
  if (v.endsWith('.beta')) return 'beta';
  return 'stable';
}

final class _BuildContext {
  final String dartSdkRoot;
  final String dartDartPadSdk;
  final String flutterRoot;
  final String tempDir;
  final String myappDir;
  final String flutterBin;
  final String dartBin;
  final String dartAotRuntimeBin;
  final String flutterAssetDir;
  final String assetDir;
  final String? bootstrapCode;
  final bool buildWebSdk;
  final bool useCdn;

  _BuildContext({
    required this.dartSdkRoot,
    required this.dartDartPadSdk,
    required this.flutterRoot,
    required this.tempDir,
    required this.myappDir,
    required this.flutterBin,
    required this.dartBin,
    required this.dartAotRuntimeBin,
    required this.flutterAssetDir,
    required this.assetDir,
    required this.bootstrapCode,
    required this.buildWebSdk,
    required this.useCdn,
  });
}

Future<void> _buildFlutterDartPadSdk(_BuildContext ctx) async {
  Directory(ctx.flutterAssetDir).createSync(recursive: true);

  // 2. Scrape Assets (CanvasKit, Fonts)
  print('Scraping assets...');
  final sourceAssetsDir = p.join(ctx.myappDir, 'build', 'web', 'assets');
  copyDirectoryContents(sourceAssetsDir, p.join(ctx.flutterAssetDir, 'assets'));

  print('Copying flutter.js');
  _copyFile(
    p.join(ctx.myappDir, 'build', 'web', 'flutter.js'),
    p.join(ctx.flutterAssetDir, 'flutter.js'),
  );

  final String canvasKitBaseUrl;
  if (ctx.useCdn) {
    canvasKitBaseUrl = await _resolveAndVerifyCanvasKitCdnUrl(
      ctx.flutterRoot,
      ctx.myappDir,
    );
  } else {
    print('Scraping CanvasKit...');
    final sourceCanvasKitDir = p.join(
      ctx.myappDir,
      'build',
      'web',
      'canvaskit',
    );
    final destCanvasKitDir = p.join(ctx.flutterAssetDir, 'canvaskit');
    copyDirectoryContents(sourceCanvasKitDir, destCanvasKitDir);
    _verifyLocalCanvasKitFiles(destCanvasKitDir);
    canvasKitBaseUrl = './canvaskit/';
  }

  // 3. Compile flutter_web.js and flutter_web.dill
  print('Compiling flutter_web.js and flutter_web.dill...');
  final pkgConfigPath = p.join(
    ctx.myappDir,
    '.dart_tool',
    'package_config.json',
  );
  final pkgConfig =
      jsonDecode(File(pkgConfigPath).readAsStringSync())
          as Map<String, dynamic>;

  final compileSources = <String>[];
  final packageRootPaths = <String, String>{};
  for (final pkgEntry in pkgConfig['packages'] as List<dynamic>) {
    final pkg = pkgEntry as Map<String, dynamic>;
    final name = pkg['name'] as String;
    if (name == 'sky_engine' || name == 'myapp') continue;

    final rootUriStr = pkg['rootUri'] as String;
    final rootUri = Uri.parse(rootUriStr);
    final rootPath = rootUri.scheme == 'file'
        ? rootUri.toFilePath()
        : p.normalize(p.join(ctx.myappDir, '.dart_tool', rootUriStr));
    packageRootPaths[name] = rootPath;

    final libDir = Directory(p.join(rootPath, pkg['packageUri'] as String));
    if (libDir.existsSync()) {
      final topLevelFiles = libDir
          .listSync(recursive: false)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));
      for (final file in topLevelFiles) {
        final relative = p.relative(file.path, from: libDir.path);
        if (name == 'matcher' && relative == 'mirror_matchers.dart') {
          continue;
        }
        compileSources.add('package:$name/${p.toUri(relative).path}');
      }
    }
  }

  final webSdk = ctx.buildWebSdk
      ? _buildWebSdk(ctx, pkgConfigPath)
      : _copyWebSdk(ctx);

  final snapshotPath = p.join(
    ctx.dartSdkRoot,
    'bin',
    'snapshots',
    'dartdevc.dart.snapshot',
  );
  final outlinePath = webSdk.outlineDill;
  final outputJsPath = p.join(ctx.flutterAssetDir, 'flutter_web.js');
  final outputDillPath = p.join(ctx.tempDir, 'flutter_web.dill');

  _runSync(ctx.dartBin, [
    snapshotPath,
    '-s',
    outlinePath,
    '--modules=ddc',
    '--canary',
    '--track-creation-locations',
    '--module-name=flutter_web',
    '--packages=$pkgConfigPath',
    '-o',
    outputJsPath,
    ...compileSources,
  ], ctx.myappDir);

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
    '--track-creation-locations',
    '--packages-file',
    pkgConfigPath,
    '--dart-sdk-summary',
    outlinePath,
    '--output',
    outputDillPath,
    ...compileSources.expand((s) => ['--source', s]),
  ], ctx.myappDir);

  print('Copying dart_sdk.js...');
  _copyFile(webSdk.dartSdkJs, p.join(ctx.flutterAssetDir, 'dart_sdk.js'));
  _copyFile(
    '${webSdk.dartSdkJs}.map',
    p.join(ctx.flutterAssetDir, 'dart_sdk.js.map'),
  );

  // Synthesize sandbox.js
  print('Synthesizing sandbox.js...');
  final sandboxJsPatch = File(
    p.join(ctx.assetDir, 'sandbox_flutter_patch.js'),
  ).readAsStringSync().replaceAll('{{canvasKitBaseUrl}}', canvasKitBaseUrl);
  final sandboxJs = File(
    p.join(ctx.dartDartPadSdk, 'sandbox.js'),
  ).readAsStringSync();
  File(
    p.join(ctx.flutterAssetDir, 'sandbox.js'),
  ).writeAsStringSync('$sandboxJsPatch\n$sandboxJs');

  // Copy worker from Dart DartPad SDK.
  print('Copying worker...');
  for (final f in [
    'dart_stack_trace_mapper.js',
    'ddc_module_loader.js',
    'worker.js',
    'worker.mjs',
    'worker.support.js',
    'worker.wasm',
    'worker.wasm.map',
  ]) {
    _copyFile(p.join(ctx.dartDartPadSdk, f), p.join(ctx.flutterAssetDir, f));
  }

  // Extract exact hosted package versions from `flutter pub deps --json`
  final depsJson = _runSync(ctx.flutterBin, [
    'pub',
    'deps',
    '--json',
  ], ctx.myappDir);

  // 4. Create sdk.tar
  print('Building sdk.tar...');
  final tar = tarWritingSink(
    File(p.join(ctx.flutterAssetDir, 'sdk.tar')).openWrite(),
  );

  final defaultBootstrapCode = File(
    p.join(ctx.assetDir, 'bootstrap_flutter.dart.tmpl'),
  ).readAsStringSync();

  tar.addJsonFile(
    target: DartPadConfig.defaultDartPadConfigPath,
    json: DartPadConfig(
      dartSdkPath: '/sdk/bin/cache/dart-sdk',
      flutterSdkPath: '/sdk',
      summaryModules: {
        '/sdk/bin/cache/flutter_web_sdk/kernel/flutter_web.dill': 'flutter_web',
      },
      modes: [
        DartPadRunMode(mode: 'console'),
        DartPadRunMode(
          mode: 'flutter',
          entrypointWrapperTemplate: ctx.bootstrapCode ?? defaultBootstrapCode,
        ),
      ],
      trackCreationLocations: true,
    ),
  );

  print('Adding Dart SDK lib...');
  // Note: `lib/_internal/js_runtime/` MUST be retained because
  // `sdk/lib/_internal/sdk_library_metadata/lib/libraries.dart` maps
  // `dart:_interceptors`, `dart:_native_typed_data`, and `dart:_js_helper`
  // (used by `dart:js_interop` and `dart:html` in `FolderBasedDartSdk`)
  // to `_internal/js_runtime/lib/...`. Conversely, `js_dev_runtime/` has
  // zero entries in `libraries.dart` and DDC uses `ddc_outline.dill`.
  const excludedInternalDirs = [
    '_internal/vm/',
    '_internal/vm_shared/',
    '_internal/wasm/',
    '_internal/js_dev_runtime/',
  ];
  tar.addDirectory(
    target: '/sdk/bin/cache/dart-sdk/lib',
    source: p.join(webSdk.dartSdkRoot, 'lib'),
    where: (f) {
      if (excludedInternalDirs.any(f.startsWith)) return false;
      return (f.endsWith('.dart') ||
              f.endsWith('.json') ||
              f.contains('_internal/')) &&
          !f.endsWith('.dill');
    },
  );

  print('Adding version and libraries');
  tar.addFile(
    target: '/sdk/bin/cache/flutter.version.json',
    source: p.join(ctx.flutterRoot, 'bin/cache/flutter.version.json'),
  );
  tar.addFile(
    target: '/sdk/bin/cache/libraries.json',
    source: p.join(webSdk.dartSdkRoot, 'lib', 'libraries.json'),
  );
  tar.addFile(
    target: '/sdk/bin/cache/dart-sdk/version',
    source: p.join(webSdk.dartSdkRoot, 'version'),
  );

  // Add the ddc_outline.dill which contains dart:ui
  tar.addFile(
    target: '/sdk/bin/cache/dart-sdk/lib/_internal/ddc_outline.dill',
    source: webSdk.outlineDill,
  );

  // Add the framework outline dill we just built
  tar.addFile(
    target: '/sdk/bin/cache/flutter_web_sdk/kernel/flutter_web.dill',
    source: outputDillPath,
  );

  for (final pkg in [
    'flutter',
    'flutter_web_plugins',
    'flutter_localizations',
    'flutter_test',
    'integration_test',
    'flutter_driver',
    'fuchsia_remote_debug_protocol',
  ]) {
    print('Adding package:$pkg for analysis...');
    tar.addDirectory(
      target: '/sdk/packages/$pkg',
      source: p.join(ctx.flutterRoot, 'packages', pkg),
      where: (f) =>
          !f.startsWith('test/') &&
          !f.endsWith('.arb') &&
          ((pkg != 'flutter' && f == 'pubspec.yaml') || f.startsWith('lib/')),
    );
  }

  // Pin all hosted dependencies baked into `flutter_web.dill` (including
  // `material_ui` and `cupertino_ui`) in `/sdk/packages/flutter/pubspec.yaml`
  // so `pub get` in the worker resolves the exact precompiled versions, and
  // pre-populate `/pub-cache` so `package:pub` does not need to download them.
  final hostedVersions = _extractHostedPackageVersions(depsJson);
  for (final MapEntry(key: name, value: version) in hostedVersions.entries) {
    final rootPath = packageRootPaths[name];
    if (rootPath == null) {
      throw StateError(
        'Missing package_config.json rootPath for hosted package $name',
      );
    }
    final pubCacheRoot = p.dirname(p.dirname(p.dirname(rootPath)));
    final hashFile = p.join(
      pubCacheRoot,
      'hosted-hashes',
      'pub.dev',
      '$name-$version.sha256',
    );
    if (!File(hashFile).existsSync()) {
      throw StateError('Missing pub cache hash file at $hashFile');
    }
    print('Pre-populating /pub-cache with package:$name ($version)...');
    tar.addDirectory(
      target: '/pub-cache/hosted/pub.dev/$name-$version',
      source: rootPath,
      where: (f) =>
          f == 'pubspec.yaml' || (f.startsWith('lib/') && f.endsWith('.dart')),
    );
    tar.addFile(
      target: '/pub-cache/hosted-hashes/pub.dev/$name-$version.sha256',
      source: hashFile,
    );
  }
  final flutterPubspec = _yamlToJson(
    File(
      p.join(ctx.flutterRoot, 'packages', 'flutter', 'pubspec.yaml'),
    ).readAsStringSync(),
  );
  flutterPubspec['dependencies'] = {
    ...(flutterPubspec['dependencies'] as Map<String, Object?>? ?? {}),
    ...hostedVersions,
  };
  tar.addJsonFile(
    target: '/sdk/packages/flutter/pubspec.yaml',
    json: flutterPubspec,
  );

  // Add sky_engine
  tar.addDirectory(
    target: '/sdk/bin/cache/pkg/sky_engine',
    source: p.join(ctx.flutterRoot, 'bin/cache/pkg/sky_engine'),
    where: (f) => f.endsWith('pubspec.yaml') || f.startsWith('lib/'),
  );

  await tar.close();

  print('\nSuccessfully built Flutter DartPad SDK in ${ctx.flutterAssetDir}');
}

final class _WebSdk {
  final String outlineDill;
  final String dartSdkJs;
  final String dartSdkRoot;

  _WebSdk({
    required this.outlineDill,
    required this.dartSdkJs,
    required this.dartSdkRoot,
  });
}

_WebSdk _copyWebSdk(_BuildContext ctx) {
  final kernel = p.join(
    ctx.flutterRoot,
    'bin',
    'cache',
    'flutter_web_sdk',
    'kernel',
  );
  return _WebSdk(
    outlineDill: p.join(kernel, 'ddc_outline.dill'),
    dartSdkJs: p.join(kernel, 'ddcLibraryBundle-canvaskit', 'dart_sdk.js'),
    dartSdkRoot: p.join(ctx.flutterRoot, 'bin', 'cache', 'dart-sdk'),
  );
}

_WebSdk _buildWebSdk(_BuildContext ctx, String pkgConfigPath) {
  print('Building web SDK...');
  final flutterWebSdk = p.join(
    ctx.flutterRoot,
    'bin',
    'cache',
    'flutter_web_sdk',
  );
  final outputDir = p.join(ctx.tempDir, 'websdk');
  Directory(outputDir).createSync(recursive: true);

  final flutterLibSpec = jsonDecode(
    File(p.join(flutterWebSdk, 'libraries.json')).readAsStringSync(),
  );
  final flutterLibraries =
      ((flutterLibSpec as Map)['dartdevc'] as Map)['libraries'] as Map;
  File(p.join(outputDir, 'dartpad_libraries.json')).writeAsStringSync(
    jsonEncode({
      'dartdevc': {
        'include': [
          {'path': 'lib/libraries.json', 'target': 'dartdevc'},
        ],
        'libraries': flutterLibraries,
      },
    }),
  );

  final libraries = [
    'dart:core',
    ...flutterLibraries.keys.map((library) => 'dart:$library'),
  ];

  final fileSystem = [
    '--multi-root=$outputDir${p.separator}',
    '--multi-root=${ctx.dartSdkRoot}${p.separator}',
    '--multi-root=$flutterWebSdk${p.separator}',
    '--multi-root-scheme=org-dartlang-sdk',
    '--libraries-file=org-dartlang-sdk:///dartpad_libraries.json',
  ];

  final outlineDill = p.join(outputDir, 'ddc_outline.dill');
  _runSync(ctx.dartAotRuntimeBin, [
    p.join(
      ctx.dartSdkRoot,
      'bin',
      'snapshots',
      'kernel_worker_aot.dart.snapshot',
    ),
    '--target=ddc',
    '--summary-only',
    '--include-unsupported-platform-library-stubs',
    ...fileSystem,
    '--packages-file=$pkgConfigPath',
    '--output=$outlineDill',
    ...libraries.expand((library) => ['--source', library]),
  ], ctx.tempDir);

  final dartSdkJs = p.join(outputDir, 'dart_sdk.js');
  _runSync(ctx.dartBin, [
    p.join(ctx.dartSdkRoot, 'bin', 'snapshots', 'dartdevc.dart.snapshot'),
    '--compile-sdk',
    '--modules=ddc',
    '--canary',
    '--no-summarize',
    '-DFLUTTER_WEB_USE_SKIA=true',
    ...fileSystem,
    '--packages=$pkgConfigPath',
    '-o',
    dartSdkJs,
    ...libraries,
  ], ctx.tempDir);

  return _WebSdk(
    outlineDill: outlineDill,
    dartSdkJs: dartSdkJs,
    dartSdkRoot: ctx.dartSdkRoot,
  );
}

String _runSync(String command, List<String> args, String workingDir) {
  final result = Process.runSync(command, args, workingDirectory: workingDir);
  if (result.exitCode != 0) {
    print('Command failed: $command ${args.join(' ')}');
    print('stdout: ${result.stdout}');
    print('stderr: ${result.stderr}');
    throw StateError('Command failed: $command');
  }
  return result.stdout.toString();
}

void _copyFile(String source, String dest) => File(source).copySync(dest);

Map<String, String> _extractHostedPackageVersions(String depsJson) {
  final data = jsonDecode(depsJson) as Map<String, Object?>;
  final packages = data['packages'] as List<Object?>;
  return {
    for (final pkg in packages)
      if (pkg is Map && pkg['source'] == 'hosted')
        pkg['name'] as String: pkg['version'] as String,
  };
}

Map<String, Object?> _yamlToJson(String yamlString) =>
    jsonDecode(jsonEncode(loadYaml(yamlString))) as Map<String, Object?>;

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
      final relative = p.posix.joinAll(
        p.split(p.relative(f.path, from: source)),
      );
      if (where != null && !where(relative)) continue;
      add(
        TarEntry.data(
          TarHeader(name: p.posix.join(target, relative), mode: 420),
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
    throw StateError('Flutter not found in PATH');
  }
  return result.stdout.toString().split('\n').first.trim();
}

Future<String> _resolveDartPadPackageRoot() async {
  final uri = await Isolate.resolvePackageUri(
    Uri.parse('package:dartpad/dartpad.dart'),
  );
  if (uri == null) {
    throw StateError('Unable to resolve package:dartpad.');
  }
  return p.dirname(p.dirname(p.fromUri(uri)));
}

const _kRequiredCanvasKitFiles = [
  'canvaskit.js',
  'canvaskit.wasm',
  'chromium/canvaskit.js',
  'chromium/canvaskit.wasm',
];

void _verifyLocalCanvasKitFiles(String canvasKitDir) {
  for (final relPath in _kRequiredCanvasKitFiles) {
    final file = File(p.joinAll([canvasKitDir, ...relPath.split('/')]));
    if (!file.existsSync() || file.lengthSync() == 0) {
      throw StateError('Missing or empty local CanvasKit file: ${file.path}');
    }
  }
}

Future<String> _resolveAndVerifyCanvasKitCdnUrl(
  String flutterRoot,
  String myappDir,
) async {
  final versionFile = File(
    p.join(flutterRoot, 'bin', 'cache', 'flutter.version.json'),
  );
  if (!versionFile.existsSync()) {
    throw StateError('Missing ${versionFile.path}');
  }
  final versionJson =
      jsonDecode(versionFile.readAsStringSync()) as Map<String, Object?>;
  final engineRevision = versionJson['engineRevision'] as String?;
  if (engineRevision == null ||
      !RegExp(r'^[0-9a-f]{40}$').hasMatch(engineRevision)) {
    throw StateError(
      'Invalid or missing engineRevision in ${versionFile.path}: '
      '$engineRevision',
    );
  }

  // Cross-check against build/web/flutter_bootstrap.js generated by
  // `flutter build web` to ensure flutter_tools agrees on engineRevision.
  final bootstrapFile = File(
    p.join(myappDir, 'build', 'web', 'flutter_bootstrap.js'),
  );
  if (bootstrapFile.existsSync()) {
    final bootstrapContent = bootstrapFile.readAsStringSync();
    final match = RegExp(
      r'"engineRevision"\s*:\s*"([0-9a-f]{40})"',
    ).firstMatch(bootstrapContent);
    if (match != null && match.group(1) != engineRevision) {
      throw StateError(
        'Engine revision mismatch between flutter.version.json '
        '($engineRevision) and flutter_bootstrap.js (${match.group(1)})',
      );
    }
  }

  final baseUrl = 'https://www.gstatic.com/flutter-canvaskit/$engineRevision/';
  print('Verifying CanvasKit CDN resources at $baseUrl...');
  final client = http.Client();
  try {
    for (final relPath in _kRequiredCanvasKitFiles) {
      final uri = Uri.parse('$baseUrl$relPath');
      final response = await client.head(uri);
      final contentLength = int.tryParse(
        response.headers['content-length'] ?? '',
      );
      if (response.statusCode != 200 ||
          (contentLength != null && contentLength <= 0)) {
        throw StateError(
          'CanvasKit CDN verification failed for $uri '
          '(HTTP ${response.statusCode}, content-length: $contentLength). '
          'Pass --no-use-cdn to bundle local CanvasKit files instead.',
        );
      }
    }
  } finally {
    client.close();
  }
  return baseUrl;
}
