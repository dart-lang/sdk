// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisEngine;
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/utilities/legacy.dart';
import 'package:linter/src/rules.dart';
import 'package:meta/meta.dart';

import 'src/utilities/mock_packages.dart';

class AbstractContextTest with ResourceProviderMixin {
  static bool _lintRulesAreRegistered = false;

  static final ByteStore _byteStore = MemoryByteStore();

  final Map<String, String> _declaredVariables = {};
  AnalysisContextCollectionImpl? _analysisContextCollection;

  List<AnalysisDriver> get allDrivers {
    _createAnalysisContexts();
    return _analysisContextCollection!.contexts.map((e) => e.driver).toList();
  }

  /// The file system specific path for `analysis_options.yaml` in
  /// [testPackageRootPath].
  String get analysisOptionsPath =>
      convertPath('$testPackageRootPath/analysis_options.yaml');

  List<String> get collectionIncludedPaths => [workspaceRootPath];

  /// Return a list of the experiments that are to be enabled for tests in this
  /// class, an empty list if there are no experiments that should be enabled.
  List<String> get experiments => [
        EnableString.class_modifiers,
        EnableString.macros,
        EnableString.patterns,
        EnableString.records,
        EnableString.sealed_class,
      ];

  String get latestLanguageVersion =>
      '${ExperimentStatus.currentVersion.major}.'
      '${ExperimentStatus.currentVersion.minor}';

  /// The path that is not in [workspaceRootPath], contains external packages.
  String get packagesRootPath => '/packages';

  Folder get sdkRoot => newFolder('/sdk');

  Future<AnalysisSession> get session => sessionFor(testPackageRootPath);

  /// The path for `analysis_options.yaml` in [testPackageRootPath].
  String get testAnalysisOptionsPath =>
      convertPath('$testPackageRootPath/analysis_options.yaml');

  String? get testPackageLanguageVersion => latestLanguageVersion;

  String get testPackageLibPath => '$testPackageRootPath/lib';

  String get testPackageRootPath => '$workspaceRootPath/test';

  String get testPackageTestPath => '$testPackageRootPath/test';

  /// The file system specific path for `pubspec.yaml` in [testPackageRootPath].
  String get testPubspecPath =>
      convertPath('$testPackageRootPath/pubspec.yaml');

  String get workspaceRootPath => '/home';

  Future<void> analyzeTestPackageFiles() async {
    var analysisContext = contextFor(testPackageRootPath);
    var files = analysisContext.contextRoot.analyzedFiles().toList();
    for (var path in files) {
      await analysisContext.applyPendingFileChanges();
      await analysisContext.currentSession.getResolvedUnit(path);
    }
  }

  void changeFile(String path) {
    path = convertPath(path);
    driverFor(path).changeFile(path);
  }

  AnalysisContext contextFor(String path) {
    return _contextFor(path);
  }

  /// Create an analysis options file based on the given arguments.
  void createAnalysisOptionsFile({
    List<String>? experiments,
    List<String>? cannotIgnore,
    bool? implicitCasts,
    List<String>? lints,
  }) {
    var buffer = StringBuffer();

    if (experiments != null || implicitCasts != null || cannotIgnore != null) {
      buffer.writeln('analyzer:');
    }

    if (experiments != null) {
      buffer.writeln('  enable-experiment:');
      for (var experiment in experiments) {
        buffer.writeln('    - $experiment');
      }
    }

    if (implicitCasts != null) {
      buffer.writeln('  strong-mode:');
      buffer.writeln('    implicit-casts: $implicitCasts');
    }

    if (cannotIgnore != null) {
      buffer.writeln('  cannot-ignore:');
      for (var unignorable in cannotIgnore) {
        buffer.writeln('    - $unignorable');
      }
    }

    if (lints != null) {
      buffer.writeln('linter:');
      buffer.writeln('  rules:');
      for (var lint in lints) {
        buffer.writeln('    - $lint');
      }
    }

    newFile(analysisOptionsPath, buffer.toString());
  }

  AnalysisDriver driverFor(String path) {
    return _contextFor(path).driver;
  }

  /// Return the existing analysis context that should be used to analyze the
  /// given [path], or throw [StateError] if the [path] is not analyzed in any
  /// of the created analysis contexts.
  DriverBasedAnalysisContext getContext(String path) {
    path = convertPath(path);
    return _analysisContextCollection!.contextFor(path);
  }

  /// Return the existing analysis driver that should be used to analyze the
  /// given [path], or throw [StateError] if the [path] is not analyzed in any
  /// of the created analysis contexts.
  AnalysisDriver getDriver(String path) {
    var context = getContext(path);
    return context.driver;
  }

  Future<ResolvedUnitResult> getResolvedUnit(String path) async =>
      await (await session).getResolvedUnit(path) as ResolvedUnitResult;

  @override
  File newFile(String path, String content) {
    if (_analysisContextCollection != null && !path.endsWith('.dart')) {
      throw StateError('Only dart files can be changed after analysis.');
    }

    path = convertPath(path);
    _addAnalyzedFileToDrivers(path);
    return super.newFile(path, content);
  }

  Future<ResolvedUnitResult> resolveFile(String path) async {
    path = convertPath(path);
    var session = await sessionFor(path);
    return await session.getResolvedUnit(path) as ResolvedUnitResult;
  }

  Future<AnalysisSession> sessionFor(String path) async {
    var analysisContext = _contextFor(path);
    await analysisContext.applyPendingFileChanges();
    return analysisContext.currentSession;
  }

  @mustCallSuper
  void setUp() {
    if (!_lintRulesAreRegistered) {
      registerLintRules();
      _lintRulesAreRegistered = true;
    }

    setupResourceProvider();

    createMockSdk(
      resourceProvider: resourceProvider,
      root: sdkRoot,
    );

    writeTestPackageConfig();

    createAnalysisOptionsFile(
      experiments: experiments,
    );
  }

  void setupResourceProvider() {}

  void tearDown() {
    noSoundNullSafety = true;
    AnalysisEngine.instance.clearCaches();
  }

  /// Update `pubspec.yaml` and create the driver.
  void updateTestPubspecFile(String content) {
    newFile(testPubspecPath, content);
  }

  void verifyCreatedCollection() {}

  void writePackageConfig(String path, PackageConfigFileBuilder config) {
    newFile(path, config.toContent(toUriStr: toUriStr));
  }

  void writeTestPackageConfig({
    PackageConfigFileBuilder? config,
    String? languageVersion,
    bool flutter = false,
    bool meta = false,
    bool vector_math = false,
  }) {
    if (config == null) {
      config = PackageConfigFileBuilder();
    } else {
      config = config.copy();
    }

    config.add(
      name: 'test',
      rootPath: testPackageRootPath,
      languageVersion: languageVersion ?? testPackageLanguageVersion,
    );

    if (meta || flutter) {
      var libFolder = MockPackages.instance.addMeta(resourceProvider);
      config.add(name: 'meta', rootPath: libFolder.parent.path);
    }

    if (flutter) {
      {
        var libFolder = MockPackages.instance.addUI(resourceProvider);
        config.add(name: 'ui', rootPath: libFolder.parent.path);
      }
      {
        var libFolder = MockPackages.instance.addFlutter(resourceProvider);
        config.add(name: 'flutter', rootPath: libFolder.parent.path);
      }
    }

    if (vector_math) {
      var libFolder = MockPackages.instance.addVectorMath(resourceProvider);
      config.add(name: 'vector_math', rootPath: libFolder.parent.path);
    }

    var path = '$testPackageRootPath/.dart_tool/package_config.json';
    writePackageConfig(path, config);
  }

  void _addAnalyzedFilesToDrivers() {
    for (var analysisContext in _analysisContextCollection!.contexts) {
      for (var path in analysisContext.contextRoot.analyzedFiles()) {
        if (file_paths.isDart(resourceProvider.pathContext, path)) {
          analysisContext.driver.addFile(path);
        }
      }
    }
  }

  void _addAnalyzedFileToDrivers(String path) {
    var collection = _analysisContextCollection;
    if (collection != null) {
      for (var analysisContext in collection.contexts) {
        if (analysisContext.contextRoot.isAnalyzed(path)) {
          analysisContext.driver.addFile(path);
        }
      }
    }
  }

  DriverBasedAnalysisContext _contextFor(String path) {
    _createAnalysisContexts();

    path = convertPath(path);
    return _analysisContextCollection!.contextFor(path);
  }

  /// Create all analysis contexts in [collectionIncludedPaths].
  void _createAnalysisContexts() {
    if (_analysisContextCollection != null) {
      return;
    }

    _analysisContextCollection = AnalysisContextCollectionImpl(
      byteStore: _byteStore,
      declaredVariables: _declaredVariables,
      enableIndex: true,
      includedPaths: collectionIncludedPaths.map(convertPath).toList(),
      resourceProvider: resourceProvider,
      sdkPath: sdkRoot.path,
    );

    _addAnalyzedFilesToDrivers();
    verifyCreatedCollection();
  }
}
