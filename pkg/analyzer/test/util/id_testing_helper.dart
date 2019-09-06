// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(paulberry,johnniwinther): Use the code for extraction of test data from
// annotated code from CFE.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart' hide Annotation;
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/analysis/testing_data.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:front_end/src/testing/annotated_code_helper.dart';
import 'package:front_end/src/testing/id.dart'
    show ActualData, Id, IdValue, MemberId, NodeId;
import 'package:front_end/src/testing/id_testing.dart';

/// Test configuration used for testing the analyzer with constant evaluation.
final TestConfig analyzerConstantUpdate2018Config = TestConfig(
    analyzerMarker, 'analyzer with constant-update-2018',
    featureSet: FeatureSet.forTesting(
        sdkVersion: '2.2.2',
        additionalFeatures: [Feature.constant_update_2018]));

/// Test configuration used for testing the analyzer with NNBD.
final TestConfig analyzerNnbdConfig = TestConfig(
    analyzerMarker, 'analyzer with NNBD',
    featureSet: FeatureSet.forTesting(
        sdkVersion: '2.2.2', additionalFeatures: [Feature.non_nullable]));

/// A fake absolute directory used as the root of a memory-file system in ID
/// tests.
Uri _defaultDir = Uri.parse('file:///a/b/c/');

Future<bool> checkTests<T>(
    String rawCode, DataComputer<T> dataComputer, FeatureSet featureSet) async {
  AnnotatedCode code =
      new AnnotatedCode.fromText(rawCode, commentStart, commentEnd);
  String testFileName = 'test.dart';
  var testFileUri = _toTestUri(testFileName);
  var memorySourceFiles = {testFileName: code.sourceCode};
  var marker = 'analyzer';
  Map<String, MemberAnnotations<IdValue>> expectedMaps = {
    marker: new MemberAnnotations<IdValue>(),
  };
  computeExpectedMap(testFileUri, testFileName, code, expectedMaps,
      onFailure: onFailure);
  Map<Uri, AnnotatedCode> codeMap = {testFileUri: code};
  var testData = TestData(testFileName, testFileUri, testFileUri,
      memorySourceFiles, codeMap, expectedMaps);
  var config =
      TestConfig(marker, 'provisional test config', featureSet: featureSet);
  return runTestForConfig<T>(testData, dataComputer, config);
}

/// Creates the testing URI used for [fileName] in annotated tests.
Uri createUriForFileName(String fileName) => _toTestUri(fileName);

void onFailure(String message) {
  throw StateError(message);
}

/// Runs [dataComputer] on [testData] for all [testedConfigs].
///
/// Returns `true` if an error was encountered.
Future<bool> runTest<T>(TestData testData, DataComputer<T> dataComputer,
    List<TestConfig> testedConfigs,
    {bool testAfterFailures,
    bool forUserLibrariesOnly: true,
    Iterable<Id> globalIds: const <Id>[],
    void onFailure(String message)}) async {
  bool hasFailures = false;
  for (TestConfig config in testedConfigs) {
    if (await runTestForConfig(testData, dataComputer, config,
        fatalErrors: !testAfterFailures, onFailure: onFailure)) {
      hasFailures = true;
    }
  }
  return hasFailures;
}

/// Creates a test runner for [dataComputer] on [testedConfigs].
RunTestFunction runTestFor<T>(
    DataComputer<T> dataComputer, List<TestConfig> testedConfigs) {
  return (TestData testData,
      {bool testAfterFailures, bool verbose, bool succinct, bool printCode}) {
    return runTest(testData, dataComputer, testedConfigs,
        testAfterFailures: testAfterFailures, onFailure: onFailure);
  };
}

/// Runs [dataComputer] on [testData] for [config].
///
/// Returns `true` if an error was encountered.
Future<bool> runTestForConfig<T>(
    TestData testData, DataComputer<T> dataComputer, TestConfig config,
    {bool fatalErrors, void onFailure(String message)}) async {
  MemberAnnotations<IdValue> memberAnnotations =
      testData.expectedMaps[config.marker];
  var resourceProvider = new MemoryResourceProvider();
  for (var entry in testData.memorySourceFiles.entries) {
    resourceProvider.newFile(
        resourceProvider.convertPath(_toTestUri(entry.key).path), entry.value);
  }
  var sdk = new MockSdk(resourceProvider: resourceProvider);
  var logBuffer = new StringBuffer();
  var logger = new PerformanceLog(logBuffer);
  var scheduler = new AnalysisDriverScheduler(logger);
  // TODO(paulberry): Do we need a non-empty package map for any of these tests?
  var packageMap = <String, List<Folder>>{};
  var byteStore = new MemoryByteStore();
  var analysisOptions = AnalysisOptionsImpl()
    ..contextFeatures = config.featureSet;
  var driver = new AnalysisDriver(
      scheduler,
      logger,
      resourceProvider,
      byteStore,
      new FileContentOverlay(),
      null,
      new SourceFactory([
        new DartUriResolver(sdk),
        new PackageMapUriResolver(resourceProvider, packageMap),
        new ResourceUriResolver(resourceProvider)
      ], null, resourceProvider),
      analysisOptions,
      retainDataForTesting: true);
  scheduler.start();
  var result = await driver
      .getResult(resourceProvider.convertPath(testData.entryPoint.path));
  var errors =
      result.errors.where((e) => e.severity == Severity.error).toList();
  if (errors.isNotEmpty) {
    onFailure('Errors found:\n  ${errors.join('\n  ')}');
    return true;
  }
  Map<Uri, Map<Id, ActualData<T>>> actualMaps = <Uri, Map<Id, ActualData<T>>>{};
  Map<Id, ActualData<T>> globalData = <Id, ActualData<T>>{};

  Map<Id, ActualData<T>> actualMapFor(Uri uri) {
    return actualMaps.putIfAbsent(uri, () => <Id, ActualData<T>>{});
  }

  dataComputer.computeUnitData(
      driver.testingData, result.unit, actualMapFor(testData.entryPoint));
  var compiledData = AnalyzerCompiledData<T>(
      testData.code, testData.entryPoint, actualMaps, globalData);
  return checkCode(config.name, testData.testFileUri, testData.code,
      memberAnnotations, compiledData, dataComputer.dataValidator,
      fatalErrors: fatalErrors, onFailure: onFailure);
}

/// Convert relative file paths into an absolute Uri as expected by the test
/// helpers.
Uri _toTestUri(String relativePath) => _defaultDir.resolve(relativePath);

class AnalyzerCompiledData<T> extends CompiledData<T> {
  // TODO(johnniwinther,paulberry): Maybe this should have access to the
  // [ResolvedUnitResult] instead.
  final Map<Uri, AnnotatedCode> code;

  AnalyzerCompiledData(
      this.code,
      Uri mainUri,
      Map<Uri, Map<Id, ActualData<T>>> actualMaps,
      Map<Id, ActualData<T>> globalData)
      : super(mainUri, actualMaps, globalData);

  @override
  int getOffsetFromId(Id id, Uri uri) {
    if (id is NodeId) {
      return id.value;
    } else if (id is MemberId) {
      if (id.className != null) {
        throw UnimplementedError('TODO(paulberry): handle class members');
      }
      var name = id.memberName;
      var unit =
          parseString(content: code[uri].sourceCode, throwIfDiagnostics: false)
              .unit;
      for (var declaration in unit.declarations) {
        if (declaration is FunctionDeclaration) {
          if (declaration.name.name == name) {
            return declaration.offset;
          }
        }
      }
      throw StateError('Member not found: $name');
    } else {
      throw StateError('Unexpected id ${id.runtimeType}');
    }
  }

  @override
  void reportError(Uri uri, int offset, String message,
      {bool succinct: false}) {
    print('$offset: $message');
  }
}

abstract class DataComputer<T> {
  const DataComputer();

  DataInterpreter<T> get dataValidator;

  /// Function that computes a data mapping for [unit].
  ///
  /// Fills [actualMap] with the data and [sourceSpanMap] with the source spans
  /// for the data origin.
  void computeUnitData(TestingData testingData, CompilationUnit unit,
      Map<Id, ActualData<T>> actualMap);
}

class TestConfig {
  final String marker;
  final String name;
  final FeatureSet featureSet;

  TestConfig(this.marker, this.name, {FeatureSet featureSet})
      : featureSet = featureSet ?? FeatureSet.fromEnableFlags([]);
}
