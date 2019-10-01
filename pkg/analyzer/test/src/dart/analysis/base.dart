// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/analysis/status.dart';
import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/generated/parser.dart' as analyzer;
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';

/**
 * Finds an [Element] with the given [name].
 */
Element findChildElement(Element root, String name, [ElementKind kind]) {
  Element result;
  root.accept(new _ElementVisitorFunctionWrapper((Element element) {
    if (element.name != name) {
      return;
    }
    if (kind != null && element.kind != kind) {
      return;
    }
    result = element;
  }));
  return result;
}

typedef bool Predicate<E>(E argument);

/**
 * A function to be called for every [Element].
 */
typedef void _ElementVisitorFunction(Element element);

class BaseAnalysisDriverTest with ResourceProviderMixin {
  DartSdk sdk;
  final ByteStore byteStore = new MemoryByteStore();
  final FileContentOverlay contentOverlay = new FileContentOverlay();

  final StringBuffer logBuffer = new StringBuffer();
  PerformanceLog logger;

  final _GeneratedUriResolverMock generatedUriResolver =
      new _GeneratedUriResolverMock();
  AnalysisDriverScheduler scheduler;
  AnalysisDriver driver;
  final List<AnalysisStatus> allStatuses = <AnalysisStatus>[];
  final List<ResolvedUnitResult> allResults = <ResolvedUnitResult>[];
  final List<ExceptionResult> allExceptions = <ExceptionResult>[];

  String testProject;
  String testFile;
  String testCode;

  List<String> enabledExperiments = [];

  bool get disableChangesAndCacheAllResults => false;

  void addTestFile(String content, {bool priority: false}) {
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
      'test': [getFolder(testProject)],
      'aaa': [getFolder('/aaa/lib')],
      'bbb': [getFolder('/bbb/lib')],
    };
    return new AnalysisDriver(
        scheduler,
        logger,
        resourceProvider,
        byteStore,
        contentOverlay,
        null,
        new SourceFactory([
          new DartUriResolver(sdk),
          generatedUriResolver,
          new PackageMapUriResolver(resourceProvider, packageMap),
          new ResourceUriResolver(resourceProvider)
        ], null, resourceProvider),
        createAnalysisOptions(),
        disableChangesAndCacheAllResults: disableChangesAndCacheAllResults,
        enableIndex: true,
        externalSummaries: externalSummaries);
  }

  AnalysisOptionsImpl createAnalysisOptions() => new AnalysisOptionsImpl()
    ..useFastaParser = analyzer.Parser.useFasta
    ..enabledExperiments = enabledExperiments;

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
    sdk = new MockSdk(resourceProvider: resourceProvider);
    testProject = convertPath('/test/lib');
    testFile = convertPath('/test/lib/test.dart');
    logger = new PerformanceLog(logBuffer);
    scheduler = new AnalysisDriverScheduler(logger);
    driver = createAnalysisDriver();
    scheduler.start();
    scheduler.status.listen(allStatuses.add);
    driver.results.listen(allResults.add);
    driver.exceptions.listen(allExceptions.add);
  }

  void tearDown() {}
}

/**
 * Wraps an [_ElementVisitorFunction] into a [GeneralizingElementVisitor].
 */
class _ElementVisitorFunctionWrapper extends GeneralizingElementVisitor {
  final _ElementVisitorFunction function;

  _ElementVisitorFunctionWrapper(this.function);

  visitElement(Element element) {
    function(element);
    super.visitElement(element);
  }
}

class _GeneratedUriResolverMock implements UriResolver {
  Source Function(Uri, Uri) resolveAbsoluteFunction;

  Uri Function(Source) restoreAbsoluteFunction;

  @override
  void clearCache() {}

  @override
  noSuchMethod(Invocation invocation) {
    throw new StateError('Unexpected invocation of ${invocation.memberName}');
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
