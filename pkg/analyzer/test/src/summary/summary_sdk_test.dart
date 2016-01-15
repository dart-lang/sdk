// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.src.summary.summary_sdk_test;

import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, CacheState;
import 'package:analyzer/src/generated/resolver.dart' show TypeProvider;
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/summary_sdk.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/task/dart.dart';
import 'package:analyzer/task/model.dart' show AnalysisContextTarget;
import 'package:analyzer/task/model.dart';
import 'package:path/path.dart' as pathos;
import 'package:unittest/unittest.dart';

import '../../generated/test_support.dart';
import '../../reflective_tests.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(SummarySdkAnalysisContextTest);
}

@reflectiveTest
class SummarySdkAnalysisContextTest {
  static String _analyzerPackagePath;
  static bool _analyzerPackagePathInitialized = false;

  static SdkBundle sdkBundle;

  SummarySdkAnalysisContext context;

  void setUp() {
    _initializeSdkContext();
  }

  test_libraryResults() {
    if (context == null) {
      return;
    }
    // verify that there are at least some interesting libraries in the bundle
    expect(sdkBundle.linkedLibraryUris, contains('dart:core'));
    expect(sdkBundle.linkedLibraryUris, contains('dart:async'));
    expect(sdkBundle.linkedLibraryUris, contains('dart:html'));
    // verify every library
    for (String uri in sdkBundle.linkedLibraryUris) {
      // TODO(scheglov) breaks at _LibraryResynthesizer.buildImplicitTopLevelVariable
      if (uri == 'dart:io' || uri == 'dart:_isolate_helper') {
        continue;
      }
      _assertLibraryResults(uri);
    }
  }

  test_sourceKind() {
    if (context == null) {
      return;
    }
    // libraries
    _assertHasSourceKind('dart:core', SourceKind.LIBRARY);
    _assertHasSourceKind('dart:async', SourceKind.LIBRARY);
    _assertHasSourceKind('dart:math', SourceKind.LIBRARY);
    // parts
    _assertHasSourceKind('dart:core/bool.dart', SourceKind.PART);
    _assertHasSourceKind('dart:async/future.dart', SourceKind.PART);
    // unknown
    _assertHasSourceKind('dart:no_such_library.dart', null);
    _assertHasSourceKind('dart:core/no_such_part.dart', null);
  }

  test_typeProvider() {
    if (context == null) {
      return;
    }
    AnalysisContextTarget target = AnalysisContextTarget.request;
    CacheEntry cacheEntry = context.getCacheEntry(target);
    bool hasResult = context.aboutToComputeResult(cacheEntry, TYPE_PROVIDER);
    expect(hasResult, isTrue);
    expect(cacheEntry.getState(TYPE_PROVIDER), CacheState.VALID);
    TypeProvider typeProvider = cacheEntry.getValue(TYPE_PROVIDER);
    expect(typeProvider.objectType, isNotNull);
    expect(typeProvider.boolType, isNotNull);
    expect(typeProvider.intType, isNotNull);
    expect(typeProvider.futureType, isNotNull);
    expect(typeProvider.futureDynamicType, isNotNull);
    expect(typeProvider.streamType, isNotNull);
    expect(typeProvider.streamDynamicType, isNotNull);
  }

  void _assertHasLibraryElement(CacheEntry cacheEntry,
      ResultDescriptor<LibraryElement> resultDescriptor) {
    bool hasResult = context.aboutToComputeResult(cacheEntry, resultDescriptor);
    expect(hasResult, isTrue);
    expect(cacheEntry.getState(resultDescriptor), CacheState.VALID);
    LibraryElement library = cacheEntry.getValue(resultDescriptor);
    expect(library, isNotNull);
  }

  void _assertHasSourceKind(String uri, SourceKind expectedValue) {
    Source target = context.sourceFactory.forUri(uri);
    CacheEntry cacheEntry = context.getCacheEntry(target);
    ResultDescriptor<SourceKind> resultDescriptor = SOURCE_KIND;
    bool hasResult = context.aboutToComputeResult(cacheEntry, resultDescriptor);
    if (expectedValue == null) {
      expect(hasResult, isFalse);
      expect(cacheEntry.getState(resultDescriptor), CacheState.INVALID);
    } else {
      expect(hasResult, isTrue);
      expect(cacheEntry.getState(resultDescriptor), CacheState.VALID);
      SourceKind value = cacheEntry.getValue(resultDescriptor);
      expect(value, expectedValue);
    }
  }

  void _assertIsLibraryElementReady(
      CacheEntry cacheEntry, ResultDescriptor<bool> resultDescriptor) {
    bool hasResult = context.aboutToComputeResult(cacheEntry, resultDescriptor);
    expect(hasResult, isTrue);
    expect(cacheEntry.getState(resultDescriptor), CacheState.VALID);
    bool ready = cacheEntry.getValue(resultDescriptor);
    expect(ready, isTrue);
  }

  void _assertLibraryResults(String uri) {
    Source target = context.sourceFactory.forUri(uri);
    CacheEntry cacheEntry = context.getCacheEntry(target);
    _assertHasLibraryElement(cacheEntry, LIBRARY_ELEMENT1);
    _assertHasLibraryElement(cacheEntry, LIBRARY_ELEMENT2);
    _assertHasLibraryElement(cacheEntry, LIBRARY_ELEMENT3);
    _assertHasLibraryElement(cacheEntry, LIBRARY_ELEMENT4);
    _assertHasLibraryElement(cacheEntry, LIBRARY_ELEMENT5);
    _assertHasLibraryElement(cacheEntry, LIBRARY_ELEMENT6);
    _assertHasLibraryElement(cacheEntry, LIBRARY_ELEMENT7);
    _assertHasLibraryElement(cacheEntry, LIBRARY_ELEMENT8);
    _assertHasLibraryElement(cacheEntry, LIBRARY_ELEMENT);
    _assertIsLibraryElementReady(cacheEntry, READY_LIBRARY_ELEMENT2);
    _assertIsLibraryElementReady(cacheEntry, READY_LIBRARY_ELEMENT5);
    _assertIsLibraryElementReady(cacheEntry, READY_LIBRARY_ELEMENT6);
  }

  void _initializeSdkBundle() {
    if (sdkBundle != null) {
      return;
    }
    // prepare analyzer path
    String analyzerPath = getAnalyzerPackagePath();
    if (analyzerPath == null) {
      return;
    }
    // prepare summary path
    String sdkSummaryPath = pathos.join(
        analyzerPath, 'test', 'src', 'summary', 'sdk_analysis_summary');
    File file = new File(sdkSummaryPath);
    if (!file.existsSync()) {
      return;
    }
    // load SdkBundle
    List<int> bytes = file.readAsBytesSync();
    sdkBundle = new SdkBundle.fromBuffer(bytes);
  }

  void _initializeSdkContext() {
    _initializeSdkBundle();
    if (sdkBundle == null) {
      return;
    }
    context = new _TestSummarySdkAnalysisContext(sdkBundle);
    DartSdk sdk = new _TestSummaryDartSdk();
    context.sourceFactory = new SourceFactory([new DartUriResolver(sdk)]);
  }

  static String getAnalyzerPackagePath() {
    if (!_analyzerPackagePathInitialized) {
      _analyzerPackagePathInitialized = true;
      _analyzerPackagePath = _computeAnalyzerPackagePath();
    }
    return _analyzerPackagePath;
  }

  /**
   * Return the path to the `analyzer` package root, or `null` if it cannot
   * be determined.
   *
   * This method expects that one of the `analyzer` tests was run, so
   * [Platform.script] is inside of the `analyzer/test` folder.
   */
  static String _computeAnalyzerPackagePath() {
    Uri uri = Platform.script;
    if (uri == null || uri.scheme != 'file') {
      return null;
    }
    String path = pathos.fromUri(uri);
    List<String> segments = pathos.split(path);
    while (segments.length > 2) {
      if (segments[segments.length - 1] == 'test' &&
          segments[segments.length - 2] == 'analyzer') {
        segments.removeLast();
        return pathos.joinAll(segments);
      }
      segments.removeLast();
    }
    return null;
  }
}

class _TestSummaryDartSdk implements DartSdk {
  @override
  Source mapDartUri(String uriStr) {
    Uri uri = Uri.parse(uriStr);
    List<String> segments = uri.pathSegments;
    if (segments.length == 1) {
      String libraryName = segments.first;
      String path = '/sdk/$libraryName/$libraryName.dart';
      return new _TestSummarySdkSource(path, uri);
    } else {
      String path = '/sdk/' + segments.join('/');
      return new _TestSummarySdkSource(path, uri);
    }
  }

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/**
 * [SummarySdkAnalysisContext] with simplified cache creation.
 */
class _TestSummarySdkAnalysisContext extends SummarySdkAnalysisContext {
  _TestSummarySdkAnalysisContext(SdkBundle bundle) : super(bundle);

  @override
  AnalysisCache createCacheFromSourceFactory(SourceFactory factory) {
    return new AnalysisCache(<CachePartition>[new SdkCachePartition(this)]);
  }
}

class _TestSummarySdkSource extends TestSourceWithUri {
  _TestSummarySdkSource(String path, Uri uri) : super(path, uri);

  @override
  bool get isInSystemLibrary => true;

  @override
  Uri resolveRelativeUri(Uri relativeUri) {
    Uri baseUri = uri;
    if (uri.scheme == 'dart') {
      String libraryName = uri.path;
      baseUri = Uri.parse('dart:$libraryName/$libraryName.dart');
    }
    return baseUri.resolveUri(relativeUri);
  }
}
