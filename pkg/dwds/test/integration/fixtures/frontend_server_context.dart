// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:dwds/asset_reader.dart';
import 'package:dwds/data/build_result.dart';
import 'package:dwds/expression_compiler.dart';
import 'package:dwds/src/loaders/frontend_server_strategy_provider.dart';
import 'package:dwds/src/loaders/strategy.dart';
import 'package:dwds/src/utilities/server.dart';
import 'package:dwds_test_common/fixtures/context.dart';
import 'package:dwds_test_common/fixtures/utilities.dart';
import 'package:dwds_test_common/utilities.dart';
import 'package:file/local.dart';
import 'package:logging/logging.dart' as logging;
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';

import '../../frontend_server_common/asset_server.dart';
import '../../frontend_server_common/resident_runner.dart';

class FrontendServerTestContext extends TestContext {
  ResidentWebRunner? _webRunner;
  TestAssetServer? _assetReader;
  LoadStrategy? _loadStrategy;
  ExpressionCompiler? _expressionCompiler;

  late LocalFileSystem frontendServerFileSystem;

  final _logger = logging.Logger('FrontendServerContext');

  FrontendServerTestContext(super.project, super.sdkConfigurationProvider)
    : super.protected();

  @override
  String get appUrlPath =>
      webCompatiblePath([project.directoryToServe, project.filePathToServe]);

  @override
  String get basePath => assetReader.basePath;

  @override
  bool get usesFrontendServer => true;

  ResidentWebRunner get webRunner => _webRunner!;

  @override
  TestAssetServer get assetReader => _assetReader!;

  @override
  Handler get assetHandler => assetReader.handleRequest;

  @override
  LoadStrategy get loadStrategy => _loadStrategy!;

  @override
  ExpressionCompiler? get expressionCompiler => _expressionCompiler;

  @override
  Stream<BuildResult> get buildResults => const Stream<BuildResult>.empty();

  @override
  Future<void> modeSetUp(
    TestSettings testSettings,
    TestDebugSettings debugSettings,
    TestAppMetadata appMetadata,
    Uri reloadedSourcesUri,
  ) async {
    final sdkLayout = sdkConfigurationProvider.sdkLayout;
    final buildSettings = TestBuildSettings(
      appEntrypoint: project.dartEntryFilePackageUri,
      canaryFeatures: testSettings.canaryFeatures,
      isFlutterApp: testSettings.isFlutterApp,
      experiments: testSettings.experiments,
    );

    final filePathToServe = webCompatiblePath([
      project.directoryToServe,
      project.filePathToServe,
    ]);

    _logger.info('Serving: $filePathToServe');

    final entry = p.toUri(
      p.join(project.webAssetsPath, project.dartEntryFileName),
    );
    frontendServerFileSystem = const LocalFileSystem();
    final packageUriMapper = await PackageUriMapper.create(
      frontendServerFileSystem,
      project.packageConfigFile,
      useDebuggerModuleNames: testSettings.useDebuggerModuleNames,
    );

    final compilerOptions = TestCompilerOptions(
      experiments: buildSettings.experiments,
      canaryFeatures: buildSettings.canaryFeatures,
      moduleFormat: testSettings.moduleFormat,
    );

    _webRunner = ResidentWebRunner(
      mainUri: entry,
      urlTunneler: debugSettings.urlEncoder,
      projectDirectory: Directory(project.absolutePackageDirectory).uri,
      packageConfigFile: project.packageConfigFile,
      packageUriMapper: packageUriMapper,
      fileSystemRoots: [Directory(project.absolutePackageDirectory).uri],
      fileSystemScheme: 'org-dartlang-app',
      outputPath: outputDir.path,
      compilerOptions: compilerOptions,
      sdkLayout: sdkLayout,
      verbose: testSettings.verboseCompiler,
    );

    final assetServerPort = await findUnusedPort();
    await webRunner.run(
      frontendServerFileSystem,
      hostname: appMetadata.hostname,
      port: assetServerPort,
      index: filePathToServe,
    );

    if (testSettings.enableExpressionEvaluation) {
      _expressionCompiler = webRunner.expressionCompiler;
    } else {
      _expressionCompiler = null;
    }

    _assetReader = webRunner.devFS!.assetServer;

    _loadStrategy = switch (testSettings.moduleFormat) {
      ModuleFormat.amd => FrontendServerRequireStrategyProvider(
        testSettings.reloadConfiguration,
        assetReader,
        packageUriMapper,
        () async => {},
        buildSettings,
      ).strategy,
      ModuleFormat.ddc =>
        buildSettings.canaryFeatures
            ? FrontendServerDdcLibraryBundleStrategyProvider(
                testSettings.reloadConfiguration,
                assetReader,
                packageUriMapper,
                () async => {},
                buildSettings,
                reloadedSourcesUri: reloadedSourcesUri,
              ).strategy
            : FrontendServerDdcStrategyProvider(
                testSettings.reloadConfiguration,
                assetReader,
                packageUriMapper,
                () async => {},
                buildSettings,
              ).strategy,
      _ => throw Exception(
        'Unsupported DDC module format ${testSettings.moduleFormat.name}.',
      ),
    };
  }

  @override
  Future<void> modeTearDown() async {
    await _webRunner?.stop();
    _webRunner = null;
    _assetReader = null;
    _loadStrategy = null;
    _expressionCompiler = null;
  }

  @override
  Future<void> recompile({required bool fullRestart}) async {
    await webRunner.rerun(
      fullRestart: fullRestart,
      fileServerUri: Uri.parse('http://${testServer.host}:${testServer.port}'),
    );
  }
}
