// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/error/codes.g.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisEngine;
import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:meta/meta.dart';
import 'package:test/test.dart';

/// A base test framework for writing tests that resolve a String as Dart source
/// code.
// TODO(srawlins): This is all copied from the `AbstractSingleUnitTest` and
// `AbstractContextTest` classes in the analysis_server package. It is pared
// down as the minimum amount of code needed to run the tests in this package.
class SingleUnitTest with ResourceProviderMixin {
  static final ByteStore _byteStore = MemoryByteStore();

  late String testCode;
  late ParsedUnitResult testParsedResult;
  late ResolvedUnitResult testAnalysisResult;
  late FindNode findNode;

  final Map<String, String> _declaredVariables = {};
  AnalysisContextCollectionImpl? _analysisContextCollection;

  File get testFile => getFile(_testFilePath);

  List<String> get _collectionIncludedPaths => [_workspaceRootPath];

  Folder get _sdkRoot => newFolder('/sdk');

  String get _testFilePath => '$_testPackageLibPath/test.dart';

  String get _testPackageLibPath => '$_testPackageRootPath/lib';

  String get _testPackageRootPath => '$_workspaceRootPath/test';

  String get _workspaceRootPath => '/home';

  void addTestSource(String code) {
    testCode = code;
    newFile(testFile.path, code);
  }

  void changeFile(File file) {
    _contextFor(file).driver.changeFile(file.path);
  }

  Future<ParsedUnitResult> getParsedUnit(File file) async {
    var path = file.path;
    var session = await _sessionFor(file);
    var result = session.getParsedUnit(path) as ParsedUnitResult;

    testParsedResult = result;
    testCode = result.content;
    var testUnit = result.unit;
    findNode = FindNode(testCode, testUnit);
    return result;
  }

  Future<ResolvedUnitResult> getResolvedUnit(File file) async {
    var path = file.path;
    var session = await _sessionFor(file);
    var result = await session.getResolvedUnit(path) as ResolvedUnitResult;

    testAnalysisResult = result;
    testCode = result.content;
    var testUnit = result.unit;

    expect(result.errors.where((error) {
      return error.errorCode != WarningCode.DEAD_CODE &&
          error.errorCode != WarningCode.UNUSED_CATCH_CLAUSE &&
          error.errorCode != WarningCode.UNUSED_CATCH_STACK &&
          error.errorCode != WarningCode.UNUSED_ELEMENT &&
          error.errorCode != WarningCode.UNUSED_FIELD &&
          error.errorCode != WarningCode.UNUSED_IMPORT &&
          error.errorCode != WarningCode.UNUSED_LOCAL_VARIABLE;
    }), isEmpty);

    findNode = FindNode(testCode, testUnit);
    return result;
  }

  @override
  File newFile(String path, String content) {
    if (_analysisContextCollection != null && !path.endsWith('.dart')) {
      throw StateError('Only dart files can be changed after analysis.');
    }

    var file = super.newFile(path, content);
    _addAnalyzedFileToDrivers(file);
    return file;
  }

  Future<void> parseTestCode(String code) async {
    addTestSource(code);
    await getParsedUnit(testFile);
  }

  Future<void> resolveTestCode(String code) async {
    addTestSource(code);
    await getResolvedUnit(testFile);
  }

  @mustCallSuper
  void setUp() {
    createMockSdk(resourceProvider: resourceProvider, root: _sdkRoot);
  }

  @mustCallSuper
  Future<void> tearDown() async {
    AnalysisEngine.instance.clearCaches();
    await _analysisContextCollection?.dispose();
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
    var collection = _analysisContextCollection;
    if (collection != null) {
      for (var analysisContext in collection.contexts) {
        if (analysisContext.contextRoot.isAnalyzed(file.path)) {
          analysisContext.driver.addFile(file.path);
        }
      }
    }
  }

  DriverBasedAnalysisContext _contextFor(File file) {
    _createAnalysisContexts();
    return _analysisContextCollection!.contextFor(file.path);
  }

  /// Creates all analysis contexts in [_collectionIncludedPaths].
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
      sdkPath: _sdkRoot.path,
    );

    _addAnalyzedFilesToDrivers();
  }

  Future<AnalysisSession> _sessionFor(File file) async {
    var analysisContext = _contextFor(file);
    await analysisContext.applyPendingFileChanges();
    return analysisContext.currentSession;
  }
}
