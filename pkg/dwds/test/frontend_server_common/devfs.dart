// Copyright 2020 The Dart Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Note: this is a copy from flutter tools, updated to work with dwds tests

import 'dart:convert';
import 'dart:io';

import 'package:dwds/asset_reader.dart';
import 'package:dwds/config.dart';
import 'package:dwds/expression_compiler.dart';
// ignore: implementation_imports
import 'package:dwds/src/debugging/metadata/module_metadata.dart';
import 'package:dwds/utilities.dart';
import 'package:dwds_test_common/test_sdk_layout.dart';
import 'package:file/file.dart';
import 'package:path/path.dart' as p;

import 'asset_server.dart';
import 'bootstrap.dart';
import 'frontend_server_client.dart';

class WebDevFS {
  WebDevFS({
    required this.fileSystem,
    required this.hostname,
    required this.port,
    required this.projectDirectory,
    required this.packageUriMapper,
    required this.index,
    this.urlTunneler,
    required this.sdkLayout,
    required this.compilerOptions,
  });

  final FileSystem fileSystem;
  late final TestAssetServer assetServer;
  final String hostname;
  final int port;
  final Uri projectDirectory;
  final PackageUriMapper packageUriMapper;
  final String index;
  final UrlEncoder? urlTunneler;
  List<Uri> sources = <Uri>[];
  DateTime? lastCompiled;

  final TestSdkLayout sdkLayout;
  final CompilerOptions compilerOptions;

  Future<Uri> create() async {
    assetServer = await TestAssetServer.start(
      sdkLayout.sdkDirectory,
      projectDirectory,
      fileSystem,
      index,
      hostname,
      port,
      urlTunneler,
      packageUriMapper,
    );
    return Uri.parse('http://$hostname:$port');
  }

  Future<void> dispose() {
    return assetServer.close();
  }

  Future<UpdateFSReport> update({
    required Uri mainUri,
    required String dillOutputPath,
    required ResidentCompiler generator,
    required List<Uri> invalidatedFiles,
    required bool initialCompile,
    required bool fullRestart,
    // The uri of the `HttpServer` that handles file requests.
    // TODO(srujzs): This should be the same as the uri of the AssetServer to
    // align with Flutter tools, but currently is not. Delete when that's fixed.
    required Uri? fileServerUri,
  }) async {
    final mainPath = mainUri.toFilePath();
    final outputDirectory = fileSystem.directory(
      fileSystem.file(projectDirectory.resolve(mainPath)).parent.path,
    );
    final entryPoint = mainUri.toString();

    var prefix = '';
    // If base path is not overwritten, use main's subdirectory
    // to store all files, so the paths match the requests.
    if (assetServer.basePath.isEmpty) {
      final directory = p.dirname(entryPoint);
      prefix = '$directory/';
    }

    if (initialCompile) {
      final ddcModuleLoader = '${prefix}ddc_module_loader.js';
      final require = '${prefix}require.js';
      final stackMapper = '${prefix}stack_trace_mapper.js';
      final main = '${prefix}main.dart.js';
      final bootstrap = '${prefix}main_module.bootstrap.js';

      assetServer.writeFile(
        entryPoint,
        fileSystem.file(projectDirectory.resolve(mainPath)).readAsStringSync(),
      );
      assetServer.writeFile(stackMapper, stackTraceMapper.readAsStringSync());

      switch (ddcModuleFormat) {
        case ModuleFormat.amd:
          assetServer.writeFile(require, requireJS.readAsStringSync());
          assetServer.writeFile(
            main,
            generateBootstrapScript(
              requireUrl: 'require.js',
              mapperUrl: 'stack_trace_mapper.js',
              entrypoint: entryPoint,
            ),
          );
          assetServer.writeFile(
            bootstrap,
            generateMainModule(entrypoint: entryPoint),
          );
          break;
        case ModuleFormat.ddc:
          assetServer.writeFile(
            ddcModuleLoader,
            ddcModuleLoaderJS.readAsStringSync(),
          );
          String bootstrapper;
          String mainModule;
          if (compilerOptions.canaryFeatures) {
            bootstrapper = generateDDCLibraryBundleBootstrapScript(
              ddcModuleLoaderUrl: ddcModuleLoader,
              mapperUrl: stackMapper,
              entrypoint: entryPoint,
              bootstrapUrl: bootstrap,
            );
            const onLoadEndBootstrap = 'on_load_end_bootstrap.js';
            assetServer.writeFile(
              onLoadEndBootstrap,
              generateDDCLibraryBundleOnLoadEndBootstrap(),
            );
            mainModule = generateDDCLibraryBundleMainModule(
              entrypoint: entryPoint,
              onLoadEndBootstrap: onLoadEndBootstrap,
            );
          } else {
            bootstrapper = generateDDCBootstrapScript(
              ddcModuleLoaderUrl: ddcModuleLoader,
              mapperUrl: stackMapper,
              entrypoint: entryPoint,
              bootstrapUrl: bootstrap,
            );

            // DDC uses a simple heuristic to determine exported identifier
            // names. The module name (entrypoint name here) has its extension
            // removed, and special path elements like '/', '\', and '..' are
            // replaced with
            // '__'.
            final exportedMainName = pathToJSIdentifier(
              entryPoint.split('.')[0],
            );
            mainModule = generateDDCMainModule(
              entrypoint: entryPoint,
              exportedMain: exportedMainName,
            );
          }
          assetServer.writeFile(main, bootstrapper);
          assetServer.writeFile(bootstrap, mainModule);
          break;
        default:
          throw Exception('Unsupported DDC module format $ddcModuleFormat.');
      }

      assetServer.writeFile('main_module.digests', '{}');

      final sdk = dartSdk;
      final sdkSourceMap = dartSdkSourcemap;
      assetServer.writeFile('dart_sdk.js', sdk.readAsStringSync());
      assetServer.writeFile('dart_sdk.js.map', sdkSourceMap.readAsStringSync());
      generator.reset();
    }

    final compilerOutput = await generator.recompile(
      Uri.parse('org-dartlang-app:///$mainUri'),
      invalidatedFiles,
      outputPath: p.join(dillOutputPath, 'app.dill'),
      packageConfig: packageUriMapper.packageConfig,
      recompileRestart: fullRestart,
    );
    if (compilerOutput == null || compilerOutput.errorCount > 0) {
      return UpdateFSReport(success: false);
    }
    sources = compilerOutput.sources;
    lastCompiled = DateTime.now();

    File codeFile;
    File manifestFile;
    File sourcemapFile;
    File metadataFile;
    List<String> modules;
    try {
      codeFile = outputDirectory.childFile(
        '${compilerOutput.outputFilename}.sources',
      );
      manifestFile = outputDirectory.childFile(
        '${compilerOutput.outputFilename}.json',
      );
      sourcemapFile = outputDirectory.childFile(
        '${compilerOutput.outputFilename}.map',
      );
      metadataFile = outputDirectory.childFile(
        '${compilerOutput.outputFilename}.metadata',
      );
      modules = assetServer.write(
        codeFile,
        manifestFile,
        sourcemapFile,
        metadataFile,
      );
    } on FileSystemException catch (err) {
      throw Exception('Failed to load recompiled sources:\n$err');
    }
    if (ddcModuleFormat == ModuleFormat.ddc &&
        compilerOptions.canaryFeatures &&
        !initialCompile) {
      writeReloadedSources(modules, fileServerUri!);
    }
    return UpdateFSReport(
      success: true,
      syncedBytes: codeFile.lengthSync(),
      invalidatedSourcesCount: invalidatedFiles.length,
    )..invalidatedModules = modules;
  }

  static const String reloadedSourcesFileName = 'reloaded_sources.json';

  /// Given a list of [modules] that need to be reloaded during a hot restart or
  /// hot reload, writes a file that contains a list of objects each with three
  /// fields:
  ///
  /// `src`: A string that corresponds to the file path containing a DDC library
  /// bundle.
  /// `module`: The name of the library bundle in `src`.
  /// `libraries`: An array of strings containing the libraries that were
  /// compiled in `src`.
  ///
  /// For example:
  /// ```json
  /// [
  ///   {
  ///     "src": "<base_uri>/<file_name>",
  ///     "module": "<module_name>",
  ///     "libraries": ["<lib1>", "<lib2>"],
  ///   },
  /// ]
  /// ```
  ///
  /// The path of the output file should stay consistent across the lifetime of
  /// the app.
  void writeReloadedSources(List<String> modules, Uri fileServerUri) {
    final moduleToLibrary = <Map<String, Object>>[];
    for (final module in modules) {
      final metadata = ModuleMetadata.fromJson(
        json.decode(
              utf8.decode(assetServer.getMetadata('$module.metadata').toList()),
            )
            as Map<String, dynamic>,
      );
      final libraries = metadata.libraries.keys.toList();
      moduleToLibrary.add(
        createReloadedSourceEntry(
          src: '$fileServerUri/$module',
          module: metadata.name,
          libraries: libraries,
        ),
      );
    }
    assetServer.writeFile(
      reloadedSourcesFileName,
      json.encode(moduleToLibrary),
    );
  }

  static Map<String, Object> createReloadedSourceEntry({
    required String src,
    required String module,
    required List<String> libraries,
  }) => {'src': src, 'module': module, 'libraries': libraries};

  File get ddcModuleLoaderJS =>
      fileSystem.file(sdkLayout.ddcModuleLoaderJsPath);
  File get requireJS => fileSystem.file(sdkLayout.requireJsPath);
  File get dartSdk => fileSystem.file(switch (ddcModuleFormat) {
    ModuleFormat.amd => sdkLayout.amdJsPath,
    ModuleFormat.ddc => sdkLayout.ddcJsPath,
    _ => throw Exception('Unsupported DDC module format $ddcModuleFormat.'),
  });
  File get dartSdkSourcemap => fileSystem.file(switch (ddcModuleFormat) {
    ModuleFormat.amd => sdkLayout.amdJsMapPath,
    ModuleFormat.ddc => sdkLayout.ddcJsMapPath,
    _ => throw Exception('Unsupported DDC module format $ddcModuleFormat.'),
  });
  File get stackTraceMapper => fileSystem.file(sdkLayout.stackTraceMapperPath);
  ModuleFormat get ddcModuleFormat => compilerOptions.moduleFormat;
}

class UpdateFSReport {
  final bool _success;
  final int _invalidatedSourcesCount;
  final int _syncedBytes;

  UpdateFSReport({
    this._success = false,
    this._invalidatedSourcesCount = 0,
    this._syncedBytes = 0,
  });

  bool get success => _success;
  int get invalidatedSourcesCount => _invalidatedSourcesCount;
  int get syncedBytes => _syncedBytes;

  /// JavaScript modules produced by the incremental compiler in `dartdevc`
  /// mode.
  ///
  /// Only used for JavaScript compilation.
  List<String>? invalidatedModules;
}

/// The result of an invalidation check from [ProjectFileInvalidator].
class InvalidationResult {
  const InvalidationResult({this.uris});

  final List<Uri>? uris;
}

/// The [ProjectFileInvalidator] track the dependencies for a running
/// application to determine when they are dirty.
class ProjectFileInvalidator {
  ProjectFileInvalidator({required this._fileSystem});

  final FileSystem _fileSystem;

  static const String _pubCachePathLinuxAndMac = '.pub-cache';
  static const String _pubCachePathWindows = 'Pub/Cache';

  Future<InvalidationResult> findInvalidated({
    required DateTime? lastCompiled,
    required List<Uri> urisToMonitor,
    required String packagesPath,
  }) async {
    if (lastCompiled == null) {
      // Initial load.
      assert(urisToMonitor.isEmpty);
      return const InvalidationResult(uris: <Uri>[]);
    }

    final urisToScan = <Uri>[
      // Don't watch pub cache directories to speed things up a little.
      for (final Uri uri in urisToMonitor)
        if (_isNotInPubCache(uri)) uri,
    ];
    final invalidatedFiles = <Uri>[];
    for (final uri in urisToScan) {
      // Calling fs.statSync() is more performant than fs.file().statSync(),
      // but uri.toFilePath() does not work with MultiRootFileSystem.
      final updatedAt = uri.hasScheme && uri.scheme != 'file'
          ? _fileSystem.file(uri).statSync().modified
          : _fileSystem
                .statSync(uri.toFilePath(windows: Platform.isWindows))
                .modified;
      if (updatedAt.isAfter(lastCompiled)) {
        invalidatedFiles.add(uri);
      }
    }
    // We need to check the .dart_tool/package_config.json file too since it is
    // not used in compilation.
    final packageFile = _fileSystem.file(packagesPath);
    final packageUri = packageFile.uri;
    final updatedAt = packageFile.statSync().modified;
    if (updatedAt.isAfter(lastCompiled)) {
      invalidatedFiles.add(packageUri);
    }

    return InvalidationResult(uris: invalidatedFiles);
  }

  bool _isNotInPubCache(Uri uri) {
    return !(Platform.isWindows && uri.path.contains(_pubCachePathWindows)) &&
        !uri.path.contains(_pubCachePathLinuxAndMac);
  }
}
