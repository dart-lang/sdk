// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
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
import 'package:path/path.dart';
import 'package:test/test.dart';

import 'src/utilities/mock_packages.dart';

class AbstractContextTest with ResourceProviderMixin {
  static bool _lintRulesAreRegistered = false;

  static final ByteStore _byteStore = MemoryByteStore();

  final Map<String, String> _declaredVariables = {};
  AnalysisContextCollectionImpl? _analysisContextCollection;

  /// If not `null`, [getResolvedUnit] will use the context that corresponds
  /// to this file, instead of the given file.
  File? fileForContextSelection;

  /// TODO(scheglov) Stop writing into it. Convert into getter.
  late String testFilePath = '$testPackageLibPath/test.dart';

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
        EnableString.inline_class,
        EnableString.macros,
      ];

  String get latestLanguageVersion =>
      '${ExperimentStatus.currentVersion.major}.'
      '${ExperimentStatus.currentVersion.minor}';

  /// The path that is not in [workspaceRootPath], contains external packages.
  String get packagesRootPath => '/packages';

  Folder get sdkRoot => newFolder('/sdk');

  Future<AnalysisSession> get session => sessionFor(testFile);

  /// The path for `analysis_options.yaml` in [testPackageRootPath].
  String get testAnalysisOptionsPath =>
      convertPath('$testPackageRootPath/analysis_options.yaml');

  File get testFile => getFile(testFilePath);

  String? get testPackageLanguageVersion => latestLanguageVersion;

  String get testPackageLibPath => '$testPackageRootPath/lib';

  String get testPackageRootPath => '$workspaceRootPath/test';

  String get testPackageTestPath => '$testPackageRootPath/test';

  /// The file system specific path for `pubspec.yaml` in [testPackageRootPath].
  String get testPubspecPath =>
      convertPath('$testPackageRootPath/pubspec.yaml');

  String get workspaceRootPath => '/home';

  Future<void> analyzeTestPackageFiles() async {
    var analysisContext = contextFor(testFile);
    var files = analysisContext.contextRoot.analyzedFiles().toList();
    for (var path in files) {
      await analysisContext.applyPendingFileChanges();
      await analysisContext.currentSession.getResolvedUnit(path);
    }
  }

  void assertSourceChange(SourceChange sourceChange, String expected) {
    final buffer = StringBuffer();
    _writeSourceChangeToBuffer(
      buffer: buffer,
      sourceChange: sourceChange,
    );
    _assertTextExpectation(buffer.toString(), expected);
  }

  void changeFile(File file) {
    final path = file.path;
    driverFor(file).changeFile(path);
  }

  /// Returns the existing analysis context that should be used to analyze the
  /// given [file], or throw [StateError] if the [file] is not analyzed in any
  /// of the created analysis contexts.
  AnalysisContext contextFor(File file) {
    return _contextFor(file);
  }

  /// Create an analysis options file based on the given arguments.
  void createAnalysisOptionsFile({
    List<String>? experiments,
    List<String>? cannotIgnore,
    List<String>? lints,
  }) {
    var buffer = StringBuffer();

    if (experiments != null || cannotIgnore != null) {
      buffer.writeln('analyzer:');
    }

    if (experiments != null) {
      buffer.writeln('  enable-experiment:');
      for (var experiment in experiments) {
        buffer.writeln('    - $experiment');
      }
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

  /// Returns the existing analysis driver that should be used to analyze the
  /// given [file], or throw [StateError] if the [file] is not analyzed in any
  /// of the created analysis contexts.
  AnalysisDriver driverFor(File file) {
    return _contextFor(file).driver;
  }

  Future<ParsedUnitResult> getParsedUnit(File file) async {
    final path = file.path;
    final session = await sessionFor(fileForContextSelection ?? file);
    final result = session.getParsedUnit(path);
    return result as ParsedUnitResult;
  }

  Future<ResolvedUnitResult> getResolvedUnit(File file) async {
    final path = file.path;
    final session = await sessionFor(fileForContextSelection ?? file);
    final result = await session.getResolvedUnit(path);
    return result as ResolvedUnitResult;
  }

  @override
  File newFile(String path, String content) {
    if (_analysisContextCollection != null && !path.endsWith('.dart')) {
      throw StateError('Only dart files can be changed after analysis.');
    }

    final file = super.newFile(path, content);
    _addAnalyzedFileToDrivers(file);
    return file;
  }

  Future<AnalysisSession> sessionFor(File file) async {
    var analysisContext = _contextFor(file);
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

  void _addAnalyzedFileToDrivers(File file) {
    final path = file.path;
    var collection = _analysisContextCollection;
    if (collection != null) {
      for (var analysisContext in collection.contexts) {
        if (analysisContext.contextRoot.isAnalyzed(path)) {
          analysisContext.driver.addFile(path);
        }
      }
    }
  }

  void _assertTextExpectation(String actual, String expected) {
    if (actual != expected) {
      print('-' * 64);
      print(actual.trimRight());
      print('-' * 64);
    }
    expect(actual, expected);
  }

  DriverBasedAnalysisContext _contextFor(File file) {
    _createAnalysisContexts();
    return _analysisContextCollection!.contextFor(file.path);
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

  /// If the path style is `Windows`, returns the corresponding Posix path.
  /// Otherwise the path is already a Posix path, and it is returned as is.
  /// TODO(scheglov) This is duplicate.
  String _posixPath(File file) {
    final pathContext = resourceProvider.pathContext;
    if (pathContext.style == Style.windows) {
      final components = pathContext.split(file.path);
      return '/${components.skip(1).join('/')}';
    } else {
      return file.path;
    }
  }

  void _writeSourceChangeToBuffer({
    required StringBuffer buffer,
    required SourceChange sourceChange,
  }) {
    for (final fileEdit in sourceChange.edits) {
      final file = getFile(fileEdit.file);
      buffer.writeln('>>>>>>>>>> ${_posixPath(file)}');
      final current = file.readAsStringSync();
      final updated = SourceEdit.applySequence(current, fileEdit.edits);
      buffer.write(updated);
    }
  }
}
