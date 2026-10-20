// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'shared.dart';

/// Holds cached compiled SDKs (relative to the current directory).
final _cacheDir = p.join('.dart_tool', 'frontend_server_client', 'sdk');

/// Folders in [_cacheDir] that hold the outputs of an in-progress compile.
const _tmpPrefix = 'tmp_';

/// The platform that `dart_sdk.js` is compiled from.
File _platformDill(String sdk) =>
    File(p.join(sdk, 'lib', '_internal', 'ddc_platform.dill'));

/// The compiler that compiles `dart_sdk.js`.
File _ddcSnapshot(String sdk) =>
    File(p.join(sdk, 'bin', 'snapshots', 'dartdevc_aot.dart.snapshot'));

/// The SDK scripts loaded by a DDC library bundle app.
///
/// See `generateDdcLibraryBundleBootstrapScript`.
class DdcLibraryBundleSdkAssets {
  /// `ddc_module_loader.js`
  final Uint8List moduleLoader;

  /// `dart_stack_trace_mapper.js`
  final Uint8List stackTraceMapper;

  /// `dart_sdk.js`
  final Uint8List sdkJs;

  /// [sdkJs]'s source map.
  final Uint8List sdkJsMap;

  DdcLibraryBundleSdkAssets._(
    this.moduleLoader,
    this.stackTraceMapper,
    this.sdkJs,
    this.sdkJsMap,
  );

  /// Loads the SDK scripts for an app compiled by the frontend server of the
  /// SDK at [sdkRoot].
  ///
  /// [sdkRoot] defaults to the SDK running this process, so pass it when
  /// running as a compiled executable. It must be the SDK that
  /// `DartDevcFrontendServerClient.start` uses, started with
  /// `dartdevcModuleFormat: 'ddc'` and `canaryFeatures: true`.
  ///
  /// Reads `dart_sdk.js` from [sdkJsPath] if given. It must be compiled by
  /// [sdkRoot]'s DDC with `--modules=ddc --canary`, with its source map at
  /// `<sdkJsPath>.map`. Otherwise compiles `dart_sdk.js` and caches it in
  /// `.dart_tool/frontend_server_client/sdk` of the current directory, which
  /// should be the package root.
  ///
  /// Only checks that [sdkJsPath] and its source map exist. Scripts from a
  /// different SDK build, even one with the same version, can break the app in
  /// the browser. See the package README for all requirements.
  static Future<DdcLibraryBundleSdkAssets> load({
    String? sdkJsPath,
    String? sdkRoot,
  }) async {
    final sdk = sdkRoot ?? sdkDir;
    final devCompilerDir = p.join(sdk, 'lib', 'dev_compiler');
    final sdkJsFile = sdkJsPath != null
        ? _checkProvidedSdkJs(sdkJsPath)
        : await _cachedSdkJs(sdk);
    return DdcLibraryBundleSdkAssets._(
      await File(
        p.join(devCompilerDir, 'ddc', 'ddc_module_loader.js'),
      ).readAsBytes(),
      await File(
        p.join(devCompilerDir, 'web', 'dart_stack_trace_mapper.js'),
      ).readAsBytes(),
      await sdkJsFile.readAsBytes(),
      await File('${sdkJsFile.path}.map').readAsBytes(),
    );
  }

  /// Returns [sdkJsPath]'s file after validating that it and its sourcemap
  /// exist.
  static File _checkProvidedSdkJs(String sdkJsPath) {
    for (final path in [sdkJsPath, '$sdkJsPath.map']) {
      if (!File(path).existsSync()) {
        throw ArgumentError.value(
          sdkJsPath,
          'sdkJsPath',
          '$path does not exist',
        );
      }
    }
    return File(sdkJsPath);
  }

  /// Returns [sdk]'s cached `dart_sdk.js`, compiling it if it isn't cached.
  ///
  /// Also deletes previous SDK caches to save disk space.
  static Future<File> _cachedSdkJs(String sdk) async {
    final sdkJs = await _cacheLocation(sdk);
    if (sdkJs.existsSync() && File('${sdkJs.path}.map').existsSync()) {
      return sdkJs;
    }
    await Directory(_cacheDir).create(recursive: true);
    final tempDir = await Directory(_cacheDir).createTemp(_tmpPrefix);
    try {
      await _addToCache(await _compileSdkJs(sdk, tempDir), sdkJs);
    } finally {
      await tempDir.delete(recursive: true);
    }
    _deleteOtherCachedSdks(sdkJs.parent);
    return sdkJs;
  }

  /// Returns the location of [sdk]'s cached `dart_sdk.js` (even if it does not
  /// yet exist).
  static Future<File> _cacheLocation(String sdk) async {
    final version = (await File(p.join(sdk, 'version')).readAsString()).trim();
    // Local builds of the SDK can change the platform or compiler without
    // changing version.
    final platformModified = await _platformDill(sdk).lastModified();
    final compilerModified = await _ddcSnapshot(sdk).lastModified();
    return File(
      p.join(
        _cacheDir,
        '$version-${platformModified.millisecondsSinceEpoch}-'
            '${compilerModified.millisecondsSinceEpoch}',
        'dart_sdk.js',
      ),
    );
  }

  /// Compiles [sdk]'s `dart_sdk.js` and its source map into [outDir].
  static Future<File> _compileSdkJs(String sdk, Directory outDir) async {
    final sdkJs = File(p.join(outDir.path, 'dart_sdk.js'));
    final result = await Process.run(
      p.join(
        sdk,
        'bin',
        Platform.isWindows ? 'dartaotruntime.exe' : 'dartaotruntime',
      ),
      [
        _ddcSnapshot(sdk).path,
        '--multi-root-scheme=org-dartlang-sdk',
        '--modules=ddc',
        '--canary',
        '--module-name=dart_sdk',
        '-o',
        sdkJs.path,
        _platformDill(sdk).path,
      ],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    if (result.exitCode != 0) {
      throw StateError(
        'Failed to compile the Dart SDK:\n'
        '${result.stdout}\n${result.stderr}',
      );
    }
    return sdkJs;
  }

  /// Moves [compiled] JS and its source map to [cached].
  static Future<void> _addToCache(File compiled, File cached) async {
    await cached.parent.create(recursive: true);
    // Move the source map first so it exists when the JS file does.
    await File('${compiled.path}.map').rename('${cached.path}.map');
    await compiled.rename(cached.path);
  }

  /// Deletes cached SDKs other than [sdkPathToKeep], skipping in-progress
  /// compiles.
  static void _deleteOtherCachedSdks(Directory sdkPathToKeep) {
    for (final entry in Directory(_cacheDir).listSync()) {
      if (entry is Directory &&
          entry.path != sdkPathToKeep.path &&
          !p.basename(entry.path).startsWith(_tmpPrefix)) {
        try {
          entry.deleteSync(recursive: true);
        } on FileSystemException {
          // May be in use by another process.
        }
      }
    }
  }
}
