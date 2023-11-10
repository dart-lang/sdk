// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/testing/id.dart';
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:front_end/src/fasta/messages.dart';
import 'package:front_end/src/testing/id_extractor.dart';
import 'package:front_end/src/testing/kernel_id_testing.dart';
import 'package:kernel/ast.dart';

import 'memory_compiler.dart';

/// Test configuration used for testing CFE in its default state.
const TestConfig defaultDdcConfig = TestConfig(ddcMarker, 'ddc');

/// Convert relative file paths into an absolute Uri as expected by the test
/// helpers above.
Uri toTestUri(String relativePath) => memoryDirectory.resolve(relativePath);

/// Create the testing URI used for [fileName] in annotated tests.
Uri createUriForFileName(String fileName) => toTestUri(fileName);

/// Helper called when an error is found through the id-testing.
void onFailure(String message) => throw StateError(message);

/// DDC-specific [TestResultData] which holds a [MemoryCompilerResult] as its
/// [compilerResult].
class DdcTestResultData
    extends TestResultData<TestConfig, MemoryCompilerResult> {
  DdcTestResultData(super.config, super.compilerResult);

  @override
  Component get component => compilerResult.ddcResult.component;
}

/// Base class for computing id-test data from a DDC compilation.
abstract class DdcDataComputer<T> extends DataComputer<T, TestConfig,
    MemoryCompilerResult, DdcTestResultData> {
  const DdcDataComputer();
}

/// Creates a test runner for [dataComputer] on [testedConfigs].
RunTestFunction<T> runTestFor<T>(
    DdcDataComputer<T> dataComputer, List<TestConfig> testedConfigs) {
  return (MarkerOptions markerOptions, TestData testData,
      {required bool testAfterFailures,
      required bool verbose,
      required bool succinct,
      required bool printCode,
      Map<String, List<String>>? skipMap,
      required Uri nullUri}) {
    return runTest(markerOptions, testData, dataComputer, testedConfigs,
        testAfterFailures: testAfterFailures,
        verbose: verbose,
        succinct: succinct,
        printCode: printCode,
        onFailure: onFailure,
        skipMap: skipMap,
        nullUri: nullUri);
  };
}

/// Runs [dataComputer] on [testData] for each [testedConfigs].
Future<Map<String, TestResult<T>>> runTest<T>(
    MarkerOptions markerOptions,
    TestData testData,
    DdcDataComputer<T> dataComputer,
    List<TestConfig> testedConfigs,
    {required bool testAfterFailures,
    required bool verbose,
    required bool succinct,
    required bool printCode,
    bool forUserLibrariesOnly = true,
    Iterable<Id> globalIds = const <Id>[],
    required void Function(String message) onFailure,
    Map<String, List<String>>? skipMap,
    required Uri nullUri}) async {
  var results = <String, TestResult<T>>{};
  for (var config in testedConfigs) {
    results[config.marker] = await runTestForConfig(
        markerOptions, testData, dataComputer, config,
        fatalErrors: !testAfterFailures,
        onFailure: onFailure,
        verbose: verbose,
        succinct: succinct,
        printCode: printCode,
        nullUri: nullUri);
  }
  return results;
}

/// Computes the [TestResult] for running [dataComputer] on [testData] for
/// the given test [config].
Future<TestResult<T>> runTestForConfig<T>(MarkerOptions markerOptions,
    TestData testData, DdcDataComputer<T> dataComputer, TestConfig config,
    {required bool fatalErrors,
    required bool verbose,
    required bool succinct,
    required bool printCode,
    bool forUserLibrariesOnly = true,
    Iterable<Id> globalIds = const <Id>[],
    required void Function(String message) onFailure,
    required Uri nullUri}) async {
  var result =
      await compileFromMemory(testData.memorySourceFiles, testData.entryPoint);

  var errors = <FormattedMessage>[];
  for (var error in result.errors) {
    if (error is FormattedMessage) {
      errors.add(error);
    }
  }
  var testResultData = DdcTestResultData(config, result);
  return processCompiledResult(
      markerOptions, testData, dataComputer, testResultData, errors,
      fatalErrors: fatalErrors,
      verbose: verbose,
      succinct: succinct,
      onFailure: onFailure,
      nullUri: nullUri);
}

/// Base class for extracting AST-based test data from a DDC compilation.
class DdcDataExtractor<T> extends DataExtractor<T> {
  final MemoryCompilerResult compilerResult;

  DdcDataExtractor(this.compilerResult, super.actualMap);

  @override
  void fail(String message) {
    onFailure(message);
  }

  @override
  void report(Uri uri, int offset, String message) {
    printMessageInLocation(
        compilerResult.ddcResult.component.uriToSource, uri, offset, message);
  }
}
