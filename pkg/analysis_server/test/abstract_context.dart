// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisEngine;
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/platform.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer_testing/configuration_files_mixin.dart';
import 'package:analyzer_testing/experiments/experiments.dart';
import 'package:analyzer_testing/mock_packages/mock_packages.dart';
import 'package:analyzer_testing/resource_provider_mixin.dart';
import 'package:analyzer_testing/utilities/utilities.dart';
import 'package:meta/meta.dart';

/// A base class for various analysis server tests.
///
/// Sets up an in-memory file system with a stub SDK, package configuration,
/// and default analysis options. Provides helper methods and properties for
/// creating test files, configuring analysis contexts, and obtaining resolved
/// ASTs.
class AbstractContextTest
    with MockPackagesMixin, ConfigurationFilesMixin, ResourceProviderMixin {
  /// The byte store that is reused between tests.
  ///
  /// This allows reusing all unlinked and linked summaries for SDK, so that
  /// tests run much faster. However nothing is preserved between Dart VM runs,
  /// so changes to the implementation are still fully verified.
  static final MemoryByteStore _sharedByteStore = MemoryByteStore();

  final ByteStore _byteStore = _sharedByteStore;

  final Map<String, String> _declaredVariables = {};
  AnalysisContextCollectionImpl? _analysisContextCollection;

  /// The file system specific path for `analysis_options.yaml` in
  /// [testPackageRootPath].
  String get analysisOptionsPath =>
      convertPath('$testPackageRootPath/analysis_options.yaml');

  /// The [AnalysisContextCollection] managing the analysis contexts.
  AnalysisContextCollection get contextCollection {
    _createAnalysisContexts();
    return _analysisContextCollection!;
  }

  /// The file system path to the mock SDK root directory.
  @override
  String get dartSdkPath => sdkRoot.path;

  /// The line terminator being used for test files and to be expected in edits.
  String get eol => testEol;

  /// Return a list of the experimental features that are to be enabled for
  /// tests in this class.
  List<Feature> get experimentalFeatures => experimentalFeaturesForTests;

  /// The path that is not in [workspaceRootPath], contains external packages.
  @override
  String get packagesRootPath => '/packages';

  /// The [Folder] representing the stub SDK root directory.
  ///
  /// Can be overridden by subclasses that require a custom SDK setup.
  Folder get sdkRoot => newFolder('/sdk');

  /// The [AnalysisSession] for the test package's [testFile], after applying
  /// any pending file changes.
  Future<AnalysisSession> get session async {
    var analysisContext = contextFor(testFile);
    await analysisContext.applyPendingFileChanges();
    return analysisContext.currentSession;
  }

  /// The default [File] for testing, located at [testFilePath].
  ///
  /// Most single-file tests write source code to this file.
  File get testFile => getFile(testFilePath);

  /// The file system path of [testFile].
  String get testFilePath => '$testPackageLibPath/test.dart';

  /// The file system path of the `lib` directory of the package-under-test.
  String get testPackageLibPath => '$testPackageRootPath/lib';

  /// The file system path of the root of the package-under-test.
  @override
  String get testPackageRootPath => '$workspaceRootPath/test';

  /// The file system path to the `test` directory of the package-under-test.
  ///
  /// Rarely used except when a test specifically tests files situated inside a
  /// package's `test` directory.
  String get testPackageTestPath => '$testPackageRootPath/test';

  /// The file system specific path for `pubspec.yaml` in [testPackageRootPath].
  String get testPubspecPath =>
      convertPath('$testPackageRootPath/pubspec.yaml');

  /// The file system path of the root of the workspace.
  String get workspaceRootPath => '/home';

  List<String> get _collectionIncludedPaths => [workspaceRootPath];

  /// Returns the existing analysis context that should be used to analyze the
  /// given [file], or throw [StateError] if the [file] is not analyzed in any
  /// of the created analysis contexts.
  DriverBasedAnalysisContext contextFor(File file) {
    _createAnalysisContexts();
    return _analysisContextCollection!.contextFor(file.path);
  }

  /// Create an analysis options file based on the given arguments.
  void createAnalysisOptionsFile({
    List<String> includes = const [],
    List<Feature> experimentalFeatures = const [],
    List<String> legacyPlugins = const [],
    List<String> cannotIgnore = const [],
    List<String> lints = const [],
    Map<String, Object?> errors = const {},
    bool propagateLinterExceptions = true,
    bool strictCasts = false,
    bool strictInference = false,
    bool strictRawTypes = false,
  }) {
    writeAnalysisOptionsFile(
      analysisOptionsContent(
        includes: includes,
        experimentalFeatures: experimentalFeatures,
        legacyPlugins: legacyPlugins,
        propagateLinterExceptions: propagateLinterExceptions,
        rules: lints,
        errors: errors,
        unignorableNames: cannotIgnore,
        strictCasts: strictCasts,
        strictInference: strictInference,
        strictRawTypes: strictRawTypes,
      ),
    );
  }

  /// Resolves and returns the [ResolvedUnitResult] for the given [file].
  Future<ResolvedUnitResult> getResolvedUnit(File file) async {
    var result = await (await session).getResolvedUnit(file.path);
    return result as ResolvedUnitResult;
  }

  /// Creates or updates a file at [path] with the given [content].
  ///
  /// Line endings in [content] are normalized using [normalizeSource], and the
  /// file is added to relevant analysis drivers if analysis contexts have
  /// already been created.
  ///
  /// Throws a [StateError] if a non-Dart file is modified after the analysis
  /// context collection has already been initialized.
  @override
  File newFile(String path, String content) {
    if (_analysisContextCollection != null && !path.endsWith('.dart')) {
      throw StateError('Only dart files can be changed after analysis.');
    }

    var file = super.newFile(path, normalizeSource(content));
    _addAnalyzedFileToDrivers(file);
    return file;
  }

  /// Normalizes newlines in [code] for the current platform.
  String normalizeSource(String code) => normalizeNewlinesForPlatform(code);

  /// Initializes the test environment before each test.
  @mustCallSuper
  void setUp() {
    createMockSdk(resourceProvider: resourceProvider, root: sdkRoot);

    writeTestPackageConfig2();

    createAnalysisOptionsFile(experimentalFeatures: experimentalFeatures);
  }

  /// Disposes of the test environment after each test.
  ///
  /// Clears analysis engine caches and disposes of the analysis context
  /// collection.
  @mustCallSuper
  Future<void> tearDown() async {
    AnalysisEngine.instance.clearCaches();
    await _analysisContextCollection?.dispose();
  }

  /// Updates `pubspec.yaml` and create the driver.
  void updateTestPubspecFile(String content) {
    newFile(testPubspecPath, content);
  }

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

  /// Create all analysis contexts in [_collectionIncludedPaths].
  void _createAnalysisContexts() {
    if (_analysisContextCollection != null) {
      return;
    }

    _analysisContextCollection = AnalysisContextCollectionImpl(
      byteStore: _byteStore,
      declaredVariables: _declaredVariables,
      enableIndex: true,
      includedPaths: _collectionIncludedPaths.map(convertPath).toList(),
      resourceProvider: resourceProvider,
      sdkPath: sdkRoot.path,
      withFineDependencies: true,
    );

    _addAnalyzedFilesToDrivers();
  }
}
