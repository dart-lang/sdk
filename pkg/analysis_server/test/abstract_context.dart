// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisEngine;
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/platform.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/utilities/extensions/file_system.dart';
import 'package:analyzer_utilities/test/mock_packages/mock_packages.dart';
import 'package:linter/src/rules.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

import 'support/configuration_files.dart';
import 'test_macros.dart';

class AbstractContextTest
    with
        MockPackagesMixin,
        ConfigurationFilesMixin,
        ResourceProviderMixin,
        TestMacros {
  static bool _lintRulesAreRegistered = false;

  static final ByteStore _byteStore = MemoryByteStore();

  /// Whether to rewrite line endings in test code based on platform.
  bool useLineEndingsForPlatform = false;

  final Map<String, String> _declaredVariables = {};
  AnalysisContextCollectionImpl? _analysisContextCollection;

  /// If not `null`, [getResolvedUnit] will use the context that corresponds
  /// to this file, instead of the given file.
  File? fileForContextSelection;

  // TODO(scheglov): Stop writing into it. Convert into getter.
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
        Feature.macros.enableString,
        Feature.wildcard_variables.enableString,
      ];

  /// The path that is not in [workspaceRootPath], contains external packages.
  @override
  String get packagesRootPath => '/packages';

  Folder get sdkRoot => newFolder('/sdk');

  Future<AnalysisSession> get session => sessionFor(testFile);

  /// The path for `analysis_options.yaml` in [testPackageRootPath].
  String get testAnalysisOptionsPath =>
      convertPath('$testPackageRootPath/analysis_options.yaml');

  File get testFile => getFile(testFilePath);

  String get testPackageLibPath => '$testPackageRootPath/lib';

  @override
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
    var buffer = StringBuffer();
    _writeSourceChangeToBuffer(
      buffer: buffer,
      sourceChange: sourceChange,
    );
    _assertTextExpectation(buffer.toString(), expected);
  }

  void changeFile(File file) {
    var path = file.path;
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
    List<String> experiments = const [],
    List<String> cannotIgnore = const [],
    List<String> lints = const [],
    Map<String, Object?> errors = const {},
  }) {
    var buffer = StringBuffer();

    if (experiments.isNotEmpty ||
        cannotIgnore.isNotEmpty ||
        errors.isNotEmpty) {
      buffer.writeln('analyzer:');
    }

    if (errors.isNotEmpty) {
      buffer.writeln('  errors:');
      for (var error in errors.entries) {
        buffer.writeln('    ${error.key}: ${error.value}');
      }
    }

    if (experiments.isNotEmpty) {
      buffer.writeln('  enable-experiment:');
      for (var experiment in experiments) {
        buffer.writeln('    - $experiment');
      }
    }

    if (cannotIgnore.isNotEmpty) {
      buffer.writeln('  cannot-ignore:');
      for (var unignorable in cannotIgnore) {
        buffer.writeln('    - $unignorable');
      }
    }

    if (lints.isNotEmpty) {
      buffer.writeln('linter:');
      buffer.writeln('  rules:');
      for (var lint in lints) {
        buffer.writeln('    - $lint');
      }
    }

    writeAnalysisOptionsFile(buffer.toString());
  }

  /// Returns the existing analysis driver that should be used to analyze the
  /// given [file], or throw [StateError] if the [file] is not analyzed in any
  /// of the created analysis contexts.
  AnalysisDriver driverFor(File file) {
    return _contextFor(file).driver;
  }

  Future<ParsedUnitResult> getParsedUnit(File file) async {
    var path = file.path;
    var session = await sessionFor(fileForContextSelection ?? file);
    var result = session.getParsedUnit(path);
    return result as ParsedUnitResult;
  }

  Future<ResolvedUnitResult> getResolvedUnit(File file) async {
    var path = file.path;
    var session = await sessionFor(fileForContextSelection ?? file);
    var result = await session.getResolvedUnit(path);
    return result as ResolvedUnitResult;
  }

  @override
  File newFile(String path, String content) {
    if (_analysisContextCollection != null && !path.endsWith('.dart')) {
      throw StateError('Only dart files can be changed after analysis.');
    }

    var file = super.newFile(path, normalizeSource(content));
    _addAnalyzedFileToDrivers(file);
    return file;
  }

  /// Convenience function to normalize newlines in [code] for the current
  /// platform if [useLineEndingsForPlatform] is `true`.
  String normalizeSource(String code) =>
      useLineEndingsForPlatform ? normalizeNewlinesForPlatform(code) : code;

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
      registerBuiltInProducers();
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

  @mustCallSuper
  Future<void> tearDown() async {
    AnalysisEngine.instance.clearCaches();
    await _analysisContextCollection?.dispose();
  }

  /// Update `pubspec.yaml` and create the driver.
  void updateTestPubspecFile(String content) {
    newFile(testPubspecPath, content);
  }

  void verifyCreatedCollection() {}

  /// Writes string content as an analysis options file.
  void writeAnalysisOptionsFile(String content) {
    newFile(analysisOptionsPath, content);
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
    var path = file.path;
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

  void _writeSourceChangeToBuffer({
    required StringBuffer buffer,
    required SourceChange sourceChange,
  }) {
    for (var fileEdit in sourceChange.edits) {
      var file = getFile(fileEdit.file);
      buffer.writeln('>>>>>>>>>> ${file.posixPath}');
      var current = file.readAsStringSync();
      var updated = SourceEdit.applySequence(current, fileEdit.edits);
      buffer.write(updated);
    }
  }
}
