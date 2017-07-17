// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server/src/services/search/search_engine_internal.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:front_end/src/base/performace_logger.dart';
import 'package:front_end/src/incremental/byte_store.dart';
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
  final MemoryResourceProvider provider = new MemoryResourceProvider();
  DartSdk sdk;
  final ByteStore byteStore = new MemoryByteStore();
  final FileContentOverlay contentOverlay = new FileContentOverlay();

  final StringBuffer logBuffer = new StringBuffer();
  PerformanceLog logger;

  AnalysisDriverScheduler scheduler;

  void setUp() {
    sdk = new MockSdk(resourceProvider: provider);
    logger = new PerformanceLog(logBuffer);
    scheduler = new AnalysisDriverScheduler(logger);
    scheduler.start();
  }

  test_membersOfSubtypes_hasMembers() async {
    var a = _p('/test/a.dart');
    var b = _p('/test/b.dart');
    var c = _p('/test/c.dart');

    provider.newFile(a, '''
class A {
  void a() {}
  void b() {}
  void c() {}
}
''');
    provider.newFile(b, '''
import 'a.dart';
class B extends A {
  void a() {}
}
''');
    provider.newFile(c, '''
import 'a.dart';
class C extends A {
  void b() {}
}
''');

    var driver1 = _newDriver();
    var driver2 = _newDriver();

    driver1.addFile(a);
    driver2.addFile(b);
    driver2.addFile(c);
    await scheduler.waitForIdle();

    var resultA = await driver1.getResult(a);
    ClassElement elementA = resultA.unit.element.types[0];

    var searchEngine = new SearchEngineImpl([driver1, driver2]);
    Set<String> members = await searchEngine.membersOfSubtypes(elementA);
    expect(members, unorderedEquals(['a', 'b']));
  }

  test_membersOfSubtypes_noMembers() async {
    var a = _p('/test/a.dart');
    var b = _p('/test/b.dart');

    provider.newFile(a, '''
class A {
  void a() {}
  void b() {}
  void c() {}
}
''');
    provider.newFile(b, '''
import 'a.dart';
class B extends A {}
''');

    var driver = _newDriver();

    driver.addFile(a);
    driver.addFile(b);
    await scheduler.waitForIdle();

    var resultA = await driver.getResult(a);
    ClassElement elementA = resultA.unit.element.types[0];

    var searchEngine = new SearchEngineImpl([driver]);
    Set<String> members = await searchEngine.membersOfSubtypes(elementA);
    expect(members, isEmpty);
  }

  test_membersOfSubtypes_noSubtypes() async {
    var a = _p('/test/a.dart');
    var b = _p('/test/b.dart');

    provider.newFile(a, '''
class A {
  void a() {}
  void b() {}
  void c() {}
}
''');
    provider.newFile(b, '''
import 'a.dart';
class B {
  void a() {}
}
''');

    var driver = _newDriver();

    driver.addFile(a);
    driver.addFile(b);
    await scheduler.waitForIdle();

    var resultA = await driver.getResult(a);
    ClassElement elementA = resultA.unit.element.types[0];

    var searchEngine = new SearchEngineImpl([driver]);
    Set<String> members = await searchEngine.membersOfSubtypes(elementA);
    expect(members, isNull);
  }

  test_membersOfSubtypes_private() async {
    var a = _p('/test/a.dart');
    var b = _p('/test/b.dart');

    provider.newFile(a, '''
class A {
  void a() {}
  void _b() {}
  void _c() {}
}
class B extends A {
  void _b() {}
}
''');
    provider.newFile(b, '''
import 'a.dart';
class C extends A {
  void a() {}
  void _c() {}
}
class D extends B {
  void _c() {}
}
''');

    var driver1 = _newDriver();
    var driver2 = _newDriver();

    driver1.addFile(a);
    driver2.addFile(b);
    await scheduler.waitForIdle();

    var resultA = await driver1.getResult(a);
    ClassElement elementA = resultA.unit.element.types[0];

    var searchEngine = new SearchEngineImpl([driver1, driver2]);
    Set<String> members = await searchEngine.membersOfSubtypes(elementA);
    expect(members, unorderedEquals(['a', '_b']));
  }

  test_searchAllSubtypes() async {
    var p = _p('/test.dart');

    provider.newFile(p, '''
class T {}
class A extends T {}
class B extends A {}
class C implements B {}
''');

    var driver = _newDriver();
    driver.addFile(p);

    var resultA = await driver.getResult(p);
    ClassElement element = resultA.unit.element.types[0];

    var searchEngine = new SearchEngineImpl([driver]);
    Set<ClassElement> subtypes = await searchEngine.searchAllSubtypes(element);
    expect(subtypes, hasLength(3));
    expect(subtypes, contains(predicate((ClassElement e) => e.name == 'A')));
    expect(subtypes, contains(predicate((ClassElement e) => e.name == 'B')));
    expect(subtypes, contains(predicate((ClassElement e) => e.name == 'C')));
  }

  test_searchAllSubtypes_acrossDrivers() async {
    var a = _p('/test/a.dart');
    var b = _p('/test/b.dart');

    provider.newFile(a, '''
class T {}
class A extends T {}
''');
    provider.newFile(b, '''
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

    var searchEngine = new SearchEngineImpl([driver1, driver2]);
    Set<ClassElement> subtypes = await searchEngine.searchAllSubtypes(element);
    expect(subtypes, hasLength(3));
    expect(subtypes, contains(predicate((ClassElement e) => e.name == 'A')));
    expect(subtypes, contains(predicate((ClassElement e) => e.name == 'B')));
    expect(subtypes, contains(predicate((ClassElement e) => e.name == 'C')));
  }

  test_searchMemberDeclarations() async {
    var a = _p('/test/a.dart');
    var b = _p('/test/b.dart');

    var codeA = '''
class A {
  int test; // 1
  int testTwo;
}
''';
    var codeB = '''
class B {
  void test() {} // 2
  void testTwo() {}
}
int test;
''';

    provider.newFile(a, codeA);
    provider.newFile(b, codeB);

    var driver1 = _newDriver();
    var driver2 = _newDriver();

    driver1.addFile(a);
    driver2.addFile(b);

    while (scheduler.isAnalyzing) {
      await new Future.delayed(new Duration(milliseconds: 1));
    }

    var searchEngine = new SearchEngineImpl([driver1, driver2]);
    List<SearchMatch> matches =
        await searchEngine.searchMemberDeclarations('test');
    expect(matches, hasLength(2));

    void assertHasElement(String name, int nameOffset) {
      expect(
          matches,
          contains(predicate((SearchMatch m) =>
              m.kind == MatchKind.DECLARATION &&
              m.element.name == name &&
              m.element.nameOffset == nameOffset)));
    }

    assertHasElement('test', codeA.indexOf('test; // 1'));
    assertHasElement('test', codeB.indexOf('test() {} // 2'));
  }

  test_searchMemberReferences() async {
    var a = _p('/test/a.dart');
    var b = _p('/test/b.dart');

    provider.newFile(a, '''
class A {
  int test;
}
foo(p) {
  p.test;
}
''');
    provider.newFile(b, '''
import 'a.dart';
bar(p) {
  p.test = 1;
}
''');

    var driver1 = _newDriver();
    var driver2 = _newDriver();

    driver1.addFile(a);
    driver2.addFile(b);

    var searchEngine = new SearchEngineImpl([driver1, driver2]);
    List<SearchMatch> matches =
        await searchEngine.searchMemberReferences('test');
    expect(matches, hasLength(2));
    expect(
        matches,
        contains(predicate((SearchMatch m) =>
            m.element.name == 'foo' || m.kind == MatchKind.READ)));
    expect(
        matches,
        contains(predicate((SearchMatch m) =>
            m.element.name == 'bar' || m.kind == MatchKind.WRITE)));
  }

  test_searchReferences() async {
    var a = _p('/test/a.dart');
    var b = _p('/test/b.dart');

    provider.newFile(a, '''
class T {}
T a;
''');
    provider.newFile(b, '''
import 'a.dart';
T b;
''');

    var driver1 = _newDriver();
    var driver2 = _newDriver();

    driver1.addFile(a);
    driver2.addFile(b);

    var resultA = await driver1.getResult(a);
    ClassElement element = resultA.unit.element.types[0];

    var searchEngine = new SearchEngineImpl([driver1, driver2]);
    List<SearchMatch> matches = await searchEngine.searchReferences(element);
    expect(matches, hasLength(2));
    expect(
        matches, contains(predicate((SearchMatch m) => m.element.name == 'a')));
    expect(
        matches, contains(predicate((SearchMatch m) => m.element.name == 'b')));
  }

  test_searchTopLevelDeclarations() async {
    var a = _p('/test/a.dart');
    var b = _p('/test/b.dart');

    provider.newFile(a, '''
class A {}
int a;
''');
    provider.newFile(b, '''
class B {}
get b => 42;
''');

    var driver1 = _newDriver();
    var driver2 = _newDriver();

    driver1.addFile(a);
    driver2.addFile(b);

    while (scheduler.isAnalyzing) {
      await new Future.delayed(new Duration(milliseconds: 1));
    }

    var searchEngine = new SearchEngineImpl([driver1, driver2]);
    List<SearchMatch> matches =
        await searchEngine.searchTopLevelDeclarations('.*');
    expect(
        matches.where((match) => !match.libraryElement.isInSdk), hasLength(4));

    void assertHasElement(String name) {
      expect(
          matches,
          contains(predicate((SearchMatch m) =>
              m.kind == MatchKind.DECLARATION && m.element.name == name)));
    }

    assertHasElement('A');
    assertHasElement('a');
    assertHasElement('B');
    assertHasElement('b');
  }

  AnalysisDriver _newDriver() => new AnalysisDriver(
      scheduler,
      logger,
      provider,
      byteStore,
      contentOverlay,
      null,
      new SourceFactory(
          [new DartUriResolver(sdk), new ResourceUriResolver(provider)],
          null,
          provider),
      new AnalysisOptionsImpl()..strongMode = true);

  String _p(String path) => provider.convertPath(path);
}
