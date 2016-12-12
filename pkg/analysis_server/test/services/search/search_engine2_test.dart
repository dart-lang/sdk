// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server/src/services/search/search_engine_internal2.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../mock_sdk.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SearchEngineImpl2Test);
  });
}

@reflectiveTest
class SearchEngineImpl2Test {
  static final MockSdk sdk = new MockSdk();

  final MemoryResourceProvider provider = new MemoryResourceProvider();
  final ByteStore byteStore = new MemoryByteStore();
  final FileContentOverlay contentOverlay = new FileContentOverlay();

  final StringBuffer logBuffer = new StringBuffer();
  PerformanceLog logger;

  AnalysisDriverScheduler scheduler;

  void setUp() {
    logger = new PerformanceLog(logBuffer);
    scheduler = new AnalysisDriverScheduler(logger);
    scheduler.start();
  }

  test_searchAllSubtypes() async {
    var p = _p('/test.dart');

    provider.newFile(
        p,
        '''
class T {}
class A extends T {}
class B extends A {}
class C implements B {}
''');

    var driver = _newDriver();
    driver.addFile(p);

    var resultA = await driver.getResult(p);
    ClassElement element = resultA.unit.element.types[0];

    var searchEngine = new SearchEngineImpl2([driver]);
    Set<ClassElement> subtypes = await searchEngine.searchAllSubtypes(element);
    expect(subtypes, hasLength(3));
    expect(subtypes, contains(predicate((ClassElement e) => e.name == 'A')));
    expect(subtypes, contains(predicate((ClassElement e) => e.name == 'B')));
    expect(subtypes, contains(predicate((ClassElement e) => e.name == 'C')));
  }

  test_searchAllSubtypes_acrossDrivers() async {
    var a = _p('/test/a.dart');
    var b = _p('/test/b.dart');

    provider.newFile(
        a,
        '''
class T {}
class A extends T {}
''');
    provider.newFile(
        b,
        '''
import 'a.dart';
class B extends A {}
class C extends B {}
''');

    var driver1 = _newDriver();
    var driver2 = _newDriver();

    driver1.addFile(a);
    driver2.addFile(b);

    var resultA = await driver1.getResult(a);
    ClassElement element = resultA.unit.element.types[0];

    var searchEngine = new SearchEngineImpl2([driver1, driver2]);
    Set<ClassElement> subtypes = await searchEngine.searchAllSubtypes(element);
    expect(subtypes, hasLength(3));
    expect(subtypes, contains(predicate((ClassElement e) => e.name == 'A')));
    expect(subtypes, contains(predicate((ClassElement e) => e.name == 'B')));
    expect(subtypes, contains(predicate((ClassElement e) => e.name == 'C')));
  }

  test_searchReferences() async {
    var a = _p('/test/a.dart');
    var b = _p('/test/b.dart');

    provider.newFile(
        a,
        '''
class T {}
T a;
''');
    provider.newFile(
        b,
        '''
import 'a.dart';
T b;
''');

    var driver1 = _newDriver();
    var driver2 = _newDriver();

    driver1.addFile(a);
    driver2.addFile(b);

    var resultA = await driver1.getResult(a);
    ClassElement element = resultA.unit.element.types[0];

    var searchEngine = new SearchEngineImpl2([driver1, driver2]);
    List<SearchMatch> matches = await searchEngine.searchReferences(element);
    expect(matches, hasLength(2));
    expect(
        matches, contains(predicate((SearchMatch m) => m.element.name == 'a')));
    expect(
        matches, contains(predicate((SearchMatch m) => m.element.name == 'b')));
  }

  AnalysisDriver _newDriver() => new AnalysisDriver(
      scheduler,
      logger,
      provider,
      byteStore,
      contentOverlay,
      new SourceFactory(
          [new DartUriResolver(sdk), new ResourceUriResolver(provider)],
          null,
          provider),
      new AnalysisOptionsImpl()..strongMode = true);

  String _p(String path) => provider.convertPath(path);
}
