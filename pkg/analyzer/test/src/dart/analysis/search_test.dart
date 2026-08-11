// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/search.dart';
import 'package:analyzer/src/test_utilities/find_element2.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer/src/utilities/cancellation.dart';
import 'package:analyzer_testing/package_config_file_builder.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../util/diff.dart';
import '../resolution/context_collection_resolution.dart';
import '../resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SearchTest);
    defineReflectiveTests(SearchMultipleDriversTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class SearchMultipleDriversTest extends PubPackageResolutionTest {
  @override
  List<String> get collectionIncludedPaths => [
    workspaceRootPath,
    otherPackageRootPath,
  ];

  AnalysisDriver get driver => driverFor(testFile);

  String get otherPackageRootPath => '$workspaceRootPath/other';

  test_declarations_searchesFilesOnlyOnce() async {
    // Create another driver to search in to ensure we don't get dupe results.
    var otherFile = newFile(convertPath('$otherPackageRootPath/main.dart'), '');
    var otherDriver = driverFor(otherFile);
    var results = WorkspaceSymbols();

    // Search both drivers.
    await FindDeclarations(
      [driver, otherDriver],
      results,
      '',
      null,
      ownedFiles: analysisContextCollection.ownedFiles,
      performance: OperationPerformanceImpl('<root>'),
    ).compute();

    // Ensure only one result for an SDK class, and that the file was tracked as searched.
    var declarations = results.declarations;
    expect(
      declarations.where((element) => element.name == 'Duration'),
      hasLength(1),
    );
  }
}

@reflectiveTest
class SearchTest extends PubPackageResolutionTest {
  final OperationPerformanceImpl performance = OperationPerformanceImpl(
    '<root>',
  );
  late AnalysisDriver driver = driverFor(testFile);
  Set<Uri>? includedLibraryUris;

  String get testUriStr => 'package:test/test.dart';

  void assertDeclarationsText(
    WorkspaceSymbols symbols,
    Map<File, String> inFiles,
    String expected,
  ) {
    var actual = _getDeclarationsText(symbols, inFiles);
    if (actual != expected) {
      NodeTextExpectationsCollector.add(actual);
      if (NodeTextExpectationsCollector.shouldPrintFailureDetails) {
        printPrettyDiff(expected, actual);
      }
      fail('See the difference above.');
    }
  }

  Future<void> assertDirectSubtypeReferencesText(
    InterfaceElement element,
    String expected,
  ) async {
    var results = await driver.search.directSubtypeReferences(element);
    var actual = _getSearchResultsText(results);
    if (actual != expected) {
      NodeTextExpectationsCollector.add(actual);
      if (NodeTextExpectationsCollector.shouldPrintFailureDetails) {
        printPrettyDiff(expected, actual);
      }
      fail('See the difference above.');
    }
  }

  Future<void> assertElementReferencesText(
    Element element,
    String expected,
  ) async {
    var results = await driver.search.references(element);
    var actual = _getSearchResultsText(results);
    if (actual != expected) {
      NodeTextExpectationsCollector.add(actual);
      if (NodeTextExpectationsCollector.shouldPrintFailureDetails) {
        printPrettyDiff(expected, actual);
      }
      fail('See the difference above.');
    }
  }

  Future<void> assertElementsReferencesText(
    Map<String, Element> elements,
    String expected,
  ) async {
    var resultsByLabel = <String, List<SearchResult>>{};
    for (var entry in elements.entries) {
      resultsByLabel[entry.key] = await driver.search.references(entry.value);
    }
    var actual = _getSearchResultsTextByLabel(resultsByLabel);
    if (actual != expected) {
      NodeTextExpectationsCollector.add(actual);
      if (NodeTextExpectationsCollector.shouldPrintFailureDetails) {
        printPrettyDiff(expected, actual);
      }
      fail('See the difference above.');
    }
  }

  Future<void> assertLibraryFragmentReferencesText(
    LibraryFragment fragment,
    String expected,
  ) async {
    var results = await driver.search.referencesLibraryFragment(fragment);
    var actual = _getSearchResultsText2(results);
    if (actual != expected) {
      NodeTextExpectationsCollector.add(actual);
      if (NodeTextExpectationsCollector.shouldPrintFailureDetails) {
        printPrettyDiff(expected, actual);
      }
      fail('See the difference above.');
    }
  }

  Future<void> assertLibraryImportReferencesText(
    LibraryImport import,
    String expected,
  ) async {
    var results = await driver.search.referencesLibraryImport(import);
    var actual = _getSearchResultsText2(results);
    if (actual != expected) {
      NodeTextExpectationsCollector.add(actual);
      if (NodeTextExpectationsCollector.shouldPrintFailureDetails) {
        printPrettyDiff(expected, actual);
      }
      fail('See the difference above.');
    }
  }

  Future<void> assertUnresolvedMemberReferencesText(
    String name,
    String expected,
  ) async {
    var results = await driver.search.unresolvedMemberReferences(name);
    var actual = _getSearchResultsText(results);
    if (actual != expected) {
      NodeTextExpectationsCollector.add(actual);
      if (NodeTextExpectationsCollector.shouldPrintFailureDetails) {
        printPrettyDiff(expected, actual);
      }
      fail('See the difference above.');
    }
  }

  test_classMembers_class() async {
    var result = await resolveTestCode('''
class A {
  test() {}
}
class B {
  int test = 1;
  int testTwo = 2;
  main() {
    int test = 3;
  }
}
''');
    expect(
      await _findClassMembers('test'),
      unorderedEquals([
        result.findElement.method('test', of: 'A'),
        result.findElement.field('test', of: 'B'),
      ]),
    );
  }

  test_classMembers_enum() async {
    var result = await resolveTestCode('''
enum E1 {
  v;
  void test() {}
}

enum E2 {
  v;
  final int test = 0;
}
''');
    expect(
      await _findClassMembers('test'),
      unorderedEquals([
        result.findElement.method('test', of: 'E1'),
        result.findElement.field('test', of: 'E2'),
      ]),
    );
  }

  test_classMembers_importNotDart() async {
    await resolveTestCode('''
import 'not-dart.txt';
''');
    expect(await _findClassMembers('test'), isEmpty);
  }

  test_classMembers_mixin() async {
    var result = await resolveTestCode('''
mixin A {
  test() {}
}
mixin B {
  int test = 1;
  int testTwo = 2;
  main() {
    int test = 3;
  }
}
''');
    expect(
      await _findClassMembers('test'),
      unorderedEquals([
        result.findElement.method('test', of: 'A'),
        result.findElement.field('test', of: 'B'),
      ]),
    );
  }

  test_declarations_cancel() async {
    await resolveTestCode('''
class C {
  int f;
  C();
  C.named();
  int get g => 0;
  void set s(_) {}
  void m() {}
}
''');
    var results = WorkspaceSymbols();
    var token = CancelableToken();
    var searchFuture = FindDeclarations(
      [driver],
      results,
      '',
      null,
      ownedFiles: analysisContextCollection.ownedFiles,
      performance: performance,
    ).compute(token);
    token.cancel();
    await searchFuture;
    expect(results.cancelled, isTrue);
  }

  test_declarations_class() async {
    await resolveTestCode('''
class C {
  int f;
  C();
  C.named();
  int get g => 0;
  void set s(_) {}
  void m() {}
}
''');
    var results = WorkspaceSymbols();
    await FindDeclarations(
      [driver],
      results,
      '',
      null,
      ownedFiles: analysisContextCollection.ownedFiles,
      performance: performance,
    ).compute();
    assertDeclarationsText(
      results,
      {testFile: 'testFile'},
      r'''
testFile
  CLASS C
    offset: 6 1:7
    codeOffset: 0 + 91
  FIELD f
    offset: 16 2:7
    codeOffset: 12 + 5
    className: C
  CONSTRUCTOR new
    offset: 21 3:3
    codeOffset: 21 + 4
    className: C
    parameters: ()
  CONSTRUCTOR named
    offset: 30 4:5
    codeOffset: 28 + 10
    className: C
    parameters: ()
  GETTER g
    offset: 49 5:11
    codeOffset: 41 + 15
    className: C
  SETTER s
    offset: 68 6:12
    codeOffset: 59 + 16
    className: C
    parameters: (dynamic _)
  METHOD m
    offset: 83 7:8
    codeOffset: 78 + 11
    className: C
    parameters: ()
''',
    );
  }

  test_declarations_class_unnamed() async {
    await resolveTestCode('''
class {
  void foo() {}
}
''');
    var results = WorkspaceSymbols();
    await FindDeclarations(
      [driver],
      results,
      'foo',
      null,
      ownedFiles: analysisContextCollection.ownedFiles,
      performance: performance,
    ).compute();
    assertDeclarationsText(
      results,
      {testFile: 'testFile'},
      r'''
''',
    );
  }

  test_declarations_discover() async {
    var aaaPackageRootPath = '$packagesRootPath/aaa';
    var bbbPackageRootPath = '$packagesRootPath/bbb';
    var cccPackageRootPath = '$packagesRootPath/ccc';
    var aaaFilePath = convertPath('$aaaPackageRootPath/lib/a.dart');
    var bbbFilePath = convertPath('$bbbPackageRootPath/lib/b.dart');
    var cccFilePath = convertPath('$cccPackageRootPath/lib/c.dart');

    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'aaa', rootFolder: getFolder(aaaPackageRootPath))
        ..add(name: 'bbb', rootFolder: getFolder(bbbPackageRootPath)),
    );

    var file_a = newFile(aaaFilePath, 'class A {}');
    var file_b = newFile(bbbFilePath, 'class B {}');
    var file_c = newFile(cccFilePath, 'class C {}');

    await resolveTestCode('class T {}');

    var results = WorkspaceSymbols();
    await FindDeclarations(
      [driver],
      results,
      '',
      null,
      ownedFiles: analysisContextCollection.ownedFiles,
      performance: performance,
    ).compute();

    assertDeclarationsText(
      results,
      {
        testFile: 'testFile',
        file_a: 'file_a',
        file_b: 'file_b',
        file_c: 'file_c',
      },
      r'''
testFile
  CLASS T
    offset: 6 1:7
    codeOffset: 0 + 10
file_a
  CLASS A
    offset: 6 1:7
    codeOffset: 0 + 10
file_b
  CLASS B
    offset: 6 1:7
    codeOffset: 0 + 10
''',
    );
  }

  test_declarations_enum() async {
    await resolveTestCode('''
enum E {
  a, bb, ccc
}
''');

    var results = WorkspaceSymbols();
    await FindDeclarations(
      [driver],
      results,
      '',
      null,
      ownedFiles: analysisContextCollection.ownedFiles,
      performance: performance,
    ).compute();
    assertDeclarationsText(
      results,
      {testFile: 'testFile'},
      r'''
testFile
  ENUM E
    offset: 5 1:6
    codeOffset: 0 + 23
  ENUM_CONSTANT a
    offset: 11 2:3
    codeOffset: 11 + 1
  ENUM_CONSTANT bb
    offset: 14 2:6
    codeOffset: 14 + 2
  ENUM_CONSTANT ccc
    offset: 18 2:10
    codeOffset: 18 + 3
''',
    );
  }

  test_declarations_enum_unnamed() async {
    await resolveTestCode('''
enum {
  foo
}
''');
    var results = WorkspaceSymbols();
    await FindDeclarations(
      [driver],
      results,
      'foo',
      null,
      ownedFiles: analysisContextCollection.ownedFiles,
      performance: performance,
    ).compute();
    assertDeclarationsText(
      results,
      {testFile: 'testFile'},
      r'''
''',
    );
  }

  test_declarations_extension() async {
    await resolveTestCode('''
extension E on int {
  int f;
  int get g => 0;
  void set s(_) {}
  void m() {}
}
''');
    var results = WorkspaceSymbols();
    await FindDeclarations(
      [driver],
      results,
      '',
      null,
      ownedFiles: analysisContextCollection.ownedFiles,
      performance: performance,
    ).compute();
    assertDeclarationsText(
      results,
      {testFile: 'testFile'},
      r'''
testFile
  EXTENSION E
    offset: 10 1:11
    codeOffset: 0 + 82
  FIELD f
    offset: 27 2:7
    codeOffset: 23 + 5
  GETTER g
    offset: 40 3:11
    codeOffset: 32 + 15
  SETTER s
    offset: 59 4:12
    codeOffset: 50 + 16
    parameters: (dynamic _)
  METHOD m
    offset: 74 5:8
    codeOffset: 69 + 11
    parameters: ()
''',
    );
  }

  test_declarations_extensionType() async {
    await resolveTestCode('''
extension type E(int it) {
  int get g => 0;
  void set s(_) {}
  void m() {}
}
''');
    var results = WorkspaceSymbols();
    await FindDeclarations(
      [driver],
      results,
      '',
      null,
      ownedFiles: analysisContextCollection.ownedFiles,
      performance: performance,
    ).compute();
    assertDeclarationsText(
      results,
      {testFile: 'testFile'},
      r'''
testFile
  EXTENSION_TYPE E
    offset: 15 1:16
    codeOffset: 0 + 79
  CONSTRUCTOR new
    offset: 15 1:16
    codeOffset: 15 + 9
    className: E
    parameters: (int it)
  GETTER g
    offset: 37 2:11
    codeOffset: 29 + 15
    className: E
  SETTER s
    offset: 56 3:12
    codeOffset: 47 + 16
    className: E
    parameters: (dynamic _)
  METHOD m
    offset: 71 4:8
    codeOffset: 66 + 11
    className: E
    parameters: ()
''',
    );
  }

  test_declarations_extensionType_unnamed() async {
    await resolveTestCode('''
extension type (int foo) {}
''');
    var results = WorkspaceSymbols();
    await FindDeclarations(
      [driver],
      results,
      'foo',
      null,
      ownedFiles: analysisContextCollection.ownedFiles,
      performance: performance,
    ).compute();
    assertDeclarationsText(
      results,
      {testFile: 'testFile'},
      r'''
''',
    );
  }

  test_declarations_fuzzyMatch() async {
    await resolveTestCode('''
class A {}
class B {}
class C {}
class D {}
''');
    var results = WorkspaceSymbols();
    await FindDeclarations(
      [driver],
      results,
      'A',
      null,
      ownedFiles: analysisContextCollection.ownedFiles,
      performance: performance,
    ).compute();
    assertDeclarationsText(
      results,
      {testFile: 'testFile'},
      r'''
testFile
  CLASS A
    offset: 6 1:7
    codeOffset: 0 + 10
''',
    );
  }

  test_declarations_maxResults() async {
    await resolveTestCode('''
class A {}
class B {}
class C {}
''');
    var results = WorkspaceSymbols();
    await FindDeclarations(
      [driver],
      results,
      '',
      2,
      ownedFiles: analysisContextCollection.ownedFiles,
      performance: performance,
    ).compute();
    expect(results.declarations, hasLength(2));
  }

  test_declarations_mixin() async {
    await resolveTestCode('''
mixin M {
  int f;
  int get g => 0;
  void set s(_) {}
  void m() {}
}
''');
    var results = WorkspaceSymbols();
    await FindDeclarations(
      [driver],
      results,
      '',
      null,
      ownedFiles: analysisContextCollection.ownedFiles,
      performance: performance,
    ).compute();
    assertDeclarationsText(
      results,
      {testFile: 'testFile'},
      r'''
testFile
  MIXIN M
    offset: 6 1:7
    codeOffset: 0 + 71
  FIELD f
    offset: 16 2:7
    codeOffset: 12 + 5
    mixinName: M
  GETTER g
    offset: 29 3:11
    codeOffset: 21 + 15
    mixinName: M
  SETTER s
    offset: 48 4:12
    codeOffset: 39 + 16
    mixinName: M
    parameters: (dynamic _)
  METHOD m
    offset: 63 5:8
    codeOffset: 58 + 11
    mixinName: M
    parameters: ()
''',
    );
  }

  test_declarations_mixin_unnamed() async {
    await resolveTestCode('''
mixin {
  void foo() {}
}
''');
    var results = WorkspaceSymbols();
    await FindDeclarations(
      [driver],
      results,
      'foo',
      null,
      ownedFiles: analysisContextCollection.ownedFiles,
      performance: performance,
    ).compute();
    assertDeclarationsText(
      results,
      {testFile: 'testFile'},
      r'''
''',
    );
  }

  test_declarations_onlyForFile() async {
    newFile('$testPackageLibPath/a.dart', 'class A {}');
    var b = newFile('$testPackageLibPath/b.dart', 'class B {}');

    var results = WorkspaceSymbols();
    await FindDeclarations(
      [driver],
      results,
      '',
      null,
      onlyForFile: b.path,
      ownedFiles: analysisContextCollection.ownedFiles,
      performance: performance,
    ).compute();
    expect(results.files, [b.path]);

    assertDeclarationsText(
      results,
      {testFile: 'testFile', b: 'file_b'},
      r'''
file_b
  CLASS B
    offset: 6 1:7
    codeOffset: 0 + 10
''',
    );
  }

  test_declarations_parameters() async {
    await resolveTestCode('''
class C {
  int get g => 0;
  void m(int a, double b) {}
}
void f(bool a, String b) {}
''');
    var results = WorkspaceSymbols();
    await FindDeclarations(
      [driver],
      results,
      '',
      null,
      ownedFiles: analysisContextCollection.ownedFiles,
      performance: performance,
    ).compute();
    assertDeclarationsText(
      results,
      {testFile: 'testFile'},
      r'''
testFile
  CLASS C
    offset: 6 1:7
    codeOffset: 0 + 58
  GETTER g
    offset: 20 2:11
    codeOffset: 12 + 15
    className: C
  METHOD m
    offset: 35 3:8
    codeOffset: 30 + 26
    className: C
    parameters: (int a, double b)
  FUNCTION f
    offset: 64 5:6
    codeOffset: 59 + 27
    parameters: (bool a, String b)
''',
    );
  }

  test_declarations_parameters_functionTyped() async {
    await resolveTestCode('''
void f1(bool a(int b, String c)) {}
void f2(a(b, c)) {}
void f3(bool Function(int a, String b) c) {}
void f4(bool Function(int, String) a) {}
''');
    var results = WorkspaceSymbols();
    await FindDeclarations(
      [driver],
      results,
      '',
      null,
      ownedFiles: analysisContextCollection.ownedFiles,
      performance: performance,
    ).compute();
    assertDeclarationsText(
      results,
      {testFile: 'testFile'},
      r'''
testFile
  FUNCTION f1
    offset: 5 1:6
    codeOffset: 0 + 35
    parameters: (bool Function(int, String) a)
  FUNCTION f2
    offset: 41 2:6
    codeOffset: 36 + 19
    parameters: (dynamic Function(dynamic, dynamic) a)
  FUNCTION f3
    offset: 61 3:6
    codeOffset: 56 + 44
    parameters: (bool Function(int, String) c)
  FUNCTION f4
    offset: 106 4:6
    codeOffset: 101 + 40
    parameters: (bool Function(int, String) a)
''',
    );
  }

  test_declarations_parameters_typeArguments() async {
    await resolveTestCode('''
class A<T, T2> {
  void m1(Map<int, String> a) {}
  void m2<U>(Map<T, U> a) {}
  void m3<U1, U2>(Map<Map<T2, U2>, Map<U1, T>> a) {}
}
''');
    var results = WorkspaceSymbols();
    await FindDeclarations(
      [driver],
      results,
      '',
      null,
      ownedFiles: analysisContextCollection.ownedFiles,
      performance: performance,
    ).compute();
    assertDeclarationsText(
      results,
      {testFile: 'testFile'},
      r'''
testFile
  CLASS A
    offset: 6 1:7
    codeOffset: 0 + 133
  METHOD m1
    offset: 24 2:8
    codeOffset: 19 + 30
    className: A
    parameters: (Map<int, String> a)
  METHOD m2
    offset: 57 3:8
    codeOffset: 52 + 26
    className: A
    parameters: (Map<T, U> a)
  METHOD m3
    offset: 86 4:8
    codeOffset: 81 + 50
    className: A
    parameters: (Map<Map<T2, U2>, Map<U1, T>> a)
''',
    );
  }

  test_declarations_top() async {
    await resolveTestCode('''
int get g => 0;
void set s(_) {}
void f(int p) {}
int v;
typedef void tf1();
typedef tf2<T> = int Function<S>(T tp, S sp);
''');
    var results = WorkspaceSymbols();
    await FindDeclarations(
      [driver],
      results,
      '',
      null,
      ownedFiles: analysisContextCollection.ownedFiles,
      performance: performance,
    ).compute();
    assertDeclarationsText(
      results,
      {testFile: 'testFile'},
      r'''
testFile
  GETTER g
    offset: 8 1:9
    codeOffset: 0 + 15
  SETTER s
    offset: 25 2:10
    codeOffset: 16 + 16
    parameters: (dynamic _)
  FUNCTION f
    offset: 38 3:6
    codeOffset: 33 + 16
    parameters: (int p)
  VARIABLE v
    offset: 54 4:5
    codeOffset: 50 + 5
  TYPE_ALIAS tf1
    offset: 70 5:14
    codeOffset: 57 + 19
  TYPE_ALIAS tf2
    offset: 85 6:9
    codeOffset: 77 + 45
''',
    );
  }

  test_directSubtypeReferences_class_discover2() async {
    var aaaPackageRootPath = '$packagesRootPath/aaa';
    var bbbPackageRootPath = '$packagesRootPath/bbb';
    var cccPackageRootPath = '$packagesRootPath/ccc';

    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'aaa', rootFolder: getFolder(aaaPackageRootPath))
        ..add(name: 'bbb', rootFolder: getFolder(bbbPackageRootPath)),
    );

    addTestFile('class T implements List {}');
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
class A implements List {}
''');

    newFile('$bbbPackageRootPath/lib/b.dart', r'''
class B implements List {}
''');

    newFile('$cccPackageRootPath/lib/c.dart', r'''
class C implements List {}
''');

    var coreLibResult =
        await driver.getLibraryByUri('dart:core') as LibraryElementResult;
    var listElement = coreLibResult.element.getClass('List')!;

    var results = await driver.search.directSubtypeReferences(listElement);

    void assertHasResult(String uriStr, String name, {bool not = false}) {
      var matcher = contains(
        predicate((SearchResult r) {
          var element = r.enclosingFragment.element;
          return element.library!.uri.toString() == uriStr &&
              element.name == name;
        }),
      );
      expect(results, not ? isNot(matcher) : matcher);
    }

    assertHasResult('package:test/test.dart', 'T');
    assertHasResult('package:aaa/a.dart', 'A');
    assertHasResult('package:bbb/b.dart', 'B');
    assertHasResult('package:ccc/c.dart', 'C', not: true);
  }

  test_directSubtypesWithMembers_class() async {
    var result = await resolveTestCode('''
class A {}

class B extends A {
  void methodB() {}
}

class C extends Object with A {
  void methodC() {}
}

class D implements A {
  void methodD() {}
}

class E extends B {
  void methodE() {}
}

class F {}
''');
    var a = result.findElement.class_('A');

    // Search by 'type'.
    var directSubtypes = await driver.search.directSubtypesWithMembersOfType(a);
    expect(directSubtypes, hasLength(3));

    DirectSubtypeWithMembers b = directSubtypes.singleWhere(
      (r) => r.name == 'B',
    );
    DirectSubtypeWithMembers c = directSubtypes.singleWhere(
      (r) => r.name == 'C',
    );
    DirectSubtypeWithMembers d = directSubtypes.singleWhere(
      (r) => r.name == 'D',
    );

    expect(b.library.resource, testFile);
    expect(b.id, '${testFile.path};${testFile.path};B');
    expect(b.members, ['methodB']);

    expect(c.library.resource, testFile);
    expect(c.id, '${testFile.path};${testFile.path};C');
    expect(c.members, ['methodC']);

    expect(d.library.resource, testFile);
    expect(d.id, '${testFile.path};${testFile.path};D');
    expect(d.members, ['methodD']);

    // Search by 'id'.
    {
      var directSubtypes = await driver.search
          .directSubtypesWithMembersOfSubtype(b);
      expect(directSubtypes, hasLength(1));
      DirectSubtypeWithMembers e = directSubtypes.singleWhere(
        (r) => r.name == 'E',
      );
      expect(e.members, ['methodE']);
    }
  }

  test_directSubtypesWithMembers_class_discover() async {
    var aaaPackageRootPath = '$packagesRootPath/aaa';
    var bbbPackageRootPath = '$packagesRootPath/bbb';

    var aaaFilePath = convertPath('$aaaPackageRootPath/lib/a.dart');
    var bbbFilePath = convertPath('$bbbPackageRootPath/lib/b.dart');

    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'aaa', rootFolder: getFolder(aaaPackageRootPath))
        ..add(name: 'bbb', rootFolder: getFolder(bbbPackageRootPath)),
    );

    var aUri = 'package:aaa/a.dart';

    addTestFile(r'''
import 'package:aaa/a.dart';

class T1 extends A {
  void method1() {}
}

class T2 extends A {
  void method2() {}
}
''');

    newFile(bbbFilePath, r'''
import 'package:aaa/a.dart';

class B extends A {
  void method1() {}
}
''');

    newFile(aaaFilePath, r'''
class A {
  void method1() {}
  void method2() {}
}
''');

    var aLibraryResult =
        await driver.getLibraryByUri(aUri) as LibraryElementResult;
    var aClass = aLibraryResult.element.getClass('A')!;

    // Search by 'type'.
    var directSubtypes = await driver.search.directSubtypesWithMembersOfType(
      aClass,
    );
    expect(directSubtypes, hasLength(3));

    DirectSubtypeWithMembers t1 = directSubtypes.singleWhere(
      (r) => r.name == 'T1',
    );
    DirectSubtypeWithMembers t2 = directSubtypes.singleWhere(
      (r) => r.name == 'T2',
    );
    DirectSubtypeWithMembers b = directSubtypes.singleWhere(
      (r) => r.name == 'B',
    );

    expect(t1.library.resource, testFile);
    expect(t1.id, '${testFile.path};${testFile.path};T1');
    expect(t1.members, ['method1']);

    expect(t2.library.resource, testFile);
    expect(t2.id, '${testFile.path};${testFile.path};T2');
    expect(t2.members, ['method2']);

    expect(b.library.resource, getFile(bbbFilePath));
    expect(b.id, '$bbbFilePath;$bbbFilePath;B');
    expect(b.members, ['method1']);
  }

  test_directSubtypesWithMembers_class_files() async {
    String pathB = convertPath('$testPackageLibPath/b.dart');
    String pathC = convertPath('$testPackageLibPath/c.dart');
    newFile(pathB, r'''
import 'test.dart';
class B extends A {}
''');
    newFile(pathC, r'''
import 'test.dart';
class C extends A {}
class D {}
''');

    var result = await resolveTestCode('''
class A {}
''');
    var a = result.findElement.class_('A');

    var directSubtypes = await driver.search.directSubtypesWithMembersOfType(a);
    expect(directSubtypes, hasLength(2));

    DirectSubtypeWithMembers b = directSubtypes.singleWhere(
      (r) => r.name == 'B',
    );
    DirectSubtypeWithMembers c = directSubtypes.singleWhere(
      (r) => r.name == 'C',
    );

    expect(b.id, endsWith('b.dart;B'));
    expect(c.id, endsWith('c.dart;C'));
  }

  test_directSubtypesWithMembers_class_missingName() async {
    var result = await resolveTestCode('''
class {}
''');
    var a = result.findElement.libraryElement.classes.single;
    var directSubtypes = await driver.search.directSubtypesWithMembersOfType(a);
    expect(directSubtypes, isEmpty);
  }

  test_directSubtypesWithMembers_enum() async {
    var result = await resolveTestCode('''
class A {}

enum E1 implements A {
  v;
  void methodE1() {}
}

enum E2 with A {
  v;
  void methodE2() {}
}

class B {}
''');

    var directSubtypes = await driver.search.directSubtypesWithMembersOfType(
      result.findElement.class_('A'),
    );
    expect(directSubtypes, hasLength(2));

    var resultE1 = directSubtypes.singleWhere((r) => r.name == 'E1');
    var resultE2 = directSubtypes.singleWhere((r) => r.name == 'E2');

    expect(resultE1.library.resource, testFile);
    expect(resultE1.id, '${testFile.path};${testFile.path};E1');
    expect(resultE1.members, ['methodE1']);

    expect(resultE2.library.resource, testFile);
    expect(resultE2.id, '${testFile.path};${testFile.path};E2');
    expect(resultE2.members, ['methodE2']);
  }

  test_directSubtypesWithMembers_extensionType() async {
    var result = await resolveTestCode('''
class A {}

extension type E1(A it) implements A {
  void methodE1() {}
}

extension type E2(A it) implements A {
  void methodE2() {}
}
''');

    var directSubtypes = await driver.search.directSubtypesWithMembersOfType(
      result.findElement.class_('A'),
    );
    expect(directSubtypes, hasLength(2));

    var resultE1 = directSubtypes.singleWhere((r) => r.name == 'E1');
    var resultE2 = directSubtypes.singleWhere((r) => r.name == 'E2');

    expect(resultE1.library.resource, testFile);
    expect(resultE1.id, '${testFile.path};${testFile.path};E1');
    expect(resultE1.members, ['methodE1']);

    expect(resultE2.library.resource, testFile);
    expect(resultE2.id, '${testFile.path};${testFile.path};E2');
    expect(resultE2.members, ['methodE2']);
  }

  test_directSubtypesWithMembers_extensionType2() async {
    var result = await resolveTestCode('''
extension type A(int it) {}

extension type B(int it) implements A {
  void methodB() {}
}
''');

    var directSubtypes = await driver.search.directSubtypesWithMembersOfType(
      result.findElement.extensionType('A'),
    );
    expect(directSubtypes, hasLength(1));

    var B = directSubtypes.singleWhere((r) => r.name == 'B');

    expect(B.library.resource, testFile);
    expect(B.id, '${testFile.path};${testFile.path};B');
    expect(B.members, ['methodB']);
  }

  test_directSubtypesWithMembers_mixin_superclassConstraints() async {
    var result = await resolveTestCode('''
class A {
  void methodA() {}
}

class B {
  void methodB() {}
}

mixin M on A, B {
  void methodA() {}
  void methodM() {}
}
''');
    var a = result.findElement.class_('A');
    var b = result.findElement.class_('B');

    {
      var directSubtypes = await driver.search.directSubtypesWithMembersOfType(
        a,
      );
      expect(directSubtypes, hasLength(1));

      var m = directSubtypes.singleWhere((r) => r.name == 'M');
      expect(m.library.resource, testFile);
      expect(m.id, '${testFile.path};${testFile.path};M');
      expect(m.members, ['methodA', 'methodM']);
    }

    {
      var directSubtypes = await driver.search.directSubtypesWithMembersOfType(
        b,
      );
      expect(directSubtypes, hasLength(1));

      var m = directSubtypes.singleWhere((r) => r.name == 'M');
      expect(m.library.resource, testFile);
      expect(m.id, '${testFile.path};${testFile.path};M');
      expect(m.members, ['methodA', 'methodM']);
    }
  }

  test_issue49951_references_dontAddToKnown_unrelated() async {
    var myRoot = newFolder('$workspaceRootPath/packages/my');

    var myFile = newFile('${myRoot.path}/lib/my.dart', r'''
class A {}
''');

    // Configure `package:my`.
    writePackageConfig(
      myRoot.path,
      PackageConfigFileBuilder()..add(name: 'my', rootFolder: myRoot),
    );

    var mySession = contextFor(myFile).currentSession;
    var libraryElementResult = await mySession.getLibraryByUri(
      'package:my/my.dart',
    );
    libraryElementResult as LibraryElementResult;

    var A = libraryElementResult.element.getClass('A')!;

    var testDriver = driverFor(testFile);

    // No references, but this is not the most important.
    var references = await testDriver.search.references(A);
    expect(references, isEmpty);

    // We should not add the file to known files. It is not in the
    // `package:test` itself, and not in a package from its package config.
    // So, it is absolutely unrelated to `package:test`.
    for (var knowFile in testDriver.fsState.knownFiles) {
      if (knowFile.path == myFile.path) {
        fail('The file should not be added.');
      }
    }
  }

  test_sameNameDeclarations_class() async {
    var result = await resolveTestCode('''
class Foo {
  Foo.bar() {
    bar();
  }
  void bar() => Foo.bar();
}
''');
    var results = WorkspaceSymbols();
    await FindDeclarations(
      [driver],
      results,
      '',
      null,
      ownedFiles: analysisContextCollection.ownedFiles,
      performance: performance,
    ).compute();
    assertDeclarationsText(
      results,
      {testFile: 'testFile'},
      r'''
testFile
  CLASS Foo
    offset: 6 1:7
    codeOffset: 0 + 69
  CONSTRUCTOR bar
    offset: 18 2:7
    codeOffset: 14 + 26
    className: Foo
    parameters: ()
  METHOD bar
    offset: 48 5:8
    codeOffset: 43 + 24
    className: Foo
    parameters: ()
''',
    );
    Element element = result.findElement.constructor('bar');
    await assertElementReferencesText(element, '''
class Foo {
  Foo.bar() {
    bar();
  }
  void bar() => Foo.bar();
                   ^^^^ INVOCATION qualified
}
''');
    element = result.findElement.method('bar');
    await assertElementReferencesText(element, r'''
class Foo {
  Foo.bar() {
    bar();
    ^^^ INVOCATION
  }
  void bar() => Foo.bar();
}
''');
  }

  test_scenario_ClassElement_hierarchy_class_extends() async {
    var result = await resolveTestCode(r'''
import 'test.dart' as p;

class A {}

class B extends A {}
class B_q extends p.A {}
''');
    var element = result.findElement.class_('A');

    await assertElementReferencesText(element, r'''
import 'test.dart' as p;

class A {}

class B extends A {}
                ^ REFERENCE
class B_q extends p.A {}
                    ^ REFERENCE qualified
''');

    await assertDirectSubtypeReferencesText(element, r'''
import 'test.dart' as p;

class A {}

class B extends A {}
                ^ REFERENCE_IN_EXTENDS_CLAUSE
class B_q extends p.A {}
                    ^ REFERENCE_IN_EXTENDS_CLAUSE qualified
''');
  }

  test_scenario_ClassElement_hierarchy_class_extends_implicitObject() async {
    var result = await resolveTestCode('''
class A {}
''');
    includedLibraryUris = {Uri.parse(testUriStr)};
    var element = result.typeProvider.objectType.element;
    await assertElementReferencesText(element, r'''''');
    await assertDirectSubtypeReferencesText(element, '');
  }

  test_scenario_ClassElement_hierarchy_class_implements() async {
    var result = await resolveTestCode(r'''
import 'test.dart' as p;

class A {}

class B implements A {}
class B_q implements p.A {}
''');
    var element = result.findElement.class_('A');

    await assertElementReferencesText(element, r'''
import 'test.dart' as p;

class A {}

class B implements A {}
                   ^ REFERENCE
class B_q implements p.A {}
                       ^ REFERENCE qualified
''');

    await assertDirectSubtypeReferencesText(element, r'''
import 'test.dart' as p;

class A {}

class B implements A {}
                   ^ REFERENCE_IN_IMPLEMENTS_CLAUSE
class B_q implements p.A {}
                       ^ REFERENCE_IN_IMPLEMENTS_CLAUSE qualified
''');
  }

  test_scenario_ClassElement_hierarchy_class_with() async {
    var result = await resolveTestCode(r'''
import 'test.dart' as p;

class A {}

class D extends Object with A {}
class D_q extends Object with p.A {}
''');
    var element = result.findElement.class_('A');

    await assertElementReferencesText(element, r'''
import 'test.dart' as p;

class A {}

class D extends Object with A {}
                            ^ REFERENCE
class D_q extends Object with p.A {}
                                ^ REFERENCE qualified
''');

    await assertDirectSubtypeReferencesText(element, r'''
import 'test.dart' as p;

class A {}

class D extends Object with A {}
                            ^ REFERENCE_IN_WITH_CLAUSE
class D_q extends Object with p.A {}
                                ^ REFERENCE_IN_WITH_CLAUSE qualified
''');
  }

  test_scenario_ClassElement_hierarchy_classTypeAlias_with() async {
    var result = await resolveTestCode(r'''
import 'test.dart' as p;

class A {}

class D2 = Object with A;
class D2_q = Object with p.A;
''');
    var element = result.findElement.class_('A');

    await assertElementReferencesText(element, r'''
import 'test.dart' as p;

class A {}

class D2 = Object with A;
                       ^ REFERENCE
class D2_q = Object with p.A;
                           ^ REFERENCE qualified
''');

    await assertDirectSubtypeReferencesText(element, r'''
import 'test.dart' as p;

class A {}

class D2 = Object with A;
                       ^ REFERENCE_IN_WITH_CLAUSE
class D2_q = Object with p.A;
                           ^ REFERENCE_IN_WITH_CLAUSE qualified
''');
  }

  test_scenario_ClassElement_hierarchy_enum_implements() async {
    var result = await resolveTestCode(r'''
import 'test.dart' as p;

class A {}

enum E implements A { v }
enum E_q implements p.A { v }
''');
    var element = result.findElement.class_('A');

    await assertElementReferencesText(element, r'''
import 'test.dart' as p;

class A {}

enum E implements A { v }
                  ^ REFERENCE
enum E_q implements p.A { v }
                      ^ REFERENCE qualified
''');

    await assertDirectSubtypeReferencesText(element, r'''
import 'test.dart' as p;

class A {}

enum E implements A { v }
                  ^ REFERENCE_IN_IMPLEMENTS_CLAUSE
enum E_q implements p.A { v }
                      ^ REFERENCE_IN_IMPLEMENTS_CLAUSE qualified
''');
  }

  test_scenario_ClassElement_hierarchy_extensionType_implements() async {
    var result = await resolveTestCode(r'''
import 'test.dart' as p;

class A {}

extension type E(A it) implements A {}
extension type E_q(A it) implements p.A {}
''');
    var element = result.findElement.class_('A');

    await assertElementReferencesText(element, r'''
import 'test.dart' as p;

class A {}

extension type E(A it) implements A {}
                 ^ REFERENCE
                                  ^ REFERENCE
extension type E_q(A it) implements p.A {}
                   ^ REFERENCE
                                      ^ REFERENCE qualified
''');

    await assertDirectSubtypeReferencesText(element, r'''
import 'test.dart' as p;

class A {}

extension type E(A it) implements A {}
                                  ^ REFERENCE_IN_IMPLEMENTS_CLAUSE
extension type E_q(A it) implements p.A {}
                                      ^ REFERENCE_IN_IMPLEMENTS_CLAUSE qualified
''');
  }

  test_scenario_ClassElement_hierarchy_mixin_implements() async {
    var result = await resolveTestCode(r'''
import 'test.dart' as p;

class A {}

mixin M implements A {}
mixin M_q implements p.A {}
''');
    var element = result.findElement.class_('A');

    await assertElementReferencesText(element, r'''
import 'test.dart' as p;

class A {}

mixin M implements A {}
                   ^ REFERENCE
mixin M_q implements p.A {}
                       ^ REFERENCE qualified
''');

    await assertDirectSubtypeReferencesText(element, r'''
import 'test.dart' as p;

class A {}

mixin M implements A {}
                   ^ REFERENCE_IN_IMPLEMENTS_CLAUSE
mixin M_q implements p.A {}
                       ^ REFERENCE_IN_IMPLEMENTS_CLAUSE qualified
''');
  }

  test_scenario_ClassElement_hierarchy_mixin_on() async {
    var result = await resolveTestCode(r'''
import 'test.dart' as p;

class A {}

mixin M2 on A {}
mixin M2_q on p.A {}
''');
    var element = result.findElement.class_('A');

    await assertElementReferencesText(element, r'''
import 'test.dart' as p;

class A {}

mixin M2 on A {}
            ^ REFERENCE
mixin M2_q on p.A {}
                ^ REFERENCE qualified
''');

    await assertDirectSubtypeReferencesText(element, r'''
import 'test.dart' as p;

class A {}

mixin M2 on A {}
            ^ REFERENCE_IN_ON_CLAUSE
mixin M2_q on p.A {}
                ^ REFERENCE_IN_ON_CLAUSE qualified
''');
  }

  test_scenario_ExtensionTypeElement_hierarchy_extensionType_implements() async {
    var result = await resolveTestCode(r'''
import 'test.dart' as p;

extension type A(int it) {}

extension type B(int it) implements A {}
extension type B_q(int it) implements p.A {}
''');
    var element = result.findElement.extensionType('A');
    await assertElementReferencesText(element, r'''
import 'test.dart' as p;

extension type A(int it) {}

extension type B(int it) implements A {}
                                    ^ REFERENCE
extension type B_q(int it) implements p.A {}
                                        ^ REFERENCE qualified
''');

    await assertDirectSubtypeReferencesText(element, r'''
import 'test.dart' as p;

extension type A(int it) {}

extension type B(int it) implements A {}
                                    ^ REFERENCE_IN_IMPLEMENTS_CLAUSE
extension type B_q(int it) implements p.A {}
                                        ^ REFERENCE_IN_IMPLEMENTS_CLAUSE qualified
''');
  }

  test_scenario_MixinElement_hierarchy_class_implements() async {
    var result = await resolveTestCode(r'''
mixin A {}
class B implements A {}
''');
    var element = result.findElement.mixin('A');

    await assertElementReferencesText(element, r'''
mixin A {}
class B implements A {}
                   ^ REFERENCE
''');

    await assertDirectSubtypeReferencesText(element, r'''
mixin A {}
class B implements A {}
                   ^ REFERENCE_IN_IMPLEMENTS_CLAUSE
''');
  }

  test_scenario_MixinElement_hierarchy_class_with() async {
    var result = await resolveTestCode(r'''
mixin A {}
class B extends Object with A {}
''');
    var element = result.findElement.mixin('A');

    await assertElementReferencesText(element, r'''
mixin A {}
class B extends Object with A {}
                            ^ REFERENCE
''');

    await assertDirectSubtypeReferencesText(element, r'''
mixin A {}
class B extends Object with A {}
                            ^ REFERENCE_IN_WITH_CLAUSE
''');
  }

  test_scenario_MixinElement_hierarchy_classTypeAlias_with() async {
    var result = await resolveTestCode(r'''
mixin A {}
class B = Object with A;
''');
    var element = result.findElement.mixin('A');

    await assertElementReferencesText(element, r'''
mixin A {}
class B = Object with A;
                      ^ REFERENCE
''');

    await assertDirectSubtypeReferencesText(element, r'''
mixin A {}
class B = Object with A;
                      ^ REFERENCE_IN_WITH_CLAUSE
''');
  }

  test_scenario_MixinElement_hierarchy_enum_implements() async {
    var result = await resolveTestCode(r'''
mixin A {}
enum E implements A {
  v
}
''');
    var element = result.findElement.mixin('A');

    await assertElementReferencesText(element, r'''
mixin A {}
enum E implements A {
                  ^ REFERENCE
  v
}
''');

    await assertDirectSubtypeReferencesText(element, r'''
mixin A {}
enum E implements A {
                  ^ REFERENCE_IN_IMPLEMENTS_CLAUSE
  v
}
''');
  }

  test_scenario_MixinElement_hierarchy_enum_with() async {
    var result = await resolveTestCode(r'''
mixin A {}
enum E with A {
  v
}
''');
    var element = result.findElement.mixin('A');

    await assertElementReferencesText(element, r'''
mixin A {}
enum E with A {
            ^ REFERENCE
  v
}
''');

    await assertDirectSubtypeReferencesText(element, r'''
mixin A {}
enum E with A {
            ^ REFERENCE_IN_WITH_CLAUSE
  v
}
''');
  }

  test_scenario_MixinElement_hierarchy_extensionType_implements() async {
    var result = await resolveTestCode(r'''
mixin A {}
extension type E(A it) implements A {}
''');
    var element = result.findElement.mixin('A');

    await assertElementReferencesText(element, r'''
mixin A {}
extension type E(A it) implements A {}
                 ^ REFERENCE
                                  ^ REFERENCE
''');

    await assertDirectSubtypeReferencesText(element, r'''
mixin A {}
extension type E(A it) implements A {}
                                  ^ REFERENCE_IN_IMPLEMENTS_CLAUSE
''');
  }

  test_scenario_MixinElement_hierarchy_mixin_implements() async {
    var result = await resolveTestCode(r'''
mixin A {}
mixin M implements A {}
''');
    var element = result.findElement.mixin('A');

    await assertElementReferencesText(element, r'''
mixin A {}
mixin M implements A {}
                   ^ REFERENCE
''');

    await assertDirectSubtypeReferencesText(element, r'''
mixin A {}
mixin M implements A {}
                   ^ REFERENCE_IN_IMPLEMENTS_CLAUSE
''');
  }

  test_scenario_MixinElement_hierarchy_mixin_on() async {
    var result = await resolveTestCode(r'''
mixin A {}
mixin M on A {}
''');
    var element = result.findElement.mixin('A');

    await assertElementReferencesText(element, r'''
mixin A {}
mixin M on A {}
           ^ REFERENCE
''');

    await assertDirectSubtypeReferencesText(element, r'''
mixin A {}
mixin M on A {}
           ^ REFERENCE_IN_ON_CLAUSE
''');
  }

  test_scenario_TypeAliasElement_modern_hierarchy_class_extends() async {
    var result = await resolveTestCode('''
class A<T> {}
typedef B = A<int>;
class C extends B {}
''');

    var element = result.findElement.typeAlias('B');
    await assertElementReferencesText(element, r'''
class A<T> {}
typedef B = A<int>;
class C extends B {}
                ^ REFERENCE
''');

    var aliasedClass = result.findElement.class_('A');
    // TODO(scheglov): Subtypes for the aliased class should be reported.
    await assertDirectSubtypeReferencesText(aliasedClass, r'''
''');
  }

  test_scenario_TypeAliasElement_modern_hierarchy_class_implements() async {
    var result = await resolveTestCode('''
class A<T> {}
typedef B = A<int>;
class C implements B {}
''');

    var element = result.findElement.typeAlias('B');
    await assertElementReferencesText(element, r'''
class A<T> {}
typedef B = A<int>;
class C implements B {}
                   ^ REFERENCE
''');

    var aliasedClass = result.findElement.class_('A');
    // TODO(scheglov): Subtypes for the aliased class should be reported.
    await assertDirectSubtypeReferencesText(aliasedClass, r'''
''');
  }

  test_scenario_TypeAliasElement_modern_hierarchy_class_with() async {
    var result = await resolveTestCode('''
class A<T> {}
typedef B = A<int>;
class C extends Object with B {}
''');

    var element = result.findElement.typeAlias('B');
    await assertElementReferencesText(element, r'''
class A<T> {}
typedef B = A<int>;
class C extends Object with B {}
                            ^ REFERENCE
''');

    var aliasedClass = result.findElement.class_('A');
    // TODO(scheglov): Subtypes for the aliased class should be reported.
    await assertDirectSubtypeReferencesText(aliasedClass, r'''
''');
  }

  test_searchMemberReferences_qualified_resolved() async {
    await resolveTestCode('''
class C {
  var test;
}
main(C c) {
  c.test;
  c.test = 1;
  c.test += 2;
  c.test();
}
''');

    await assertUnresolvedMemberReferencesText('test', '');
  }

  test_searchMemberReferences_qualified_unresolved() async {
    await resolveTestCode('''
void f(p) {
  p.test;
  p.test = 1;
  p.test += 2;
  p.test();
}
''');

    await assertUnresolvedMemberReferencesText('test', r'''
void f(p) {
  p.test;
    ^^^^ READ qualified unresolved
  p.test = 1;
    ^^^^ WRITE qualified unresolved
  p.test += 2;
    ^^^^ READ_WRITE qualified unresolved
  p.test();
    ^^^^ INVOCATION qualified unresolved
}
''');
  }

  test_searchMemberReferences_unqualified_resolved() async {
    await resolveTestCode('''
class C {
  var test;
  main() {
    test;
    test = 1;
    test += 2;
    test();
  }
}
''');

    await assertUnresolvedMemberReferencesText('test', '');
  }

  test_searchMemberReferences_unqualified_unresolved() async {
    await resolveTestCode('''
class C {
  main() {
    print(test);
    test = 1;
    test += 2;
    test();
  }
}
''');

    await assertUnresolvedMemberReferencesText('test', r'''
class C {
  main() {
    print(test);
          ^^^^ READ unresolved
    test = 1;
    ^^^^ WRITE unresolved
    test += 2;
    ^^^^ READ_WRITE unresolved
    test();
    ^^^^ INVOCATION unresolved
  }
}
''');
  }

  test_searchReferences_analyzer_diagnosticCode() async {
    var analyzerPackageRootPath = '$workspaceRootPath/pkg/analyzer';
    writePackageConfig(
      analyzerPackageRootPath,
      PackageConfigFileBuilder()
        ..add(name: 'analyzer', rootFolder: getFolder(analyzerPackageRootPath)),
    );

    var analyzerPackageLibPath = '$analyzerPackageRootPath/lib';
    var analyzerPackageTestPath = '$analyzerPackageRootPath/test';
    var diagnosticFile = newFile(
      '$analyzerPackageLibPath/src/diagnostic/diagnostic.dart',
      r'''
const myDiagnosticCode = 0;
''',
    );

    var diagnosticLibrary = await libraryElementForFile(diagnosticFile);
    var element = diagnosticLibrary.topLevelVariables.firstWhere(
      (v) => v.name == 'myDiagnosticCode',
    );

    var analyzerTestFile = newFile('$analyzerPackageTestPath/test.dart', r'''
void f() {
  '// [diag.myDiagnosticCode]';
}
''');
    driver = driverFor(analyzerTestFile);
    driver.addFile2(analyzerTestFile);
    await driver.applyPendingFileChanges();

    await assertElementReferencesText(element, r'''
test.dart
---------
void f() {
  '// [diag.myDiagnosticCode]';
            ^^^^^^^^^^^^^^^^ REFERENCE qualified
}
''');
  }

  @FailingTest() // TODO(scheglov): implement augmentation
  test_searchReferences_class_constructor_declaredInAugmentation() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment class A {
  A.named();
}
''');

    var result = await resolveTestCode('''
part 'a.dart';

class A {
  void foo() {
    A.named();
  }
}

void f() {
  A.named();
}
''');

    var A = result.findElement.class_('A');
    var element = A.constructors.single;
    expect(element.name, 'named');

    await assertElementReferencesText(element, r'''
<testLibraryFragment>::@class::A::@method::foo
  46 5:6 |.named| INVOCATION qualified
<testLibraryFragment>::@function::f
  77 10:4 |.named| INVOCATION qualified
''');
  }

  test_searchReferences_class_getter_in_objectPattern() async {
    var result = await resolveTestCode('''
void f(Object? x) {
  if (x case A(foo: 0)) {}
  if (x case A(: var foo)) {}
}

class A {
  int get foo => 0;
}
''');
    var element = result.findElement.getter('foo');
    await assertElementReferencesText(element, r'''
void f(Object? x) {
  if (x case A(foo: 0)) {}
               ^^^ REFERENCE_IN_PATTERN_FIELD qualified
  if (x case A(: var foo)) {}
               ^0 REFERENCE_IN_PATTERN_FIELD qualified
}

class A {
  int get foo => 0;
}
''');
  }

  test_searchReferences_class_method_in_objectPattern() async {
    var result = await resolveTestCode('''
void f(Object? x) {
  if (x case A(foo: _)) {}
  if (x case A(: var foo)) {}
}

class A {
  void foo() {}
}
''');
    var element = result.findElement.method('foo');
    await assertElementReferencesText(element, r'''
void f(Object? x) {
  if (x case A(foo: _)) {}
               ^^^ REFERENCE qualified
  if (x case A(: var foo)) {}
               ^0 REFERENCE qualified
}

class A {
  void foo() {}
}
''');
  }

  test_searchReferences_class_method_in_objectPattern_otherFile() async {
    String other = convertPath('$testPackageLibPath/other.dart');
    String otherCode = '''
import 'test.dart';

void f(Object? x) {
  if (x case A(foo: _)) {}
  if (x case A(: var foo)) {}
}
''';
    newFile(other, otherCode);

    var result = await resolveTestCode('''
class A {
  void foo() {}
}
''');
    var element = result.findElement.method('foo');
    await assertElementReferencesText(element, r'''
package:test/other.dart
-----------------------
import 'test.dart';

void f(Object? x) {
  if (x case A(foo: _)) {}
               ^^^ REFERENCE qualified
  if (x case A(: var foo)) {}
               ^0 REFERENCE qualified
}
''');
  }

  test_searchReferences_ClassElement_enum() async {
    var result = await resolveTestCode('''
enum MyEnum {a}

main(MyEnum p) {
  MyEnum v;
  MyEnum.a;
}
''');
    var element = result.findElement.enum_('MyEnum');
    await assertElementReferencesText(element, r'''
enum MyEnum {a}

main(MyEnum p) {
     ^^^^^^ REFERENCE
  MyEnum v;
  ^^^^^^ REFERENCE
  MyEnum.a;
  ^^^^^^ REFERENCE
}
''');
  }

  test_searchReferences_ClassElement_mixin() async {
    var result = await resolveTestCode('''
mixin A {}
class B extends Object with A {}
''');
    var element = result.findElement.mixin('A');
    await assertElementReferencesText(element, r'''
mixin A {}
class B extends Object with A {}
                            ^ REFERENCE
''');
  }

  test_searchReferences_ClassElement_reference_annotation() async {
    var result = await resolveTestCode(r'''
import 'test.dart' as p;

class A {
  const A();
  const A.named();
  static const int myConstant = 0;
}

@A()
@p.A()
@A.named()
@p.A.named()
@A.myConstant
@p.A.myConstant
void f() {}
''');
    var element = result.findElement.class_('A');
    await assertElementReferencesText(element, r'''
import 'test.dart' as p;

class A {
  const A();
        ^ REFERENCE
  const A.named();
        ^ REFERENCE
  static const int myConstant = 0;
}

@A()
 ^ REFERENCE
@p.A()
   ^ REFERENCE qualified
@A.named()
 ^ REFERENCE
@p.A.named()
   ^ REFERENCE qualified
@A.myConstant
 ^ REFERENCE
@p.A.myConstant
   ^ REFERENCE qualified
void f() {}
''');
  }

  test_searchReferences_ClassElement_reference_annotation_typeArgument() async {
    var result = await resolveTestCode('''
class A<T> {
  const A();
}

class B {}

@A<B>()
void f() {}
''');

    var element = result.findElement.class_('B');
    await assertElementReferencesText(element, r'''
class A<T> {
  const A();
}

class B {}

@A<B>()
   ^ REFERENCE
void f() {}
''');
  }

  test_searchReferences_ClassElement_reference_classTypeAlias() async {
    var result = await resolveTestCode(r'''
class A {}
class B = Object with A;
void f(B p) {
  B v;
}
''');
    var element = result.findElement.class_('B');
    await assertElementReferencesText(element, r'''
class A {}
class B = Object with A;
void f(B p) {
       ^ REFERENCE
  B v;
  ^ REFERENCE
}
''');
  }

  test_searchReferences_ClassElement_reference_comment() async {
    var result = await resolveTestCode(r'''
import 'test.dart' as p;

class A {}

/// [A] and [p.A].
void f() {}
''');
    var element = result.findElement.class_('A');
    await assertElementReferencesText(element, r'''
import 'test.dart' as p;

class A {}

/// [A] and [p.A].
     ^ REFERENCE
               ^ REFERENCE qualified
void f() {}
''');
  }

  test_searchReferences_ClassElement_reference_definedInSdk() async {
    var result = await resolveTestCode('''
import 'dart:math';
Random v1;
Random v2;
''');
    includedLibraryUris = {Uri.parse(testUriStr)};

    var element = result.findElement.importFind('dart:math').class_('Random');
    await assertElementReferencesText(element, r'''
import 'dart:math';
Random v1;
^^^^^^ REFERENCE
Random v2;
^^^^^^ REFERENCE
''');
  }

  test_searchReferences_ClassElement_reference_definedInside() async {
    var result = await resolveTestCode('''
class A {};
main(A p) {
  A v;
}
class B1 extends A {}
class B2 implements A {}
class B3 extends Object with A {}
List<A> v2 = null;
''');
    var element = result.findElement.class_('A');
    await assertElementReferencesText(element, r'''
class A {};
main(A p) {
     ^ REFERENCE
  A v;
  ^ REFERENCE
}
class B1 extends A {}
                 ^ REFERENCE
class B2 implements A {}
                    ^ REFERENCE
class B3 extends Object with A {}
                             ^ REFERENCE
List<A> v2 = null;
     ^ REFERENCE
''');
  }

  test_searchReferences_ClassElement_reference_definedOutside() async {
    newFile('$testPackageLibPath/lib.dart', r'''
class A {};
''');
    var result = await resolveTestCode('''
import 'lib.dart';
main(A p) {
  A v;
}
''');
    var element = result.findNode.namedType('A p').element!;
    await assertElementReferencesText(element, r'''
import 'lib.dart';
main(A p) {
     ^ REFERENCE
  A v;
  ^ REFERENCE
}
''');
  }

  test_searchReferences_ClassElement_reference_instanceCreation() async {
    var result = await resolveTestCode(r'''
import 'test.dart' as p;

class A {}

void f() {
  A();
  p.A();
}
''');
    var element = result.findElement.class_('A');
    await assertElementReferencesText(element, r'''
import 'test.dart' as p;

class A {}

void f() {
  A();
  ^ REFERENCE
  p.A();
    ^ REFERENCE qualified
}
''');
  }

  test_searchReferences_ClassElement_reference_memberAccess() async {
    var result = await resolveTestCode(r'''
import 'test.dart' as p;

class A {
  static void foo() {}
}

void f() {
  A.foo();
  p.A.foo();
}
''');
    var element = result.findElement.class_('A');
    await assertElementReferencesText(element, r'''
import 'test.dart' as p;

class A {
  static void foo() {}
}

void f() {
  A.foo();
  ^ REFERENCE
  p.A.foo();
    ^ REFERENCE qualified
}
''');
  }

  test_searchReferences_ClassElement_reference_namedType() async {
    var result = await resolveTestCode(r'''
import 'test.dart' as p;

class A {}

void f() {
  A v1;
  p.A v2;
  List<A> v3;
  List<p.A> v4;
}
''');
    var element = result.findElement.class_('A');
    await assertElementReferencesText(element, r'''
import 'test.dart' as p;

class A {}

void f() {
  A v1;
  ^ REFERENCE
  p.A v2;
    ^ REFERENCE qualified
  List<A> v3;
       ^ REFERENCE
  List<p.A> v4;
         ^ REFERENCE qualified
}
''');
  }

  test_searchReferences_ClassElement_reference_recordTypeAnnotation_named() async {
    var result = await resolveTestCode('''
class A {}

void f(({int foo, A bar}) r) {}
''');
    var element = result.findElement.class_('A');
    await assertElementReferencesText(element, r'''
class A {}

void f(({int foo, A bar}) r) {}
                  ^ REFERENCE
''');
  }

  test_searchReferences_ClassElement_reference_recordTypeAnnotation_positional() async {
    var result = await resolveTestCode('''
class A {}

void f((int, A) r) {}
''');
    var element = result.findElement.class_('A');
    await assertElementReferencesText(element, r'''
class A {}

void f((int, A) r) {}
             ^ REFERENCE
''');
  }

  test_searchReferences_ClassElement_reference_typeLiteral() async {
    var result = await resolveTestCode(r'''
import 'test.dart' as p;

class A {}

var v = A;
var v_p = p.A;
''');
    var element = result.findElement.class_('A');
    await assertElementReferencesText(element, r'''
import 'test.dart' as p;

class A {}

var v = A;
        ^ REFERENCE
var v_p = p.A;
            ^ REFERENCE qualified
''');
  }

  test_searchReferences_ConstructorElement_class_annotation() async {
    var result = await resolveTestCode(r'''
import 'test.dart' as p;

class A {
  const A();
  const A.named();
}

@A()
@p.A()
@A.named()
@p.A.named()
void f() {}
''');

    var unnamed = result.findElement.unnamedConstructor('A');
    await assertElementReferencesText(unnamed, r'''
import 'test.dart' as p;

class A {
  const A();
  const A.named();
}

@A()
  ^0 INVOCATION qualified
@p.A()
    ^0 INVOCATION qualified
@A.named()
@p.A.named()
void f() {}
''');

    var named = result.findElement.constructor('named', of: 'A');
    await assertElementReferencesText(named, r'''
import 'test.dart' as p;

class A {
  const A();
  const A.named();
}

@A()
@p.A()
@A.named()
  ^^^^^^ INVOCATION qualified
@p.A.named()
    ^^^^^^ INVOCATION qualified
void f() {}
''');
  }

  test_searchReferences_ConstructorElement_class_method_sameName() async {
    var result = await resolveTestCode('''
class A {
  A.foo() {
    foo();
  }

  A foo() => A.foo();
}
''');
    var element = result.findElement.constructor('foo');
    await assertElementReferencesText(element, r'''
class A {
  A.foo() {
    foo();
  }

  A foo() => A.foo();
              ^^^^ INVOCATION qualified
}
''');
  }

  test_searchReferences_ConstructorElement_class_named_dotShorthand_otherFile() async {
    // Note, we don't mention `A`, only the constructor name `foo`.
    newFile('$testPackageLibPath/other.dart', '''
import 'test.dart';

void useConstructor() {
  useA(.foo());
}
''');
    var result = await resolveTestCode('''
class A {
  A.foo();
}
void useA(A a) {}
''');
    var element = result.findElement.constructor('foo');
    await assertElementReferencesText(element, r'''
package:test/other.dart
-----------------------
import 'test.dart';

void useConstructor() {
  useA(.foo());
        ^^^ DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
}
''');
  }

  test_searchReferences_ConstructorElement_class_named_newHead() async {
    var result = await resolveTestCode('''
/// [new A.foo] and [A.foo]
class A {
  new foo() {}
  new bar() : this.foo();
  factory baz() = A.foo;
}
class B extends A {
  new () : super.foo();
}
void useConstructor() {
  A.foo();
  A.foo;
  A a = .foo();
}
''');
    var element = result.findElement.constructor('foo');
    await assertElementReferencesText(element, r'''
/// [new A.foo] and [A.foo]
          ^^^^ REFERENCE qualified
                      ^^^^ REFERENCE qualified
class A {
  new foo() {}
  new bar() : this.foo();
                  ^^^^ INVOCATION qualified
  factory baz() = A.foo;
                   ^^^^ REFERENCE qualified
}
class B extends A {
  new () : super.foo();
                ^^^^ INVOCATION qualified
}
void useConstructor() {
  A.foo();
   ^^^^ INVOCATION qualified
  A.foo;
   ^^^^ REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  A a = .foo();
         ^^^ DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
}
''');
  }

  test_searchReferences_ConstructorElement_class_named_primary() async {
    var result = await resolveTestCode('''
/// [new A.foo] and [A.foo]
class A.foo() {
  new bar() : this.foo();
  factory baz() = A.foo;
}
class B() extends A {
  this : super.foo();
}
void useConstructor() {
  A.foo();
  A.foo;
  A a = .foo();
}
''');
    var element = result.findElement.constructor('foo');
    await assertElementReferencesText(element, r'''
/// [new A.foo] and [A.foo]
          ^^^^ REFERENCE qualified
                      ^^^^ REFERENCE qualified
class A.foo() {
  new bar() : this.foo();
                  ^^^^ INVOCATION qualified
  factory baz() = A.foo;
                   ^^^^ REFERENCE qualified
}
class B() extends A {
  this : super.foo();
              ^^^^ INVOCATION qualified
}
void useConstructor() {
  A.foo();
   ^^^^ INVOCATION qualified
  A.foo;
   ^^^^ REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  A a = .foo();
         ^^^ DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
}
''');
  }

  test_searchReferences_ConstructorElement_class_named_typeName() async {
    var result = await resolveTestCode('''
/// [new A.foo] and [A.foo]
class A {
  A.foo() {}
  A.bar() : this.foo();
  factory A.baz() = A.foo;
}
class B extends A {
  B() : super.foo();
}
void useConstructor() {
  A.foo();
  A.foo;
  A a = .foo();
}
''');
    var element = result.findElement.constructor('foo');
    await assertElementReferencesText(element, r'''
/// [new A.foo] and [A.foo]
          ^^^^ REFERENCE qualified
                      ^^^^ REFERENCE qualified
class A {
  A.foo() {}
  A.bar() : this.foo();
                ^^^^ INVOCATION qualified
  factory A.baz() = A.foo;
                     ^^^^ REFERENCE qualified
}
class B extends A {
  B() : super.foo();
             ^^^^ INVOCATION qualified
}
void useConstructor() {
  A.foo();
   ^^^^ INVOCATION qualified
  A.foo;
   ^^^^ REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  A a = .foo();
         ^^^ DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
}
''');
  }

  test_searchReferences_ConstructorElement_class_named_typeName_viaTypeAlias() async {
    var result = await resolveTestCode('''
/// [new B.foo] and [B.foo]
class A<T> {
  A.foo() {}
  A.bar() : this.foo();
  factory A.baz() = A.foo;
}
typedef B = A<int>;
class C extends B {
  C() : super.foo();
}
void useConstructor() {
  B.foo();
  B.foo;
  B b = .foo();
}
''');

    var element = result.findElement.constructor('foo');
    await assertElementReferencesText(element, r'''
/// [new B.foo] and [B.foo]
          ^^^^ REFERENCE qualified
                      ^^^^ REFERENCE qualified
class A<T> {
  A.foo() {}
  A.bar() : this.foo();
                ^^^^ INVOCATION qualified
  factory A.baz() = A.foo;
                     ^^^^ REFERENCE qualified
}
typedef B = A<int>;
class C extends B {
  C() : super.foo();
             ^^^^ INVOCATION qualified
}
void useConstructor() {
  B.foo();
   ^^^^ INVOCATION qualified
  B.foo;
   ^^^^ REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  B b = .foo();
         ^^^ DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
}
''');
  }

  test_searchReferences_ConstructorElement_class_unnamed_dotShorthand_otherFile() async {
    // Note, we don't mention `A`, only the constructor name `new`.
    newFile('$testPackageLibPath/other.dart', '''
import 'test.dart';

void useConstructor() {
  useA(.new());
}
''');
    var result = await resolveTestCode('''
class A {}
void useA(A a) {}
''');
    var element = result.findElement.unnamedConstructor('A');
    await assertElementReferencesText(element, r'''
package:test/other.dart
-----------------------
import 'test.dart';

void useConstructor() {
  useA(.new());
        ^^^ DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
}
''');
  }

  test_searchReferences_ConstructorElement_class_unnamed_implicit() async {
    var result = await resolveTestCode('''
/// [new A] and [A.new]
class B {
  B();
  factory B.baz() = A;
}
class A extends B {}
class C extends A {
  C() : super();
}
void useConstructor() {
  A();
  A.new;
  A a = .new();
}
''');
    var element = result.findElement.unnamedConstructor('A');
    await assertElementReferencesText(element, r'''
/// [new A] and [A.new]
          ^0 REFERENCE qualified
                  ^^^^ REFERENCE qualified
class B {
  B();
  factory B.baz() = A;
                     ^0 REFERENCE qualified
}
class A extends B {}
class C extends A {
  C() : super();
             ^0 INVOCATION qualified
}
void useConstructor() {
  A();
   ^0 INVOCATION qualified
  A.new;
   ^^^^ REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  A a = .new();
         ^^^ DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
}
''');
  }

  test_searchReferences_ConstructorElement_class_unnamed_implicitInvocation_fromNewHead() async {
    var result = await resolveTestCode('''
class A {
  A();
}

class B extends A {
  new ();
  new bar();
  factory new.baz() = A;
}
''');
    var element = result.findElement.unnamedConstructor('A');
    await assertElementReferencesText(element, r'''
class A {
  A();
}

class B extends A {
  new ();
  ^^^ INVOCATION qualified
  new bar();
  ^^^^^^^ INVOCATION qualified
  factory new.baz() = A;
                       ^0 REFERENCE qualified
}
''');
  }

  test_searchReferences_ConstructorElement_class_unnamed_implicitInvocation_fromTypeName() async {
    var result = await resolveTestCode('''
class A {
  A();
}

class B extends A {
  B();
  B.bar();
  factory B.baz() = A;
}

class C extends A {}
''');
    var element = result.findElement.unnamedConstructor('A');
    await assertElementReferencesText(element, r'''
class A {
  A();
}

class B extends A {
  B();
  ^ INVOCATION qualified
  B.bar();
  ^^^^^ INVOCATION qualified
  factory B.baz() = A;
                     ^0 REFERENCE qualified
}

class C extends A {}
      ^ INVOCATION qualified
''');
  }

  test_searchReferences_ConstructorElement_class_unnamed_newHead() async {
    var result = await resolveTestCode('''
/// [new A] and [A.new]
class A {
  new () {}
  new bar() : this();
  factory baz() = A;
}
class B extends A {
  new () : super();
}
void useConstructor() {
  A();
  A.new;
  A a = .new();
}
''');
    var element = result.findElement.unnamedConstructor('A');
    await assertElementReferencesText(element, r'''
/// [new A] and [A.new]
          ^0 REFERENCE qualified
                  ^^^^ REFERENCE qualified
class A {
  new () {}
  new bar() : this();
                  ^0 INVOCATION qualified
  factory baz() = A;
                   ^0 REFERENCE qualified
}
class B extends A {
  new () : super();
                ^0 INVOCATION qualified
}
void useConstructor() {
  A();
   ^0 INVOCATION qualified
  A.new;
   ^^^^ REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  A a = .new();
         ^^^ DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
}
''');
  }

  test_searchReferences_ConstructorElement_class_unnamed_otherFile() async {
    String other = convertPath('$testPackageLibPath/other.dart');
    String otherCode = '''
import 'test.dart';

void f() {
  A();
}
''';
    newFile(other, otherCode);

    var result = await resolveTestCode('''
class A {
  A() {}
}
''');
    var element = result.findElement.unnamedConstructor('A');
    await assertElementReferencesText(element, r'''
package:test/other.dart
-----------------------
import 'test.dart';

void f() {
  A();
   ^0 INVOCATION qualified
}
''');
  }

  test_searchReferences_ConstructorElement_class_unnamed_primary() async {
    var result = await resolveTestCode('''
/// [new A] and [A.new]
class A() {
  new bar() : this();
  factory baz() = A;
}
class B() extends A {
  this : super();
}
void useConstructor() {
  A();
  A.new;
  A a = .new();
}
''');
    var element = result.findElement.unnamedConstructor('A');
    await assertElementReferencesText(element, r'''
/// [new A] and [A.new]
          ^0 REFERENCE qualified
                  ^^^^ REFERENCE qualified
class A() {
  new bar() : this();
                  ^0 INVOCATION qualified
  factory baz() = A;
                   ^0 REFERENCE qualified
}
class B() extends A {
  this : super();
              ^0 INVOCATION qualified
}
void useConstructor() {
  A();
   ^0 INVOCATION qualified
  A.new;
   ^^^^ REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  A a = .new();
         ^^^ DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
}
''');
  }

  test_searchReferences_ConstructorElement_class_unnamed_typeName() async {
    var result = await resolveTestCode('''
/// [new A] and [A.new]
class A {
  A() {}
  A.bar() : this();
  factory A.baz() = A;
}
class B extends A {
  B() : super();
}
void useConstructor() {
  A();
  A.new;
  A a = .new();
}
''');
    var element = result.findElement.unnamedConstructor('A');
    await assertElementReferencesText(element, r'''
/// [new A] and [A.new]
          ^0 REFERENCE qualified
                  ^^^^ REFERENCE qualified
class A {
  A() {}
  A.bar() : this();
                ^0 INVOCATION qualified
  factory A.baz() = A;
                     ^0 REFERENCE qualified
}
class B extends A {
  B() : super();
             ^0 INVOCATION qualified
}
void useConstructor() {
  A();
   ^0 INVOCATION qualified
  A.new;
   ^^^^ REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  A a = .new();
         ^^^ DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
}
''');
  }

  test_searchReferences_ConstructorElement_class_unnamed_typeName_explicitNew() async {
    var result = await resolveTestCode('''
/// [new A] and [A.new]
class A {
  A.new() {}
  A.bar() : this.new();
  factory A.baz() = A.new;
}
class B extends A {
  B() : super.new();
}
void useConstructor() {
  A.new();
  A.new;
  A a = .new();
}
''');
    var element = result.findElement.unnamedConstructor('A');
    await assertElementReferencesText(element, r'''
/// [new A] and [A.new]
          ^0 REFERENCE qualified
                  ^^^^ REFERENCE qualified
class A {
  A.new() {}
  A.bar() : this.new();
                ^^^^ INVOCATION qualified
  factory A.baz() = A.new;
                     ^^^^ REFERENCE qualified
}
class B extends A {
  B() : super.new();
             ^^^^ INVOCATION qualified
}
void useConstructor() {
  A.new();
   ^^^^ INVOCATION qualified
  A.new;
   ^^^^ REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  A a = .new();
         ^^^ DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
}
''');
  }

  test_searchReferences_ConstructorElement_class_unnamed_viaTypeAlias_otherFile() async {
    // Note, we use neither `A` nor `new`, only `B`.
    newFile('$testPackageLibPath/other.dart', '''
import 'test.dart';

class C extends B {
  C() : super();
}

void useConstructor() {
  B();
}
''');
    var result = await resolveTestCode('''
class A<T> {}
typedef B = A<int>;
''');
    var element = result.findElement.unnamedConstructor('A');
    await assertElementReferencesText(element, r'''
package:test/other.dart
-----------------------
import 'test.dart';

class C extends B {
  C() : super();
             ^0 INVOCATION qualified
}

void useConstructor() {
  B();
   ^0 INVOCATION qualified
}
''');
  }

  test_searchReferences_ConstructorElement_class_unnamed_viaTypeAliasChain_otherFile() async {
    // Note, we use neither `A` nor `new`, only `C`.
    newFile('$testPackageLibPath/other.dart', '''
import 'test.dart';

class D extends C {
  D() : super();
}

void useConstructor() {
  C();
}
''');
    var result = await resolveTestCode('''
class A<T> {}
typedef B = A<int>;
typedef C = B;
''');
    var element = result.findElement.unnamedConstructor('A');
    await assertElementReferencesText(element, r'''
package:test/other.dart
-----------------------
import 'test.dart';

class D extends C {
  D() : super();
             ^0 INVOCATION qualified
}

void useConstructor() {
  C();
   ^0 INVOCATION qualified
}
''');
  }

  test_searchReferences_ConstructorElement_classTypeAlias_cycle() async {
    var result = await resolveTestCode('''
class M {}
class A = B with M;
class B = A with M;
void useConstructor() {
  A();
  B();
}
''');
    expect(result.errors, isNotEmpty);
  }

  test_searchReferences_ConstructorElement_classTypeAlias_named() async {
    var result = await resolveTestCode('''
class M {}
class A {
  A() {}
  A.named() {}
}
class B = A with M;
class C = B with M;
void useConstructor() {
  B();
  B.named();
  C();
  C.named();
}
''');
    var element = result.findElement.constructor('named', of: 'A');
    await assertElementReferencesText(element, r'''
class M {}
class A {
  A() {}
  A.named() {}
}
class B = A with M;
class C = B with M;
void useConstructor() {
  B();
  B.named();
   ^^^^^^ INVOCATION qualified
  C();
  C.named();
   ^^^^^^ INVOCATION qualified
}
''');
  }

  test_searchReferences_ConstructorElement_classTypeAlias_unnamed() async {
    var result = await resolveTestCode('''
class M {}
class A {
  A() {}
  A.named() {}
}
class B = A with M;
class C = B with M;
void useConstructor() {
  B();
  B.named();
  C();
  C.named();
}
''');
    var element = result.findElement.unnamedConstructor('A');
    await assertElementReferencesText(element, r'''
class M {}
class A {
  A() {}
  A.named() {}
}
class B = A with M;
class C = B with M;
void useConstructor() {
  B();
   ^0 INVOCATION qualified
  B.named();
  C();
   ^0 INVOCATION qualified
  C.named();
}
''');
  }

  test_searchReferences_ConstructorElement_enum_named_newHead() async {
    var result = await resolveTestCode('''
/// [new E.foo] and [E.foo]
enum E {
  v.foo();
  const new foo();
  const new bar() : this.foo();
  const factory baz() = E.foo;
}
void useConstructor() {
  E.foo();
  E.foo;
  E a = .foo();
}
''');
    var element = result.findElement.constructor('foo');
    await assertElementReferencesText(element, r'''
/// [new E.foo] and [E.foo]
          ^^^^ REFERENCE qualified
                      ^^^^ REFERENCE qualified
enum E {
  v.foo();
   ^^^^ INVOCATION qualified
  const new foo();
  const new bar() : this.foo();
                        ^^^^ INVOCATION qualified
  const factory baz() = E.foo;
                         ^^^^ REFERENCE qualified
}
void useConstructor() {
  E.foo();
   ^^^^ INVOCATION qualified
  E.foo;
   ^^^^ REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  E a = .foo();
         ^^^ DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
}
''');
  }

  test_searchReferences_ConstructorElement_enum_named_primary() async {
    var result = await resolveTestCode('''
/// [new E.foo] and [E.foo]
enum E.foo() {
  v.foo();
  const new bar() : this.foo();
  const factory baz() = E.foo;
}
void useConstructor() {
  E.foo();
  E.foo;
  E a = .foo();
}
''');
    var element = result.findElement.constructor('foo');
    await assertElementReferencesText(element, r'''
/// [new E.foo] and [E.foo]
          ^^^^ REFERENCE qualified
                      ^^^^ REFERENCE qualified
enum E.foo() {
  v.foo();
   ^^^^ INVOCATION qualified
  const new bar() : this.foo();
                        ^^^^ INVOCATION qualified
  const factory baz() = E.foo;
                         ^^^^ REFERENCE qualified
}
void useConstructor() {
  E.foo();
   ^^^^ INVOCATION qualified
  E.foo;
   ^^^^ REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  E a = .foo();
         ^^^ DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
}
''');
  }

  test_searchReferences_ConstructorElement_enum_named_typeName() async {
    var result = await resolveTestCode('''
/// [new E.foo] and [E.foo]
enum E {
  v.foo();
  const E.foo();
  const E.bar() : this.foo();
  const factory E.baz() = E.foo;
}
void useConstructor() {
  E.foo();
  E.foo;
  E a = .foo();
}
''');
    var element = result.findElement.constructor('foo');
    await assertElementReferencesText(element, r'''
/// [new E.foo] and [E.foo]
          ^^^^ REFERENCE qualified
                      ^^^^ REFERENCE qualified
enum E {
  v.foo();
   ^^^^ INVOCATION qualified
  const E.foo();
  const E.bar() : this.foo();
                      ^^^^ INVOCATION qualified
  const factory E.baz() = E.foo;
                           ^^^^ REFERENCE qualified
}
void useConstructor() {
  E.foo();
   ^^^^ INVOCATION qualified
  E.foo;
   ^^^^ REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  E a = .foo();
         ^^^ DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
}
''');
  }

  test_searchReferences_ConstructorElement_enum_unnamed_implicit() async {
    var result = await resolveTestCode('''
/// [new E] and [E.new]
enum E {
  v1,
  v2(),
  v3.new();
  const factory E.other() = E;
}
void useConstructor() {
  E();
  E.new;
  E a = .new();
}
''');
    var element = result.findElement.unnamedConstructor('E');
    await assertElementReferencesText(element, r'''
/// [new E] and [E.new]
          ^0 REFERENCE qualified
                  ^^^^ REFERENCE qualified
enum E {
  v1,
    ^0 INVOCATION_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS qualified
  v2(),
    ^0 INVOCATION qualified
  v3.new();
    ^^^^ INVOCATION qualified
  const factory E.other() = E;
                             ^0 REFERENCE qualified
}
void useConstructor() {
  E();
   ^0 INVOCATION qualified
  E.new;
   ^^^^ REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  E a = .new();
         ^^^ DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
}
''');
  }

  test_searchReferences_ConstructorElement_enum_unnamed_newHead() async {
    var result = await resolveTestCode('''
/// [new E] and [E.new]
enum E {
  v1,
  v2(),
  v3.new();
  const new ();
  const factory other() = E.new;
}
void useConstructor() {
  E();
  E.new;
  E a = .new();
}
''');
    var element = result.findElement.unnamedConstructor('E');
    await assertElementReferencesText(element, r'''
/// [new E] and [E.new]
          ^0 REFERENCE qualified
                  ^^^^ REFERENCE qualified
enum E {
  v1,
    ^0 INVOCATION_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS qualified
  v2(),
    ^0 INVOCATION qualified
  v3.new();
    ^^^^ INVOCATION qualified
  const new ();
  const factory other() = E.new;
                           ^^^^ REFERENCE qualified
}
void useConstructor() {
  E();
   ^0 INVOCATION qualified
  E.new;
   ^^^^ REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  E a = .new();
         ^^^ DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
}
''');
  }

  test_searchReferences_ConstructorElement_enum_unnamed_primary() async {
    var result = await resolveTestCode('''
/// [new E] and [E.new]
enum E() {
  v1,
  v2(),
  v3.new();
  const factory other() = E.new;
}
void useConstructor() {
  E();
  E.new;
  E a = .new();
}
''');
    var element = result.findElement.unnamedConstructor('E');
    await assertElementReferencesText(element, r'''
/// [new E] and [E.new]
          ^0 REFERENCE qualified
                  ^^^^ REFERENCE qualified
enum E() {
  v1,
    ^0 INVOCATION_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS qualified
  v2(),
    ^0 INVOCATION qualified
  v3.new();
    ^^^^ INVOCATION qualified
  const factory other() = E.new;
                           ^^^^ REFERENCE qualified
}
void useConstructor() {
  E();
   ^0 INVOCATION qualified
  E.new;
   ^^^^ REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  E a = .new();
         ^^^ DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
}
''');
  }

  test_searchReferences_ConstructorElement_enum_unnamed_typeName() async {
    var result = await resolveTestCode('''
/// [new E] and [E.new]
enum E {
  v1,
  v2(),
  v3.new();
  const E();
  const factory E.other() = E;
}
void useConstructor() {
  E();
  E.new;
  E a = .new();
}
''');
    var element = result.findElement.unnamedConstructor('E');
    await assertElementReferencesText(element, r'''
/// [new E] and [E.new]
          ^0 REFERENCE qualified
                  ^^^^ REFERENCE qualified
enum E {
  v1,
    ^0 INVOCATION_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS qualified
  v2(),
    ^0 INVOCATION qualified
  v3.new();
    ^^^^ INVOCATION qualified
  const E();
  const factory E.other() = E;
                             ^0 REFERENCE qualified
}
void useConstructor() {
  E();
   ^0 INVOCATION qualified
  E.new;
   ^^^^ REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  E a = .new();
         ^^^ DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
}
''');
  }

  test_searchReferences_ConstructorElement_enum_unnamed_typeName_explicitNew() async {
    var result = await resolveTestCode('''
/// [new E] and [E.new]
enum E {
  v1,
  v2(),
  v3.new();
  const E.new();
  const factory E.other() = E.new;
}
void useConstructor() {
  E();
  E.new;
  E a = .new();
}
''');
    var element = result.findElement.unnamedConstructor('E');
    await assertElementReferencesText(element, r'''
/// [new E] and [E.new]
          ^0 REFERENCE qualified
                  ^^^^ REFERENCE qualified
enum E {
  v1,
    ^0 INVOCATION_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS qualified
  v2(),
    ^0 INVOCATION qualified
  v3.new();
    ^^^^ INVOCATION qualified
  const E.new();
  const factory E.other() = E.new;
                             ^^^^ REFERENCE qualified
}
void useConstructor() {
  E();
   ^0 INVOCATION qualified
  E.new;
   ^^^^ REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  E a = .new();
         ^^^ DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
}
''');
  }

  test_searchReferences_ConstructorElement_extensionType_named_newHead() async {
    var result = await resolveTestCode('''
/// [new A.foo] and [A.foo]
extension type A(int it) {
  new foo(this.it);
  new bar() : this.foo(0);
  factory baz(int it) = A.foo;
}
void useConstructor() {
  A.foo(0);
  A.foo;
  A a = .foo(0);
}
''');
    var element = result.findElement.constructor('foo');
    await assertElementReferencesText(element, r'''
/// [new A.foo] and [A.foo]
          ^^^^ REFERENCE qualified
                      ^^^^ REFERENCE qualified
extension type A(int it) {
  new foo(this.it);
  new bar() : this.foo(0);
                  ^^^^ INVOCATION qualified
  factory baz(int it) = A.foo;
                         ^^^^ REFERENCE qualified
}
void useConstructor() {
  A.foo(0);
   ^^^^ INVOCATION qualified
  A.foo;
   ^^^^ REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  A a = .foo(0);
         ^^^ DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
}
''');
  }

  test_searchReferences_ConstructorElement_extensionType_named_primary() async {
    var result = await resolveTestCode('''
/// [new A.foo] and [A.foo]
extension type A.foo(int it) {
  new bar() : this.foo(0);
  factory baz(int it) = A.foo;
}
void useConstructor() {
  A.foo(0);
  A.foo;
  A a = .foo(0);
}
''');
    var element = result.findElement.constructor('foo');
    await assertElementReferencesText(element, r'''
/// [new A.foo] and [A.foo]
          ^^^^ REFERENCE qualified
                      ^^^^ REFERENCE qualified
extension type A.foo(int it) {
  new bar() : this.foo(0);
                  ^^^^ INVOCATION qualified
  factory baz(int it) = A.foo;
                         ^^^^ REFERENCE qualified
}
void useConstructor() {
  A.foo(0);
   ^^^^ INVOCATION qualified
  A.foo;
   ^^^^ REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  A a = .foo(0);
         ^^^ DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
}
''');
  }

  test_searchReferences_ConstructorElement_extensionType_named_typeName() async {
    var result = await resolveTestCode('''
/// [new A.foo] and [A.foo]
extension type A(int it) {
  A.foo(this.it);
  A.bar() : this.foo(0);
  factory A.baz(int it) = A.foo;
}
void useConstructor() {
  A.foo(0);
  A.foo;
  A a = .foo(0);
}
''');
    var element = result.findElement.constructor('foo');
    await assertElementReferencesText(element, r'''
/// [new A.foo] and [A.foo]
          ^^^^ REFERENCE qualified
                      ^^^^ REFERENCE qualified
extension type A(int it) {
  A.foo(this.it);
  A.bar() : this.foo(0);
                ^^^^ INVOCATION qualified
  factory A.baz(int it) = A.foo;
                           ^^^^ REFERENCE qualified
}
void useConstructor() {
  A.foo(0);
   ^^^^ INVOCATION qualified
  A.foo;
   ^^^^ REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  A a = .foo(0);
         ^^^ DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
}
''');
  }

  test_searchReferences_ConstructorElement_extensionType_unnamed_newHead() async {
    var result = await resolveTestCode('''
/// [new A] and [A.new]
extension type A.named(int it) {
  new (this.it);
  new bar() : this(0);
  factory baz(int it) = A.new;
}
void useConstructor() {
  A(0);
  A.new;
  A a = .new(0);
}
''');
    var element = result.findElement.unnamedConstructor('A');
    await assertElementReferencesText(element, r'''
/// [new A] and [A.new]
          ^0 REFERENCE qualified
                  ^^^^ REFERENCE qualified
extension type A.named(int it) {
  new (this.it);
  new bar() : this(0);
                  ^0 INVOCATION qualified
  factory baz(int it) = A.new;
                         ^^^^ REFERENCE qualified
}
void useConstructor() {
  A(0);
   ^0 INVOCATION qualified
  A.new;
   ^^^^ REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  A a = .new(0);
         ^^^ DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
}
''');
  }

  test_searchReferences_ConstructorElement_extensionType_unnamed_primary() async {
    var result = await resolveTestCode('''
/// [new A] and [A.new]
extension type A(int it) {
  new bar() : this(0);
  factory baz(int it) = A.new;
}
void useConstructor() {
  A(0);
  A.new;
  A a = .new(0);
}
''');
    var element = result.findElement.unnamedConstructor('A');
    await assertElementReferencesText(element, r'''
/// [new A] and [A.new]
          ^0 REFERENCE qualified
                  ^^^^ REFERENCE qualified
extension type A(int it) {
  new bar() : this(0);
                  ^0 INVOCATION qualified
  factory baz(int it) = A.new;
                         ^^^^ REFERENCE qualified
}
void useConstructor() {
  A(0);
   ^0 INVOCATION qualified
  A.new;
   ^^^^ REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  A a = .new(0);
         ^^^ DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
}
''');
  }

  test_searchReferences_ConstructorElement_extensionType_unnamed_typeName() async {
    var result = await resolveTestCode('''
/// [new A] and [A.new]
extension type A.named(int it) {
  A(this.it);
  A.bar() : this(0);
  factory A.baz(int it) = A.new;
}
void useConstructor() {
  A(0);
  A.new;
  A a = .new(0);
}
''');
    var element = result.findElement.unnamedConstructor('A');
    await assertElementReferencesText(element, r'''
/// [new A] and [A.new]
          ^0 REFERENCE qualified
                  ^^^^ REFERENCE qualified
extension type A.named(int it) {
  A(this.it);
  A.bar() : this(0);
                ^0 INVOCATION qualified
  factory A.baz(int it) = A.new;
                           ^^^^ REFERENCE qualified
}
void useConstructor() {
  A(0);
   ^0 INVOCATION qualified
  A.new;
   ^^^^ REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  A a = .new(0);
         ^^^ DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
}
''');
  }

  test_searchReferences_ConstructorElement_extensionType_unnamed_typeName_explicitNew() async {
    var result = await resolveTestCode('''
/// [new A] and [A.new]
extension type A.named(int it) {
  A.new(this.it);
  A.bar() : this.new(0);
  factory A.baz(int it) = A.new;
}
void useConstructor() {
  A.new(0);
  A.new;
  A a = .new(0);
}
''');
    var element = result.findElement.unnamedConstructor('A');
    await assertElementReferencesText(element, r'''
/// [new A] and [A.new]
          ^0 REFERENCE qualified
                  ^^^^ REFERENCE qualified
extension type A.named(int it) {
  A.new(this.it);
  A.bar() : this.new(0);
                ^^^^ INVOCATION qualified
  factory A.baz(int it) = A.new;
                           ^^^^ REFERENCE qualified
}
void useConstructor() {
  A.new(0);
   ^^^^ INVOCATION qualified
  A.new;
   ^^^^ REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  A a = .new(0);
         ^^^ DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
}
''');
  }

  test_searchReferences_constructorField_outsideFile() async {
    // Create an external file with a class that has a constructor field.
    newFile('$testPackageLibPath/other.dart', r'''
import 'test.dart';

class B extends A {
  B({super.x});
}
''');
    // Resolve test code that imports the external file and references the field.
    var result = await resolveTestCode(r'''
class A {
  int? x;
  A({this.x});
}
''');
    // Look up field 'x' and assert that its reference is correctly found.
    var field = result.findElement.fieldFormalParameter('x');
    await assertElementReferencesText(field, r'''
package:test/other.dart
-----------------------
import 'test.dart';

class B extends A {
  B({super.x});
           ^ REFERENCE_BY_NAMED_ARGUMENT qualified
}
''');
  }

  test_searchReferences_EnumElement_reference_annotation() async {
    var result = await resolveTestCode(r'''
import 'test.dart' as p;

enum E {
  v;
  const E();
  const E.named();
  static const int myConstant = 0;
}

@E()
@p.E()
@E.named()
@p.E.named()
@E.myConstant
@p.E.myConstant
void f() {}
''');
    var element = result.findElement.enum_('E');
    await assertElementReferencesText(element, r'''
import 'test.dart' as p;

enum E {
  v;
  const E();
        ^ REFERENCE
  const E.named();
        ^ REFERENCE
  static const int myConstant = 0;
}

@E()
 ^ REFERENCE
@p.E()
   ^ REFERENCE qualified
@E.named()
 ^ REFERENCE
@p.E.named()
   ^ REFERENCE qualified
@E.myConstant
 ^ REFERENCE
@p.E.myConstant
   ^ REFERENCE qualified
void f() {}
''');
  }

  test_searchReferences_EnumElement_reference_comment() async {
    var result = await resolveTestCode(r'''
import 'test.dart' as p;

enum E { v }

/// [E] and [p.E].
void f() {}
''');
    var element = result.findElement.enum_('E');
    await assertElementReferencesText(element, r'''
import 'test.dart' as p;

enum E { v }

/// [E] and [p.E].
     ^ REFERENCE
               ^ REFERENCE qualified
void f() {}
''');
  }

  test_searchReferences_EnumElement_reference_instanceCreation() async {
    var result = await resolveTestCode(r'''
import 'test.dart' as p;

enum E {
  v;
  const E();
}

void f() {
  const E();
  const p.E();
}
''');
    var element = result.findElement.enum_('E');
    await assertElementReferencesText(element, r'''
import 'test.dart' as p;

enum E {
  v;
  const E();
        ^ REFERENCE
}

void f() {
  const E();
        ^ REFERENCE
  const p.E();
          ^ REFERENCE qualified
}
''');
  }

  test_searchReferences_EnumElement_reference_memberAccess() async {
    var result = await resolveTestCode(r'''
import 'test.dart' as p;

enum E {
  v;
  static void foo() {}
}

void f() {
  E.foo();
  p.E.foo();
}
''');
    var element = result.findElement.enum_('E');
    await assertElementReferencesText(element, r'''
import 'test.dart' as p;

enum E {
  v;
  static void foo() {}
}

void f() {
  E.foo();
  ^ REFERENCE
  p.E.foo();
    ^ REFERENCE qualified
}
''');
  }

  test_searchReferences_EnumElement_reference_namedType() async {
    var result = await resolveTestCode(r'''
import 'test.dart' as p;

enum E { v }

void f() {
  E v1;
  p.E v2;
}
''');
    var element = result.findElement.enum_('E');
    await assertElementReferencesText(element, r'''
import 'test.dart' as p;

enum E { v }

void f() {
  E v1;
  ^ REFERENCE
  p.E v2;
    ^ REFERENCE qualified
}
''');
  }

  test_searchReferences_ExtensionElement() async {
    var result = await resolveTestCode('''
extension E on int {
  void foo() {}
  static void bar() {}
}

main() {
  E(0).foo();
  E.bar();
}
''');
    var element = result.findElement.extension_('E');
    await assertElementReferencesText(element, r'''
extension E on int {
  void foo() {}
  static void bar() {}
}

main() {
  E(0).foo();
  ^ REFERENCE
  E.bar();
  ^ REFERENCE
}
''');
  }

  test_searchReferences_ExtensionTypeElement_reference_annotation() async {
    var result = await resolveTestCode(r'''
import 'test.dart' as p;

extension type const A(int it) {}

@A(0)
@p.A(0)
void f() {}
''');
    var element = result.findElement.extensionType('A');
    await assertElementReferencesText(element, r'''
import 'test.dart' as p;

extension type const A(int it) {}

@A(0)
 ^ REFERENCE
@p.A(0)
   ^ REFERENCE qualified
void f() {}
''');
  }

  test_searchReferences_ExtensionTypeElement_reference_comment() async {
    var result = await resolveTestCode(r'''
import 'test.dart' as p;

extension type A(int it) {}

/// [A] and [p.A].
void f() {}
''');
    var element = result.findElement.extensionType('A');
    await assertElementReferencesText(element, r'''
import 'test.dart' as p;

extension type A(int it) {}

/// [A] and [p.A].
     ^ REFERENCE
               ^ REFERENCE qualified
void f() {}
''');
  }

  test_searchReferences_ExtensionTypeElement_reference_instanceCreation() async {
    var result = await resolveTestCode(r'''
import 'test.dart' as p;

extension type A(int it) {}

void f() {
  A(0);
  p.A(0);
}
''');
    var element = result.findElement.extensionType('A');
    await assertElementReferencesText(element, r'''
import 'test.dart' as p;

extension type A(int it) {}

void f() {
  A(0);
  ^ REFERENCE
  p.A(0);
    ^ REFERENCE qualified
}
''');
  }

  test_searchReferences_ExtensionTypeElement_reference_memberAccess() async {
    var result = await resolveTestCode(r'''
import 'test.dart' as p;

extension type A(int it) {
  static void foo() {}
}

void f() {
  A.foo();
  p.A.foo();
}
''');
    var element = result.findElement.extensionType('A');
    await assertElementReferencesText(element, r'''
import 'test.dart' as p;

extension type A(int it) {
  static void foo() {}
}

void f() {
  A.foo();
  ^ REFERENCE
  p.A.foo();
    ^ REFERENCE qualified
}
''');
  }

  test_searchReferences_ExtensionTypeElement_reference_namedType() async {
    var result = await resolveTestCode(r'''
import 'test.dart' as p;

extension type A(int it) {}

void f() {
  A v1;
  p.A v2;
}
''');
    var element = result.findElement.extensionType('A');
    await assertElementReferencesText(element, r'''
import 'test.dart' as p;

extension type A(int it) {}

void f() {
  A v1;
  ^ REFERENCE
  p.A v2;
    ^ REFERENCE qualified
}
''');
  }

  test_searchReferences_FieldElement_ofClass_instance_fieldDeclaration() async {
    var result = await resolveTestCode('''
/// [foo] and [A.foo]
class A {
  int foo;
  A({this.foo = 0});
  A.foo() : foo = 0;

  void useField() {
    foo;
    foo = 0;
    foo += 1;
    foo ??= 2;
    foo++;
    --foo;
    this.foo;
    this.foo = 0;
    this.foo += 1;
    this.foo ??= 2;
    this.foo++;
    --this.foo;
  }
}

void useField(A a) {
  a.foo;
  a.foo = 0;
  a.foo += 1;
  a.foo ??= 2;
  a.foo++;
  --a.foo;
  A(foo: 0);
}

class B extends A {
  void useSuper() {
    super.foo;
    super.foo = 0;
    super.foo += 1;
    super.foo ??= 2;
    super.foo++;
    --super.foo;
  }
}
''');
    var field = result.findElement.field('foo');

    await assertElementsReferencesText(
      {
        'field': field,
        'getter': field.getter!,
        'setter': field.setter!,
        'num.+': result.typeProvider.numElement.getMethod('+')!,
        'num.-': result.typeProvider.numElement.getMethod('-')!,
      },
      r'''
/// [foo] and [A.foo]
     ^^^ field REFERENCE
     ^^^ getter REFERENCE
                 ^^^ field REFERENCE qualified
                 ^^^ getter REFERENCE qualified
class A {
  int foo;
  A({this.foo = 0});
          ^^^ field WRITE qualified
  A.foo() : foo = 0;
            ^^^ field WRITE qualified

  void useField() {
    foo;
    ^^^ field READ
    ^^^ getter INVOCATION
    foo = 0;
    ^^^ field WRITE
    ^^^ setter INVOCATION
    foo += 1;
    ^^^ field READ_WRITE
    ^^^ getter INVOCATION
    ^^^ setter INVOCATION
        ^^ num.+ INVOCATION qualified
    foo ??= 2;
    ^^^ field READ_WRITE
    ^^^ getter INVOCATION
    ^^^ setter INVOCATION
    foo++;
    ^^^ field READ_WRITE
    ^^^ getter INVOCATION
    ^^^ setter INVOCATION
       ^^ num.+ INVOCATION qualified
    --foo;
    ^^ num.- INVOCATION qualified
      ^^^ field READ_WRITE
      ^^^ getter INVOCATION
      ^^^ setter INVOCATION
    this.foo;
         ^^^ field READ qualified
         ^^^ getter INVOCATION qualified
    this.foo = 0;
         ^^^ field WRITE qualified
         ^^^ setter INVOCATION qualified
    this.foo += 1;
         ^^^ field READ_WRITE qualified
         ^^^ getter INVOCATION qualified
         ^^^ setter INVOCATION qualified
             ^^ num.+ INVOCATION qualified
    this.foo ??= 2;
         ^^^ field READ_WRITE qualified
         ^^^ getter INVOCATION qualified
         ^^^ setter INVOCATION qualified
    this.foo++;
         ^^^ field READ_WRITE qualified
         ^^^ getter INVOCATION qualified
         ^^^ setter INVOCATION qualified
            ^^ num.+ INVOCATION qualified
    --this.foo;
    ^^ num.- INVOCATION qualified
           ^^^ field READ_WRITE qualified
           ^^^ getter INVOCATION qualified
           ^^^ setter INVOCATION qualified
  }
}

void useField(A a) {
  a.foo;
    ^^^ field READ qualified
    ^^^ getter INVOCATION qualified
  a.foo = 0;
    ^^^ field WRITE qualified
    ^^^ setter INVOCATION qualified
  a.foo += 1;
    ^^^ field READ_WRITE qualified
    ^^^ getter INVOCATION qualified
    ^^^ setter INVOCATION qualified
        ^^ num.+ INVOCATION qualified
  a.foo ??= 2;
    ^^^ field READ_WRITE qualified
    ^^^ getter INVOCATION qualified
    ^^^ setter INVOCATION qualified
  a.foo++;
    ^^^ field READ_WRITE qualified
    ^^^ getter INVOCATION qualified
    ^^^ setter INVOCATION qualified
       ^^ num.+ INVOCATION qualified
  --a.foo;
  ^^ num.- INVOCATION qualified
      ^^^ field READ_WRITE qualified
      ^^^ getter INVOCATION qualified
      ^^^ setter INVOCATION qualified
  A(foo: 0);
}

class B extends A {
  void useSuper() {
    super.foo;
          ^^^ field READ qualified
          ^^^ getter INVOCATION qualified
    super.foo = 0;
          ^^^ field WRITE qualified
          ^^^ setter INVOCATION qualified
    super.foo += 1;
          ^^^ field READ_WRITE qualified
          ^^^ getter INVOCATION qualified
          ^^^ setter INVOCATION qualified
              ^^ num.+ INVOCATION qualified
    super.foo ??= 2;
          ^^^ field READ_WRITE qualified
          ^^^ getter INVOCATION qualified
          ^^^ setter INVOCATION qualified
    super.foo++;
          ^^^ field READ_WRITE qualified
          ^^^ getter INVOCATION qualified
          ^^^ setter INVOCATION qualified
             ^^ num.+ INVOCATION qualified
    --super.foo;
    ^^ num.- INVOCATION qualified
            ^^^ field READ_WRITE qualified
            ^^^ getter INVOCATION qualified
            ^^^ setter INVOCATION qualified
  }
}
''',
    );
  }

  test_searchReferences_FieldElement_ofClass_instance_getterDeclaration() async {
    var result = await resolveTestCode('''
/// [foo] and [A.foo]
class A {
  A() : foo = 0;
  int get foo => 0;

  void useGetter() {
    foo;
    this.foo;
  }
}

void useGetter(A a) {
  a.foo;
}

class B extends A {
  void useSuper() {
    super.foo;
  }
}
''');
    var field = result.findElement.field('foo');

    await assertElementsReferencesText(
      {'field': field, 'getter': field.getter!},
      r'''
/// [foo] and [A.foo]
     ^^^ field REFERENCE
     ^^^ getter REFERENCE
                 ^^^ field REFERENCE qualified
                 ^^^ getter REFERENCE qualified
class A {
  A() : foo = 0;
  int get foo => 0;

  void useGetter() {
    foo;
    ^^^ field READ
    ^^^ getter INVOCATION
    this.foo;
         ^^^ field READ qualified
         ^^^ getter INVOCATION qualified
  }
}

void useGetter(A a) {
  a.foo;
    ^^^ field READ qualified
    ^^^ getter INVOCATION qualified
}

class B extends A {
  void useSuper() {
    super.foo;
          ^^^ field READ qualified
          ^^^ getter INVOCATION qualified
  }
}
''',
    );
  }

  test_searchReferences_FieldElement_ofClass_instance_getterSetterDeclarations() async {
    var result = await resolveTestCode('''
class A {
  A() : foo = 0;
  int get foo => 0;
  set foo(int _) {}

  void useField() {
    foo;
    foo = 0;
    foo += 1;
    foo ??= 2;
    foo++;
    --foo;
    this.foo;
    this.foo = 0;
    this.foo += 1;
    this.foo ??= 2;
    this.foo++;
    --this.foo;
  }
}

void useField(A a) {
  a.foo;
  a.foo = 0;
  a.foo += 1;
  a.foo ??= 2;
  a.foo++;
  --a.foo;
}

class B extends A {
  void useSuper() {
    super.foo;
    super.foo = 0;
    super.foo += 1;
    super.foo ??= 2;
    super.foo++;
    --super.foo;
  }
}
''');
    var field = result.findElement.field('foo');

    await assertElementsReferencesText(
      {
        'field': field,
        'getter': field.getter!,
        'setter': field.setter!,
        'num.+': result.typeProvider.numElement.getMethod('+')!,
        'num.-': result.typeProvider.numElement.getMethod('-')!,
      },
      r'''
class A {
  A() : foo = 0;
  int get foo => 0;
  set foo(int _) {}

  void useField() {
    foo;
    ^^^ field READ
    ^^^ getter INVOCATION
    foo = 0;
    ^^^ field WRITE
    ^^^ setter INVOCATION
    foo += 1;
    ^^^ field READ_WRITE
    ^^^ getter INVOCATION
    ^^^ setter INVOCATION
        ^^ num.+ INVOCATION qualified
    foo ??= 2;
    ^^^ field READ_WRITE
    ^^^ getter INVOCATION
    ^^^ setter INVOCATION
    foo++;
    ^^^ field READ_WRITE
    ^^^ getter INVOCATION
    ^^^ setter INVOCATION
       ^^ num.+ INVOCATION qualified
    --foo;
    ^^ num.- INVOCATION qualified
      ^^^ field READ_WRITE
      ^^^ getter INVOCATION
      ^^^ setter INVOCATION
    this.foo;
         ^^^ field READ qualified
         ^^^ getter INVOCATION qualified
    this.foo = 0;
         ^^^ field WRITE qualified
         ^^^ setter INVOCATION qualified
    this.foo += 1;
         ^^^ field READ_WRITE qualified
         ^^^ getter INVOCATION qualified
         ^^^ setter INVOCATION qualified
             ^^ num.+ INVOCATION qualified
    this.foo ??= 2;
         ^^^ field READ_WRITE qualified
         ^^^ getter INVOCATION qualified
         ^^^ setter INVOCATION qualified
    this.foo++;
         ^^^ field READ_WRITE qualified
         ^^^ getter INVOCATION qualified
         ^^^ setter INVOCATION qualified
            ^^ num.+ INVOCATION qualified
    --this.foo;
    ^^ num.- INVOCATION qualified
           ^^^ field READ_WRITE qualified
           ^^^ getter INVOCATION qualified
           ^^^ setter INVOCATION qualified
  }
}

void useField(A a) {
  a.foo;
    ^^^ field READ qualified
    ^^^ getter INVOCATION qualified
  a.foo = 0;
    ^^^ field WRITE qualified
    ^^^ setter INVOCATION qualified
  a.foo += 1;
    ^^^ field READ_WRITE qualified
    ^^^ getter INVOCATION qualified
    ^^^ setter INVOCATION qualified
        ^^ num.+ INVOCATION qualified
  a.foo ??= 2;
    ^^^ field READ_WRITE qualified
    ^^^ getter INVOCATION qualified
    ^^^ setter INVOCATION qualified
  a.foo++;
    ^^^ field READ_WRITE qualified
    ^^^ getter INVOCATION qualified
    ^^^ setter INVOCATION qualified
       ^^ num.+ INVOCATION qualified
  --a.foo;
  ^^ num.- INVOCATION qualified
      ^^^ field READ_WRITE qualified
      ^^^ getter INVOCATION qualified
      ^^^ setter INVOCATION qualified
}

class B extends A {
  void useSuper() {
    super.foo;
          ^^^ field READ qualified
          ^^^ getter INVOCATION qualified
    super.foo = 0;
          ^^^ field WRITE qualified
          ^^^ setter INVOCATION qualified
    super.foo += 1;
          ^^^ field READ_WRITE qualified
          ^^^ getter INVOCATION qualified
          ^^^ setter INVOCATION qualified
              ^^ num.+ INVOCATION qualified
    super.foo ??= 2;
          ^^^ field READ_WRITE qualified
          ^^^ getter INVOCATION qualified
          ^^^ setter INVOCATION qualified
    super.foo++;
          ^^^ field READ_WRITE qualified
          ^^^ getter INVOCATION qualified
          ^^^ setter INVOCATION qualified
             ^^ num.+ INVOCATION qualified
    --super.foo;
    ^^ num.- INVOCATION qualified
            ^^^ field READ_WRITE qualified
            ^^^ getter INVOCATION qualified
            ^^^ setter INVOCATION qualified
  }
}
''',
    );
  }

  test_searchReferences_FieldElement_ofClass_instance_setterDeclaration() async {
    var result = await resolveTestCode('''
/// [foo] and [A.foo]
class A {
  A() : foo = 0;
  set foo(int _) {}

  void useSetter() {
    foo = 0;
    this.foo = 0;
  }
}

void useSetter(A a) {
  a.foo = 0;
}

class B extends A {
  void useSuper() {
    super.foo = 0;
  }
}
''');
    var field = result.findElement.field('foo');

    await assertElementsReferencesText(
      {'field': field, 'setter': field.setter!},
      r'''
/// [foo] and [A.foo]
     ^^^ field REFERENCE
     ^^^ setter REFERENCE
                 ^^^ field REFERENCE qualified
                 ^^^ setter REFERENCE qualified
class A {
  A() : foo = 0;
  set foo(int _) {}

  void useSetter() {
    foo = 0;
    ^^^ field WRITE
    ^^^ setter INVOCATION
    this.foo = 0;
         ^^^ field WRITE qualified
         ^^^ setter INVOCATION qualified
  }
}

void useSetter(A a) {
  a.foo = 0;
    ^^^ field WRITE qualified
    ^^^ setter INVOCATION qualified
}

class B extends A {
  void useSuper() {
    super.foo = 0;
          ^^^ field WRITE qualified
          ^^^ setter INVOCATION qualified
  }
}
''',
    );
  }

  test_searchReferences_FieldElement_ofClass_parenthesizedReceiver_compound() async {
    var result = await resolveTestCode('''
class A {
  int foo = 0;
}

void f(A a) {
  (a).foo += 2;
}
''');
    var field = result.findElement.field('foo');

    await assertElementsReferencesText(
      {
        'field': field,
        'getter': field.getter!,
        'setter': field.setter!,
        'num.+': result.typeProvider.numElement.getMethod('+')!,
      },
      r'''
class A {
  int foo = 0;
}

void f(A a) {
  (a).foo += 2;
      ^^^ field READ_WRITE qualified
      ^^^ getter INVOCATION qualified
      ^^^ setter INVOCATION qualified
          ^^ num.+ INVOCATION qualified
}
''',
    );
  }

  test_searchReferences_FieldElement_ofClass_parenthesizedReceiver_ifNull() async {
    var result = await resolveTestCode('''
class A {
  int? foo;
}

void f(A a) {
  (a).foo ??= 2;
}
''');
    var field = result.findElement.field('foo');

    await assertElementsReferencesText(
      {'field': field, 'getter': field.getter!, 'setter': field.setter!},
      r'''
class A {
  int? foo;
}

void f(A a) {
  (a).foo ??= 2;
      ^^^ field READ_WRITE qualified
      ^^^ getter INVOCATION qualified
      ^^^ setter INVOCATION qualified
}
''',
    );
  }

  test_searchReferences_FieldElement_ofClass_static_fieldDeclaration() async {
    var result = await resolveTestCode('''
/// [foo] and [A.foo]
class A {
  static int foo = 0;
  static void useField() {
    foo;
    foo = 0;
    A.foo;
    A.foo = 0;
  }
}

void useField() {
  A.foo;
  A.foo = 0;
  A a = .foo;
}
''');
    var field = result.findElement.field('foo');

    await assertElementsReferencesText(
      {'field': field, 'getter': field.getter!, 'setter': field.setter!},
      r'''
/// [foo] and [A.foo]
     ^^^ field REFERENCE
     ^^^ getter REFERENCE
                 ^^^ field REFERENCE qualified
                 ^^^ getter REFERENCE qualified
class A {
  static int foo = 0;
  static void useField() {
    foo;
    ^^^ field READ
    ^^^ getter INVOCATION
    foo = 0;
    ^^^ field WRITE
    ^^^ setter INVOCATION
    A.foo;
      ^^^ field READ qualified
      ^^^ getter INVOCATION qualified
    A.foo = 0;
      ^^^ field WRITE qualified
      ^^^ setter INVOCATION qualified
  }
}

void useField() {
  A.foo;
    ^^^ field READ qualified
    ^^^ getter INVOCATION qualified
  A.foo = 0;
    ^^^ field WRITE qualified
    ^^^ setter INVOCATION qualified
  A a = .foo;
         ^^^ field READ qualified
         ^^^ getter INVOCATION qualified
}
''',
    );
  }

  test_searchReferences_FieldElement_ofEnum_instance_fieldDeclaration() async {
    var result = await resolveTestCode('''
/// [foo] and [E.foo]
enum E {
  v;
  int? foo; // a compile-time error
  E({this.foo});
  void useField() {
    foo;
    foo = 0;
  }
}
void useField(E e) {
  e.foo;
  e.foo = 0;
  E(foo: 0);
}
''');
    var field = result.findElement.field('foo');

    await assertElementsReferencesText(
      {'field': field, 'getter': field.getter!, 'setter': field.setter!},
      r'''
/// [foo] and [E.foo]
     ^^^ field REFERENCE
     ^^^ getter REFERENCE
                 ^^^ field REFERENCE qualified
                 ^^^ getter REFERENCE qualified
enum E {
  v;
  int? foo; // a compile-time error
  E({this.foo});
          ^^^ field WRITE qualified
  void useField() {
    foo;
    ^^^ field READ
    ^^^ getter INVOCATION
    foo = 0;
    ^^^ field WRITE
    ^^^ setter INVOCATION
  }
}
void useField(E e) {
  e.foo;
    ^^^ field READ qualified
    ^^^ getter INVOCATION qualified
  e.foo = 0;
    ^^^ field WRITE qualified
    ^^^ setter INVOCATION qualified
  E(foo: 0);
}
''',
    );
  }

  test_searchReferences_FieldElement_ofEnum_instance_fieldDeclaration_final_invalidWrite() async {
    var result = await resolveTestCode('''
enum E {
  v;
  final int foo = 0;
  void f() {
    foo = 1;
  }
}
''');
    var field = result.findElement.field('foo');

    await assertElementsReferencesText(
      {'field': field, 'getter': field.getter!},
      r'''
enum E {
  v;
  final int foo = 0;
  void f() {
    foo = 1;
    ^^^ field REFERENCE
    ^^^ getter REFERENCE
  }
}
''',
    );
  }

  test_searchReferences_FieldElement_ofEnum_instance_getterDeclaration() async {
    var result = await resolveTestCode('''
enum E {
  v;
  E() : foo = 0;
  int get foo => 0;
}
''');
    var field = result.findElement.field('foo');

    await assertElementsReferencesText(
      {'field': field, 'getter': field.getter!},
      r'''
''',
    );
  }

  test_searchReferences_FieldElement_ofEnum_instance_getterSetterDeclarations() async {
    var result = await resolveTestCode('''
enum E {
  v;
  E() : foo = 0;
  int get foo => 0;
  set foo(_) {}
}
''');
    var field = result.findElement.field('foo');

    await assertElementsReferencesText(
      {'field': field, 'getter': field.getter!, 'setter': field.setter!},
      r'''
''',
    );
  }

  test_searchReferences_FieldElement_ofEnum_instance_index() async {
    var result = await resolveTestCode('''
enum MyEnum {
  v1, v2, v3
}
main() {
  MyEnum.v1.index;
  MyEnum.values;
  MyEnum.v1;
  MyEnum.v2;
}
''');
    var index = result.typeProvider.enumElement!.getField('index')!;
    await assertElementsReferencesText(
      {'field': index, 'getter': index.getter!},
      r'''
enum MyEnum {
  v1, v2, v3
}
main() {
  MyEnum.v1.index;
            ^^^^^ field READ qualified
            ^^^^^ getter INVOCATION qualified
  MyEnum.values;
  MyEnum.v1;
  MyEnum.v2;
}
''',
    );
  }

  test_searchReferences_FieldElement_ofEnum_instance_setterDeclaration() async {
    var result = await resolveTestCode('''
enum E {
  v;
  E() : foo = 0;
  set foo(_) {}
}
''');
    var field = result.findElement.field('foo');

    await assertElementsReferencesText(
      {'field': field, 'setter': field.setter!},
      r'''
''',
    );
  }

  test_searchReferences_FieldElement_ofEnum_static_constants() async {
    var result = await resolveTestCode(r'''
import 'test.dart' as p;

/// [v1], [MyEnum.v1], and [p.MyEnum.v1]
enum MyEnum {
  v1, v2, v3
}
main() {
  MyEnum.v1.index;
  MyEnum.values;
  MyEnum.v1;
  MyEnum.v2;
  p.MyEnum.v1;
  p.MyEnum.values;
}
''');
    var values = result.findElement.field('values');
    await assertElementsReferencesText(
      {'field': values, 'getter': values.getter!},
      r'''
import 'test.dart' as p;

/// [v1], [MyEnum.v1], and [p.MyEnum.v1]
enum MyEnum {
  v1, v2, v3
}
main() {
  MyEnum.v1.index;
  MyEnum.values;
         ^^^^^^ field READ qualified
         ^^^^^^ getter INVOCATION qualified
  MyEnum.v1;
  MyEnum.v2;
  p.MyEnum.v1;
  p.MyEnum.values;
           ^^^^^^ field READ qualified
           ^^^^^^ getter INVOCATION qualified
}
''',
    );

    var v1 = result.findElement.field('v1');
    await assertElementsReferencesText(
      {'field': v1, 'getter': v1.getter!},
      r'''
import 'test.dart' as p;

/// [v1], [MyEnum.v1], and [p.MyEnum.v1]
     ^^ field REFERENCE
     ^^ getter REFERENCE
                  ^^ field REFERENCE qualified
                  ^^ getter REFERENCE qualified
                                     ^^ field REFERENCE qualified
                                     ^^ getter REFERENCE qualified
enum MyEnum {
  v1, v2, v3
}
main() {
  MyEnum.v1.index;
         ^^ field READ qualified
         ^^ getter INVOCATION qualified
  MyEnum.values;
  MyEnum.v1;
         ^^ field READ qualified
         ^^ getter INVOCATION qualified
  MyEnum.v2;
  p.MyEnum.v1;
           ^^ field READ qualified
           ^^ getter INVOCATION qualified
  p.MyEnum.values;
}
''',
    );

    var v2 = result.findElement.field('v2');
    await assertElementsReferencesText(
      {'field': v2, 'getter': v2.getter!},
      r'''
import 'test.dart' as p;

/// [v1], [MyEnum.v1], and [p.MyEnum.v1]
enum MyEnum {
  v1, v2, v3
}
main() {
  MyEnum.v1.index;
  MyEnum.values;
  MyEnum.v1;
  MyEnum.v2;
         ^^ field READ qualified
         ^^ getter INVOCATION qualified
  p.MyEnum.v1;
  p.MyEnum.values;
}
''',
    );
  }

  test_searchReferences_FieldElement_ofExtension_instance_getterSetterDeclarations() async {
    var result = await resolveTestCode('''
extension E on int {
  int get foo => 0;
  set foo(int _) {}
}

void useField(int a) {
  a.foo;
  a.foo = 0;
  a.foo += 1;
  a.foo ??= 2;
  a.foo++;
  --a.foo;
  E(a).foo;
  E(a).foo = 0;
  E(a).foo += 1;
  E(a).foo ??= 2;
  E(a).foo++;
  --E(a).foo;
}
''');
    var field = result.findElement.field('foo');

    await assertElementsReferencesText(
      {
        'field': field,
        'getter': field.getter!,
        'setter': field.setter!,
        'num.+': result.typeProvider.numElement.getMethod('+')!,
        'num.-': result.typeProvider.numElement.getMethod('-')!,
      },
      r'''
extension E on int {
  int get foo => 0;
  set foo(int _) {}
}

void useField(int a) {
  a.foo;
    ^^^ field READ qualified
    ^^^ getter INVOCATION qualified
  a.foo = 0;
    ^^^ field WRITE qualified
    ^^^ setter INVOCATION qualified
  a.foo += 1;
    ^^^ field READ_WRITE qualified
    ^^^ getter INVOCATION qualified
    ^^^ setter INVOCATION qualified
        ^^ num.+ INVOCATION qualified
  a.foo ??= 2;
    ^^^ field READ_WRITE qualified
    ^^^ getter INVOCATION qualified
    ^^^ setter INVOCATION qualified
  a.foo++;
    ^^^ field READ_WRITE qualified
    ^^^ getter INVOCATION qualified
    ^^^ setter INVOCATION qualified
       ^^ num.+ INVOCATION qualified
  --a.foo;
  ^^ num.- INVOCATION qualified
      ^^^ field READ_WRITE qualified
      ^^^ getter INVOCATION qualified
      ^^^ setter INVOCATION qualified
  E(a).foo;
       ^^^ field READ qualified
       ^^^ getter INVOCATION qualified
  E(a).foo = 0;
       ^^^ field WRITE qualified
       ^^^ setter INVOCATION qualified
  E(a).foo += 1;
       ^^^ field READ_WRITE qualified
       ^^^ getter INVOCATION qualified
       ^^^ setter INVOCATION qualified
           ^^ num.+ INVOCATION qualified
  E(a).foo ??= 2;
       ^^^ field READ_WRITE qualified
       ^^^ getter INVOCATION qualified
       ^^^ setter INVOCATION qualified
  E(a).foo++;
       ^^^ field READ_WRITE qualified
       ^^^ getter INVOCATION qualified
       ^^^ setter INVOCATION qualified
          ^^ num.+ INVOCATION qualified
  --E(a).foo;
  ^^ num.- INVOCATION qualified
         ^^^ field READ_WRITE qualified
         ^^^ getter INVOCATION qualified
         ^^^ setter INVOCATION qualified
}
''',
    );
  }

  test_searchReferences_FieldElement_ofExtensionType_static_fieldDeclaration() async {
    var result = await resolveTestCode('''
/// [foo] and [A.foo]
extension type A(int it) {
  static int foo = 0;
  void useField() {
    foo;
    foo = 0;
  }
}
void useField() {
  A.foo;
  A.foo = 0;
}
''');
    var field = result.findElement.field('foo');

    await assertElementsReferencesText(
      {'field': field, 'getter': field.getter!, 'setter': field.setter!},
      r'''
/// [foo] and [A.foo]
     ^^^ field REFERENCE
     ^^^ getter REFERENCE
                 ^^^ field REFERENCE qualified
                 ^^^ getter REFERENCE qualified
extension type A(int it) {
  static int foo = 0;
  void useField() {
    foo;
    ^^^ field READ
    ^^^ getter INVOCATION
    foo = 0;
    ^^^ field WRITE
    ^^^ setter INVOCATION
  }
}
void useField() {
  A.foo;
    ^^^ field READ qualified
    ^^^ getter INVOCATION qualified
  A.foo = 0;
    ^^^ field WRITE qualified
    ^^^ setter INVOCATION qualified
}
''',
    );
  }

  test_searchReferences_FormalParameterElement_multiplyDefined_generic() async {
    newFile('$testPackageLibPath/a.dart', r'''
void foo<T>({T? test}) {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
void foo<T>({T? test}) {}
''');

    var result = await resolveTestCode(r"""
import 'a.dart';
import 'b.dart';

void f() {
  foo(test: 0);
}
""");

    var elementA = result.findElement
        .importFind('package:test/a.dart')
        .topFunction('foo')
        .parameter('test');
    await assertElementReferencesText(elementA, r'''
import 'a.dart';
import 'b.dart';

void f() {
  foo(test: 0);
      ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
}
''');

    var elementB = result.findElement
        .importFind('package:test/b.dart')
        .topFunction('foo')
        .parameter('test');
    await assertElementReferencesText(elementB, r'''
''');
  }

  test_searchReferences_FormalParameterElement_ofConstructor_primary_optionalNamed() async {
    var result = await resolveTestCode('''
class A({int? test}) {
  /// [test]
  this : assert(test != null) {
    test;
    test = 0;
    test += 0;
    (test,) = (0,);
    for (test in [0]) {}
  }

  A.redirect({int? test}) : this(test: test);
}

class B extends A {
  B({super.test});
}

class C extends A {
  C({int? test}) : super(test: test);
}

void f() {
  A(test: 0);
  A _ = .new(test: 0);
}
''');
    var element = result.findElement.unnamedConstructor('A').parameter('test');
    await assertElementReferencesText(element, r'''
class A({int? test}) {
  /// [test]
       ^^^^ REFERENCE
  this : assert(test != null) {
                ^^^^ READ
    test;
    ^^^^ READ
    test = 0;
    ^^^^ WRITE
    test += 0;
    ^^^^ READ_WRITE
    (test,) = (0,);
     ^^^^ WRITE
    for (test in [0]) {}
         ^^^^ WRITE
  }

  A.redirect({int? test}) : this(test: test);
                                 ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
}

class B extends A {
  B({super.test});
           ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
}

class C extends A {
  C({int? test}) : super(test: test);
                         ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
}

void f() {
  A(test: 0);
    ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
  A _ = .new(test: 0);
             ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
}
''');
  }

  test_searchReferences_FormalParameterElement_ofConstructor_primary_optionalNamed_genericClass() async {
    var result = await resolveTestCode('''
class A<T>({T? test}) {
  /// [test]
  this : assert(test != null) {
    test;
    test = null;
    (test,) = (null,);
    for (test in [null]) {}
  }

  A.redirect({T? test}) : this(test: test);
}

class B<T> extends A<T> {
  B({super.test});
}

class C<T> extends A<T> {
  C({T? test}) : super(test: test);
}

void f() {
  A(test: 0);
  A<int> _ = .new(test: 0);
}
''');
    var element = result.findElement.unnamedConstructor('A').parameter('test');
    await assertElementReferencesText(element, r'''
class A<T>({T? test}) {
  /// [test]
       ^^^^ REFERENCE
  this : assert(test != null) {
                ^^^^ READ
    test;
    ^^^^ READ
    test = null;
    ^^^^ WRITE
    (test,) = (null,);
     ^^^^ WRITE
    for (test in [null]) {}
         ^^^^ WRITE
  }

  A.redirect({T? test}) : this(test: test);
                               ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
}

class B<T> extends A<T> {
  B({super.test});
           ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
}

class C<T> extends A<T> {
  C({T? test}) : super(test: test);
                       ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
}

void f() {
  A(test: 0);
    ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
  A<int> _ = .new(test: 0);
                  ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
}
''');
  }

  test_searchReferences_FormalParameterElement_ofConstructor_primary_optionalPositional() async {
    var result = await resolveTestCode('''
class A([int? test]) {
  /// [test]
  this : assert(test != null) {
    test;
    test = 0;
    test += 0;
    (test,) = (0,);
    for (test in [0]) {}
  }

  A.redirect([int? test]) : this(test);
}

class B extends A {
  B([super.test]);
}

class C extends A {
  C([int? test]) : super(test);
}

void f() {
  A(0);
  A _ = .new(0);
}
''');
    var element = result.findElement.unnamedConstructor('A').parameter('test');
    await assertElementReferencesText(element, r'''
class A([int? test]) {
  /// [test]
       ^^^^ REFERENCE
  this : assert(test != null) {
                ^^^^ READ
    test;
    ^^^^ READ
    test = 0;
    ^^^^ WRITE
    test += 0;
    ^^^^ READ_WRITE
    (test,) = (0,);
     ^^^^ WRITE
    for (test in [0]) {}
         ^^^^ WRITE
  }

  A.redirect([int? test]) : this(test);
}

class B extends A {
  B([super.test]);
           ^^^^ REFERENCE qualified
}

class C extends A {
  C([int? test]) : super(test);
}

void f() {
  A(0);
  A _ = .new(0);
}
''');
  }

  test_searchReferences_FormalParameterElement_ofConstructor_primary_requiredNamed() async {
    var result = await resolveTestCode('''
class A({required int test}) {
  /// [test]
  this : assert(test != -1) {
    test;
    test = 0;
    test += 0;
    (test,) = (0,);
    for (test in [0]) {}
  }

  A.redirect({required int test}) : this(test: test);
}

class B extends A {
  B({required super.test});
}

class C extends A {
  C({required int test}) : super(test: test);
}

void f() {
  A(test: 0);
  A _ = .new(test: 0);
}
''');
    var element = result.findElement.unnamedConstructor('A').parameter('test');
    await assertElementReferencesText(element, r'''
class A({required int test}) {
  /// [test]
       ^^^^ REFERENCE
  this : assert(test != -1) {
                ^^^^ READ
    test;
    ^^^^ READ
    test = 0;
    ^^^^ WRITE
    test += 0;
    ^^^^ READ_WRITE
    (test,) = (0,);
     ^^^^ WRITE
    for (test in [0]) {}
         ^^^^ WRITE
  }

  A.redirect({required int test}) : this(test: test);
                                         ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
}

class B extends A {
  B({required super.test});
                    ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
}

class C extends A {
  C({required int test}) : super(test: test);
                                 ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
}

void f() {
  A(test: 0);
    ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
  A _ = .new(test: 0);
             ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
}
''');
  }

  test_searchReferences_FormalParameterElement_ofConstructor_primary_requiredPositional() async {
    var result = await resolveTestCode('''
class A(int test) {
  /// [test]
  this : assert(test != -1) {
    test;
    test = 0;
    test += 0;
    (test,) = (0,);
    for (test in [0]) {}
  }

  A.redirect(int test) : this(test);
}

class B extends A {
  B(super.test);
}

class C extends A {
  C(int test) : super(test);
}

void f() {
  A(0);
  A _ = .new(0);
}
''');
    var element = result.findElement.unnamedConstructor('A').parameter('test');
    await assertElementReferencesText(element, r'''
class A(int test) {
  /// [test]
       ^^^^ REFERENCE
  this : assert(test != -1) {
                ^^^^ READ
    test;
    ^^^^ READ
    test = 0;
    ^^^^ WRITE
    test += 0;
    ^^^^ READ_WRITE
    (test,) = (0,);
     ^^^^ WRITE
    for (test in [0]) {}
         ^^^^ WRITE
  }

  A.redirect(int test) : this(test);
}

class B extends A {
  B(super.test);
          ^^^^ REFERENCE qualified
}

class C extends A {
  C(int test) : super(test);
}

void f() {
  A(0);
  A _ = .new(0);
}
''');
  }

  test_searchReferences_FormalParameterElement_ofConstructor_typeName_optionalNamed() async {
    var result = await resolveTestCode('''
class A {
  /// [test]
  A({int? test}) : assert(test != null) {
    test;
    test = 0;
    test += 0;
    (test,) = (0,);
    for (test in [0]) {}
  }

  A.redirect({int? test}) : this(test: test);
}

class B extends A {
  B({super.test});
}

class C extends A {
  C({int? test}) : super(test: test);
}

void f() {
  A(test: 0);
  A _ = .new(test: 0);
}
''');
    var element = result.findElement.unnamedConstructor('A').parameter('test');
    await assertElementReferencesText(element, r'''
class A {
  /// [test]
       ^^^^ REFERENCE
  A({int? test}) : assert(test != null) {
                          ^^^^ READ
    test;
    ^^^^ READ
    test = 0;
    ^^^^ WRITE
    test += 0;
    ^^^^ READ_WRITE
    (test,) = (0,);
     ^^^^ WRITE
    for (test in [0]) {}
         ^^^^ WRITE
  }

  A.redirect({int? test}) : this(test: test);
                                 ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
}

class B extends A {
  B({super.test});
           ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
}

class C extends A {
  C({int? test}) : super(test: test);
                         ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
}

void f() {
  A(test: 0);
    ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
  A _ = .new(test: 0);
             ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
}
''');
  }

  test_searchReferences_FormalParameterElement_ofConstructor_typeName_optionalNamed_genericClass() async {
    var result = await resolveTestCode('''
class A<T> {
  /// [test]
  A({T? test}) : assert(test != null) {
    test;
    test = null;
    (test,) = (null,);
    for (test in [null]) {}
  }

  A.redirect({T? test}) : this(test: test);
}

class B<T> extends A<T> {
  B({super.test});
}

class C<T> extends A<T> {
  C({T? test}) : super(test: test);
}

void f() {
  A(test: 0);
  A<int> _ = .new(test: 0);
}
''');
    var element = result.findElement.unnamedConstructor('A').parameter('test');
    await assertElementReferencesText(element, r'''
class A<T> {
  /// [test]
       ^^^^ REFERENCE
  A({T? test}) : assert(test != null) {
                        ^^^^ READ
    test;
    ^^^^ READ
    test = null;
    ^^^^ WRITE
    (test,) = (null,);
     ^^^^ WRITE
    for (test in [null]) {}
         ^^^^ WRITE
  }

  A.redirect({T? test}) : this(test: test);
                               ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
}

class B<T> extends A<T> {
  B({super.test});
           ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
}

class C<T> extends A<T> {
  C({T? test}) : super(test: test);
                       ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
}

void f() {
  A(test: 0);
    ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
  A<int> _ = .new(test: 0);
                  ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
}
''');
  }

  test_searchReferences_FormalParameterElement_ofConstructor_typeName_optionalPositional() async {
    var result = await resolveTestCode('''
class A {
  /// [test]
  A([int? test]) : assert(test != null) {
    test;
    test = 0;
    test += 0;
    (test,) = (0,);
    for (test in [0]) {}
  }

  A.redirect([int? test]) : this(test);
}

class B extends A {
  B([super.test]);
}

class C extends A {
  C([int? test]) : super(test);
}

void f() {
  A(0);
  A _ = .new(0);
}
''');
    var element = result.findElement.unnamedConstructor('A').parameter('test');
    await assertElementReferencesText(element, r'''
class A {
  /// [test]
       ^^^^ REFERENCE
  A([int? test]) : assert(test != null) {
                          ^^^^ READ
    test;
    ^^^^ READ
    test = 0;
    ^^^^ WRITE
    test += 0;
    ^^^^ READ_WRITE
    (test,) = (0,);
     ^^^^ WRITE
    for (test in [0]) {}
         ^^^^ WRITE
  }

  A.redirect([int? test]) : this(test);
}

class B extends A {
  B([super.test]);
           ^^^^ REFERENCE qualified
}

class C extends A {
  C([int? test]) : super(test);
}

void f() {
  A(0);
  A _ = .new(0);
}
''');
  }

  test_searchReferences_FormalParameterElement_ofConstructor_typeName_requiredNamed() async {
    var result = await resolveTestCode('''
class A {
  /// [test]
  A({required int test}) : assert(test != -1) {
    test;
    test = 0;
    test += 0;
    (test,) = (0,);
    for (test in [0]) {}
  }

  A.redirect({required int test}) : this(test: test);
}

class B extends A {
  B({required super.test});
}

class C extends A {
  C({required int test}) : super(test: test);
}

void f() {
  A(test: 0);
  A _ = .new(test: 0);
}
''');
    var element = result.findElement.unnamedConstructor('A').parameter('test');
    await assertElementReferencesText(element, r'''
class A {
  /// [test]
       ^^^^ REFERENCE
  A({required int test}) : assert(test != -1) {
                                  ^^^^ READ
    test;
    ^^^^ READ
    test = 0;
    ^^^^ WRITE
    test += 0;
    ^^^^ READ_WRITE
    (test,) = (0,);
     ^^^^ WRITE
    for (test in [0]) {}
         ^^^^ WRITE
  }

  A.redirect({required int test}) : this(test: test);
                                         ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
}

class B extends A {
  B({required super.test});
                    ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
}

class C extends A {
  C({required int test}) : super(test: test);
                                 ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
}

void f() {
  A(test: 0);
    ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
  A _ = .new(test: 0);
             ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
}
''');
  }

  test_searchReferences_FormalParameterElement_ofConstructor_typeName_requiredPositional() async {
    var result = await resolveTestCode('''
class A {
  /// [test]
  A(int test) : assert(test != -1) {
    test;
    test = 0;
    test += 0;
    (test,) = (0,);
    for (test in [0]) {}
  }

  A.redirect(int test) : this(test);
}

class B extends A {
  B(super.test);
}

class C extends A {
  C(int test) : super(test);
}

void f() {
  A(0);
  A _ = .new(0);
}
''');
    var element = result.findElement.unnamedConstructor('A').parameter('test');
    await assertElementReferencesText(element, r'''
class A {
  /// [test]
       ^^^^ REFERENCE
  A(int test) : assert(test != -1) {
                       ^^^^ READ
    test;
    ^^^^ READ
    test = 0;
    ^^^^ WRITE
    test += 0;
    ^^^^ READ_WRITE
    (test,) = (0,);
     ^^^^ WRITE
    for (test in [0]) {}
         ^^^^ WRITE
  }

  A.redirect(int test) : this(test);
}

class B extends A {
  B(super.test);
          ^^^^ REFERENCE qualified
}

class C extends A {
  C(int test) : super(test);
}

void f() {
  A(0);
  A _ = .new(0);
}
''');
  }

  test_searchReferences_FormalParameterElement_ofGenericFunctionType_optionalNamed() async {
    var result = await resolveTestCode('''
typedef F = void Function({int? test});

void g(F f) {
  f(test: 0);
}
''');
    var element = result.findElement.parameter('test');
    await assertElementReferencesText(element, r'''
''');
  }

  test_searchReferences_FormalParameterElement_ofGenericFunctionType_optionalNamed_call() async {
    var result = await resolveTestCode('''
typedef F<T> = void Function({T? test});

void g(F<int> f) {
  f.call(test: 0);
}
''');
    var element = result.findElement.parameter('test');
    await assertElementReferencesText(element, r'''
''');
  }

  test_searchReferences_FormalParameterElement_ofLocalFunction_optionalNamed() async {
    _makeTestFilePriority();
    var result = await resolveTestCode('''
void f() {
  /// [test]
  void foo({int? test}) {
    test;
    test = 0;
    test += 0;
    (test,) = (0,);
    for (test in [0]) {}
  }

  foo(test: 0);
  foo.call(test: 1);
  (foo)(test: 2);
}
''');
    var element = result.findElement.parameter('test');
    await assertElementReferencesText(element, r'''
void f() {
  /// [test]
  void foo({int? test}) {
    test;
    ^^^^ READ
    test = 0;
    ^^^^ WRITE
    test += 0;
    ^^^^ READ_WRITE
    (test,) = (0,);
     ^^^^ WRITE
    for (test in [0]) {}
         ^^^^ WRITE
  }

  foo(test: 0);
      ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
  foo.call(test: 1);
           ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
  (foo)(test: 2);
        ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
}
''');
  }

  test_searchReferences_FormalParameterElement_ofLocalFunction_optionalNamed_generic() async {
    _makeTestFilePriority();
    var result = await resolveTestCode('''
void f() {
  void foo<T>({T? test}) {
    test;
    test = 0;
    test += 0;
    (test,) = (0,);
    for (test in [0]) {}
  }

  foo(test: 0);
  foo.call(test: 1);
  (foo)(test: 2);
}
''');
    var element = result.findElement.parameter('test');
    await assertElementReferencesText(element, r'''
void f() {
  void foo<T>({T? test}) {
    test;
    ^^^^ READ
    test = 0;
    ^^^^ WRITE
    test += 0;
    ^^^^ READ_WRITE
    (test,) = (0,);
     ^^^^ WRITE
    for (test in [0]) {}
         ^^^^ WRITE
  }

  foo(test: 0);
      ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
  foo.call(test: 1);
           ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
  (foo)(test: 2);
        ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
}
''');
  }

  test_searchReferences_FormalParameterElement_ofLocalFunction_optionalPositional() async {
    _makeTestFilePriority();
    var result = await resolveTestCode('''
void f() {
  /// [test]
  void foo([int? test]) {
    test;
    test = 0;
    test += 0;
    (test,) = (0,);
    for (test in [0]) {}
  }

  foo(0);
  foo.call(1);
  (foo)(2);
}
''');
    var element = result.findElement.parameter('test');
    await assertElementReferencesText(element, r'''
void f() {
  /// [test]
  void foo([int? test]) {
    test;
    ^^^^ READ
    test = 0;
    ^^^^ WRITE
    test += 0;
    ^^^^ READ_WRITE
    (test,) = (0,);
     ^^^^ WRITE
    for (test in [0]) {}
         ^^^^ WRITE
  }

  foo(0);
  foo.call(1);
  (foo)(2);
}
''');
  }

  test_searchReferences_FormalParameterElement_ofLocalFunction_requiredNamed() async {
    _makeTestFilePriority();
    var result = await resolveTestCode('''
void f() {
  /// [test]
  void foo({required int test}) {
    test;
    test = 0;
    test += 0;
    (test,) = (0,);
    for (test in [0]) {}
  }

  foo(test: 0);
  foo.call(test: 1);
  (foo)(test: 2);
}
''');
    var element = result.findElement.parameter('test');
    await assertElementReferencesText(element, r'''
void f() {
  /// [test]
  void foo({required int test}) {
    test;
    ^^^^ READ
    test = 0;
    ^^^^ WRITE
    test += 0;
    ^^^^ READ_WRITE
    (test,) = (0,);
     ^^^^ WRITE
    for (test in [0]) {}
         ^^^^ WRITE
  }

  foo(test: 0);
      ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
  foo.call(test: 1);
           ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
  (foo)(test: 2);
        ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
}
''');
  }

  test_searchReferences_FormalParameterElement_ofLocalFunction_requiredPositional() async {
    _makeTestFilePriority();
    var result = await resolveTestCode('''
void f() {
  /// [test]
  void foo(int test) {
    test;
    test = 0;
    test += 0;
    (test,) = (0,);
    for (test in [0]) {}
  }

  foo(0);
  foo.call(1);
  (foo)(2);
}
''');
    var element = result.findElement.parameter('test');
    await assertElementReferencesText(element, r'''
void f() {
  /// [test]
  void foo(int test) {
    test;
    ^^^^ READ
    test = 0;
    ^^^^ WRITE
    test += 0;
    ^^^^ READ_WRITE
    (test,) = (0,);
     ^^^^ WRITE
    for (test in [0]) {}
         ^^^^ WRITE
  }

  foo(0);
  foo.call(1);
  (foo)(2);
}
''');
  }

  test_searchReferences_FormalParameterElement_ofMethod_optionalNamed() async {
    var result = await resolveTestCode('''
class A {
  /// [test]
  void foo({int? test}) {
    test;
    test = 0;
    test += 0;
    (test,) = (0,);
    for (test in [0]) {}
  }
}

void f(A a) {
  a.foo(test: 0);
  a.foo.call(test: 1);
  (a.foo)(test: 2);
}
''');
    var element = result.findElement.parameter('test');
    await assertElementReferencesText(element, r'''
class A {
  /// [test]
       ^^^^ REFERENCE
  void foo({int? test}) {
    test;
    ^^^^ READ
    test = 0;
    ^^^^ WRITE
    test += 0;
    ^^^^ READ_WRITE
    (test,) = (0,);
     ^^^^ WRITE
    for (test in [0]) {}
         ^^^^ WRITE
  }
}

void f(A a) {
  a.foo(test: 0);
        ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
  a.foo.call(test: 1);
             ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
  (a.foo)(test: 2);
          ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
}
''');
  }

  test_searchReferences_FormalParameterElement_ofMethod_optionalNamed_genericClass() async {
    var result = await resolveTestCode('''
class A<T> {
  /// [test]
  void foo({T? test}) {
    test;
    test = null;
    test = test;
    (test,) = (null,);
    for (test in [null]) {}
  }
}

void f(A<int> a) {
  a.foo(test: 0);
  a.foo.call(test: 1);
  (a.foo)(test: 2);
}
''');
    var element = result.findElement.parameter('test');
    await assertElementReferencesText(element, r'''
class A<T> {
  /// [test]
       ^^^^ REFERENCE
  void foo({T? test}) {
    test;
    ^^^^ READ
    test = null;
    ^^^^ WRITE
    test = test;
    ^^^^ WRITE
           ^^^^ READ
    (test,) = (null,);
     ^^^^ WRITE
    for (test in [null]) {}
         ^^^^ WRITE
  }
}

void f(A<int> a) {
  a.foo(test: 0);
        ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
  a.foo.call(test: 1);
  (a.foo)(test: 2);
}
''');
  }

  test_searchReferences_FormalParameterElement_ofMethod_optionalPositional() async {
    var result = await resolveTestCode('''
class A {
  /// [test]
  void foo([int? test]) {
    test;
    test = 0;
    test += 0;
    (test,) = (0,);
    for (test in [0]) {}
  }
}

void f(A a) {
  a.foo(0);
  a.foo.call(1);
  (a.foo)(2);
}
''');
    var element = result.findElement.parameter('test');
    await assertElementReferencesText(element, r'''
class A {
  /// [test]
       ^^^^ REFERENCE
  void foo([int? test]) {
    test;
    ^^^^ READ
    test = 0;
    ^^^^ WRITE
    test += 0;
    ^^^^ READ_WRITE
    (test,) = (0,);
     ^^^^ WRITE
    for (test in [0]) {}
         ^^^^ WRITE
  }
}

void f(A a) {
  a.foo(0);
  a.foo.call(1);
  (a.foo)(2);
}
''');
  }

  test_searchReferences_FormalParameterElement_ofMethod_requiredNamed() async {
    var result = await resolveTestCode('''
class A {
  /// [test]
  void foo({required int test}) {
    test;
    test = 0;
    test += 0;
    (test,) = (0,);
    for (test in [0]) {}
  }
}

void f(A a) {
  a.foo(test: 0);
  a.foo.call(test: 1);
  (a.foo)(test: 2);
}
''');
    var element = result.findElement.parameter('test');
    await assertElementReferencesText(element, r'''
class A {
  /// [test]
       ^^^^ REFERENCE
  void foo({required int test}) {
    test;
    ^^^^ READ
    test = 0;
    ^^^^ WRITE
    test += 0;
    ^^^^ READ_WRITE
    (test,) = (0,);
     ^^^^ WRITE
    for (test in [0]) {}
         ^^^^ WRITE
  }
}

void f(A a) {
  a.foo(test: 0);
        ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
  a.foo.call(test: 1);
             ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
  (a.foo)(test: 2);
          ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
}
''');
  }

  test_searchReferences_FormalParameterElement_ofMethod_requiredPositional() async {
    var result = await resolveTestCode('''
class A {
  /// [test]
  void foo(int test) {
    test;
    test = 0;
    test += 0;
    (test,) = (0,);
    for (test in [0]) {}
  }
}

void f(A a) {
  a.foo(0);
  a.foo.call(1);
  (a.foo)(2);
}
''');
    var element = result.findElement.parameter('test');
    await assertElementReferencesText(element, r'''
class A {
  /// [test]
       ^^^^ REFERENCE
  void foo(int test) {
    test;
    ^^^^ READ
    test = 0;
    ^^^^ WRITE
    test += 0;
    ^^^^ READ_WRITE
    (test,) = (0,);
     ^^^^ WRITE
    for (test in [0]) {}
         ^^^^ WRITE
  }
}

void f(A a) {
  a.foo(0);
  a.foo.call(1);
  (a.foo)(2);
}
''');
  }

  test_searchReferences_FormalParameterElement_ofTopLevelFunction_optionalNamed() async {
    var result = await resolveTestCode('''
/// [test]
void foo({int? test}) {
  test;
  test = 0;
  test += 0;
  (test,) = (0,);
  for (test in [0]) {}
}
void f() {
  foo(test: 0);
  foo.call(test: 1);
  (foo)(test: 2);
}
''');
    var element = result.findElement.parameter('test');
    await assertElementReferencesText(element, r'''
/// [test]
     ^^^^ REFERENCE
void foo({int? test}) {
  test;
  ^^^^ READ
  test = 0;
  ^^^^ WRITE
  test += 0;
  ^^^^ READ_WRITE
  (test,) = (0,);
   ^^^^ WRITE
  for (test in [0]) {}
       ^^^^ WRITE
}
void f() {
  foo(test: 0);
      ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
  foo.call(test: 1);
           ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
  (foo)(test: 2);
        ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
}
''');
  }

  test_searchReferences_FormalParameterElement_ofTopLevelFunction_optionalNamed_argumentAnywhere() async {
    var result = await resolveTestCode('''
/// [test]
void foo(int a, int b, {int? test}) {
  test;
  test = 0;
  test += 0;
  (test,) = (0,);
  for (test in [0]) {}
}

void f() {
  foo(0, test: 0, 0);
  foo.call(0, test: 1, 0);
  (foo)(0, test: 2, 0);
}
''');
    var element = result.findElement.parameter('test');
    await assertElementReferencesText(element, r'''
/// [test]
     ^^^^ REFERENCE
void foo(int a, int b, {int? test}) {
  test;
  ^^^^ READ
  test = 0;
  ^^^^ WRITE
  test += 0;
  ^^^^ READ_WRITE
  (test,) = (0,);
   ^^^^ WRITE
  for (test in [0]) {}
       ^^^^ WRITE
}

void f() {
  foo(0, test: 0, 0);
         ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
  foo.call(0, test: 1, 0);
              ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
  (foo)(0, test: 2, 0);
           ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
}
''');
  }

  test_searchReferences_FormalParameterElement_ofTopLevelFunction_optionalPositional() async {
    var result = await resolveTestCode('''
/// [test]
void foo([int? test]) {
  test;
  test = 0;
  test += 0;
  (test,) = (0,);
  for (test in [0]) {}
}
void f() {
  foo(0);
  foo.call(1);
  (foo)(2);
}
''');
    var element = result.findElement.parameter('test');
    await assertElementReferencesText(element, r'''
/// [test]
     ^^^^ REFERENCE
void foo([int? test]) {
  test;
  ^^^^ READ
  test = 0;
  ^^^^ WRITE
  test += 0;
  ^^^^ READ_WRITE
  (test,) = (0,);
   ^^^^ WRITE
  for (test in [0]) {}
       ^^^^ WRITE
}
void f() {
  foo(0);
  foo.call(1);
  (foo)(2);
}
''');
  }

  test_searchReferences_FormalParameterElement_ofTopLevelFunction_requiredNamed() async {
    var result = await resolveTestCode('''
/// [test]
void foo({required int test}) {
  test;
  test = 0;
  test += 0;
  (test,) = (0,);
  for (test in [0]) {}
}

void f() {
  foo(test: 0);
  foo.call(test: 1);
  (foo)(test: 2);
}
''');
    var element = result.findElement.parameter('test');
    await assertElementReferencesText(element, r'''
/// [test]
     ^^^^ REFERENCE
void foo({required int test}) {
  test;
  ^^^^ READ
  test = 0;
  ^^^^ WRITE
  test += 0;
  ^^^^ READ_WRITE
  (test,) = (0,);
   ^^^^ WRITE
  for (test in [0]) {}
       ^^^^ WRITE
}

void f() {
  foo(test: 0);
      ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
  foo.call(test: 1);
           ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
  (foo)(test: 2);
        ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
}
''');
  }

  test_searchReferences_FormalParameterElement_ofTopLevelFunction_requiredPositional() async {
    var result = await resolveTestCode('''
/// [test]
void foo(int test) {
  test;
  test = 0;
  test += 0;
  (test,) = (0,);
  for (test in [0]) {}
}

void f() {
  foo(0);
  foo.call(1);
  (foo)(2);
}
''');
    var element = result.findElement.parameter('test');
    await assertElementReferencesText(element, r'''
/// [test]
     ^^^^ REFERENCE
void foo(int test) {
  test;
  ^^^^ READ
  test = 0;
  ^^^^ WRITE
  test += 0;
  ^^^^ READ_WRITE
  (test,) = (0,);
   ^^^^ WRITE
  for (test in [0]) {}
       ^^^^ WRITE
}

void f() {
  foo(0);
  foo.call(1);
  (foo)(2);
}
''');
  }

  test_searchReferences_FormalParameterElement_synthetic_leastUpperBound() async {
    var result = await resolveTestCode('''
int f1({int? test}) => 0;
int f2({int? test}) => 0;
void g(bool b) {
  var f = b ? f1 : f2;
  f(test: 0);
}''');

    var element1 = result.findElement.function('f1').parameter('test');
    await assertElementReferencesText(element1, r'''
''');

    var element2 = result.findElement.function('f2').parameter('test');
    await assertElementReferencesText(element2, r'''
''');
  }

  test_searchReferences_FunctionElement() async {
    var result = await resolveTestCode('''
test() {}
main() {
  test();
  test;
}
''');
    var element = result.findElement.function('test');
    await assertElementReferencesText(element, r'''
test() {}
main() {
  test();
  ^^^^ INVOCATION
  test;
  ^^^^ REFERENCE
}
''');
  }

  test_searchReferences_FunctionElement_local() async {
    makeFilePriority(testFile);
    var result = await resolveTestCode('''
main() {
  test() {}
  test();
  test;
}
''');
    var element = result.findElement.localFunction('test');
    await assertElementReferencesText(element, r'''
main() {
  test() {}
  test();
  ^^^^ INVOCATION
  test;
  ^^^^ REFERENCE
}
''');
  }

  test_searchReferences_GetterElement_ofClass_instance_invalidWrite() async {
    var result = await resolveTestCode('''
class A {
  int get foo => 0;
  void f() {
    foo = 1;
  }
}
''');
    var element = result.findElement.getter('foo');
    await assertElementReferencesText(element, r'''
class A {
  int get foo => 0;
  void f() {
    foo = 1;
    ^^^ REFERENCE
  }
}
''');
  }

  test_searchReferences_GetterElement_ofClass_invocation() async {
    var result = await resolveTestCode('''
class A {
  get foo => null;
  void useGetter() {
    this.foo();
    foo();
  }
}''');
    var element = result.findElement.getter('foo');
    await assertElementReferencesText(element, r'''
class A {
  get foo => null;
  void useGetter() {
    this.foo();
         ^^^ INVOCATION qualified
    foo();
    ^^^ INVOCATION
  }
}
''');
  }

  test_searchReferences_GetterElement_ofClass_objectPattern() async {
    var result = await resolveTestCode('''
class A {
  int get foo => 0;
}

void useGetter(Object? x) {
  if (x case A(foo: 0)) {}
  if (x case A(: var foo)) {}
}
''');
    var element = result.findElement.getter('foo');
    await assertElementReferencesText(element, r'''
class A {
  int get foo => 0;
}

void useGetter(Object? x) {
  if (x case A(foo: 0)) {}
               ^^^ REFERENCE_IN_PATTERN_FIELD qualified
  if (x case A(: var foo)) {}
               ^0 REFERENCE_IN_PATTERN_FIELD qualified
}
''');
  }

  test_searchReferences_GetterElement_ofClass_objectPattern_otherFile() async {
    String other = convertPath('$testPackageLibPath/other.dart');
    String otherCode = '''
import 'test.dart';

void useGetter(Object? x) {
  if (x case A(foo: 0)) {}
  if (x case A(: var foo)) {}
}
''';
    newFile(other, otherCode);

    var result = await resolveTestCode('''
class A {
  int get foo => 0;
}
''');
    var element = result.findElement.getter('foo');
    await assertElementReferencesText(element, r'''
package:test/other.dart
-----------------------
import 'test.dart';

void useGetter(Object? x) {
  if (x case A(foo: 0)) {}
               ^^^ REFERENCE_IN_PATTERN_FIELD qualified
  if (x case A(: var foo)) {}
               ^0 REFERENCE_IN_PATTERN_FIELD qualified
}
''');
  }

  test_searchReferences_GetterElement_ofClass_static() async {
    var result = await resolveTestCode('''
import 'test.dart' as p;

/// [foo], [A.foo], [p.A.foo]
class A {
  static int get foo => 0;
  static void useGetter() {
    foo;
  }
}

void useGetter() {
  A.foo;
  p.A.foo;
}
''');
    var element = result.findElement.getter('foo');
    await assertElementReferencesText(element, r'''
import 'test.dart' as p;

/// [foo], [A.foo], [p.A.foo]
     ^^^ REFERENCE
              ^^^ REFERENCE qualified
                         ^^^ REFERENCE qualified
class A {
  static int get foo => 0;
  static void useGetter() {
    foo;
    ^^^ INVOCATION
  }
}

void useGetter() {
  A.foo;
    ^^^ INVOCATION qualified
  p.A.foo;
      ^^^ INVOCATION qualified
}
''');
  }

  test_searchReferences_ImportElement_noPrefix() async {
    var result = await resolveTestCode('''
import 'dart:math' show max, pi, Random hide min;
export 'dart:math' show max, pi, Random hide min;
main() {
  pi;
  new Random();
  max(1, 2);
}
Random bar() => null;
''');
    var element = result.findElement.import('dart:math', mustBeUnique: false);
    await assertLibraryImportReferencesText(element, r'''
import 'dart:math' show max, pi, Random hide min;
export 'dart:math' show max, pi, Random hide min;
main() {
  pi;
  ^0
  new Random();
      ^0
  max(1, 2);
  ^0
}
Random bar() => null;
^0
''');
  }

  test_searchReferences_ImportElement_noPrefix_inPackage() async {
    var aaaPackageRootPath = '$packagesRootPath/aaa';
    var aaaFilePath = convertPath('$aaaPackageRootPath/lib/a.dart');

    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'aaa', rootFolder: getFolder(aaaPackageRootPath)),
    );

    fileForContextSelection = testFile;

    var result = await resolveFileCode(aaaFilePath, '''
import 'dart:math' show max, pi, Random hide min;
export 'dart:math' show max, pi, Random hide min;
main() {
  pi;
  new Random();
  max(1, 2);
}
Random bar() => null;
''');

    var element = result.findElement.import('dart:math');
    await assertLibraryImportReferencesText(element, r'''
package:aaa/a.dart
------------------
import 'dart:math' show max, pi, Random hide min;
export 'dart:math' show max, pi, Random hide min;
main() {
  pi;
  ^0
  new Random();
      ^0
  max(1, 2);
  ^0
}
Random bar() => null;
^0
''');
  }

  test_searchReferences_ImportElement_withPrefix() async {
    var result = await resolveTestCode('''
import 'dart:math' as math show max, pi, Random hide min;
export 'dart:math' show max, pi, Random hide min;
main() {
  math.pi;
  new math.Random();
  math.max(1, 2);
}
math.Random bar() => null;
''');
    var element = result.findElement.import('dart:math', mustBeUnique: false);
    await assertLibraryImportReferencesText(element, r'''
import 'dart:math' as math show max, pi, Random hide min;
export 'dart:math' show max, pi, Random hide min;
main() {
  math.pi;
  ^^^^^
  new math.Random();
      ^^^^^
  math.max(1, 2);
  ^^^^^
}
math.Random bar() => null;
^^^^^
''');
  }

  test_searchReferences_ImportElement_withPrefix_forMultipleImports() async {
    var result = await resolveTestCode('''
import 'dart:async' as p;
import 'dart:math' as p;
main() {
  p.Random r;
  p.Future f;
}
''');
    {
      var element = result.findElement.import('dart:async');
      await assertLibraryImportReferencesText(element, r'''
import 'dart:async' as p;
import 'dart:math' as p;
main() {
  p.Random r;
  p.Future f;
  ^^
}
''');
    }
    {
      var element = result.findElement.import('dart:math');
      await assertLibraryImportReferencesText(element, r'''
import 'dart:async' as p;
import 'dart:math' as p;
main() {
  p.Random r;
  ^^
  p.Future f;
}
''');
    }
  }

  test_searchReferences_LabelElement() async {
    makeFilePriority(testFile);
    var result = await resolveTestCode('''
main() {
label:
  while (true) {
    if (true) {
      break label;
    }
    break label;
  }
}
''');
    var element = result.findElement.label('label');
    await assertElementReferencesText(element, r'''
main() {
label:
  while (true) {
    if (true) {
      break label;
            ^^^^^ REFERENCE
    }
    break label;
          ^^^^^ REFERENCE
  }
}
''');
  }

  test_searchReferences_LibraryElement_inPackage() async {
    var aaaPackageRootPath = '$packagesRootPath/aaa';

    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'aaa', rootFolder: getFolder(aaaPackageRootPath)),
    );

    var libPath = convertPath('$aaaPackageRootPath/lib/a.dart');
    var partPathA = convertPath('$aaaPackageRootPath/lib/unitA.dart');
    var partPathB = convertPath('$aaaPackageRootPath/lib/unitB.dart');

    newFile(partPathA, 'part of lib;');
    newFile(partPathB, 'part of lib;');

    fileForContextSelection = testFile;

    var result = await resolveFileCode(libPath, '''
library lib;
part 'unitA.dart';
part 'unitB.dart';
''');
    var element = result.libraryElement;
    await assertElementReferencesText(element, r'''
package:aaa/unitA.dart
----------------------
part of lib;
        ^^^ REFERENCE

package:aaa/unitB.dart
----------------------
part of lib;
        ^^^ REFERENCE
''');
  }

  test_searchReferences_LibraryElement_partOfName() async {
    newFile('$testPackageLibPath/unitA.dart', 'part of lib;');
    newFile('$testPackageLibPath/unitB.dart', 'part of lib;');
    var result = await resolveTestCode('''
library lib;
part 'unitA.dart';
part 'unitB.dart';
''');
    var element = result.libraryElement;
    await assertElementReferencesText(element, r'''
package:test/unitA.dart
-----------------------
part of lib;
        ^^^ REFERENCE

package:test/unitB.dart
-----------------------
part of lib;
        ^^^ REFERENCE
''');
  }

  test_searchReferences_LibraryElement_partOfUri() async {
    newFile('$testPackageLibPath/unitA.dart', r'''
part of 'test.dart';
''');

    newFile('$testPackageLibPath/unitB.dart', r'''
part of 'test.dart';
''');

    var result = await resolveTestCode('''
part 'unitA.dart';
part 'unitB.dart';
''');

    var element = result.libraryElement;
    await assertElementReferencesText(element, r'''
package:test/unitA.dart
-----------------------
part of 'test.dart';
        ^^^^^^^^^^^ REFERENCE

package:test/unitB.dart
-----------------------
part of 'test.dart';
        ^^^^^^^^^^^ REFERENCE
''');
  }

  test_searchReferences_LibraryFragment_reference_export() async {
    newFile('$testPackageLibPath/foo.dart', '');
    var result = await resolveTestCode('''
export 'foo.dart';
''');
    var element = result.findElement
        .export('package:test/foo.dart')
        .exportedLibrary!
        .firstFragment;
    await assertLibraryFragmentReferencesText(element, r'''
export 'foo.dart';
       ^^^^^^^^^^
''');
  }

  test_searchReferences_LibraryFragment_reference_import() async {
    newFile('$testPackageLibPath/foo.dart', '');
    var result = await resolveTestCode('''
import 'foo.dart';
''');
    var element = result.findElement
        .importFind('package:test/foo.dart')
        .libraryFragment;
    await assertLibraryFragmentReferencesText(element, r'''
import 'foo.dart';
       ^^^^^^^^^^
''');
  }

  test_searchReferences_LibraryFragment_reference_part() async {
    newFile('$testPackageLibPath/foo.dart', r'''
part of 'test.dart';
''');

    var result = await resolveTestCode('''
part 'foo.dart';
''');

    var element = result.findElement.part('package:test/foo.dart');
    await assertLibraryFragmentReferencesText(element, r'''
part 'foo.dart';
     ^^^^^^^^^^
''');
  }

  test_searchReferences_LocalVariableElement() async {
    makeFilePriority(testFile);
    var result = await resolveTestCode(r'''
main() {
  var v;
  v = 1;
  v += 2;
  v;
  v();
}
''');
    var element = result.findElement.localVar('v');
    await assertElementReferencesText(element, r'''
main() {
  var v;
  v = 1;
  ^ WRITE
  v += 2;
  ^ READ_WRITE
  v;
  ^ READ
  v();
  ^ READ
}
''');
  }

  test_searchReferences_LocalVariableElement_inForEachElement_expressionBody() async {
    makeFilePriority(testFile);
    var result = await resolveTestCode('''
Object f() => [
  for (var v in []) v,
];
''');
    var element = result.findElement.localVar('v');
    await assertElementReferencesText(element, r'''
Object f() => [
  for (var v in []) v,
                    ^ READ
];
''');
  }

  test_searchReferences_LocalVariableElement_inForEachElement_inBlock() async {
    makeFilePriority(testFile);
    var result = await resolveTestCode('''
Object f() {
  {
    return [
      for (var v in []) v,
    ];
  }
}
''');
    var element = result.findElement.localVar('v');
    await assertElementReferencesText(element, r'''
Object f() {
  {
    return [
      for (var v in []) v,
                        ^ READ
    ];
  }
}
''');
  }

  test_searchReferences_LocalVariableElement_inForEachElement_inFunctionBody() async {
    makeFilePriority(testFile);
    var result = await resolveTestCode('''
Object f() {
  return [
    for (var v in []) v,
  ];
}
''');
    var element = result.findElement.localVar('v');
    await assertElementReferencesText(element, r'''
Object f() {
  return [
    for (var v in []) v,
                      ^ READ
  ];
}
''');
  }

  test_searchReferences_LocalVariableElement_inForEachElement_topLevel() async {
    makeFilePriority(testFile);
    var result = await resolveTestCode('''
var x = [
  for (var v in []) v,
];
''');
    var element = result.findElement.localVar('v');
    await assertElementReferencesText(element, r'''
var x = [
  for (var v in []) v,
                    ^ READ
];
''');
  }

  test_searchReferences_LocalVariableElement_inForEachLoop() async {
    makeFilePriority(testFile);
    var result = await resolveTestCode('''
main() {
  for (var v in []) {
    v = 1;
    v += 2;
    v;
    v();
  }
}
''');
    var element = result.findElement.localVar('v');
    await assertElementReferencesText(element, r'''
main() {
  for (var v in []) {
    v = 1;
    ^ WRITE
    v += 2;
    ^ READ_WRITE
    v;
    ^ READ
    v();
    ^ READ
  }
}
''');
  }

  test_searchReferences_LocalVariableElement_inPackage() async {
    var aaaPackageRootPath = '$packagesRootPath/aaa';
    var a_file = newFile('$aaaPackageRootPath/lib/a.dart', '''
main() {
  var v;
  v = 1;
  v += 2;
  v;
  v();
}
''');

    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'aaa', rootFolder: getFolder(aaaPackageRootPath)),
    );

    fileForContextSelection = testFile;

    driverFor(testFile).priorityFiles2 = [a_file];
    var result = await resolveFile2(a_file);

    var element = result.findElement.localVar('v');
    await assertElementReferencesText(element, r'''
package:aaa/a.dart
------------------
main() {
  var v;
  v = 1;
  ^ WRITE
  v += 2;
  ^ READ_WRITE
  v;
  ^ READ
  v();
  ^ READ
}
''');
  }

  test_searchReferences_MethodElement_normal_ofClass_instance() async {
    var result = await resolveTestCode('''
/// [foo] and [A.foo]
class A {
  void foo() {}
  void useFoo(Object? x) {
    this.foo();
    foo();
    this.foo;
    foo;
    if (x case A(foo: _)) {}
    if (x case A(: var foo)) {}
  }
}
void useFoo(A a) {
  a.foo();
  a.foo;
}
''');
    var element = result.findElement.method('foo');

    await assertElementReferencesText(element, r'''
/// [foo] and [A.foo]
     ^^^ REFERENCE
                 ^^^ REFERENCE qualified
class A {
  void foo() {}
  void useFoo(Object? x) {
    this.foo();
         ^^^ INVOCATION qualified
    foo();
    ^^^ INVOCATION
    this.foo;
         ^^^ REFERENCE qualified
    foo;
    ^^^ REFERENCE
    if (x case A(foo: _)) {}
                 ^^^ REFERENCE qualified
    if (x case A(: var foo)) {}
                 ^0 REFERENCE qualified
  }
}
void useFoo(A a) {
  a.foo();
    ^^^ INVOCATION qualified
  a.foo;
    ^^^ REFERENCE qualified
}
''');
  }

  test_searchReferences_MethodElement_normal_ofClass_instance_generic() async {
    var result = await resolveTestCode('''
/// [foo] and [A.foo]
class A<T> {
  void foo() {}
  void useFoo(Object? x) {
    this.foo();
    foo();
    this.foo;
    foo;
    if (x case A<int>(foo: _)) {}
    if (x case A<int>(: var foo)) {}
  }
}
void useFoo(A<int> a) {
  a.foo();
  a.foo;
}
''');
    var element = result.findElement.method('foo');
    await assertElementReferencesText(element, r'''
/// [foo] and [A.foo]
     ^^^ REFERENCE
                 ^^^ REFERENCE qualified
class A<T> {
  void foo() {}
  void useFoo(Object? x) {
    this.foo();
         ^^^ INVOCATION qualified
    foo();
    ^^^ INVOCATION
    this.foo;
         ^^^ REFERENCE qualified
    foo;
    ^^^ REFERENCE
    if (x case A<int>(foo: _)) {}
                      ^^^ REFERENCE qualified
    if (x case A<int>(: var foo)) {}
                      ^0 REFERENCE qualified
  }
}
void useFoo(A<int> a) {
  a.foo();
    ^^^ INVOCATION qualified
  a.foo;
    ^^^ REFERENCE qualified
}
''');
  }

  test_searchReferences_MethodElement_normal_ofClass_parenthesizedReceiver_ifNull() async {
    var result = await resolveTestCode('''
class A {
  void foo() {}
}

void f(A a) {
  (a).foo ??= () {};
//    ^^^
// [diag.assignmentToMethod] Methods can't be assigned a value.
//            ^^^^^
// [diag.deadCode] Dead code.
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
}
''');
    var element = result.findElement.method('foo');

    await assertElementReferencesText(element, r'''
class A {
  void foo() {}
}

void f(A a) {
  (a).foo ??= () {};
      ^^^ REFERENCE qualified
//    ^^^
// [diag.assignmentToMethod] Methods can't be assigned a value.
//            ^^^^^
// [diag.deadCode] Dead code.
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
}
''');
  }

  test_searchReferences_MethodElement_normal_ofClass_static() async {
    var result = await resolveTestCode('''
import 'test.dart' as p;

/// [foo], [A.foo], [p.A.foo]
class A {
  static A foo() => A();
  static void useFoo() {
    foo();
    foo;
  }
}

void useFoo() {
  A.foo();
  A.foo;
  A a = .foo();
  A aa = .foo;
  p.A.foo();
  p.A.foo;
}
''');
    var element = result.findElement.method('foo');

    await assertElementReferencesText(element, r'''
import 'test.dart' as p;

/// [foo], [A.foo], [p.A.foo]
     ^^^ REFERENCE
              ^^^ REFERENCE qualified
                         ^^^ REFERENCE qualified
class A {
  static A foo() => A();
  static void useFoo() {
    foo();
    ^^^ INVOCATION
    foo;
    ^^^ REFERENCE
  }
}

void useFoo() {
  A.foo();
    ^^^ INVOCATION qualified
  A.foo;
    ^^^ REFERENCE qualified
  A a = .foo();
         ^^^ INVOCATION qualified
  A aa = .foo;
          ^^^ REFERENCE qualified
  p.A.foo();
      ^^^ INVOCATION qualified
  p.A.foo;
      ^^^ REFERENCE qualified
}
''');
  }

  test_searchReferences_MethodElement_normal_ofClass_static_dotShorthand_otherFile() async {
    // Note, we don't mention `A`, only the method name `foo`.
    newFile('$testPackageLibPath/other.dart', '''
import 'test.dart';

void useFoo() {
  useA(.foo());
}
''');
    var result = await resolveTestCode('''
class A {
  static A foo() => A();
}
void useA(A a) {}
''');
    var element = result.findElement.method('foo');

    await assertElementReferencesText(element, r'''
package:test/other.dart
-----------------------
import 'test.dart';

void useFoo() {
  useA(.foo());
        ^^^ INVOCATION qualified
}
''');
  }

  test_searchReferences_MethodElement_normal_ofClass_static_viaTypeAlias_otherFile() async {
    newFile('$testPackageLibPath/other.dart', '''
import 'test.dart';

void useFoo() {
  B.foo();
  B.foo;
}
''');
    var result = await resolveTestCode('''
class A {
  static A foo() => A();
}
typedef B = A;
''');
    var element = result.findElement.method('foo');

    await assertElementReferencesText(element, r'''
package:test/other.dart
-----------------------
import 'test.dart';

void useFoo() {
  B.foo();
    ^^^ INVOCATION qualified
  B.foo;
    ^^^ REFERENCE qualified
}
''');
  }

  test_searchReferences_MethodElement_normal_ofEnum_instance() async {
    var result = await resolveTestCode('''
/// [foo] and [E.foo]
enum E {
  v;
  void foo() {}
  void useFoo() {
    this.foo();
    foo();
    this.foo;
    foo;
  }
}
void useFoo(E e) {
  e.foo();
  e.foo;
}
''');
    var element = result.findElement.method('foo');

    await assertElementReferencesText(element, r'''
/// [foo] and [E.foo]
     ^^^ REFERENCE
                 ^^^ REFERENCE qualified
enum E {
  v;
  void foo() {}
  void useFoo() {
    this.foo();
         ^^^ INVOCATION qualified
    foo();
    ^^^ INVOCATION
    this.foo;
         ^^^ REFERENCE qualified
    foo;
    ^^^ REFERENCE
  }
}
void useFoo(E e) {
  e.foo();
    ^^^ INVOCATION qualified
  e.foo;
    ^^^ REFERENCE qualified
}
''');
  }

  test_searchReferences_MethodElement_normal_ofEnum_static() async {
    var result = await resolveTestCode('''
/// [foo] and [E.foo]
enum E {
  v;
  static void foo() {}
  static void useFoo() {
    foo();
    foo;
  }
}
void useFoo() {
  E.foo();
  E.foo;
}
''');
    var element = result.findElement.method('foo');

    await assertElementReferencesText(element, r'''
/// [foo] and [E.foo]
     ^^^ REFERENCE
                 ^^^ REFERENCE qualified
enum E {
  v;
  static void foo() {}
  static void useFoo() {
    foo();
    ^^^ INVOCATION
    foo;
    ^^^ REFERENCE
  }
}
void useFoo() {
  E.foo();
    ^^^ INVOCATION qualified
  E.foo;
    ^^^ REFERENCE qualified
}
''');
  }

  test_searchReferences_MethodElement_normal_ofExtension_named_instance() async {
    var result = await resolveTestCode('''
/// [foo] and [E.foo]
extension E on int {
  void foo() {}
}

void useFoo() {
  0.foo();
  0.foo;
}
''');
    var element = result.findElement.method('foo');

    await assertElementReferencesText(element, r'''
/// [foo] and [E.foo]
     ^^^ REFERENCE
                 ^^^ REFERENCE qualified
extension E on int {
  void foo() {}
}

void useFoo() {
  0.foo();
    ^^^ INVOCATION qualified
  0.foo;
    ^^^ REFERENCE qualified
}
''');
  }

  test_searchReferences_MethodElement_normal_ofExtension_named_static() async {
    var result = await resolveTestCode('''
/// [foo] and [E.foo]
extension E on int {
  static void foo() {}
}

void useFoo() {
  E.foo();
  E.foo;
}
''');
    var element = result.findElement.method('foo');

    await assertElementReferencesText(element, r'''
/// [foo] and [E.foo]
     ^^^ REFERENCE
                 ^^^ REFERENCE qualified
extension E on int {
  static void foo() {}
}

void useFoo() {
  E.foo();
    ^^^ INVOCATION qualified
  E.foo;
    ^^^ REFERENCE qualified
}
''');
  }

  test_searchReferences_MethodElement_normal_ofExtension_unnamed_instance() async {
    var result = await resolveTestCode('''
/// [foo] and [int.foo]
extension on int {
  void foo() {} // int
}

/// [foo] and [double.foo]
extension on double {
  void foo() {} // double
}

void useFoo() {
  0.foo();
  0.foo;
  (1.2).foo();
  (1.2).foo;
}
''');

    var intMethod = result.findNode.methodDeclaration('foo() {} // int');
    var intMethodElement = intMethod.declaredFragment!.element;
    await assertElementReferencesText(intMethodElement, r'''
/// [foo] and [int.foo]
     ^^^ REFERENCE
extension on int {
  void foo() {} // int
}

/// [foo] and [double.foo]
extension on double {
  void foo() {} // double
}

void useFoo() {
  0.foo();
    ^^^ INVOCATION qualified
  0.foo;
    ^^^ REFERENCE qualified
  (1.2).foo();
  (1.2).foo;
}
''');

    var doubleMethod = result.findNode.methodDeclaration('foo() {} // double');
    var doubleMethodElement = doubleMethod.declaredFragment!.element;
    await assertElementReferencesText(doubleMethodElement, r'''
/// [foo] and [int.foo]
extension on int {
  void foo() {} // int
}

/// [foo] and [double.foo]
     ^^^ REFERENCE
extension on double {
  void foo() {} // double
}

void useFoo() {
  0.foo();
  0.foo;
  (1.2).foo();
        ^^^ INVOCATION qualified
  (1.2).foo;
        ^^^ REFERENCE qualified
}
''');
  }

  test_searchReferences_MethodElement_normal_ofExtensionType_instance() async {
    var result = await resolveTestCode('''
/// [foo] and [A.foo]
extension type A(int it) {
  void foo() {}
  void useFoo() {
    this.foo();
    foo();
    this.foo;
    foo;
  }
}
void useFoo() {
  var a = A(0);
  a.foo();
  a.foo;
}
''');
    var element = result.findElement.method('foo');

    await assertElementReferencesText(element, r'''
/// [foo] and [A.foo]
     ^^^ REFERENCE
                 ^^^ REFERENCE qualified
extension type A(int it) {
  void foo() {}
  void useFoo() {
    this.foo();
         ^^^ INVOCATION qualified
    foo();
    ^^^ INVOCATION
    this.foo;
         ^^^ REFERENCE qualified
    foo;
    ^^^ REFERENCE
  }
}
void useFoo() {
  var a = A(0);
  a.foo();
    ^^^ INVOCATION qualified
  a.foo;
    ^^^ REFERENCE qualified
}
''');
  }

  test_searchReferences_MethodElement_normal_ofExtensionType_static() async {
    var result = await resolveTestCode('''
/// [foo] and [A.foo]
extension type A(int it) {
  static void foo() {}
  static void useFoo() {
    foo();
    foo;
  }
}
void useFoo() {
  A.foo();
  A.foo;
}
''');
    var element = result.findElement.method('foo');

    await assertElementReferencesText(element, r'''
/// [foo] and [A.foo]
     ^^^ REFERENCE
                 ^^^ REFERENCE qualified
extension type A(int it) {
  static void foo() {}
  static void useFoo() {
    foo();
    ^^^ INVOCATION
    foo;
    ^^^ REFERENCE
  }
}
void useFoo() {
  A.foo();
    ^^^ INVOCATION qualified
  A.foo;
    ^^^ REFERENCE qualified
}
''');
  }

  test_searchReferences_MethodElement_normal_ofMixin_instance() async {
    var result = await resolveTestCode('''
/// [foo] and [M.foo]
mixin M {
  void foo() {}
  void useFoo() {
    this.foo();
    foo();
    this.foo;
    foo;
  }
}
void useFoo(M m) {
  m.foo();
  m.foo;
}
''');
    var element = result.findElement.method('foo');

    await assertElementReferencesText(element, r'''
/// [foo] and [M.foo]
     ^^^ REFERENCE
                 ^^^ REFERENCE qualified
mixin M {
  void foo() {}
  void useFoo() {
    this.foo();
         ^^^ INVOCATION qualified
    foo();
    ^^^ INVOCATION
    this.foo;
         ^^^ REFERENCE qualified
    foo;
    ^^^ REFERENCE
  }
}
void useFoo(M m) {
  m.foo();
    ^^^ INVOCATION qualified
  m.foo;
    ^^^ REFERENCE qualified
}
''');
  }

  test_searchReferences_MethodElement_normal_ofMixin_static() async {
    var result = await resolveTestCode('''
/// [foo] and [M.foo]
mixin M {
  static void foo() {}
  static void useFoo() {
    foo();
    foo;
  }
}
void useFoo() {
  M.foo();
  M.foo;
  M m = .foo();
}
''');
    var element = result.findElement.method('foo');

    await assertElementReferencesText(element, r'''
/// [foo] and [M.foo]
     ^^^ REFERENCE
                 ^^^ REFERENCE qualified
mixin M {
  static void foo() {}
  static void useFoo() {
    foo();
    ^^^ INVOCATION
    foo;
    ^^^ REFERENCE
  }
}
void useFoo() {
  M.foo();
    ^^^ INVOCATION qualified
  M.foo;
    ^^^ REFERENCE qualified
  M m = .foo();
         ^^^ INVOCATION qualified
}
''');
  }

  test_searchReferences_MethodElement_operator_ofClass_binary() async {
    var result = await resolveTestCode('''
/// [operator +] and [A.operator +]
class A {
  operator +(other) => this;
}
void useOperator(A a) {
  a + 1;
  a += 2;
  ++a;
  a++;
}
''');
    var element = result.findElement.method('+');

    await assertElementReferencesText(element, r'''
/// [operator +] and [A.operator +]
              ^ REFERENCE
                                 ^ REFERENCE qualified
class A {
  operator +(other) => this;
}
void useOperator(A a) {
  a + 1;
    ^ INVOCATION qualified
  a += 2;
    ^^ INVOCATION qualified
  ++a;
  ^^ INVOCATION qualified
  a++;
   ^^ INVOCATION qualified
}
''');
  }

  test_searchReferences_MethodElement_operator_ofClass_index() async {
    var result = await resolveTestCode('''
/// [operator []] and [A.operator []]
class A {
  operator [](i) => null;
}
void useOperator(A a) {
  a[0];
}
''');
    var element = result.findElement.method('[]');

    await assertElementReferencesText(element, r'''
/// [operator []] and [A.operator []]
class A {
  operator [](i) => null;
}
void useOperator(A a) {
  a[0];
   ^ INVOCATION qualified
}
''');
  }

  test_searchReferences_MethodElement_operator_ofClass_indexEq() async {
    var result = await resolveTestCode('''
/// [operator []=] and [A.operator []=]
class A {
  operator []=(i, v) {}
}
void useOperator(A a) {
  a[1] = 42;
}
''');
    var element = result.findElement.method('[]=');

    await assertElementReferencesText(element, r'''
/// [operator []=] and [A.operator []=]
class A {
  operator []=(i, v) {}
}
void useOperator(A a) {
  a[1] = 42;
   ^ INVOCATION qualified
}
''');
  }

  test_searchReferences_MethodElement_operator_ofClass_prefix() async {
    var result = await resolveTestCode('''
/// [operator ~] and [A.operator ~]
class A {
  A operator ~() => this;
}
void useOperator(A a) {
  ~a;
}
''');
    var element = result.findElement.method('~');

    await assertElementReferencesText(element, r'''
/// [operator ~] and [A.operator ~]
              ^ REFERENCE
                                 ^ REFERENCE qualified
class A {
  A operator ~() => this;
}
void useOperator(A a) {
  ~a;
  ^ INVOCATION qualified
}
''');
  }

  test_searchReferences_MethodElement_operator_ofEnum_binary() async {
    var result = await resolveTestCode('''
/// [operator +] and [E.operator +]
enum E {
  v;
  int operator +(other) => 0;
}
void useOperator(E e) {
  e + 1;
  e += 2;
  ++e;
  e++;
}
''');
    var element = result.findElement.method('+');

    await assertElementReferencesText(element, r'''
/// [operator +] and [E.operator +]
              ^ REFERENCE
                                 ^ REFERENCE qualified
enum E {
  v;
  int operator +(other) => 0;
}
void useOperator(E e) {
  e + 1;
    ^ INVOCATION qualified
  e += 2;
    ^^ INVOCATION qualified
  ++e;
  ^^ INVOCATION qualified
  e++;
   ^^ INVOCATION qualified
}
''');
  }

  test_searchReferences_MethodElement_operator_ofEnum_index() async {
    var result = await resolveTestCode('''
/// [operator []] and [E.operator []]
enum E {
  v;
  int operator [](int index) => 0;
}
void useOperator(E e) {
  e[0];
}
''');
    var element = result.findElement.method('[]');

    await assertElementReferencesText(element, r'''
/// [operator []] and [E.operator []]
enum E {
  v;
  int operator [](int index) => 0;
}
void useOperator(E e) {
  e[0];
   ^ INVOCATION qualified
}
''');
  }

  test_searchReferences_MethodElement_operator_ofEnum_indexEq() async {
    var result = await resolveTestCode('''
/// [operator []=] and [E.operator []=]
enum E {
  v;
  operator []=(int index, int value) {}
}
void useOperator(E e) {
  e[1] = 42;
}
''');
    var element = result.findElement.method('[]=');

    await assertElementReferencesText(element, r'''
/// [operator []=] and [E.operator []=]
enum E {
  v;
  operator []=(int index, int value) {}
}
void useOperator(E e) {
  e[1] = 42;
   ^ INVOCATION qualified
}
''');
  }

  test_searchReferences_MethodElement_operator_ofEnum_prefix() async {
    var result = await resolveTestCode('''
/// [operator ~] and [E.operator ~]
enum E {
  e;
  int operator ~() => 0;
}
void useOperator(E e) {
  ~e;
}
''');
    var element = result.findElement.method('~');

    await assertElementReferencesText(element, r'''
/// [operator ~] and [E.operator ~]
              ^ REFERENCE
                                 ^ REFERENCE qualified
enum E {
  e;
  int operator ~() => 0;
}
void useOperator(E e) {
  ~e;
  ^ INVOCATION qualified
}
''');
  }

  test_searchReferences_MethodElement_operator_ofExtension_binary() async {
    var result = await resolveTestCode('''
/// [operator +] and [E.operator +]
extension E on int {
  int operator +(int other) => 0;
}
void useOperator(int e) {
  E(e) + 1;
}
''');
    var element = result.findElement.method('+');

    await assertElementReferencesText(element, r'''
/// [operator +] and [E.operator +]
              ^ REFERENCE
                                 ^ REFERENCE qualified
extension E on int {
  int operator +(int other) => 0;
}
void useOperator(int e) {
  E(e) + 1;
       ^ INVOCATION qualified
}
''');
  }

  test_searchReferences_MethodElement_operator_ofExtension_index() async {
    var result = await resolveTestCode('''
/// [operator []] and [E.operator []]
extension E on int {
  int operator [](int index) => 0;
}
void useOperator(int e) {
  E(e)[0];
}
''');
    var element = result.findElement.method('[]');

    await assertElementReferencesText(element, r'''
/// [operator []] and [E.operator []]
extension E on int {
  int operator [](int index) => 0;
}
void useOperator(int e) {
  E(e)[0];
      ^ INVOCATION qualified
}
''');
  }

  test_searchReferences_MethodElement_operator_ofExtension_indexEq() async {
    var result = await resolveTestCode('''
/// [operator []=] and [E.operator []=]
extension E on int {
  operator []=(int index, int value) {}
}
void useOperator(int e) {
  E(e)[1] = 42;
}
''');
    var element = result.findElement.method('[]=');

    await assertElementReferencesText(element, r'''
/// [operator []=] and [E.operator []=]
extension E on int {
  operator []=(int index, int value) {}
}
void useOperator(int e) {
  E(e)[1] = 42;
      ^ INVOCATION qualified
}
''');
  }

  test_searchReferences_MethodElement_operator_ofExtension_prefix() async {
    var result = await resolveTestCode('''
/// [operator ~] and [E.operator ~]
extension E on int {
  int operator ~() => 0;
}
void useOperator(int e) {
  ~E(e);
}
''');
    var element = result.findElement.method('~');

    await assertElementReferencesText(element, r'''
/// [operator ~] and [E.operator ~]
              ^ REFERENCE
                                 ^ REFERENCE qualified
extension E on int {
  int operator ~() => 0;
}
void useOperator(int e) {
  ~E(e);
  ^ INVOCATION qualified
}
''');
  }

  test_searchReferences_MethodElement_operator_ofExtensionType_binary() async {
    var result = await resolveTestCode('''
/// [operator +] and [A.operator +]
extension type A(int it) {
  int operator +(int other) => 0;
}
void useOperator(A a) {
  a + 1;
  a += 2;
  ++a;
  a++;
}
''');
    var element = result.findElement.method('+');

    await assertElementReferencesText(element, r'''
/// [operator +] and [A.operator +]
              ^ REFERENCE
                                 ^ REFERENCE qualified
extension type A(int it) {
  int operator +(int other) => 0;
}
void useOperator(A a) {
  a + 1;
    ^ INVOCATION qualified
  a += 2;
    ^^ INVOCATION qualified
  ++a;
  ^^ INVOCATION qualified
  a++;
   ^^ INVOCATION qualified
}
''');
  }

  test_searchReferences_MethodElement_operator_ofExtensionType_index() async {
    var result = await resolveTestCode('''
/// [operator []] and [A.operator []]
extension type A(int it) {
  int operator [](int index) => 0;
}
void useOperator(A a) {
  a[0];
}
''');
    var element = result.findElement.method('[]');

    await assertElementReferencesText(element, r'''
/// [operator []] and [A.operator []]
extension type A(int it) {
  int operator [](int index) => 0;
}
void useOperator(A a) {
  a[0];
   ^ INVOCATION qualified
}
''');
  }

  test_searchReferences_MethodElement_operator_ofExtensionType_indexEq() async {
    var result = await resolveTestCode('''
/// [operator []=] and [A.operator []=]
extension type A(int it) {
  operator []=(int index, int value) {}
}
void useOperator(A a) {
  a[1] = 42;
}
''');
    var element = result.findElement.method('[]=');

    await assertElementReferencesText(element, r'''
/// [operator []=] and [A.operator []=]
extension type A(int it) {
  operator []=(int index, int value) {}
}
void useOperator(A a) {
  a[1] = 42;
   ^ INVOCATION qualified
}
''');
  }

  test_searchReferences_MethodElement_operator_ofExtensionType_prefix() async {
    var result = await resolveTestCode('''
/// [operator ~] and [A.operator ~]
extension type A(int it) {
  int operator ~() => 0;
}
void useOperator(A a) {
  ~a;
}
''');
    var element = result.findElement.method('~');

    await assertElementReferencesText(element, r'''
/// [operator ~] and [A.operator ~]
              ^ REFERENCE
                                 ^ REFERENCE qualified
extension type A(int it) {
  int operator ~() => 0;
}
void useOperator(A a) {
  ~a;
  ^ INVOCATION qualified
}
''');
  }

  test_searchReferences_MethodElement_operator_ofMixin_binary() async {
    var result = await resolveTestCode('''
/// [operator +] and [M.operator +]
mixin M {
  int operator +(int other) => 0;
}
void useOperator(M m) {
  m + 1;
  m += 2;
  ++m;
  m++;
}
''');
    var element = result.findElement.method('+');

    await assertElementReferencesText(element, r'''
/// [operator +] and [M.operator +]
              ^ REFERENCE
                                 ^ REFERENCE qualified
mixin M {
  int operator +(int other) => 0;
}
void useOperator(M m) {
  m + 1;
    ^ INVOCATION qualified
  m += 2;
    ^^ INVOCATION qualified
  ++m;
  ^^ INVOCATION qualified
  m++;
   ^^ INVOCATION qualified
}
''');
  }

  test_searchReferences_MethodElement_operator_ofMixin_index() async {
    var result = await resolveTestCode('''
/// [operator []] and [M.operator []]
mixin M {
  int operator [](int index) => 0;
}
void useOperator(M m) {
  m[0];
}
''');
    var element = result.findElement.method('[]');

    await assertElementReferencesText(element, r'''
/// [operator []] and [M.operator []]
mixin M {
  int operator [](int index) => 0;
}
void useOperator(M m) {
  m[0];
   ^ INVOCATION qualified
}
''');
  }

  test_searchReferences_MethodElement_operator_ofMixin_indexEq() async {
    var result = await resolveTestCode('''
/// [operator []=] and [M.operator []=]
mixin M {
  operator []=(int index, int value) {}
}
void useOperator(M m) {
  m[1] = 42;
}
''');
    var element = result.findElement.method('[]=');

    await assertElementReferencesText(element, r'''
/// [operator []=] and [M.operator []=]
mixin M {
  operator []=(int index, int value) {}
}
void useOperator(M m) {
  m[1] = 42;
   ^ INVOCATION qualified
}
''');
  }

  test_searchReferences_MethodElement_operator_ofMixin_prefix() async {
    var result = await resolveTestCode('''
/// [operator ~] and [M.operator ~]
mixin M {
  int operator ~() => 0;
}
void useOperator(M m) {
  ~m;
}
''');
    var element = result.findElement.method('~');

    await assertElementReferencesText(element, r'''
/// [operator ~] and [M.operator ~]
              ^ REFERENCE
                                 ^ REFERENCE qualified
mixin M {
  int operator ~() => 0;
}
void useOperator(M m) {
  ~m;
  ^ INVOCATION qualified
}
''');
  }

  test_searchReferences_MixinElement_reference_annotation() async {
    var result = await resolveTestCode(r'''
import 'test.dart' as p;

mixin A {
  static const int myConstant = 0;
}

@A.myConstant
@p.A.myConstant
void f() {}
''');
    var element = result.findElement.mixin('A');
    await assertElementReferencesText(element, r'''
import 'test.dart' as p;

mixin A {
  static const int myConstant = 0;
}

@A.myConstant
 ^ REFERENCE
@p.A.myConstant
   ^ REFERENCE qualified
void f() {}
''');
  }

  test_searchReferences_MixinElement_reference_comment() async {
    var result = await resolveTestCode(r'''
import 'test.dart' as p;

mixin A {}

/// [A] and [p.A].
void f() {}
''');
    var element = result.findElement.mixin('A');
    await assertElementReferencesText(element, r'''
import 'test.dart' as p;

mixin A {}

/// [A] and [p.A].
     ^ REFERENCE
               ^ REFERENCE qualified
void f() {}
''');
  }

  test_searchReferences_MixinElement_reference_memberAccess() async {
    var result = await resolveTestCode(r'''
import 'test.dart' as p;

mixin A {
  static void foo() {}
}

void f() {
  A.foo();
  p.A.foo();
}
''');
    var element = result.findElement.mixin('A');
    await assertElementReferencesText(element, r'''
import 'test.dart' as p;

mixin A {
  static void foo() {}
}

void f() {
  A.foo();
  ^ REFERENCE
  p.A.foo();
    ^ REFERENCE qualified
}
''');
  }

  test_searchReferences_MixinElement_reference_namedType() async {
    var result = await resolveTestCode(r'''
import 'test.dart' as p;

mixin A {}

void f(A v1, p.A v2) {}
''');
    var element = result.findElement.mixin('A');
    await assertElementReferencesText(element, r'''
import 'test.dart' as p;

mixin A {}

void f(A v1, p.A v2) {}
       ^ REFERENCE
               ^ REFERENCE qualified
''');
  }

  test_searchReferences_ParameterElement_generic_atDeclaration() async {
    var result = await resolveTestCode('''
void f() {
  B().m(p: null); // 1
  B().m(p: null); // 2
}

class A<T> {
  void m({T? p}) {} // 3
}

class B extends A<String> {}
''');
    var element = result.findElement.parameter('p');
    await assertElementReferencesText(element, r'''
void f() {
  B().m(p: null); // 1
        ^ REFERENCE_BY_NAMED_ARGUMENT qualified
  B().m(p: null); // 2
        ^ REFERENCE_BY_NAMED_ARGUMENT qualified
}

class A<T> {
  void m({T? p}) {} // 3
}

class B extends A<String> {}
''');
  }

  @FailingTest(
    // When this test begins passing, the temporary test
    // test_searchReferences_ParameterElement_generic_atInvocation_doesNotThrow_issue60005
    // can be removed.
    issue: 'https://github.com/dart-lang/sdk/issues/60200',
  )
  test_searchReferences_ParameterElement_generic_atInvocation() async {
    var result = await resolveTestCode('''
void f() {
  B().m(p: null); // 1
  B().m(p: null); // 2
}

class A<T> {
  void m({T? p}) {} // 3
}

class B extends A<String> {}
''');
    var element = result.findNode
        .namedArgument('p: null); // 1')
        .correspondingParameter!;
    await assertElementReferencesText(element, r'''
<testLibraryFragment>::@function::f
  19 2:9 |p| REFERENCE qualified
  42 3:9 |p| REFERENCE qualified
''');
  }

  /// A temporary test to ensure the search does not throw, while
  /// [test_searchReferences_ParameterElement_generic_atInvocation] is marked as
  /// failing.
  ///
  /// This test can be removed once [test_searchReferences_ParameterElement_generic_atInvocation]
  /// is passing.
  test_searchReferences_ParameterElement_generic_atInvocation_doesNotThrow_issue60005() async {
    var result = await resolveTestCode('''
void f() {
  B().m(p: null); // 1
  B().m(p: null); // 2
}

class A<T> {
  void m({T? p}) {} // 3
}

class B extends A<String> {}
''');
    var element = result.findNode
        .namedArgument('p: null); // 1')
        .correspondingParameter!;
    expect(driver.search.references(element), completes);
  }

  test_searchReferences_PrefixElement() async {
    String partCode = r'''
part of my_lib;
ppp.Future c;
''';
    newFile('$testPackageLibPath/my_part.dart', partCode);
    var result = await resolveTestCode('''
library my_lib;
import 'dart:async' as ppp;
part 'my_part.dart';
main() {
  ppp.Future a;
  ppp.Stream b;
}
''');
    var element = result.findElement.prefix('ppp');
    await assertElementReferencesText(element, r'''
package:test/my_part.dart
-------------------------
part of my_lib;
ppp.Future c;
^^^ REFERENCE

package:test/test.dart
----------------------
library my_lib;
import 'dart:async' as ppp;
part 'my_part.dart';
main() {
  ppp.Future a;
  ^^^ REFERENCE
  ppp.Stream b;
  ^^^ REFERENCE
}
''');
  }

  test_searchReferences_PrefixElement_extensionOverride() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension E on int {
  void foo() {}
}
''');

    var result = await resolveTestCode('''
import 'a.dart' as prefix;

void f() {
  prefix.E(0).foo();
}
''');
    var element = result.findElement.prefix('prefix');
    await assertElementReferencesText(element, r'''
import 'a.dart' as prefix;

void f() {
  prefix.E(0).foo();
  ^^^^^^ REFERENCE
}
''');
  }

  test_searchReferences_PrefixElement_inPackage() async {
    var aaaPackageRootPath = '$packagesRootPath/aaa';

    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'aaa', rootFolder: getFolder(aaaPackageRootPath)),
    );

    fileForContextSelection = testFile;

    var libPath = convertPath('$aaaPackageRootPath/lib/a.dart');
    var partPath = convertPath('$aaaPackageRootPath/lib/my_part.dart');

    String partCode = r'''
part of my_lib;
ppp.Future c;
''';
    newFile(partPath, partCode);
    var result = await resolveFileCode(libPath, '''
library my_lib;
import 'dart:async' as ppp;
part 'my_part.dart';
main() {
  ppp.Future a;
  ppp.Stream b;
}
''');

    var element = result.findElement.prefix('ppp');
    await assertElementReferencesText(element, r'''
package:aaa/a.dart
------------------
library my_lib;
import 'dart:async' as ppp;
part 'my_part.dart';
main() {
  ppp.Future a;
  ^^^ REFERENCE
  ppp.Stream b;
  ^^^ REFERENCE
}

package:aaa/my_part.dart
------------------------
part of my_lib;
ppp.Future c;
^^^ REFERENCE
''');
  }

  test_searchReferences_private_declaredInDefiningUnit() async {
    String p1 = convertPath('$testPackageLibPath/part1.dart');
    String p2 = convertPath('$testPackageLibPath/part2.dart');
    String p3 = convertPath('$testPackageLibPath/part3.dart');
    String code1 = 'part of lib; _C v1;';
    String code2 = 'part of lib; _C v2;';
    newFile(p1, code1);
    newFile(p2, code2);
    newFile(p3, 'part of lib; int v3;');

    var result = await resolveTestCode('''
library lib;
part 'part1.dart';
part 'part2.dart';
part 'part3.dart';
class _C {}
_C v;
''');
    var element = result.findElement.class_('_C');
    await assertElementReferencesText(element, r'''
package:test/part1.dart
-----------------------
part of lib; _C v1;
             ^^ REFERENCE

package:test/part2.dart
-----------------------
part of lib; _C v2;
             ^^ REFERENCE

package:test/test.dart
----------------------
library lib;
part 'part1.dart';
part 'part2.dart';
part 'part3.dart';
class _C {}
_C v;
^^ REFERENCE
''');
  }

  test_searchReferences_private_declaredInPart() async {
    String p1 = convertPath('$testPackageLibPath/part1.dart');
    String p2 = convertPath('$testPackageLibPath/part2.dart');

    var code = '''
library lib;
part 'part1.dart';
part 'part2.dart';
_C v;
''';
    var code1 = '''
part of lib;
class _C {}
_C v1;
''';
    String code2 = 'part of lib; _C v2;';

    newFile(p1, code1);
    newFile(p2, code2);

    var result = await resolveTestCode(code);

    var element = result.findElement
        .partFind('package:test/part1.dart')
        .class_('_C');
    await assertElementReferencesText(element, r'''
package:test/part1.dart
-----------------------
part of lib;
class _C {}
_C v1;
^^ REFERENCE

package:test/part2.dart
-----------------------
part of lib; _C v2;
             ^^ REFERENCE

package:test/test.dart
----------------------
library lib;
part 'part1.dart';
part 'part2.dart';
_C v;
^^ REFERENCE
''');
  }

  test_searchReferences_private_inPackage() async {
    var aaaPackageRootPath = '$packagesRootPath/aaa';
    var testFile = convertPath('$aaaPackageRootPath/lib/a.dart');
    var p1 = convertPath('$aaaPackageRootPath/lib/part1.dart');
    var p2 = convertPath('$aaaPackageRootPath/lib/part2.dart');

    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'aaa', rootFolder: getFolder(aaaPackageRootPath)),
    );

    fileForContextSelection = this.testFile;

    String testCode = '''
library lib;
part 'part1.dart';
part 'part2.dart';
class _C {}
_C v;
''';
    String code1 = 'part of lib; _C v1;';
    String code2 = 'part of lib; _C v2;';

    newFile(p1, code1);
    newFile(p2, code2);

    var result = await resolveFileCode(testFile, testCode);

    var element = result.findElement.class_('_C');
    await assertElementReferencesText(element, r'''
package:aaa/a.dart
------------------
library lib;
part 'part1.dart';
part 'part2.dart';
class _C {}
_C v;
^^ REFERENCE

package:aaa/part1.dart
----------------------
part of lib; _C v1;
             ^^ REFERENCE

package:aaa/part2.dart
----------------------
part of lib; _C v2;
             ^^ REFERENCE
''');
  }

  test_searchReferences_PropertyAccessor_getter_ofExtension_instance() async {
    var result = await resolveTestCode('''
extension E on int {
  int get foo => 0;

  void bar() {
    foo;
    this.foo;
  }
}

main() {
  E(0).foo;
  0.foo;
}
''');
    var element = result.findElement.getter('foo');
    await assertElementReferencesText(element, r'''
extension E on int {
  int get foo => 0;

  void bar() {
    foo;
    ^^^ INVOCATION
    this.foo;
         ^^^ INVOCATION qualified
  }
}

main() {
  E(0).foo;
       ^^^ INVOCATION qualified
  0.foo;
    ^^^ INVOCATION qualified
}
''');
  }

  test_searchReferences_PropertyAccessor_setter_ofExtension_instance() async {
    var result = await resolveTestCode('''
extension E on int {
  set foo(int _) {}

  void bar() {
    foo = 1;
    this.foo = 2;
  }
}

main() {
  E(0).foo = 3;
  0.foo = 4;
}
''');
    var element = result.findElement.setter('foo');
    await assertElementReferencesText(element, r'''
extension E on int {
  set foo(int _) {}

  void bar() {
    foo = 1;
    ^^^ INVOCATION
    this.foo = 2;
         ^^^ INVOCATION qualified
  }
}

main() {
  E(0).foo = 3;
       ^^^ INVOCATION qualified
  0.foo = 4;
    ^^^ INVOCATION qualified
}
''');
  }

  test_searchReferences_PropertyAccessorElement_getter() async {
    var result = await resolveTestCode('''
class A {
  get ggg => null;
  main() {
    ggg;
    this.ggg;
    ggg();
    this.ggg();
  }
}
''');
    var element = result.findElement.getter('ggg');
    await assertElementReferencesText(element, r'''
class A {
  get ggg => null;
  main() {
    ggg;
    ^^^ INVOCATION
    this.ggg;
         ^^^ INVOCATION qualified
    ggg();
    ^^^ INVOCATION
    this.ggg();
         ^^^ INVOCATION qualified
  }
}
''');
  }

  test_searchReferences_PropertyAccessorElement_setter() async {
    var result = await resolveTestCode('''
class A {
  set s(x) {}
  main() {
    s = 1;
    this.s = 2;
  }
}
''');
    var element = result.findElement.setter('s');
    await assertElementReferencesText(element, r'''
class A {
  set s(x) {}
  main() {
    s = 1;
    ^ INVOCATION
    this.s = 2;
         ^ INVOCATION qualified
  }
}
''');
  }

  test_searchReferences_SetterElement_ofClass_static() async {
    var result = await resolveTestCode('''
import 'test.dart' as p;

/// [foo], [A.foo], [p.A.foo]
class A {
  static set foo(int _) {}
  static void useSetter() {
    foo = 0;
  }
}

void useSetter() {
  A.foo = 0;
  p.A.foo = 0;
}
''');
    var element = result.findElement.setter('foo');
    await assertElementReferencesText(element, r'''
import 'test.dart' as p;

/// [foo], [A.foo], [p.A.foo]
     ^^^ REFERENCE
              ^^^ REFERENCE qualified
                         ^^^ REFERENCE qualified
class A {
  static set foo(int _) {}
  static void useSetter() {
    foo = 0;
    ^^^ INVOCATION
  }
}

void useSetter() {
  A.foo = 0;
    ^^^ INVOCATION qualified
  p.A.foo = 0;
      ^^^ INVOCATION qualified
}
''');
  }

  test_searchReferences_SuperFormalParameterElement_ofConstructor_optionalNamed() async {
    var result = await resolveTestCode('''
class A {
  A({int? test});
}

class B extends A {
  /// [test]
  B({super.test}) : assert(test != null);
}

void f() {
  B(test: 0);
  B _ = .new(test: 0);
}
''');
    var element = result.findElement.unnamedConstructor('B').parameter('test');
    await assertElementReferencesText(element, r'''
class A {
  A({int? test});
}

class B extends A {
  /// [test]
       ^^^^ REFERENCE
  B({super.test}) : assert(test != null);
                           ^^^^ READ
}

void f() {
  B(test: 0);
    ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
  B _ = .new(test: 0);
             ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
}
''');
  }

  test_searchReferences_SuperFormalParameterElement_ofConstructor_optionalPositional() async {
    var result = await resolveTestCode('''
class A {
  A([int? test]);
}

class B extends A {
  /// [test]
  B([super.test]) : assert(test != null);
}

void f() {
  B(0);
  B _ = .new(0);
}
''');
    var element = result.findElement.unnamedConstructor('B').parameter('test');
    await assertElementReferencesText(element, r'''
class A {
  A([int? test]);
}

class B extends A {
  /// [test]
       ^^^^ REFERENCE
  B([super.test]) : assert(test != null);
                           ^^^^ READ
}

void f() {
  B(0);
  B _ = .new(0);
}
''');
  }

  test_searchReferences_SuperFormalParameterElement_ofConstructor_requiredNamed() async {
    var result = await resolveTestCode('''
class A {
  A({required int test});
}

class B extends A {
  /// [test]
  B({required super.test}) : assert(test != -1);
}

void f() {
  B(test: 0);
  B _ = .new(test: 0);
}
''');
    var element = result.findElement.unnamedConstructor('B').parameter('test');
    await assertElementReferencesText(element, r'''
class A {
  A({required int test});
}

class B extends A {
  /// [test]
       ^^^^ REFERENCE
  B({required super.test}) : assert(test != -1);
                                    ^^^^ READ
}

void f() {
  B(test: 0);
    ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
  B _ = .new(test: 0);
             ^^^^ REFERENCE_BY_NAMED_ARGUMENT qualified
}
''');
  }

  test_searchReferences_SuperFormalParameterElement_ofConstructor_requiredPositional() async {
    var result = await resolveTestCode('''
class A {
  A(int test);
}

class B extends A {
  /// [test]
  B(super.test) : assert(test != -1);
}

void f() {
  B(0);
  B _ = .new(0);
}
''');
    var element = result.findElement.unnamedConstructor('B').parameter('test');
    await assertElementReferencesText(element, r'''
class A {
  A(int test);
}

class B extends A {
  /// [test]
       ^^^^ REFERENCE
  B(super.test) : assert(test != -1);
                         ^^^^ READ
}

void f() {
  B(0);
  B _ = .new(0);
}
''');
  }

  test_searchReferences_TopLevelFunctionElement() async {
    var result = await resolveTestCode(r'''
import 'test.dart' as p;

void foo() {}

/// [foo] and [p.foo]
void f() {
  foo();
  p.foo();
  foo;
  p.foo;
}
''');
    var element = result.findElement.topFunction('foo');
    await assertElementReferencesText(element, r'''
import 'test.dart' as p;

void foo() {}

/// [foo] and [p.foo]
     ^^^ REFERENCE
                 ^^^ REFERENCE qualified
void f() {
  foo();
  ^^^ INVOCATION
  p.foo();
    ^^^ INVOCATION qualified
  foo;
  ^^^ REFERENCE
  p.foo;
    ^^^ REFERENCE qualified
}
''');
  }

  test_searchReferences_TopLevelFunctionElement_invalidWrite() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void foo() {}

void f() {
  foo = 0;
//^^^
// [diag.assignmentToFunction] Functions can't be assigned a value.
}
''');
    var element = result.findElement.topFunction('foo');
    await assertElementReferencesText(element, r'''
void foo() {}

void f() {
  foo = 0;
  ^^^ REFERENCE
}
''');
  }

  test_searchReferences_TopLevelFunctionElement_loadLibrary() async {
    var result = await resolveTestCode('''
import 'dart:math' deferred as math;

void f() {
  math.loadLibrary();
}
''');
    var mathLib = result.findElement.import('dart:math').importedLibrary!;
    var element = mathLib.loadLibraryFunction;
    await assertElementReferencesText(element, r'''
import 'dart:math' deferred as math;

void f() {
  math.loadLibrary();
       ^^^^^^^^^^^ INVOCATION qualified
}
''');
  }

  test_searchReferences_TopLevelFunctionElement_unqualified_ifNull() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void foo() {}

void f() {
  foo ??= () {};
//^^^
// [diag.assignmentToFunction] Functions can't be assigned a value.
//        ^^^^^
// [diag.deadCode] Dead code.
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
}
''');
    var element = result.findElement.topFunction('foo');
    await assertElementReferencesText(element, r'''
void foo() {}

void f() {
  foo ??= () {};
  ^^^ REFERENCE
}
''');
  }

  test_searchReferences_TopLevelVariableElement_getterDeclaration() async {
    var result = await resolveTestCode('''
import 'test.dart' as p;

int get foo => 0;

/// [foo] and [p.foo].
void f() {
  foo;
  p.foo;
}
''');

    var variable = result.findElement.topVar('foo');
    await assertElementsReferencesText(
      {'variable': variable, 'getter': variable.getter!},
      r'''
import 'test.dart' as p;

int get foo => 0;

/// [foo] and [p.foo].
     ^^^ variable REFERENCE
     ^^^ getter REFERENCE
                 ^^^ variable REFERENCE qualified
                 ^^^ getter REFERENCE qualified
void f() {
  foo;
  ^^^ variable READ
  ^^^ getter INVOCATION
  p.foo;
    ^^^ variable READ qualified
    ^^^ getter INVOCATION qualified
}
''',
    );
  }

  test_searchReferences_TopLevelVariableElement_getterDeclaration_invalidWrite() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int get foo => 0;

void f() {
  foo = 1;
//^^^
// [diag.assignmentToFinal] 'foo' can't be used as a setter because it's final.
}
''');

    var variable = result.findElement.topVar('foo');
    await assertElementsReferencesText(
      {'variable': variable, 'getter': variable.getter!},
      r'''
int get foo => 0;

void f() {
  foo = 1;
  ^^^ variable REFERENCE
  ^^^ getter REFERENCE
}
''',
    );
  }

  test_searchReferences_TopLevelVariableElement_getterSetterDeclarations() async {
    var result = await resolveTestCode('''
import 'test.dart' as p;

int get foo => 0;
set foo(int _) {}

/// [foo] and [p.foo].
void f() {
  foo;
  foo = 0;
  foo += 1;
  foo ??= 2;
  foo++;
  --foo;
  p.foo;
  p.foo = 0;
  p.foo += 1;
  p.foo ??= 2;
  p.foo++;
  --p.foo;
}
''');

    var variable = result.findElement.topVar('foo');
    await assertElementsReferencesText(
      {
        'variable': variable,
        'getter': variable.getter!,
        'setter': variable.setter!,
        'num.+': result.typeProvider.numElement.getMethod('+')!,
        'num.-': result.typeProvider.numElement.getMethod('-')!,
      },
      r'''
import 'test.dart' as p;

int get foo => 0;
set foo(int _) {}

/// [foo] and [p.foo].
     ^^^ variable REFERENCE
     ^^^ getter REFERENCE
                 ^^^ variable REFERENCE qualified
                 ^^^ getter REFERENCE qualified
void f() {
  foo;
  ^^^ variable READ
  ^^^ getter INVOCATION
  foo = 0;
  ^^^ variable WRITE
  ^^^ setter INVOCATION
  foo += 1;
  ^^^ variable READ_WRITE
  ^^^ getter INVOCATION
  ^^^ setter INVOCATION
      ^^ num.+ INVOCATION qualified
  foo ??= 2;
  ^^^ variable READ_WRITE
  ^^^ getter INVOCATION
  ^^^ setter INVOCATION
  foo++;
  ^^^ variable READ_WRITE
  ^^^ getter INVOCATION
  ^^^ setter INVOCATION
     ^^ num.+ INVOCATION qualified
  --foo;
  ^^ num.- INVOCATION qualified
    ^^^ variable READ_WRITE
    ^^^ getter INVOCATION
    ^^^ setter INVOCATION
  p.foo;
    ^^^ variable READ qualified
    ^^^ getter INVOCATION qualified
  p.foo = 0;
    ^^^ variable WRITE qualified
    ^^^ setter INVOCATION qualified
  p.foo += 1;
    ^^^ variable READ_WRITE qualified
    ^^^ getter INVOCATION qualified
    ^^^ setter INVOCATION qualified
        ^^ num.+ INVOCATION qualified
  p.foo ??= 2;
    ^^^ variable READ_WRITE qualified
    ^^^ getter INVOCATION qualified
    ^^^ setter INVOCATION qualified
  p.foo++;
    ^^^ variable READ_WRITE qualified
    ^^^ getter INVOCATION qualified
    ^^^ setter INVOCATION qualified
       ^^ num.+ INVOCATION qualified
  --p.foo;
  ^^ num.- INVOCATION qualified
      ^^^ variable READ_WRITE qualified
      ^^^ getter INVOCATION qualified
      ^^^ setter INVOCATION qualified
}
''',
    );
  }

  test_searchReferences_TopLevelVariableElement_getterSetterDeclarations_importCombinator_show() async {
    var result = await resolveTestCode('''
import 'test.dart' show foo;

int get foo => 0;
void set foo(_) {}
''');
    var variable = result.findElement.topVar('foo');
    await assertElementsReferencesText(
      {
        'variable': variable,
        'getter': variable.getter!,
        'setter': variable.setter!,
      },
      r'''
import 'test.dart' show foo;
                        ^^^ variable REFERENCE qualified
                        ^^^ getter REFERENCE qualified
                        ^^^ setter REFERENCE qualified

int get foo => 0;
void set foo(_) {}
''',
    );
  }

  test_searchReferences_TopLevelVariableElement_setterDeclaration() async {
    var result = await resolveTestCode('''
import 'test.dart' as p;

set foo(int _) {}

void f() {
  foo = 0;
  p.foo = 0;
}
''');

    var variable = result.findElement.topVar('foo');
    await assertElementsReferencesText(
      {'variable': variable, 'setter': variable.setter!},
      r'''
import 'test.dart' as p;

set foo(int _) {}

void f() {
  foo = 0;
  ^^^ variable WRITE
  ^^^ setter INVOCATION
  p.foo = 0;
    ^^^ variable WRITE qualified
    ^^^ setter INVOCATION qualified
}
''',
    );
  }

  test_searchReferences_TopLevelVariableElement_setterDeclaration_importCombinator_show() async {
    var result = await resolveTestCode('''
import 'test.dart' show foo;

void set foo(_) {}
''');
    var variable = result.findElement.topVar('foo');
    await assertElementsReferencesText(
      {'variable': variable, 'setter': variable.setter!},
      r'''
import 'test.dart' show foo;
                        ^^^ variable REFERENCE qualified
                        ^^^ setter REFERENCE qualified

void set foo(_) {}
''',
    );
  }

  test_searchReferences_TopLevelVariableElement_variableDeclaration() async {
    var result = await resolveTestCode('''
import 'test.dart' as p;

int foo = 0;

/// [foo] and [p.foo].
@foo
@p.foo
void f() {
  foo;
  foo = 0;
  foo += 1;
  foo ??= 2;
  foo++;
  --foo;
  p.foo;
  p.foo = 0;
  p.foo += 1;
  p.foo ??= 2;
  p.foo++;
  --p.foo;
}
''');
    var variable = result.findElement.topVar('foo');

    await assertElementsReferencesText(
      {
        'variable': variable,
        'getter': variable.getter!,
        'setter': variable.setter!,
        'num.+': result.typeProvider.numElement.getMethod('+')!,
        'num.-': result.typeProvider.numElement.getMethod('-')!,
      },
      r'''
import 'test.dart' as p;

int foo = 0;

/// [foo] and [p.foo].
     ^^^ variable REFERENCE
     ^^^ getter REFERENCE
                 ^^^ variable REFERENCE qualified
                 ^^^ getter REFERENCE qualified
@foo
 ^^^ variable READ
 ^^^ getter INVOCATION
@p.foo
   ^^^ variable READ qualified
   ^^^ getter INVOCATION qualified
void f() {
  foo;
  ^^^ variable READ
  ^^^ getter INVOCATION
  foo = 0;
  ^^^ variable WRITE
  ^^^ setter INVOCATION
  foo += 1;
  ^^^ variable READ_WRITE
  ^^^ getter INVOCATION
  ^^^ setter INVOCATION
      ^^ num.+ INVOCATION qualified
  foo ??= 2;
  ^^^ variable READ_WRITE
  ^^^ getter INVOCATION
  ^^^ setter INVOCATION
  foo++;
  ^^^ variable READ_WRITE
  ^^^ getter INVOCATION
  ^^^ setter INVOCATION
     ^^ num.+ INVOCATION qualified
  --foo;
  ^^ num.- INVOCATION qualified
    ^^^ variable READ_WRITE
    ^^^ getter INVOCATION
    ^^^ setter INVOCATION
  p.foo;
    ^^^ variable READ qualified
    ^^^ getter INVOCATION qualified
  p.foo = 0;
    ^^^ variable WRITE qualified
    ^^^ setter INVOCATION qualified
  p.foo += 1;
    ^^^ variable READ_WRITE qualified
    ^^^ getter INVOCATION qualified
    ^^^ setter INVOCATION qualified
        ^^ num.+ INVOCATION qualified
  p.foo ??= 2;
    ^^^ variable READ_WRITE qualified
    ^^^ getter INVOCATION qualified
    ^^^ setter INVOCATION qualified
  p.foo++;
    ^^^ variable READ_WRITE qualified
    ^^^ getter INVOCATION qualified
    ^^^ setter INVOCATION qualified
       ^^ num.+ INVOCATION qualified
  --p.foo;
  ^^ num.- INVOCATION qualified
      ^^^ variable READ_WRITE qualified
      ^^^ getter INVOCATION qualified
      ^^^ setter INVOCATION qualified
}
''',
    );
  }

  test_searchReferences_TopLevelVariableElement_variableDeclaration_invocation() async {
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
var V;
''');
    var result = await resolveTestCode('''
import 'lib.dart' show V;
import 'lib.dart' as pref;
main() {
  pref.V = 1;
  pref.V;
  pref.V();
  V = 1;
  V;
  V();
}
''');
    var variable = result.findElement
        .importFind('package:test/lib.dart', mustBeUnique: false)
        .topVar('V');
    await assertElementsReferencesText(
      {
        'variable': variable,
        'getter': variable.getter!,
        'setter': variable.setter!,
      },
      r'''
import 'lib.dart' show V;
                       ^ variable REFERENCE qualified
                       ^ getter REFERENCE qualified
                       ^ setter REFERENCE qualified
import 'lib.dart' as pref;
main() {
  pref.V = 1;
       ^ variable WRITE qualified
       ^ setter INVOCATION qualified
  pref.V;
       ^ variable READ qualified
       ^ getter INVOCATION qualified
  pref.V();
       ^ variable READ qualified
       ^ getter INVOCATION qualified
  V = 1;
  ^ variable WRITE
  ^ setter INVOCATION
  V;
  ^ variable READ
  ^ getter INVOCATION
  V();
  ^ variable READ
  ^ getter INVOCATION
}
''',
    );
  }

  test_searchReferences_TypeAliasElement_inConstructorName() async {
    var result = await resolveTestCode('''
class A<T> {}

typedef B = A<int>;

void f() {
  B();
}
''');

    var element = result.findElement.typeAlias('B');
    await assertElementReferencesText(element, r'''
class A<T> {}

typedef B = A<int>;

void f() {
  B();
  ^ REFERENCE
}
''');
  }

  test_searchReferences_TypeAliasElement_legacy_reference() async {
    var result = await resolveTestCode('''
typedef void A();
/// [A]
void f(A p) {}
''');
    var element = result.findElement.typeAlias('A');
    await assertElementReferencesText(element, r'''
typedef void A();
/// [A]
     ^ REFERENCE
void f(A p) {}
       ^ REFERENCE
''');
  }

  test_searchReferences_TypeAliasElement_modern_reference() async {
    var result = await resolveTestCode('''
class A<T> {
  static int field = 0;
  static void method() {}
}

typedef B = A<int>;

/// [B]
void f(B p) {
  B v;
  B();
  B.field;
  B.field = 0;
  B.method();
}
''');
    var element = result.findElement.typeAlias('B');
    await assertElementReferencesText(element, r'''
class A<T> {
  static int field = 0;
  static void method() {}
}

typedef B = A<int>;

/// [B]
     ^ REFERENCE
void f(B p) {
       ^ REFERENCE
  B v;
  ^ REFERENCE
  B();
  ^ REFERENCE
  B.field;
  ^ REFERENCE
  B.field = 0;
  ^ REFERENCE
  B.method();
  ^ REFERENCE
}
''');
  }

  test_searchReferences_TypeAliasElement_modern_reference_comment() async {
    var result = await resolveTestCode(r'''
import 'test.dart' as p;

class A<T> {}
typedef B = A<int>;

/// [B] and [p.B].
void f() {}
''');
    var element = result.findElement.typeAlias('B');
    await assertElementReferencesText(element, r'''
import 'test.dart' as p;

class A<T> {}
typedef B = A<int>;

/// [B] and [p.B].
     ^ REFERENCE
               ^ REFERENCE qualified
void f() {}
''');
  }

  test_searchReferences_TypeParameterElement_ofClass() async {
    var result = await resolveTestCode('''
class A<T> {
  foo(T a) {}
  bar(T b) {}
}
''');
    var element = result.findElement.typeParameter('T');
    await assertElementReferencesText(element, r'''
class A<T> {
  foo(T a) {}
      ^ REFERENCE
  bar(T b) {}
      ^ REFERENCE
}
''');
  }

  test_searchReferences_TypeParameterElement_ofEnum() async {
    var result = await resolveTestCode('''
enum E<T> {
  v;
  final T a;
  void foo(T b) {}
}
''');
    var element = result.findElement.typeParameter('T');
    await assertElementReferencesText(element, r'''
enum E<T> {
  v;
  final T a;
        ^ REFERENCE
  void foo(T b) {}
           ^ REFERENCE
}
''');
  }

  test_searchReferences_TypeParameterElement_ofLocalFunction() async {
    makeFilePriority(testFile);
    var result = await resolveTestCode('''
main() {
  void foo<T>(T a) {
    void bar(T b) {}
  }
}
''');
    var element = result.findElement.typeParameter('T');
    await assertElementReferencesText(element, r'''
main() {
  void foo<T>(T a) {
              ^ REFERENCE
    void bar(T b) {}
             ^ REFERENCE
  }
}
''');
  }

  test_searchReferences_TypeParameterElement_ofMethod() async {
    var result = await resolveTestCode('''
class A {
  foo<T>(T p) {}
}
''');
    var element = result.findElement.typeParameter('T');
    await assertElementReferencesText(element, r'''
class A {
  foo<T>(T p) {}
         ^ REFERENCE
}
''');
  }

  test_searchReferences_TypeParameterElement_ofTopLevelFunction() async {
    var result = await resolveTestCode('''
foo<T>(T a) {
  bar(T b) {}
}
''');
    var element = result.findElement.typeParameter('T');
    await assertElementReferencesText(element, r'''
foo<T>(T a) {
       ^ REFERENCE
  bar(T b) {}
      ^ REFERENCE
}
''');
  }

  test_searchReferences_VariablePatternElement_declaration() async {
    var result = await resolveTestCode('''
void f(x) {
  var (v) = x;
  v = 1;
  v += 2;
  v;
  v();
}
''');
    var element = result.findNode.bindPatternVariableElement('v) =');
    await assertElementReferencesText(element, r'''
void f(x) {
  var (v) = x;
  v = 1;
  ^ WRITE
  v += 2;
  ^ READ_WRITE
  v;
  ^ READ
  v();
  ^ READ
}
''');
  }

  test_searchReferences_VariablePatternElement_expressionFunctionBody() async {
    var result = await resolveTestCode('''
List<int> f(Map<int, String> map) => [
  for (var MapEntry(:key) in map.entries)
    key,
];
''');
    var element = result.findNode.bindPatternVariableElement('key)');
    await assertElementReferencesText(element, r'''
List<int> f(Map<int, String> map) => [
  for (var MapEntry(:key) in map.entries)
    key,
    ^^^ READ
];
''');
  }

  test_searchReferences_VariablePatternElement_ifCase() async {
    var result = await resolveTestCode('''
void f(Object? x) {
  if (x case int v) {
    v;
  }
}
''');
    var element = result.findNode.bindPatternVariableElement('v)');
    await assertElementReferencesText(element, r'''
void f(Object? x) {
  if (x case int v) {
    v;
    ^ READ
  }
}
''');
  }

  test_searchReferences_VariablePatternElement_ifCase_logicalOr() async {
    var result = await resolveTestCode('''
void f(Object? x) {
  if (x case int v || [int v]) {
    v;
    v = 1;
  }
}
''');
    var element = result.findNode.bindPatternVariableElement('v]');
    await assertElementReferencesText(element, r'''
void f(Object? x) {
  if (x case int v || [int v]) {
    v;
    ^ READ
    v = 1;
    ^ WRITE
  }
}
''');
  }

  test_searchReferences_VariablePatternElement_patternAssignment() async {
    makeFilePriority(testFile);
    var result = await resolveTestCode('''
void f() {
  int v;
  (v, _) = (0, 1);
  v;
}
''');
    var element = result.findElement.localVar('v');
    await assertElementReferencesText(element, r'''
void f() {
  int v;
  (v, _) = (0, 1);
   ^ WRITE
  v;
  ^ READ
}
''');
  }

  test_searchReferences_VariablePatternElement_switchExpression() async {
    var result = await resolveTestCode('''
Object f(Object? x) => switch (0) {
  int v when v > 0 => v + 1 + (v = 2),
  _ => -1,
}
''');
    var element = result.findNode.bindPatternVariableElement('int v');
    await assertElementReferencesText(element, r'''
Object f(Object? x) => switch (0) {
  int v when v > 0 => v + 1 + (v = 2),
             ^ READ
                      ^ READ
                               ^ WRITE
  _ => -1,
}
''');
  }

  test_searchReferences_VariablePatternElement_switchExpression_topLevel() async {
    var result = await resolveTestCode('''
var f = switch (0) {
  int v when v > 0 => v + 1 + (v = 2),
  _ => -1,
}
''');
    var element = result.findNode.bindPatternVariableElement('int v');
    await assertElementReferencesText(element, r'''
var f = switch (0) {
  int v when v > 0 => v + 1 + (v = 2),
             ^ READ
                      ^ READ
                               ^ WRITE
  _ => -1,
}
''');
  }

  test_searchReferences_VariablePatternElement_switchStatement_shared() async {
    var result = await resolveTestCode('''
void f(Object? x) {
  switch (0) {
    case int v when v > 0:
    case [int v] when v < 0:
      v;
      v = 1;
  }
}
''');
    var element = result.findNode.bindPatternVariableElement('int v when');
    await assertElementReferencesText(element, r'''
void f(Object? x) {
  switch (0) {
    case int v when v > 0:
                    ^ READ
    case [int v] when v < 0:
                      ^ READ
      v;
      ^ READ
      v = 1;
      ^ WRITE
  }
}
''');
  }

  test_searchReferences_VariablePatternElement_switchStatement_shared_hasLogicalOr() async {
    var result = await resolveTestCode('''
void f(Object? x) {
  switch (0) {
    case int v when v > 0:
    case [int v] || [..., int v] when v < 0:
      v;
      v = 1;
  }
}
''');
    var element = result.findNode.bindPatternVariableElement('int v when');
    await assertElementReferencesText(element, r'''
void f(Object? x) {
  switch (0) {
    case int v when v > 0:
                    ^ READ
    case [int v] || [..., int v] when v < 0:
                                      ^ READ
      v;
      ^ READ
      v = 1;
      ^ WRITE
  }
}
''');
  }

  test_searchSubtypes() async {
    var result = await resolveTestCode('''
class T {}
class A extends T {}
class B = Object with T;
class C implements T {}
''');
    var element = result.findElement.class_('T');
    await assertElementReferencesText(element, r'''
class T {}
class A extends T {}
                ^ REFERENCE
class B = Object with T;
                      ^ REFERENCE
class C implements T {}
                   ^ REFERENCE
''');
  }

  test_searchSubtypes_mixinDeclaration() async {
    var result = await resolveTestCode('''
class T {}
mixin A on T {}
mixin B implements T {}
''');
    var element = result.findElement.class_('T');
    await assertElementReferencesText(element, r'''
class T {}
mixin A on T {}
           ^ REFERENCE
mixin B implements T {}
                   ^ REFERENCE
''');
  }

  test_topLevelElements() async {
    var result = await resolveTestCode('''
class A {}
class B = Object with A;
mixin C {}
typedef D();
f() {}
var g = null;
class NoMatchABCDEF {}
''');
    var a = result.findElement.class_('A');
    var b = result.findElement.class_('B');
    var c = result.findElement.mixin('C');
    var d = result.findElement.typeAlias('D');
    var f = result.findElement.function('f');
    var g = result.findElement.topVar('g');
    RegExp regExp = RegExp(r'^[ABCDfg]$');
    expect(
      await driver.search.topLevelElements(regExp),
      unorderedEquals([a, b, c, d, f, g]),
    );
  }

  String _fileHeader(String unitPath) {
    var unitResult = driver.currentSession.getParsedUnit(unitPath);
    unitResult as ParsedUnitResult;
    var uri = unitResult.uri;
    if (uri.isScheme('package') || uri.isScheme('dart')) {
      return uri.toString();
    }
    var uriStr = uri.toString();
    if (uriStr.startsWith('file:')) {
      return uriStr.substring(uriStr.lastIndexOf('/') + 1);
    }
    return uriStr;
  }

  Future<List<Element>> _findClassMembers(String name) {
    return driver.search.classMembers(name);
  }

  String _getDeclarationsText(
    WorkspaceSymbols symbols,
    Map<File, String> inFiles,
  ) {
    var groups = symbols.declarations
        .map((declaration) {
          var file = getFile(symbols.files[declaration.fileIndex]);
          var fileStr = inFiles[file];
          return fileStr != null ? MapEntry(fileStr, declaration) : null;
        })
        .nonNulls
        .groupListsBy((entry) => entry.key);

    var buffer = StringBuffer();
    for (var group in groups.entries) {
      var fileStr = group.key;
      buffer.writeln(fileStr);
      var fileDeclarations = group.value.map((e) => e.value).toList();
      var sorted = fileDeclarations.sortedBy<num>((e) => e.offset);
      for (var declaration in sorted) {
        var name = declaration.name;
        buffer.write('  ${declaration.kind.name} ');
        buffer.writeln(name.isNotEmpty ? name : '<unnamed>');
        buffer.writeln(
          '    offset: ${declaration.offset} '
          '${declaration.line}:${declaration.column}',
        );
        buffer.writeln(
          '    codeOffset: ${declaration.codeOffset} + '
          '${declaration.codeLength}',
        );

        var className = declaration.className;
        if (className != null) {
          buffer.writeln('    className: $className');
        }

        var mixinName = declaration.mixinName;
        if (mixinName != null) {
          buffer.writeln('    mixinName: $mixinName');
        }

        var parameters = declaration.parameters;
        if (parameters != null) {
          buffer.writeln('    parameters: $parameters');
        }
      }
    }
    return buffer.toString();
  }

  String _getSearchResultsText(List<SearchResult> results) {
    return _getSearchResultsTextByLabel({'': results});
  }

  String _getSearchResultsText2(List<LibraryFragmentSearchMatch> results) {
    if (includedLibraryUris case var included?) {
      results = results.where((result) {
        var uri = result.libraryFragment.source.uri;
        return included.contains(uri);
      }).toList();
    }

    if (results.isEmpty) {
      return '';
    }

    var annotationsByPath = <String, List<_SearchAnnotation>>{};
    for (var result in results) {
      var unitPath = result.libraryFragment.source.fullName;
      (annotationsByPath[unitPath] ??= []).add(
        _SearchAnnotation(
          offset: result.range.offset,
          length: result.range.length,
          text: '',
        ),
      );
    }

    return _renderAnnotations(annotationsByPath);
  }

  String _getSearchResultsTextByLabel(
    Map<String, List<SearchResult>> resultsByLabel,
  ) {
    var annotationsByPath = <String, List<_SearchAnnotation>>{};
    var labelOrder = 0;
    for (var entry in resultsByLabel.entries) {
      var label = entry.key;
      var results = entry.value;
      if (includedLibraryUris case var included?) {
        results = results.where((result) {
          var uri = result.enclosingFragment.libraryFragment?.source.uri;
          return uri != null && included.contains(uri);
        }).toList();
      }

      for (var result in results) {
        var unitPath =
            result.enclosingFragment.libraryFragment!.source.fullName;
        var buffer = StringBuffer();
        if (label.isNotEmpty) {
          buffer.write('$label ');
        }
        buffer.write(result.kind.name);
        if (result.isQualified) {
          buffer.write(' qualified');
        }
        if (!result.isResolved) {
          buffer.write(' unresolved');
        }
        (annotationsByPath[unitPath] ??= []).add(
          _SearchAnnotation(
            offset: result.offset,
            length: result.length,
            order: labelOrder,
            text: buffer.toString(),
          ),
        );
      }
      labelOrder++;
    }

    if (annotationsByPath.isEmpty) {
      return '';
    }
    return _renderAnnotations(annotationsByPath);
  }

  /// When the file is priority, its resolved result is cached, so when
  /// [Search] uses AST to find local references, it can see the same elements
  /// for formal parameters.
  void _makeTestFilePriority() {
    makeFilePriority(testFile);
  }

  String _renderAnnotations(
    Map<String, List<_SearchAnnotation>> annotationsByPath,
  ) {
    var buffer = StringBuffer();

    if (annotationsByPath.length == 1 &&
        annotationsByPath.keys.single == testFile.path) {
      _writeAnnotatedFile(
        buffer,
        testFile.path,
        annotationsByPath.values.single,
      );
      return buffer.toString();
    }

    var sortedPaths = annotationsByPath.keys.sortedBy(
      (path) => _fileHeader(path),
    );
    for (var path in sortedPaths) {
      if (buffer.isNotEmpty) {
        buffer.writeln();
      }
      var header = _fileHeader(path);
      buffer.writeln(header);
      buffer.writeln('-' * header.length);
      _writeAnnotatedFile(buffer, path, annotationsByPath[path]!);
    }

    return buffer.toString();
  }

  void _writeAnnotatedFile(
    StringBuffer buffer,
    String unitPath,
    List<_SearchAnnotation> annotations,
  ) {
    var unitResult = driver.currentSession.getParsedUnit(unitPath);
    unitResult as ParsedUnitResult;
    var lineInfo = unitResult.lineInfo;
    var content = unitResult.content;

    annotations.sort((first, second) {
      var result = first.offset.compareTo(second.offset);
      if (result != 0) return result;
      result = first.length.compareTo(second.length);
      if (result != 0) return result;
      result = first.order.compareTo(second.order);
      if (result != 0) return result;
      return first.text.compareTo(second.text);
    });

    for (var i = 1; i < annotations.length; i++) {
      var previous = annotations[i - 1];
      var current = annotations[i];
      if (previous.offset == current.offset &&
          previous.length == current.length &&
          previous.text == current.text) {
        fail('Duplicate search result at ${current.offset}: ${current.text}');
      }
    }

    var annotationsByLine = annotations.groupListsBy((annotation) {
      return lineInfo.getLocation(annotation.offset).lineNumber;
    });

    var lines = content.split('\n');
    if (lines.isNotEmpty && lines.last.isEmpty) {
      lines.removeLast();
    }
    for (var i = 0; i < lines.length; i++) {
      buffer.writeln(lines[i]);
      for (var annotation
          in annotationsByLine[i + 1] ?? const <_SearchAnnotation>[]) {
        var location = lineInfo.getLocation(annotation.offset);
        buffer.write(' ' * (location.columnNumber - 1));
        if (annotation.length == 0) {
          buffer.write('^0');
        } else {
          buffer.write('^' * annotation.length);
        }
        if (annotation.text.isNotEmpty) {
          buffer.write(' ${annotation.text}');
        }
        buffer.writeln();
      }
    }
  }
}

class _SearchAnnotation {
  final int offset;
  final int length;
  final int order;
  final String text;

  _SearchAnnotation({
    required this.offset,
    required this.length,
    this.order = 0,
    required this.text,
  });
}
