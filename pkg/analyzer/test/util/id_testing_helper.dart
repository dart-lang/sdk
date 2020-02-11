// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(paulberry,johnniwinther): Use the code for extraction of test data from
// annotated code from CFE.

import 'package:_fe_analyzer_shared/src/testing/annotated_code_helper.dart';
import 'package:_fe_analyzer_shared/src/testing/id.dart'
    show ActualData, Id, IdValue, MemberId, NodeId;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart' hide Annotation;
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/analysis/testing_data.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';

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

Future<TestResult<T>> checkTests<T>(
    String rawCode, DataComputer<T> dataComputer, FeatureSet featureSet) async {
  AnnotatedCode code =
      AnnotatedCode.fromText(rawCode, commentStart, commentEnd);
  String testFileName = 'test.dart';
  var testFileUri = _toTestUri(testFileName);
  var memorySourceFiles = {testFileName: code.sourceCode};
  var marker = 'analyzer';
  Map<String, MemberAnnotations<IdValue>> expectedMaps = {
    marker: MemberAnnotations<IdValue>(),
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
Future<Map<String, TestResult<T>>> runTest<T>(TestData testData,
    DataComputer<T> dataComputer, List<TestConfig> testedConfigs,
    {bool testAfterFailures,
    bool forUserLibrariesOnly = true,
    Iterable<Id> globalIds = const <Id>[],
    void Function(String message) onFailure,
    Map<String, List<String>> skipMap}) async {
  Map<String, TestResult<T>> results = {};
  for (TestConfig config in testedConfigs) {
    if (skipForConfig(testData.name, config.marker, skipMap)) {
      continue;
    }
    results[config.marker] = await runTestForConfig(
        testData, dataComputer, config,
        fatalErrors: !testAfterFailures, onFailure: onFailure);
  }
  return results;
}

/// Creates a test runner for [dataComputer] on [testedConfigs].
RunTestFunction<T> runTestFor<T>(
    DataComputer<T> dataComputer, List<TestConfig> testedConfigs) {
  return (TestData testData,
      {bool testAfterFailures,
      bool verbose,
      bool succinct,
      bool printCode,
      Map<String, List<String>> skipMap}) {
    return runTest(testData, dataComputer, testedConfigs,
        testAfterFailures: testAfterFailures,
        onFailure: onFailure,
        skipMap: skipMap);
  };
}

/// Runs [dataComputer] on [testData] for [config].
///
/// Returns `true` if an error was encountered.
Future<TestResult<T>> runTestForConfig<T>(
    TestData testData, DataComputer<T> dataComputer, TestConfig config,
    {bool fatalErrors,
    void Function(String message) onFailure,
    Map<String, List<String>> skipMap}) async {
  MemberAnnotations<IdValue> memberAnnotations =
      testData.expectedMaps[config.marker];
  var resourceProvider = MemoryResourceProvider();
  for (var entry in testData.memorySourceFiles.entries) {
    resourceProvider.newFile(
        resourceProvider.convertPath(_toTestUri(entry.key).path), entry.value);
  }
  var sdk = MockSdk(resourceProvider: resourceProvider);
  var logBuffer = StringBuffer();
  var logger = PerformanceLog(logBuffer);
  var scheduler = AnalysisDriverScheduler(logger);
  // TODO(paulberry): Do we need a non-empty package map for any of these tests?
  var packageMap = <String, List<Folder>>{};
  var byteStore = MemoryByteStore();
  var analysisOptions = AnalysisOptionsImpl()
    ..contextFeatures = config.featureSet;
  var driver = AnalysisDriver(
      scheduler,
      logger,
      resourceProvider,
      byteStore,
      FileContentOverlay(),
      null,
      SourceFactory([
        DartUriResolver(sdk),
        PackageMapUriResolver(resourceProvider, packageMap),
        ResourceUriResolver(resourceProvider)
      ]),
      analysisOptions,
      packages: Packages.empty,
      retainDataForTesting: true);
  scheduler.start();
  var result = await driver
      .getResult(resourceProvider.convertPath(testData.entryPoint.path));
  var errors =
      result.errors.where((e) => e.severity == Severity.error).toList();
  if (errors.isNotEmpty) {
    String _formatError(AnalysisError e) {
      var locationInfo = result.unit.lineInfo.getLocation(e.offset);
      return '$locationInfo: ${e.errorCode}: ${e.message}';
    }

    onFailure('Errors found:\n  ${errors.map(_formatError).join('\n  ')}');
    return TestResult<T>.erroneous();
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
      var className = id.className;
      var name = id.memberName;
      var unit =
          parseString(content: code[uri].sourceCode, throwIfDiagnostics: false)
              .unit;
      if (className != null) {
        for (var declaration in unit.declarations) {
          if (declaration is ClassDeclaration &&
              declaration.name.name == className) {
            for (var member in declaration.members) {
              if (member is ConstructorDeclaration) {
                if (member.name.name == name) {
                  return member.offset;
                }
              } else if (member is FieldDeclaration) {
                for (var variable in member.fields.variables) {
                  if (variable.name.name == name) {
                    return variable.offset;
                  }
                }
              } else if (member is MethodDeclaration) {
                if (member.name.name == name) {
                  return member.offset;
                }
              }
            }
          }
        }
        throw StateError('Member not found: $className.$name');
      }
      for (var declaration in unit.declarations) {
        if (declaration is FunctionDeclaration) {
          if (declaration.name.name == name) {
            return declaration.offset;
          }
        } else if (declaration is TopLevelVariableDeclaration) {
          for (var variable in declaration.variables.variables) {
            if (variable.name.name == name) {
              return variable.offset;
            }
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
      {bool succinct = false}) {
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
