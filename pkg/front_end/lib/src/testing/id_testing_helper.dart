// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;
import 'package:_fe_analyzer_shared/src/testing/id.dart'
    show ActualData, DataRegistry, Id;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:front_end/src/base/nnbd_mode.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/target/targets.dart';

import '../api_prototype/compiler_options.dart'
    show CompilerOptions, DiagnosticMessage;
import '../api_prototype/experimental_flags.dart'
    show AllowedExperimentalFlags, ExperimentalFlag;
import '../api_prototype/terminal_color_support.dart'
    show printDiagnosticMessage;
import '../base/common.dart';
import '../fasta/messages.dart' show FormattedMessage;
import '../kernel_generator_impl.dart' show InternalCompilerResult;
import 'compiler_common.dart' show compileScript, toTestUri;
import 'id_extractor.dart' show DataExtractor;
import 'kernel_id_testing.dart';

export '../fasta/compiler_context.dart' show CompilerContext;
export '../fasta/messages.dart' show FormattedMessage;
export '../kernel_generator_impl.dart' show InternalCompilerResult;

/// Test configuration used for testing CFE in its default state.
const CfeTestConfig defaultCfeConfig = const CfeTestConfig(cfeMarker, 'cfe');

class CfeTestConfig extends TestConfig {
  final Map<ExperimentalFlag, bool> explicitExperimentalFlags;
  final AllowedExperimentalFlags? allowedExperimentalFlags;
  final Uri? librariesSpecificationUri;
  final Uri? packageConfigUri;
  // TODO(johnniwinther): Tailor support to redefine selected platform
  // classes/members only.
  final bool compileSdk;
  final TestTargetFlags targetFlags;
  final NnbdMode nnbdMode;

  const CfeTestConfig(super.marker, super.name,
      {this.explicitExperimentalFlags = const {},
      this.allowedExperimentalFlags,
      this.librariesSpecificationUri,
      this.packageConfigUri,
      this.compileSdk = false,
      this.targetFlags = const TestTargetFlags(),
      this.nnbdMode = NnbdMode.Strong});

  /// Called before running test on [testData].
  ///
  /// This allows tests to customize the [options] based on the [testData].
  ///
  /// A custom object can be returned. This is passed to data computer.
  dynamic customizeCompilerOptions(
          CompilerOptions options, TestData testData) =>
      null;

  /// Called after running test on [testData] with the resulting
  /// [testResultData].
  void onCompilationResult(MarkerOptions markerOptions, TestData testData,
      CfeTestResultData testResultData) {}
}

abstract class CfeDataComputer<T> extends DataComputer<T, CfeTestConfig,
    InternalCompilerResult, CfeTestResultData> {
  const CfeDataComputer();
}

/// Auxiliary data from running a test.
class CfeTestResultData
    extends TestResultData<CfeTestConfig, InternalCompilerResult> {
  /// CustomData is passed from [CfeTestConfig.customizeCompilerOptions].
  final dynamic customData;

  CfeTestResultData(super.config, this.customData, super.compilerResult);

  @override
  Component get component => compilerResult.component!;
}

mixin CfeDataRegistryMixin<T> implements DataRegistry<T> {
  InternalCompilerResult get compilerResult;

  @override
  void report(Uri uri, int offset, String message) {
    printMessageInLocation(
        compilerResult.component!.uriToSource, uri, offset, message);
  }

  @override
  void fail(String message) {
    onFailure(message);
  }
}

class CfeDataRegistry<T> with DataRegistry<T>, CfeDataRegistryMixin<T> {
  @override
  final InternalCompilerResult compilerResult;

  @override
  final Map<Id, ActualData<T>> actualMap;

  CfeDataRegistry(this.compilerResult, this.actualMap);
}

abstract class CfeDataExtractor<T> extends DataExtractor<T>
    with CfeDataRegistryMixin<T> {
  @override
  final InternalCompilerResult compilerResult;

  CfeDataExtractor(this.compilerResult, Map<Id, ActualData<T>> actualMap)
      : super(actualMap);
}

/// Create the testing URI used for [fileName] in annotated tests.
Uri createUriForFileName(String fileName) => toTestUri(fileName);

void onFailure(String message) => throw new StateError(message);

/// Creates a test runner for [dataComputer] on [testedConfigs].
RunTestFunction<T> runTestFor<T>(
    CfeDataComputer<T> dataComputer, List<CfeTestConfig> testedConfigs) {
  retainDataForTesting = true;
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

/// Runs [dataComputer] on [testData] for all [testedConfigs].
///
/// Returns `true` if an error was encountered.
Future<Map<String, TestResult<T>>> runTest<T>(
    MarkerOptions markerOptions,
    TestData testData,
    CfeDataComputer<T> dataComputer,
    List<CfeTestConfig> testedConfigs,
    {required bool testAfterFailures,
    required bool verbose,
    required bool succinct,
    required bool printCode,
    bool forUserLibrariesOnly = true,
    Iterable<Id> globalIds = const <Id>[],
    required void onFailure(String message),
    Map<String, List<String>>? skipMap,
    required Uri nullUri}) async {
  for (CfeTestConfig config in testedConfigs) {
    if (!testData.expectedMaps.containsKey(config.marker)) {
      throw new ArgumentError("Unexpected test marker '${config.marker}'. "
          "Supported markers: ${testData.expectedMaps.keys}.");
    }
  }

  Map<String, TestResult<T>> results = {};
  for (CfeTestConfig config in testedConfigs) {
    if (skipForConfig(testData.name, config.marker, skipMap)) {
      continue;
    }
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

/// Runs [dataComputer] on [testData] for [config].
///
/// Returns `true` if an error was encountered.
Future<TestResult<T>> runTestForConfig<T>(MarkerOptions markerOptions,
    TestData testData, CfeDataComputer<T> dataComputer, CfeTestConfig config,
    {required bool fatalErrors,
    required bool verbose,
    required bool succinct,
    required bool printCode,
    bool forUserLibrariesOnly = true,
    Iterable<Id> globalIds = const <Id>[],
    required void onFailure(String message),
    required Uri nullUri}) async {
  CompilerOptions options = new CompilerOptions();
  List<FormattedMessage> errors = [];
  options.onDiagnostic = (DiagnosticMessage message) {
    if (message is FormattedMessage && message.severity == Severity.error) {
      errors.add(message);
    }
    if (!succinct) printDiagnosticMessage(message, print);
  };
  options.debugDump = printCode;
  options.target = new TestTargetWrapper(
      new NoneTarget(config.targetFlags), config.targetFlags);
  options.explicitExperimentalFlags.addAll(config.explicitExperimentalFlags);
  options.allowedExperimentalFlagsForTesting = config.allowedExperimentalFlags;
  options.nnbdMode = config.nnbdMode;
  if (config.librariesSpecificationUri != null) {
    Set<Uri> testFiles =
        testData.memorySourceFiles.keys.map(createUriForFileName).toSet();
    if (testFiles.contains(config.librariesSpecificationUri)) {
      options.librariesSpecificationUri = config.librariesSpecificationUri;
      options.compileSdk = config.compileSdk;
    }
  }
  options.packagesFileUri = config.packageConfigUri;
  dynamic customData = config.customizeCompilerOptions(options, testData);
  InternalCompilerResult compilerResult = await compileScript(
      testData.memorySourceFiles,
      options: options,
      retainDataForTesting: true,
      requireMain: false) as InternalCompilerResult;

  CfeTestResultData testResultData =
      new CfeTestResultData(config, customData, compilerResult);
  config.onCompilationResult(markerOptions, testData, testResultData);
  return processCompiledResult(
      markerOptions, testData, dataComputer, testResultData, errors,
      fatalErrors: fatalErrors,
      verbose: verbose,
      succinct: succinct,
      onFailure: onFailure,
      nullUri: nullUri);
}
