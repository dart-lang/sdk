// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/analysis/status.dart';
import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

class BaseAnalysisDriverTest with ResourceProviderMixin {
  DartSdk sdk;
  final ByteStore byteStore = MemoryByteStore();
  final FileContentOverlay contentOverlay = FileContentOverlay();

  final StringBuffer logBuffer = StringBuffer();
  PerformanceLog logger;

  final _GeneratedUriResolverMock generatedUriResolver =
      _GeneratedUriResolverMock();
  AnalysisDriverScheduler scheduler;
  AnalysisDriver driver;
  final List<AnalysisStatus> allStatuses = <AnalysisStatus>[];
  final List<ResolvedUnitResult> allResults = <ResolvedUnitResult>[];
  final List<ExceptionResult> allExceptions = <ExceptionResult>[];

  String testProject;
  String testProject2;
  String testFile;
  String testCode;

  List<String> enabledExperiments = [];

  void addTestFile(String content, {bool priority = false}) {
    testCode = content;
    newFile(testFile, content: content);
    driver.addFile(testFile);
    if (priority) {
      driver.priorityFiles = [testFile];
    }
  }

  AnalysisDriver createAnalysisDriver(
      {Map<String, List<Folder>> packageMap,
      SummaryDataStore externalSummaries}) {
    packageMap ??= <String, List<Folder>>{
      'test': [getFolder('$testProject/lib')],
      'aaa': [getFolder('/aaa/lib')],
      'bbb': [getFolder('/bbb/lib')],
    };
    return AnalysisDriver(
        scheduler,
        logger,
        resourceProvider,
        byteStore,
        contentOverlay,
        null,
        SourceFactory([
          DartUriResolver(sdk),
          generatedUriResolver,
          PackageMapUriResolver(resourceProvider, packageMap),
          ResourceUriResolver(resourceProvider)
        ]),
        createAnalysisOptions(),
        packages: Packages({
          'test': Package(
            name: 'test',
            rootFolder: getFolder(testProject),
            libFolder: getFolder('$testProject/lib'),
            languageVersion: Version.parse('2.9.0'),
          ),
          'aaa': Package(
            name: 'aaa',
            rootFolder: getFolder('/aaa'),
            libFolder: getFolder('/aaa/lib'),
            languageVersion: Version.parse('2.9.0'),
          ),
          'bbb': Package(
            name: 'bbb',
            rootFolder: getFolder('/bbb'),
            libFolder: getFolder('/bbb/lib'),
            languageVersion: Version.parse('2.9.0'),
          ),
        }),
        enableIndex: true,
        externalSummaries: externalSummaries);
  }

  AnalysisOptionsImpl createAnalysisOptions() => AnalysisOptionsImpl()
    ..useFastaParser = true
    ..contextFeatures = FeatureSet.fromEnableFlags2(
      sdkLanguageVersion: ExperimentStatus.testingSdkLanguageVersion,
      flags: enabledExperiments,
    );

  int findOffset(String search) {
    int offset = testCode.indexOf(search);
    if (offset < 0) {
      fail("Did not find '$search' in\n$testCode");
    }
    return offset;
  }

  int getLeadingIdentifierLength(String search) {
    int length = 0;
    while (length < search.length) {
      int c = search.codeUnitAt(length);
      if (c >= 'a'.codeUnitAt(0) && c <= 'z'.codeUnitAt(0)) {
        length++;
        continue;
      }
      if (c >= 'A'.codeUnitAt(0) && c <= 'Z'.codeUnitAt(0)) {
        length++;
        continue;
      }
      if (c >= '0'.codeUnitAt(0) && c <= '9'.codeUnitAt(0)) {
        length++;
        continue;
      }
      break;
    }
    return length;
  }

  void setUp() {
    sdk = MockSdk(resourceProvider: resourceProvider);
    testProject = convertPath('/test');
    testProject2 = convertPath('/test/lib');
    testFile = convertPath('/test/lib/test.dart');
    logger = PerformanceLog(logBuffer);
    scheduler = AnalysisDriverScheduler(logger);
    driver = createAnalysisDriver();
    scheduler.start();
    scheduler.status.listen(allStatuses.add);
    driver.results.listen(allResults.add);
    driver.exceptions.listen(allExceptions.add);
  }

  void tearDown() {}
}

class _GeneratedUriResolverMock implements UriResolver {
  Source Function(Uri, Uri) resolveAbsoluteFunction;

  Uri Function(Source) restoreAbsoluteFunction;

  @override
  void clearCache() {}

  @override
  noSuchMethod(Invocation invocation) {
    throw StateError('Unexpected invocation of ${invocation.memberName}');
  }

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    if (resolveAbsoluteFunction != null) {
      return resolveAbsoluteFunction(uri, actualUri);
    }
    return null;
  }

  @override
  Uri restoreAbsolute(Source source) {
    if (restoreAbsoluteFunction != null) {
      return restoreAbsoluteFunction(source);
    }
    return null;
  }
}
