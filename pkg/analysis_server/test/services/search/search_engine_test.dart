// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server/src/services/search/search_engine_internal.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SearchEngineImplTest);
  });
}

@reflectiveTest
class SearchEngineImplTest with ResourceProviderMixin {
  DartSdk sdk;
  final ByteStore byteStore = MemoryByteStore();
  final FileContentOverlay contentOverlay = FileContentOverlay();

  final StringBuffer logBuffer = StringBuffer();
  PerformanceLog logger;

  AnalysisDriverScheduler scheduler;

  void setUp() {
    sdk = MockSdk(resourceProvider: resourceProvider);
    logger = PerformanceLog(logBuffer);
    scheduler = AnalysisDriverScheduler(logger);
    scheduler.start();
  }

  Future<void> test_membersOfSubtypes_hasMembers() async {
    var a = newFile('/test/a.dart', content: '''
class A {
  void a() {}
  void b() {}
  void c() {}
}
''').path;
    var b = newFile('/test/b.dart', content: '''
import 'a.dart';
class B extends A {
  void a() {}
}
''').path;
    var c = newFile('/test/c.dart', content: '''
import 'a.dart';
class C extends A {
  void b() {}
}
''').path;

    var driver1 = _newDriver();
    var driver2 = _newDriver();

    driver1.addFile(a);
    driver2.addFile(b);
    driver2.addFile(c);
    await scheduler.waitForIdle();

    var resultA = await driver1.getResult(a);
    var elementA = resultA.unit.declaredElement.types[0];

    var searchEngine = SearchEngineImpl([driver1, driver2]);
    var members = await searchEngine.membersOfSubtypes(elementA);
    expect(members, unorderedEquals(['a', 'b']));
  }

  Future<void> test_membersOfSubtypes_noMembers() async {
    var a = newFile('/test/a.dart', content: '''
class A {
  void a() {}
  void b() {}
  void c() {}
}
''').path;
    var b = newFile('/test/b.dart', content: '''
import 'a.dart';
class B extends A {}
''').path;

    var driver = _newDriver();

    driver.addFile(a);
    driver.addFile(b);
    await scheduler.waitForIdle();

    var resultA = await driver.getResult(a);
    var elementA = resultA.unit.declaredElement.types[0];

    var searchEngine = SearchEngineImpl([driver]);
    var members = await searchEngine.membersOfSubtypes(elementA);
    expect(members, isEmpty);
  }

  Future<void> test_membersOfSubtypes_noSubtypes() async {
    var a = newFile('/test/a.dart', content: '''
class A {
  void a() {}
  void b() {}
  void c() {}
}
''').path;
    var b = newFile('/test/b.dart', content: '''
import 'a.dart';
class B {
  void a() {}
}
''').path;

    var driver = _newDriver();

    driver.addFile(a);
    driver.addFile(b);
    await scheduler.waitForIdle();

    var resultA = await driver.getResult(a);
    var elementA = resultA.unit.declaredElement.types[0];

    var searchEngine = SearchEngineImpl([driver]);
    var members = await searchEngine.membersOfSubtypes(elementA);
    expect(members, isNull);
  }

  Future<void> test_membersOfSubtypes_private() async {
    var a = newFile('/test/a.dart', content: '''
class A {
  void a() {}
  void _b() {}
  void _c() {}
}
class B extends A {
  void _b() {}
}
''').path;
    var b = newFile('/test/b.dart', content: '''
import 'a.dart';
class C extends A {
  void a() {}
  void _c() {}
}
class D extends B {
  void _c() {}
}
''').path;

    var driver1 = _newDriver();
    var driver2 = _newDriver();

    driver1.addFile(a);
    driver2.addFile(b);
    await scheduler.waitForIdle();

    var resultA = await driver1.getResult(a);
    var elementA = resultA.unit.declaredElement.types[0];

    var searchEngine = SearchEngineImpl([driver1, driver2]);
    var members = await searchEngine.membersOfSubtypes(elementA);
    expect(members, unorderedEquals(['a', '_b']));
  }

  Future<void> test_searchAllSubtypes() async {
    var p = newFile('/test.dart', content: '''
class T {}
class A extends T {}
class B extends A {}
class C implements B {}
''').path;

    var driver = _newDriver();
    driver.addFile(p);

    var resultA = await driver.getResult(p);
    var element = resultA.unit.declaredElement.types[0];

    var searchEngine = SearchEngineImpl([driver]);
    var subtypes = await searchEngine.searchAllSubtypes(element);
    expect(subtypes, hasLength(3));
    _assertContainsClass(subtypes, 'A');
    _assertContainsClass(subtypes, 'B');
    _assertContainsClass(subtypes, 'C');
  }

  Future<void> test_searchAllSubtypes_acrossDrivers() async {
    var a = newFile('/test/a.dart', content: '''
class T {}
class A extends T {}
''').path;
    var b = newFile('/test/b.dart', content: '''
import 'a.dart';
class B extends A {}
class C extends B {}
''').path;

    var driver1 = _newDriver();
    var driver2 = _newDriver();

    driver1.addFile(a);
    driver2.addFile(b);

    var resultA = await driver1.getResult(a);
    var element = resultA.unit.declaredElement.types[0];

    var searchEngine = SearchEngineImpl([driver1, driver2]);
    var subtypes = await searchEngine.searchAllSubtypes(element);
    expect(subtypes, hasLength(3));
    expect(subtypes, contains(predicate((ClassElement e) => e.name == 'A')));
    expect(subtypes, contains(predicate((ClassElement e) => e.name == 'B')));
    expect(subtypes, contains(predicate((ClassElement e) => e.name == 'C')));
  }

  Future<void> test_searchAllSubtypes_mixin() async {
    var p = newFile('/test.dart', content: '''
class T {}

mixin A on T {}
mixin B implements T {}

class C extends T {}

mixin D on C {}
mixin E implements C {}
''').path;

    var driver = _newDriver();
    driver.addFile(p);

    var resultA = await driver.getResult(p);
    var element = resultA.unit.declaredElement.types[0];

    var searchEngine = SearchEngineImpl([driver]);
    var subtypes = await searchEngine.searchAllSubtypes(element);
    expect(subtypes, hasLength(5));
    _assertContainsClass(subtypes, 'A');
    _assertContainsClass(subtypes, 'B');
    _assertContainsClass(subtypes, 'C');
    _assertContainsClass(subtypes, 'D');
    _assertContainsClass(subtypes, 'E');
  }

  Future<void> test_searchMemberDeclarations() async {
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

    var a = newFile('/test/a.dart', content: codeA).path;
    var b = newFile('/test/b.dart', content: codeB).path;

    var driver1 = _newDriver();
    var driver2 = _newDriver();

    driver1.addFile(a);
    driver2.addFile(b);

    while (scheduler.isAnalyzing) {
      await Future.delayed(Duration(milliseconds: 1));
    }

    var searchEngine = SearchEngineImpl([driver1, driver2]);
    var matches = await searchEngine.searchMemberDeclarations('test');
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

  Future<void> test_searchMemberReferences() async {
    var a = newFile('/test/a.dart', content: '''
class A {
  int test;
}
foo(p) {
  p.test;
}
''').path;
    var b = newFile('/test/b.dart', content: '''
import 'a.dart';
bar(p) {
  p.test = 1;
}
''').path;

    var driver1 = _newDriver();
    var driver2 = _newDriver();

    driver1.addFile(a);
    driver2.addFile(b);

    var searchEngine = SearchEngineImpl([driver1, driver2]);
    var matches = await searchEngine.searchMemberReferences('test');
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

  Future<void> test_searchReferences() async {
    var a = newFile('/test/a.dart', content: '''
class T {}
T a;
''').path;
    var b = newFile('/test/b.dart', content: '''
import 'a.dart';
T b;
''').path;

    var driver1 = _newDriver();
    var driver2 = _newDriver();

    driver1.addFile(a);
    driver2.addFile(b);

    var resultA = await driver1.getResult(a);
    var element = resultA.unit.declaredElement.types[0];

    var searchEngine = SearchEngineImpl([driver1, driver2]);
    var matches = await searchEngine.searchReferences(element);
    expect(matches, hasLength(2));
    expect(
        matches, contains(predicate((SearchMatch m) => m.element.name == 'a')));
    expect(
        matches, contains(predicate((SearchMatch m) => m.element.name == 'b')));
  }

  Future<void> test_searchReferences_discover_owned() async {
    var t = newFile('/test/lib/t.dart', content: '''
import 'package:aaa/a.dart';
int t;
''').path;
    var a = newFile('/aaa/lib/a.dart', content: '''
int a;
''').path;

    var driver1 = _newDriver(packageUriResolver: _mapUriResolver('aaa', a));
    var driver2 = _newDriver();

    driver1.addFile(t);
    driver2.addFile(a);

    var coreLib = await driver1.getLibraryByUri('dart:core');
    var intElement = coreLib.getType('int');

    var searchEngine = SearchEngineImpl([driver1, driver2]);
    var matches = await searchEngine.searchReferences(intElement);

    void assertHasOne(String path, String name) {
      expect(matches.where((m) {
        var element = m.element;
        return element.name == name && element.source.fullName == path;
      }), hasLength(1));
    }

    assertHasOne(t, 't');
    assertHasOne(a, 'a');
  }

  Future<void> test_searchTopLevelDeclarations() async {
    var a = newFile('/test/a.dart', content: '''
class A {}
int a;
''').path;
    var b = newFile('/test/b.dart', content: '''
class B {}
get b => 42;
''').path;

    var driver1 = _newDriver();
    var driver2 = _newDriver();

    driver1.addFile(a);
    driver2.addFile(b);

    while (scheduler.isAnalyzing) {
      await Future.delayed(Duration(milliseconds: 1));
    }

    var searchEngine = SearchEngineImpl([driver1, driver2]);
    var matches = await searchEngine.searchTopLevelDeclarations('.*');
    matches.removeWhere((match) => match.libraryElement.isInSdk);
    expect(matches, hasLength(4));

    void assertHasOneElement(String name) {
      var nameMatches = matches.where((SearchMatch m) =>
          m.kind == MatchKind.DECLARATION && m.element.name == name);
      expect(nameMatches, hasLength(1));
    }

    assertHasOneElement('A');
    assertHasOneElement('a');
    assertHasOneElement('B');
    assertHasOneElement('b');
  }

  Future<void> test_searchTopLevelDeclarations_dependentPackage() async {
    var a = newFile('/a/lib/a.dart', content: '''
class A {}
''').path;
    var driver1 = _newDriver();
    driver1.addFile(a);

    // The package:b uses the class A from the package:a,
    // so it sees the declaration the element A.
    var b = newFile('/b/lib/b.dart', content: '''
import 'package:a/a.dart';
class B extends A {}
''');
    var driver2 = _newDriver(packageUriResolver: _mapUriResolver('a', a));
    driver2.addFile(b.path);

    while (scheduler.isAnalyzing) {
      await Future.delayed(Duration(milliseconds: 1));
    }

    var searchEngine = SearchEngineImpl([driver1, driver2]);
    var matches = await searchEngine.searchTopLevelDeclarations('.*');
    // We get exactly two items: A and B.
    // I.e. we get exactly one A.
    expect(
        matches.where((match) => !match.libraryElement.isInSdk), hasLength(2));

    void assertHasOneElement(String name) {
      var nameMatches = matches.where((SearchMatch m) =>
          m.kind == MatchKind.DECLARATION && m.element.name == name);
      expect(nameMatches, hasLength(1));
    }

    assertHasOneElement('A');
    assertHasOneElement('B');
  }

  UriResolver _mapUriResolver(String packageName, String path) {
    return PackageMapUriResolver(resourceProvider, {
      packageName: [resourceProvider.getFile(path).parent]
    });
  }

  AnalysisDriver _newDriver({UriResolver packageUriResolver}) {
    var resolvers = <UriResolver>[
      DartUriResolver(sdk),
      ResourceUriResolver(resourceProvider)
    ];
    if (packageUriResolver != null) {
      resolvers.add(packageUriResolver);
    }
    resolvers.add(ResourceUriResolver(resourceProvider));

    return AnalysisDriver(scheduler, logger, resourceProvider, byteStore,
        contentOverlay, null, SourceFactory(resolvers), AnalysisOptionsImpl(),
        packages: Packages.empty, enableIndex: true);
  }

  static void _assertContainsClass(Set<ClassElement> subtypes, String name) {
    expect(subtypes, contains(predicate((ClassElement e) => e.name == name)));
  }
}
