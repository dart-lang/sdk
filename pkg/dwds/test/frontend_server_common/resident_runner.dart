// Copyright 2020 The Dart Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Note: this is a copy from flutter tools, updated to work with dwds tests,
// and some functionality removed (does not support hot reload yet)

import 'dart:async';

import 'package:dwds/asset_reader.dart';
import 'package:dwds/config.dart';
import 'package:dwds/expression_compiler.dart';
import 'package:dwds_test_common/test_sdk_layout.dart';
import 'package:file/file.dart';
import 'package:logging/logging.dart';

import 'devfs.dart';
import 'frontend_server_client.dart';

class ResidentWebRunner {
  final _logger = Logger('ResidentWebRunner');

  ResidentWebRunner({
    required this.mainUri,
    required this.urlTunneler,
    required this.projectDirectory,
    required this.packageConfigFile,
    required this.packageUriMapper,
    required this.fileSystemRoots,
    required this.fileSystemScheme,
    required this.outputPath,
    required this.compilerOptions,
    required this.sdkLayout,
    bool verbose = false,
  }) {
    final platformDillUri = Uri.file(sdkLayout.summaryPath);

    generator = ResidentCompiler(
      sdkLayout.sdkDirectory,
      projectDirectory: projectDirectory,
      packageConfigFile: packageConfigFile,
      useDebuggerModuleNames: packageUriMapper.useDebuggerModuleNames,
      platformDill: '$platformDillUri',
      fileSystemRoots: fileSystemRoots,
      fileSystemScheme: fileSystemScheme,
      compilerOptions: compilerOptions,
      sdkLayout: sdkLayout,
      verbose: verbose,
    );
    expressionCompiler = TestExpressionCompiler(generator);
  }

  final UrlEncoder? urlTunneler;
  final Uri mainUri;
  final Uri projectDirectory;
  final Uri packageConfigFile;
  final PackageUriMapper packageUriMapper;
  final String outputPath;
  final List<Uri> fileSystemRoots;
  final String fileSystemScheme;
  final CompilerOptions compilerOptions;
  final TestSdkLayout sdkLayout;

  late ResidentCompiler generator;
  late ExpressionCompiler expressionCompiler;
  ProjectFileInvalidator? _projectFileInvalidator;
  WebDevFS? devFS;
  Uri? uri;

  Future<int> run(
    FileSystem fileSystem, {
    String? hostname,
    required int port,
    required String index,
  }) async {
    _projectFileInvalidator ??= ProjectFileInvalidator(fileSystem: fileSystem);
    devFS ??= WebDevFS(
      fileSystem: fileSystem,
      hostname: hostname ?? 'localhost',
      port: port,
      projectDirectory: projectDirectory,
      packageUriMapper: packageUriMapper,
      index: index,
      urlTunneler: urlTunneler,
      sdkLayout: sdkLayout,
      compilerOptions: compilerOptions,
    );
    uri ??= await devFS!.create();

    final report = await _updateDevFS(
      initialCompile: true,
      fullRestart: false,
      fileServerUri: null,
    );
    if (!report.success) {
      _logger.severe('Failed to compile application.');
      return 1;
    }

    generator.accept();
    return 0;
  }

  Future<int> rerun({
    required bool fullRestart,
    // The uri of the `HttpServer` that handles file requests.
    // TODO(srujzs): This should be the same as the uri of the AssetServer to
    // align with Flutter tools, but currently is not. Delete when that's fixed.
    required Uri fileServerUri,
  }) async {
    final report = await _updateDevFS(
      initialCompile: false,
      fullRestart: fullRestart,
      fileServerUri: fileServerUri,
    );
    if (!report.success) {
      _logger.severe('Failed to compile application.');
      return 1;
    }

    generator.accept();
    return 0;
  }

  Future<UpdateFSReport> _updateDevFS({
    required bool initialCompile,
    required bool fullRestart,
    // The uri of the `TestServer` that handles file requests.
    // TODO(srujzs): This should be the same as the uri of the AssetServer to
    // align with Flutter tools, but currently is not. Delete when that's fixed.
    required Uri? fileServerUri,
  }) async {
    final invalidationResult = await _projectFileInvalidator!.findInvalidated(
      lastCompiled: devFS!.lastCompiled,
      urisToMonitor: devFS!.sources,
      packagesPath: packageConfigFile.toFilePath(),
    );
    final report = await devFS!.update(
      mainUri: mainUri,
      dillOutputPath: outputPath,
      generator: generator,
      invalidatedFiles: invalidationResult.uris!,
      initialCompile: initialCompile,
      fullRestart: fullRestart,
      fileServerUri: fileServerUri,
    );
    return report;
  }

  Future<void> stop() async {
    await generator.shutdown();
    await devFS!.dispose();
  }
}
