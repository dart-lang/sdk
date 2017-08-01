// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/status.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:front_end/src/base/performace_logger.dart';
import 'package:front_end/src/incremental/byte_store.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../context/mock_sdk.dart';

/**
 * Finds an [Element] with the given [name].
 */
Element findChildElement(Element root, String name, [ElementKind kind]) {
  Element result = null;
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

class BaseAnalysisDriverTest {
  final MemoryResourceProvider provider = new MemoryResourceProvider();
  DartSdk sdk;
  final ByteStore byteStore = new MemoryByteStore();
  final FileContentOverlay contentOverlay = new FileContentOverlay();

  final StringBuffer logBuffer = new StringBuffer();
  PerformanceLog logger;

  final UriResolver generatedUriResolver = new _GeneratedUriResolverMock();
  AnalysisDriverScheduler scheduler;
  AnalysisDriver driver;
  final List<AnalysisStatus> allStatuses = <AnalysisStatus>[];
  final List<AnalysisResult> allResults = <AnalysisResult>[];
  final List<ExceptionResult> allExceptions = <ExceptionResult>[];

  String testProject;
  String testFile;
  String testCode;

  bool get disableChangesAndCacheAllResults => false;

  void addTestFile(String content, {bool priority: false}) {
    testCode = content;
    provider.newFile(testFile, content);
    driver.addFile(testFile);
    if (priority) {
      driver.priorityFiles = [testFile];
    }
  }

  AnalysisDriver createAnalysisDriver({SummaryDataStore externalSummaries}) {
    return new AnalysisDriver(
        scheduler,
        logger,
        provider,
        byteStore,
        contentOverlay,
        null,
        new SourceFactory([
          new DartUriResolver(sdk),
          generatedUriResolver,
          new PackageMapUriResolver(provider, <String, List<Folder>>{
            'test': [provider.getFolder(testProject)]
          }),
          new ResourceUriResolver(provider)
        ], null, provider),
        new AnalysisOptionsImpl()
          ..strongMode = true
          ..enableUriInPartOf = true,
        disableChangesAndCacheAllResults: disableChangesAndCacheAllResults,
        externalSummaries: externalSummaries);
  }

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
    sdk = new MockSdk(resourceProvider: provider);
    testProject = _p('/test/lib');
    testFile = _p('/test/lib/test.dart');
    logger = new PerformanceLog(logBuffer);
    scheduler = new AnalysisDriverScheduler(logger);
    driver = createAnalysisDriver();
    scheduler.start();
    scheduler.status.listen(allStatuses.add);
    driver.results.listen(allResults.add);
    driver.exceptions.listen(allExceptions.add);
  }

  void tearDown() {}

  String _p(String path) => provider.convertPath(path);
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

class _GeneratedUriResolverMock extends Mock implements UriResolver {}
