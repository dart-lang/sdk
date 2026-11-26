// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:dartdev/src/web/project.dart';
import 'package:dartdev/src/web/serve/web_compiler.dart';
import 'package:frontend_server_client/frontend_server_client.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

/// The scheme of the compiler's virtual file system, whose root is the
/// package root.
///
/// The compiler knows `web/main.dart` as `org-dartlang-app:///web/main.dart`,
/// and names its module `web/main.dart`, served at `/web/main.dart.lib.js`.
/// DWDS maps `org-dartlang-app` URIs to server paths the same way.
const appScheme = 'org-dartlang-app';

/// Compiles a [WebProject] to JavaScript with the frontend server, in DDC's
/// library bundle format, and keeps the output in memory.
///
/// Each Dart library becomes one JavaScript module, served at
/// `<library path>.lib.js` (for example `web/main.dart.lib.js` and
/// `packages/<package>/<library>.dart.lib.js`), with a source map and debug
/// metadata next to it.
class DdcCompiler implements WebCompiler {
  @override
  final WebProject project;

  /// The root directory of the Dart SDK compiling [project].
  final String sdkRoot;

  final Directory _outputDirectory;
  final DartDevcFrontendServerClient _client;

  DdcCompiler._(
    this.project,
    this.sdkRoot,
    this._outputDirectory,
    this._client,
  );

  /// The temporary directory where the frontend server writes its output files
  /// for this session.
  @visibleForTesting
  String get outputDirectoryPath => _outputDirectory.path;

  /// Starts the frontend server for [project].
  ///
  /// [sdkRoot] is the SDK whose frontend server and DDC platform are used. It
  /// defaults to the SDK running this process, so pass it when running as an
  /// AOT-compiled program (like dartdev).
  static Future<DdcCompiler> start(
    WebProject project, {
    String? sdkRoot,
  }) async {
    final resolvedSdkRoot =
        sdkRoot ?? p.dirname(p.dirname(Platform.resolvedExecutable));
    // Fail now, with a message that names the problem, if this isn't a Dart
    // SDK (for example, an AOT-compiled program that didn't pass [sdkRoot]
    // gets the directory above its own `bin/`). A Dart SDK keeps its tools,
    // such as the frontend server started below, in `bin/snapshots`.
    if (!Directory(p.join(resolvedSdkRoot, 'bin', 'snapshots')).existsSync()) {
      throw ArgumentError.value(
        resolvedSdkRoot,
        'sdkRoot',
        'Not the root directory of a Dart SDK',
      );
    }
    // The frontend server writes its output files here before the client reads
    // them into memory. Each session gets its own directory so concurrent runs
    // and different entrypoints don't share an app.dill.
    // TODO(https://github.com/dart-lang/sdk/issues/64675): Replace with a
    // keyed cache directory under .dart_tool/dart_web/ for warm start.
    final outputDirectory = await Directory.systemTemp.createTemp(
      'dart_serve_',
    );
    try {
      final client = await DartDevcFrontendServerClient.start(
        _entrypointUri(project),
        p.join(outputDirectory.path, 'app.dill'),
        // DDC's library bundle format, which supports hot reload.
        dartdevcModuleFormat: 'ddc',
        canaryFeatures: true,
        // The package root is the virtual file system's root (see appScheme).
        fileSystemRoots: [project.packageRoot],
        fileSystemScheme: appScheme,
        packagesJson: project.packageConfigPath,
        sdkRoot: resolvedSdkRoot,
      );
      return DdcCompiler._(project, resolvedSdkRoot, outputDirectory, client);
    } catch (_) {
      await _deleteDirectory(outputDirectory);
      rethrow;
    }
  }

  /// The compiler's URI for the app's entrypoint, such as
  /// `org-dartlang-app:///web/main.dart`.
  String get entrypointUri => _entrypointUri(project);

  static String _entrypointUri(WebProject project) => Uri(
    scheme: appScheme,
    host: '',
    pathSegments: p.url.split(project.entrypoint),
  ).toString();

  /// Compiles the whole app.
  ///
  /// Can only be called once, for the first compile.
  ///
  /// Returns the compile errors, or an empty list if there are none. The
  /// output is kept even with errors, so the app can still be served (DDC
  /// turns most errors into exceptions thrown at runtime), and so that later
  /// incremental compiles start from it.
  // TODO(https://github.com/dart-lang/sdk/issues/64664): Support recompiling
  // changed files.
  @override
  Future<List<String>> compile() async {
    final result = await _client.compile();
    _client.accept();
    return result.errorCount == 0
        ? const []
        : result.compilerOutputLines.toList();
  }

  /// The compiled file at the URL [path] (without a leading `/`), such as
  /// `web/main.dart.lib.js` or its `.map` or `.metadata` file, or `null` if
  /// there is none.
  @override
  Uint8List? compiledFile(String path) => _client.assetBytes('/$path');

  /// The debug metadata of every module, one JSON object per line.
  ///
  /// Lists each module's name and URL, which `DdcAssets` uses to load the
  /// app's modules.
  String get mergedMetadata => _client.mergedMetadata;

  /// Stops the frontend server and deletes its temporary output directory.
  @override
  Future<void> shutdown() async {
    try {
      await _client.shutdown();
    } finally {
      await _deleteDirectory(_outputDirectory);
    }
  }

  static Future<void> _deleteDirectory(Directory directory) async {
    try {
      await directory.delete(recursive: true);
    } on FileSystemException {
      // Ignore if the directory was already removed.
    }
  }
}
