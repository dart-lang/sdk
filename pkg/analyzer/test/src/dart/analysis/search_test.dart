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
import 'package:analyzer/utilities/package_config_file_builder.dart';
import 'package:analyzer_utilities/testing/tree_string_sink.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../util/diff.dart';
import '../../../util/element_printer.dart';
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
  Set<Uri>? includedLibraryUris;

  AnalysisDriver get driver => driverFor(testFile);

  String get testUriStr => 'package:test/test.dart';

  void assertDeclarationsText(
    WorkspaceSymbols symbols,
    Map<File, String> inFiles,
    String expected,
  ) {
    var actual = _getDeclarationsText(symbols, inFiles);
    if (actual != expected) {
      NodeTextExpectationsCollector.add(actual);
      printPrettyDiff(expected, actual);
      fail('See the difference above.');
    }
  }

  Future<void> assertElementReferencesText(
    Element element,
    String expected,
  ) async {
    var searchedFiles = SearchedFiles();
    var results = await driver.search.references(element, searchedFiles);
    var actual = _getSearchResultsText(results);
    if (actual != expected) {
      NodeTextExpectationsCollector.add(actual);
      printPrettyDiff(expected, actual);
      fail('See the difference above.');
    }
    expect(actual, expected);
  }

  Future<void> assertLibraryFragmentReferencesText(
    LibraryFragment fragment,
    String expected,
  ) async {
    var results = await driver.search.referencesLibraryFragment(fragment);
    var actual = _getSearchResultsText2(results);
    if (actual != expected) {
      print(actual);
      NodeTextExpectationsCollector.add(actual);
    }
    expect(actual, expected);
  }

  Future<void> assertLibraryImportReferencesText(
    LibraryImport import,
    String expected,
  ) async {
    var searchedFiles = SearchedFiles();
    var results = await driver.search.referencesLibraryImport(
      import,
      searchedFiles,
    );
    var actual = _getSearchResultsText2(results);
    if (actual != expected) {
      print(actual);
      NodeTextExpectationsCollector.add(actual);
    }
    expect(actual, expected);
  }

  Future<void> assertSubTypesText(
    InterfaceElement element,
    String expected,
  ) async {
    var searchedFiles = SearchedFiles();
    var results = await driver.search.subTypes(element, searchedFiles);
    var actual = _getSearchResultsText(results);
    if (actual != expected) {
      NodeTextExpectationsCollector.add(actual);
      printPrettyDiff(expected, actual);
      fail('See the difference above.');
    }
    expect(actual, expected);
  }

  Future<void> assertUnresolvedMemberReferencesText(
    String name,
    String expected,
  ) async {
    var searchedFiles = SearchedFiles();
    var results = await driver.search.unresolvedMemberReferences(
      name,
      searchedFiles,
    );
    var actual = _getSearchResultsText(results);
    if (actual != expected) {
      print(actual);
      NodeTextExpectationsCollector.add(actual);
    }
    expect(actual, expected);
  }

  test_classMembers_class() async {
    await resolveTestCode('''
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
        findElement2.method('test', of: 'A'),
        findElement2.field('test', of: 'B'),
      ]),
    );
  }

  test_classMembers_enum() async {
    await resolveTestCode('''
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
        findElement2.method('test', of: 'E1'),
        findElement2.field('test', of: 'E2'),
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
    await resolveTestCode('''
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
        findElement2.method('test', of: 'A'),
        findElement2.field('test', of: 'B'),
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

  test_declarations_discover() async {
    var aaaPackageRootPath = '$packagesRootPath/aaa';
    var bbbPackageRootPath = '$packagesRootPath/bbb';
    var cccPackageRootPath = '$packagesRootPath/ccc';
    var aaaFilePath = convertPath('$aaaPackageRootPath/lib/a.dart');
    var bbbFilePath = convertPath('$bbbPackageRootPath/lib/b.dart');
    var cccFilePath = convertPath('$cccPackageRootPath/lib/c.dart');

    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: aaaPackageRootPath)
        ..add(name: 'bbb', rootPath: bbbPackageRootPath),
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

  test_issue49951_references_dontAddToKnown_unrelated() async {
    var myRoot = newFolder('$workspaceRootPath/packages/my');

    var myFile = newFile('${myRoot.path}/lib/my.dart', r'''
class A {}
''');

    // Configure `package:my`.
    writePackageConfig(
      myRoot.path,
      PackageConfigFileBuilder()..add(name: 'my', rootPath: myRoot.path),
    );

    var myDriver = driverFor(myFile);
    var mySession = contextFor(myFile).currentSession;
    var libraryElementResult = await mySession.getLibraryByUri(
      'package:my/my.dart',
    );
    libraryElementResult as LibraryElementResult;

    var A = libraryElementResult.element.getClass('A')!;

    var searchedFiles = SearchedFiles();
    searchedFiles.ownAnalyzed(myDriver.search);

    var testDriver = driverFor(testFile);

    // No references, but this is not the most important.
    var references = await testDriver.search.references(A, searchedFiles);
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
    await resolveTestCode('''
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
    Element element = findElement2.constructor('bar');
    await assertElementReferencesText(element, '''
<testLibraryFragment> bar@48
  60 5:20 |.bar| INVOCATION qualified
''');
    element = findElement2.method('bar');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> bar@18
  30 3:5 |bar| INVOCATION
''');
  }

  test_scenario_ClassElement_hierarchy_class_extends() async {
    await resolveTestCode(r'''
import 'test.dart' as p;

class A {}

class B extends A {}
class B_q extends p.A {}
''');
    var element = findElement2.class_('A');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> B@44
  54 5:17 |A| REFERENCE
<testLibraryFragment> B_q@65
  79 6:21 |A| REFERENCE qualified
''');

    await assertSubTypesText(element, r'''
<testLibraryFragment> B@44
  54 5:17 |A| REFERENCE_IN_EXTENDS_CLAUSE
<testLibraryFragment> B_q@65
  79 6:21 |A| REFERENCE_IN_EXTENDS_CLAUSE qualified
''');
  }

  test_scenario_ClassElement_hierarchy_class_extends_implicitObject() async {
    await resolveTestCode('''
class A {}
''');
    includedLibraryUris = {Uri.parse(testUriStr)};
    var element = typeProvider.objectType.element;
    await assertElementReferencesText(element, r'''''');
    await assertSubTypesText(element, '');
  }

  test_scenario_ClassElement_hierarchy_class_implements() async {
    await resolveTestCode(r'''
import 'test.dart' as p;

class A {}

class B implements A {}
class B_q implements p.A {}
''');
    var element = findElement2.class_('A');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> B@44
  57 5:20 |A| REFERENCE
<testLibraryFragment> B_q@68
  85 6:24 |A| REFERENCE qualified
''');

    await assertSubTypesText(element, r'''
<testLibraryFragment> B@44
  57 5:20 |A| REFERENCE_IN_IMPLEMENTS_CLAUSE
<testLibraryFragment> B_q@68
  85 6:24 |A| REFERENCE_IN_IMPLEMENTS_CLAUSE qualified
''');
  }

  test_scenario_ClassElement_hierarchy_class_with() async {
    await resolveTestCode(r'''
import 'test.dart' as p;

class A {}

class D extends Object with A {}
class D_q extends Object with p.A {}
''');
    var element = findElement2.class_('A');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> D@44
  66 5:29 |A| REFERENCE
<testLibraryFragment> D_q@77
  103 6:33 |A| REFERENCE qualified
''');

    await assertSubTypesText(element, r'''
<testLibraryFragment> D@44
  66 5:29 |A| REFERENCE_IN_WITH_CLAUSE
<testLibraryFragment> D_q@77
  103 6:33 |A| REFERENCE_IN_WITH_CLAUSE qualified
''');
  }

  test_scenario_ClassElement_hierarchy_classTypeAlias_with() async {
    await resolveTestCode(r'''
import 'test.dart' as p;

class A {}

class D2 = Object with A;
class D2_q = Object with p.A;
''');
    var element = findElement2.class_('A');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> D2@44
  61 5:24 |A| REFERENCE
<testLibraryFragment> D2_q@70
  91 6:28 |A| REFERENCE qualified
''');

    await assertSubTypesText(element, r'''
<testLibraryFragment> D2@44
  61 5:24 |A| REFERENCE_IN_WITH_CLAUSE
<testLibraryFragment> D2_q@70
  91 6:28 |A| REFERENCE_IN_WITH_CLAUSE qualified
''');
  }

  test_scenario_ClassElement_hierarchy_enum_implements() async {
    await resolveTestCode(r'''
import 'test.dart' as p;

class A {}

enum E implements A { v }
enum E_q implements p.A { v }
''');
    var element = findElement2.class_('A');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> E@43
  56 5:19 |A| REFERENCE
<testLibraryFragment> E_q@69
  86 6:23 |A| REFERENCE qualified
''');

    await assertSubTypesText(element, r'''
<testLibraryFragment> E@43
  56 5:19 |A| REFERENCE_IN_IMPLEMENTS_CLAUSE
<testLibraryFragment> E_q@69
  86 6:23 |A| REFERENCE_IN_IMPLEMENTS_CLAUSE qualified
''');
  }

  test_scenario_ClassElement_hierarchy_extensionType_implements() async {
    await resolveTestCode(r'''
import 'test.dart' as p;

class A {}

extension type E(A it) implements A {}
extension type E_q(A it) implements p.A {}
''');
    var element = findElement2.class_('A');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> it@57
  55 5:18 |A| REFERENCE
<testLibraryFragment> E@53
  72 5:35 |A| REFERENCE
<testLibraryFragment> it@98
  96 6:20 |A| REFERENCE
<testLibraryFragment> E_q@92
  115 6:39 |A| REFERENCE qualified
''');

    await assertSubTypesText(element, r'''
<testLibraryFragment> E@53
  72 5:35 |A| REFERENCE_IN_IMPLEMENTS_CLAUSE
<testLibraryFragment> E_q@92
  115 6:39 |A| REFERENCE_IN_IMPLEMENTS_CLAUSE qualified
''');
  }

  test_scenario_ClassElement_hierarchy_mixin_implements() async {
    await resolveTestCode(r'''
import 'test.dart' as p;

class A {}

mixin M implements A {}
mixin M_q implements p.A {}
''');
    var element = findElement2.class_('A');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> M@44
  57 5:20 |A| REFERENCE
<testLibraryFragment> M_q@68
  85 6:24 |A| REFERENCE qualified
''');

    await assertSubTypesText(element, r'''
<testLibraryFragment> M@44
  57 5:20 |A| REFERENCE_IN_IMPLEMENTS_CLAUSE
<testLibraryFragment> M_q@68
  85 6:24 |A| REFERENCE_IN_IMPLEMENTS_CLAUSE qualified
''');
  }

  test_scenario_ClassElement_hierarchy_mixin_on() async {
    await resolveTestCode(r'''
import 'test.dart' as p;

class A {}

mixin M2 on A {}
mixin M2_q on p.A {}
''');
    var element = findElement2.class_('A');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> M2@44
  50 5:13 |A| REFERENCE
<testLibraryFragment> M2_q@61
  71 6:17 |A| REFERENCE qualified
''');

    await assertSubTypesText(element, r'''
<testLibraryFragment> M2@44
  50 5:13 |A| REFERENCE_IN_ON_CLAUSE
<testLibraryFragment> M2_q@61
  71 6:17 |A| REFERENCE_IN_ON_CLAUSE qualified
''');
  }

  test_scenario_ExtensionTypeElement_hierarchy_extensionType_implements() async {
    await resolveTestCode(r'''
import 'test.dart' as p;

extension type A(int it) {}

extension type B(int it) implements A {}
extension type B_q(int it) implements p.A {}
''');
    var element = findElement2.extensionType('A');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> B@70
  91 5:37 |A| REFERENCE
<testLibraryFragment> B_q@111
  136 6:41 |A| REFERENCE qualified
''');

    await assertSubTypesText(element, r'''
<testLibraryFragment> B@70
  91 5:37 |A| REFERENCE_IN_IMPLEMENTS_CLAUSE
<testLibraryFragment> B_q@111
  136 6:41 |A| REFERENCE_IN_IMPLEMENTS_CLAUSE qualified
''');
  }

  test_scenario_MixinElement_hierarchy_class_implements() async {
    await resolveTestCode(r'''
mixin A {}
class B implements A {}
''');
    var element = findElement2.mixin('A');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> B@17
  30 2:20 |A| REFERENCE
''');

    await assertSubTypesText(element, r'''
<testLibraryFragment> B@17
  30 2:20 |A| REFERENCE_IN_IMPLEMENTS_CLAUSE
''');
  }

  test_scenario_MixinElement_hierarchy_class_with() async {
    await resolveTestCode(r'''
mixin A {}
class B extends Object with A {}
''');
    var element = findElement2.mixin('A');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> B@17
  39 2:29 |A| REFERENCE
''');

    await assertSubTypesText(element, r'''
<testLibraryFragment> B@17
  39 2:29 |A| REFERENCE_IN_WITH_CLAUSE
''');
  }

  test_scenario_MixinElement_hierarchy_classTypeAlias_with() async {
    await resolveTestCode(r'''
mixin A {}
class B = Object with A;
''');
    var element = findElement2.mixin('A');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> B@17
  33 2:23 |A| REFERENCE
''');

    await assertSubTypesText(element, r'''
<testLibraryFragment> B@17
  33 2:23 |A| REFERENCE_IN_WITH_CLAUSE
''');
  }

  test_scenario_MixinElement_hierarchy_enum_implements() async {
    await resolveTestCode(r'''
mixin A {}
enum E implements A {
  v
}
''');
    var element = findElement2.mixin('A');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> E@16
  29 2:19 |A| REFERENCE
''');

    await assertSubTypesText(element, r'''
<testLibraryFragment> E@16
  29 2:19 |A| REFERENCE_IN_IMPLEMENTS_CLAUSE
''');
  }

  test_scenario_MixinElement_hierarchy_enum_with() async {
    await resolveTestCode(r'''
mixin A {}
enum E with A {
  v
}
''');
    var element = findElement2.mixin('A');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> E@16
  23 2:13 |A| REFERENCE
''');

    await assertSubTypesText(element, r'''
<testLibraryFragment> E@16
  23 2:13 |A| REFERENCE_IN_WITH_CLAUSE
''');
  }

  test_scenario_MixinElement_hierarchy_extensionType_implements() async {
    await resolveTestCode(r'''
mixin A {}
extension type E(A it) implements A {}
''');
    var element = findElement2.mixin('A');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> it@30
  28 2:18 |A| REFERENCE
<testLibraryFragment> E@26
  45 2:35 |A| REFERENCE
''');

    await assertSubTypesText(element, r'''
<testLibraryFragment> E@26
  45 2:35 |A| REFERENCE_IN_IMPLEMENTS_CLAUSE
''');
  }

  test_scenario_MixinElement_hierarchy_mixin_implements() async {
    await resolveTestCode(r'''
mixin A {}
mixin M implements A {}
''');
    var element = findElement2.mixin('A');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> M@17
  30 2:20 |A| REFERENCE
''');

    await assertSubTypesText(element, r'''
<testLibraryFragment> M@17
  30 2:20 |A| REFERENCE_IN_IMPLEMENTS_CLAUSE
''');
  }

  test_scenario_MixinElement_hierarchy_mixin_on() async {
    await resolveTestCode(r'''
mixin A {}
mixin M on A {}
''');
    var element = findElement2.mixin('A');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> M@17
  22 2:12 |A| REFERENCE
''');

    await assertSubTypesText(element, r'''
<testLibraryFragment> M@17
  22 2:12 |A| REFERENCE_IN_ON_CLAUSE
''');
  }

  test_scenario_TypeAliasElement_modern_hierarchy_class_extends() async {
    await resolveTestCode('''
class A<T> {}
typedef B = A<int>;
class C extends B {}
''');

    var element = findElement2.typeAlias('B');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> C@40
  50 3:17 |B| REFERENCE
''');

    var aliasedClass = findElement2.class_('A');
    // TODO(scheglov): Subtypes for the aliased class should be reported.
    await assertSubTypesText(aliasedClass, r'''
''');
  }

  test_scenario_TypeAliasElement_modern_hierarchy_class_implements() async {
    await resolveTestCode('''
class A<T> {}
typedef B = A<int>;
class C implements B {}
''');

    var element = findElement2.typeAlias('B');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> C@40
  53 3:20 |B| REFERENCE
''');

    var aliasedClass = findElement2.class_('A');
    // TODO(scheglov): Subtypes for the aliased class should be reported.
    await assertSubTypesText(aliasedClass, r'''
''');
  }

  test_scenario_TypeAliasElement_modern_hierarchy_class_with() async {
    await resolveTestCode('''
class A<T> {}
typedef B = A<int>;
class C extends Object with B {}
''');

    var element = findElement2.typeAlias('B');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> C@40
  62 3:29 |B| REFERENCE
''');

    var aliasedClass = findElement2.class_('A');
    // TODO(scheglov): Subtypes for the aliased class should be reported.
    await assertSubTypesText(aliasedClass, r'''
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
<testLibraryFragment> f@5
  16 2:5 |test| READ qualified unresolved
  26 3:5 |test| WRITE qualified unresolved
  40 4:5 |test| READ_WRITE qualified unresolved
  55 5:5 |test| INVOCATION qualified unresolved
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
<testLibraryFragment> main@12
  31 3:11 |test| READ unresolved
  42 4:5 |test| WRITE unresolved
  56 5:5 |test| READ_WRITE unresolved
  71 6:5 |test| INVOCATION unresolved
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_searchReferences_class_constructor_declaredInAugmentation() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment class A {
  A.named();
}
''');

    await resolveTestCode('''
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

    var A = findElement2.class_('A');
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
    await resolveTestCode('''
void f(Object? x) {
  if (x case A(foo: 0)) {}
  if (x case A(: var foo)) {}
}

class A {
  int get foo => 0;
}
''');
    var element = findElement2.getter('foo');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@5
  35 2:16 |foo| REFERENCE_IN_PATTERN_FIELD qualified
  62 3:16 || REFERENCE_IN_PATTERN_FIELD qualified
''');
  }

  test_searchReferences_class_method_in_objectPattern() async {
    await resolveTestCode('''
void f(Object? x) {
  if (x case A(foo: _)) {}
  if (x case A(: var foo)) {}
}

class A {
  void foo() {}
}
''');
    var element = findElement2.method('foo');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@5
  35 2:16 |foo| REFERENCE qualified
  62 3:16 || REFERENCE qualified
''');
  }

  test_searchReferences_ClassElement_enum() async {
    await resolveTestCode('''
enum MyEnum {a}

main(MyEnum p) {
  MyEnum v;
  MyEnum.a;
}
''');
    var element = findElement2.enum_('MyEnum');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> p@29
  22 3:6 |MyEnum| REFERENCE
<testLibraryFragment> main@17
  36 4:3 |MyEnum| REFERENCE
  48 5:3 |MyEnum| REFERENCE
''');
  }

  test_searchReferences_ClassElement_mixin() async {
    await resolveTestCode('''
mixin A {}
class B extends Object with A {}
''');
    var element = findElement2.mixin('A');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> B@17
  39 2:29 |A| REFERENCE
''');
  }

  test_searchReferences_ClassElement_reference_annotation() async {
    await resolveTestCode(r'''
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
    var element = findElement2.class_('A');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> new@null
  44 4:9 |A| REFERENCE
<testLibraryFragment> named@59
  57 5:9 |A| REFERENCE
<testLibraryFragment> f@177
  107 9:2 |A| REFERENCE
  114 10:4 |A| REFERENCE qualified
  119 11:2 |A| REFERENCE
  132 12:4 |A| REFERENCE qualified
  143 13:2 |A| REFERENCE
  159 14:4 |A| REFERENCE qualified
''');
  }

  test_searchReferences_ClassElement_reference_annotation_typeArgument() async {
    await resolveTestCode('''
class A<T> {
  const A();
}

class B {}

@A<B>()
void f() {}
''');

    var element = findElement2.class_('B');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@54
  44 7:4 |B| REFERENCE
''');
  }

  test_searchReferences_ClassElement_reference_classTypeAlias() async {
    await resolveTestCode(r'''
class A {}
class B = Object with A;
void f(B p) {
  B v;
}
''');
    var element = findElement2.class_('B');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> p@45
  43 3:8 |B| REFERENCE
<testLibraryFragment> f@41
  52 4:3 |B| REFERENCE
''');
  }

  test_searchReferences_ClassElement_reference_comment() async {
    await resolveTestCode(r'''
import 'test.dart' as p;

class A {}

/// [A] and [p.A].
void f() {}
''');
    var element = findElement2.class_('A');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@62
  43 5:6 |A| REFERENCE
  53 5:16 |A| REFERENCE qualified
''');
  }

  test_searchReferences_ClassElement_reference_definedInSdk() async {
    await resolveTestCode('''
import 'dart:math';
Random v1;
Random v2;
''');

    var element = findElement2.importFind('dart:math').class_('Random');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> v1@27
  20 2:1 |Random| REFERENCE
<testLibraryFragment> v2@38
  31 3:1 |Random| REFERENCE
dart:math new@null
  406 20:20 |Random| REFERENCE
''');
  }

  test_searchReferences_ClassElement_reference_definedInside() async {
    await resolveTestCode('''
class A {};
main(A p) {
  A v;
}
class B1 extends A {}
class B2 implements A {}
class B3 extends Object with A {}
List<A> v2 = null;
''');
    var element = findElement2.class_('A');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> p@19
  17 2:6 |A| REFERENCE
<testLibraryFragment> main@12
  26 3:3 |A| REFERENCE
<testLibraryFragment> B1@39
  50 5:18 |A| REFERENCE
<testLibraryFragment> B2@61
  75 6:21 |A| REFERENCE
<testLibraryFragment> B3@86
  109 7:30 |A| REFERENCE
<testLibraryFragment> v2@122
  119 8:6 |A| REFERENCE
''');
  }

  test_searchReferences_ClassElement_reference_definedOutside() async {
    newFile('$testPackageLibPath/lib.dart', r'''
class A {};
''');
    await resolveTestCode('''
import 'lib.dart';
main(A p) {
  A v;
}
''');
    var element = findNode.namedType('A p').element!;
    await assertElementReferencesText(element, r'''
<testLibraryFragment> p@26
  24 2:6 |A| REFERENCE
<testLibraryFragment> main@19
  33 3:3 |A| REFERENCE
''');
  }

  test_searchReferences_ClassElement_reference_instanceCreation() async {
    await resolveTestCode(r'''
import 'test.dart' as p;

class A {}

void f() {
  A();
  p.A();
}
''');
    var element = findElement2.class_('A');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@43
  51 6:3 |A| REFERENCE
  60 7:5 |A| REFERENCE qualified
''');
  }

  test_searchReferences_ClassElement_reference_memberAccess() async {
    await resolveTestCode(r'''
import 'test.dart' as p;

class A {
  static void foo() {}
}

void f() {
  A.foo();
  p.A.foo();
}
''');
    var element = findElement2.class_('A');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@67
  75 8:3 |A| REFERENCE
  88 9:5 |A| REFERENCE qualified
''');
  }

  test_searchReferences_ClassElement_reference_namedType() async {
    await resolveTestCode(r'''
import 'test.dart' as p;

class A {}

void f() {
  A v1;
  p.A v2;
  List<A> v3;
  List<p.A> v4;
}
''');
    var element = findElement2.class_('A');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@43
  51 6:3 |A| REFERENCE
  61 7:5 |A| REFERENCE qualified
  74 8:8 |A| REFERENCE
  90 9:10 |A| REFERENCE qualified
''');
  }

  test_searchReferences_ClassElement_reference_recordTypeAnnotation_named() async {
    await resolveTestCode('''
class A {}

void f(({int foo, A bar}) r) {}
''');
    var element = findElement2.class_('A');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> r@38
  30 3:19 |A| REFERENCE
''');
  }

  test_searchReferences_ClassElement_reference_recordTypeAnnotation_positional() async {
    await resolveTestCode('''
class A {}

void f((int, A) r) {}
''');
    var element = findElement2.class_('A');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> r@28
  25 3:14 |A| REFERENCE
''');
  }

  test_searchReferences_ClassElement_reference_typeLiteral() async {
    await resolveTestCode(r'''
import 'test.dart' as p;

class A {}

var v = A;
var v_p = p.A;
''');
    var element = findElement2.class_('A');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> v@42
  46 5:9 |A| REFERENCE
<testLibraryFragment> v_p@53
  61 6:13 |A| REFERENCE qualified
''');
  }

  test_searchReferences_ConstructorElement_class_method_sameName() async {
    await resolveTestCode('''
class A {
  A.foo() {
    foo();
  }

  A foo() => A.foo();
}
''');
    var element = findElement2.constructor('foo');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> foo@42
  52 6:15 |.foo| INVOCATION qualified
''');
  }

  test_searchReferences_ConstructorElement_class_named_newHead() async {
    await resolveTestCode('''
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
    var element = findElement2.constructor('foo');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> A@34
  10 1:11 |.foo| REFERENCE qualified
  22 1:23 |.foo| REFERENCE qualified
<testLibraryFragment> bar@59
  71 4:19 |.foo| INVOCATION qualified
<testLibraryFragment> baz@89
  98 5:20 |.foo| REFERENCE qualified
<testLibraryFragment> new@null
  142 8:17 |.foo| INVOCATION qualified
<testLibraryFragment> useConstructor@157
  179 11:4 |.foo| INVOCATION qualified
  190 12:4 |.foo| REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  205 13:10 |foo| DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
''');
  }

  test_searchReferences_ConstructorElement_class_named_primary() async {
    await resolveTestCode('''
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
    var element = findElement2.constructor('foo');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> A@34
  10 1:11 |.foo| REFERENCE qualified
  22 1:23 |.foo| REFERENCE qualified
<testLibraryFragment> bar@50
  62 3:19 |.foo| INVOCATION qualified
<testLibraryFragment> baz@80
  89 4:20 |.foo| REFERENCE qualified
<testLibraryFragment> B@103
  133 7:15 |.foo| INVOCATION qualified
<testLibraryFragment> useConstructor@148
  170 10:4 |.foo| INVOCATION qualified
  181 11:4 |.foo| REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  196 12:10 |foo| DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
''');
  }

  test_searchReferences_ConstructorElement_class_named_typeName() async {
    await resolveTestCode('''
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
    var element = findElement2.constructor('foo');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> A@34
  10 1:11 |.foo| REFERENCE qualified
  22 1:23 |.foo| REFERENCE qualified
<testLibraryFragment> bar@55
  67 4:17 |.foo| INVOCATION qualified
<testLibraryFragment> baz@87
  96 5:22 |.foo| REFERENCE qualified
<testLibraryFragment> new@null
  137 8:14 |.foo| INVOCATION qualified
<testLibraryFragment> useConstructor@152
  174 11:4 |.foo| INVOCATION qualified
  185 12:4 |.foo| REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  200 13:10 |foo| DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
''');
  }

  test_searchReferences_ConstructorElement_class_named_typeName_viaTypeAlias() async {
    await resolveTestCode('''
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

    var element = findElement2.constructor('foo');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> A@34
  10 1:11 |.foo| REFERENCE qualified
  22 1:23 |.foo| REFERENCE qualified
<testLibraryFragment> bar@58
  70 4:17 |.foo| INVOCATION qualified
<testLibraryFragment> baz@90
  99 5:22 |.foo| REFERENCE qualified
<testLibraryFragment> new@null
  160 9:14 |.foo| INVOCATION qualified
<testLibraryFragment> useConstructor@175
  197 12:4 |.foo| INVOCATION qualified
  208 13:4 |.foo| REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  223 14:10 |foo| DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
''');
  }

  test_searchReferences_ConstructorElement_class_unnamed_implicit() async {
    await resolveTestCode('''
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
    var element = findElement2.unnamedConstructor('A');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> B@30
  10 1:11 || REFERENCE qualified
  18 1:19 |.new| REFERENCE qualified
<testLibraryFragment> baz@53
  62 4:22 || REFERENCE qualified
<testLibraryFragment> new@null
  120 8:14 || INVOCATION qualified
<testLibraryFragment> useConstructor@131
  153 11:4 || INVOCATION qualified
  160 12:4 |.new| REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  175 13:10 |new| DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
''');
  }

  test_searchReferences_ConstructorElement_class_unnamed_implicitInvocation_fromNewHead() async {
    await resolveTestCode('''
class A {
  A();
}

class B extends A {
  new ();
  new bar();
  factory new.baz() = A;
}
''');
    var element = findElement2.unnamedConstructor('A');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> new@null
  42 6:3 |new| INVOCATION qualified
<testLibraryFragment> bar@56
  52 7:3 |new bar| INVOCATION qualified
<testLibraryFragment> baz@77
  86 8:24 || REFERENCE qualified
''');
  }

  test_searchReferences_ConstructorElement_class_unnamed_implicitInvocation_fromTypeName() async {
    await resolveTestCode('''
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
    var element = findElement2.unnamedConstructor('A');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> new@null
  42 6:3 |B| INVOCATION qualified
<testLibraryFragment> bar@51
  49 7:3 |B.bar| INVOCATION qualified
<testLibraryFragment> baz@70
  79 8:22 || REFERENCE qualified
<testLibraryFragment> C@90
  90 11:7 |C| INVOCATION qualified
''');
  }

  test_searchReferences_ConstructorElement_class_unnamed_newHead() async {
    await resolveTestCode('''
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
    var element = findElement2.unnamedConstructor('A');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> A@30
  10 1:11 || REFERENCE qualified
  18 1:19 |.new| REFERENCE qualified
<testLibraryFragment> bar@52
  64 4:19 || INVOCATION qualified
<testLibraryFragment> baz@78
  87 5:20 || REFERENCE qualified
<testLibraryFragment> new@null
  127 8:17 || INVOCATION qualified
<testLibraryFragment> useConstructor@138
  160 11:4 || INVOCATION qualified
  167 12:4 |.new| REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  182 13:10 |new| DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
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

    await resolveTestCode('''
class A {
  A() {}
}
''');
    var element = findElement2.unnamedConstructor('A');
    await assertElementReferencesText(element, r'''
package:test/other.dart f@26
  35 4:4 || INVOCATION qualified
''');
  }

  test_searchReferences_ConstructorElement_class_unnamed_primary() async {
    await resolveTestCode('''
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
    var element = findElement2.unnamedConstructor('A');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> A@30
  10 1:11 || REFERENCE qualified
  18 1:19 |.new| REFERENCE qualified
<testLibraryFragment> bar@42
  54 3:19 || INVOCATION qualified
<testLibraryFragment> baz@68
  77 4:20 || REFERENCE qualified
<testLibraryFragment> B@87
  117 7:15 || INVOCATION qualified
<testLibraryFragment> useConstructor@128
  150 10:4 || INVOCATION qualified
  157 11:4 |.new| REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  172 12:10 |new| DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
''');
  }

  test_searchReferences_ConstructorElement_class_unnamed_typeName() async {
    await resolveTestCode('''
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
    var element = findElement2.unnamedConstructor('A');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> A@30
  10 1:11 || REFERENCE qualified
  18 1:19 |.new| REFERENCE qualified
<testLibraryFragment> bar@47
  59 4:17 || INVOCATION qualified
<testLibraryFragment> baz@75
  84 5:22 || REFERENCE qualified
<testLibraryFragment> new@null
  121 8:14 || INVOCATION qualified
<testLibraryFragment> useConstructor@132
  154 11:4 || INVOCATION qualified
  161 12:4 |.new| REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  176 13:10 |new| DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
''');
  }

  test_searchReferences_ConstructorElement_class_unnamed_typeName_explicitNew() async {
    await resolveTestCode('''
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
    var element = findElement2.unnamedConstructor('A');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> A@30
  10 1:11 || REFERENCE qualified
  18 1:19 |.new| REFERENCE qualified
<testLibraryFragment> bar@51
  63 4:17 |.new| INVOCATION qualified
<testLibraryFragment> baz@83
  92 5:22 |.new| REFERENCE qualified
<testLibraryFragment> new@null
  133 8:14 |.new| INVOCATION qualified
<testLibraryFragment> useConstructor@148
  170 11:4 |.new| INVOCATION qualified
  181 12:4 |.new| REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  196 13:10 |new| DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
''');
  }

  test_searchReferences_ConstructorElement_classTypeAlias_cycle() async {
    await resolveTestCode('''
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
    await resolveTestCode('''
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
    var element = findElement2.constructor('named', of: 'A');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> useConstructor@92
  121 10:4 |.named| INVOCATION qualified
  141 12:4 |.named| INVOCATION qualified
''');
  }

  test_searchReferences_ConstructorElement_classTypeAlias_unnamed() async {
    await resolveTestCode('''
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
    var element = findElement2.unnamedConstructor('A');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> useConstructor@92
  114 9:4 || INVOCATION qualified
  134 11:4 || INVOCATION qualified
''');
  }

  test_searchReferences_ConstructorElement_enum_named_newHead() async {
    await resolveTestCode('''
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
    var element = findElement2.constructor('foo');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> E@33
  10 1:11 |.foo| REFERENCE qualified
  22 1:23 |.foo| REFERENCE qualified
<testLibraryFragment> v@39
  40 3:4 |.foo| INVOCATION qualified
<testLibraryFragment> bar@79
  91 5:25 |.foo| INVOCATION qualified
<testLibraryFragment> baz@115
  124 6:26 |.foo| REFERENCE qualified
<testLibraryFragment> useConstructor@137
  159 9:4 |.foo| INVOCATION qualified
  170 10:4 |.foo| REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  185 11:10 |foo| DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
''');
  }

  test_searchReferences_ConstructorElement_enum_named_primary() async {
    await resolveTestCode('''
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
    var element = findElement2.constructor('foo');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> E@33
  10 1:11 |.foo| REFERENCE qualified
  22 1:23 |.foo| REFERENCE qualified
<testLibraryFragment> v@45
  46 3:4 |.foo| INVOCATION qualified
<testLibraryFragment> bar@66
  78 4:25 |.foo| INVOCATION qualified
<testLibraryFragment> baz@102
  111 5:26 |.foo| REFERENCE qualified
<testLibraryFragment> useConstructor@124
  146 8:4 |.foo| INVOCATION qualified
  157 9:4 |.foo| REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  172 10:10 |foo| DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
''');
  }

  test_searchReferences_ConstructorElement_enum_named_typeName() async {
    await resolveTestCode('''
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
    var element = findElement2.constructor('foo');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> E@33
  10 1:11 |.foo| REFERENCE qualified
  22 1:23 |.foo| REFERENCE qualified
<testLibraryFragment> v@39
  40 3:4 |.foo| INVOCATION qualified
<testLibraryFragment> bar@75
  87 5:23 |.foo| INVOCATION qualified
<testLibraryFragment> baz@113
  122 6:28 |.foo| REFERENCE qualified
<testLibraryFragment> useConstructor@135
  157 9:4 |.foo| INVOCATION qualified
  168 10:4 |.foo| REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  183 11:10 |foo| DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
''');
  }

  test_searchReferences_ConstructorElement_enum_unnamed_implicit() async {
    await resolveTestCode('''
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
    var element = findElement2.unnamedConstructor('E');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> E@29
  10 1:11 || REFERENCE qualified
  18 1:19 |.new| REFERENCE qualified
<testLibraryFragment> v1@35
  37 3:5 || INVOCATION_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS qualified
<testLibraryFragment> v2@41
  43 4:5 || INVOCATION qualified
<testLibraryFragment> v3@49
  51 5:5 |.new| INVOCATION qualified
<testLibraryFragment> other@77
  88 6:30 || REFERENCE qualified
<testLibraryFragment> useConstructor@97
  119 9:4 || INVOCATION qualified
  126 10:4 |.new| REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  141 11:10 |new| DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
''');
  }

  test_searchReferences_ConstructorElement_enum_unnamed_newHead() async {
    await resolveTestCode('''
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
    var element = findElement2.unnamedConstructor('E');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> E@29
  10 1:11 || REFERENCE qualified
  18 1:19 |.new| REFERENCE qualified
<testLibraryFragment> v1@35
  37 3:5 || INVOCATION_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS qualified
<testLibraryFragment> v2@41
  43 4:5 || INVOCATION qualified
<testLibraryFragment> v3@49
  51 5:5 |.new| INVOCATION qualified
<testLibraryFragment> other@91
  102 7:28 |.new| REFERENCE qualified
<testLibraryFragment> useConstructor@115
  137 10:4 || INVOCATION qualified
  144 11:4 |.new| REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  159 12:10 |new| DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
''');
  }

  test_searchReferences_ConstructorElement_enum_unnamed_primary() async {
    await resolveTestCode('''
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
    var element = findElement2.unnamedConstructor('E');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> E@29
  10 1:11 || REFERENCE qualified
  18 1:19 |.new| REFERENCE qualified
<testLibraryFragment> v1@37
  39 3:5 || INVOCATION_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS qualified
<testLibraryFragment> v2@43
  45 4:5 || INVOCATION qualified
<testLibraryFragment> v3@51
  53 5:5 |.new| INVOCATION qualified
<testLibraryFragment> other@77
  88 6:28 |.new| REFERENCE qualified
<testLibraryFragment> useConstructor@101
  123 9:4 || INVOCATION qualified
  130 10:4 |.new| REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  145 11:10 |new| DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
''');
  }

  test_searchReferences_ConstructorElement_enum_unnamed_typeName() async {
    await resolveTestCode('''
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
    var element = findElement2.unnamedConstructor('E');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> E@29
  10 1:11 || REFERENCE qualified
  18 1:19 |.new| REFERENCE qualified
<testLibraryFragment> v1@35
  37 3:5 || INVOCATION_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS qualified
<testLibraryFragment> v2@41
  43 4:5 || INVOCATION qualified
<testLibraryFragment> v3@49
  51 5:5 |.new| INVOCATION qualified
<testLibraryFragment> other@90
  101 7:30 || REFERENCE qualified
<testLibraryFragment> useConstructor@110
  132 10:4 || INVOCATION qualified
  139 11:4 |.new| REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  154 12:10 |new| DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
''');
  }

  test_searchReferences_ConstructorElement_enum_unnamed_typeName_explicitNew() async {
    await resolveTestCode('''
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
    var element = findElement2.unnamedConstructor('E');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> E@29
  10 1:11 || REFERENCE qualified
  18 1:19 |.new| REFERENCE qualified
<testLibraryFragment> v1@35
  37 3:5 || INVOCATION_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS qualified
<testLibraryFragment> v2@41
  43 4:5 || INVOCATION qualified
<testLibraryFragment> v3@49
  51 5:5 |.new| INVOCATION qualified
<testLibraryFragment> other@94
  105 7:30 |.new| REFERENCE qualified
<testLibraryFragment> useConstructor@118
  140 10:4 || INVOCATION qualified
  147 11:4 |.new| REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  162 12:10 |new| DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
''');
  }

  test_searchReferences_ConstructorElement_extensionType_named_newHead() async {
    await resolveTestCode('''
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
    var element = findElement2.constructor('foo');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> A@43
  10 1:11 |.foo| REFERENCE qualified
  22 1:23 |.foo| REFERENCE qualified
<testLibraryFragment> bar@81
  93 4:19 |.foo| INVOCATION qualified
<testLibraryFragment> baz@112
  127 5:26 |.foo| REFERENCE qualified
<testLibraryFragment> useConstructor@140
  162 8:4 |.foo| INVOCATION qualified
  174 9:4 |.foo| REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  189 10:10 |foo| DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
''');
  }

  test_searchReferences_ConstructorElement_extensionType_named_primary() async {
    await resolveTestCode('''
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
    var element = findElement2.constructor('foo');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> A@43
  10 1:11 |.foo| REFERENCE qualified
  22 1:23 |.foo| REFERENCE qualified
<testLibraryFragment> bar@65
  77 3:19 |.foo| INVOCATION qualified
<testLibraryFragment> baz@96
  111 4:26 |.foo| REFERENCE qualified
<testLibraryFragment> useConstructor@124
  146 7:4 |.foo| INVOCATION qualified
  158 8:4 |.foo| REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  173 9:10 |foo| DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
''');
  }

  test_searchReferences_ConstructorElement_extensionType_named_typeName() async {
    await resolveTestCode('''
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
    var element = findElement2.constructor('foo');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> A@43
  10 1:11 |.foo| REFERENCE qualified
  22 1:23 |.foo| REFERENCE qualified
<testLibraryFragment> bar@77
  89 4:17 |.foo| INVOCATION qualified
<testLibraryFragment> baz@110
  125 5:28 |.foo| REFERENCE qualified
<testLibraryFragment> useConstructor@138
  160 8:4 |.foo| INVOCATION qualified
  172 9:4 |.foo| REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  187 10:10 |foo| DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
''');
  }

  test_searchReferences_ConstructorElement_extensionType_unnamed_newHead() async {
    await resolveTestCode('''
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
    var element = findElement2.unnamedConstructor('A');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> A@39
  10 1:11 || REFERENCE qualified
  18 1:19 |.new| REFERENCE qualified
<testLibraryFragment> bar@80
  92 4:19 || INVOCATION qualified
<testLibraryFragment> baz@107
  122 5:26 |.new| REFERENCE qualified
<testLibraryFragment> useConstructor@135
  157 8:4 || INVOCATION qualified
  165 9:4 |.new| REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  180 10:10 |new| DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
''');
  }

  test_searchReferences_ConstructorElement_extensionType_unnamed_primary() async {
    await resolveTestCode('''
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
    var element = findElement2.unnamedConstructor('A');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> A@39
  10 1:11 || REFERENCE qualified
  18 1:19 |.new| REFERENCE qualified
<testLibraryFragment> bar@57
  69 3:19 || INVOCATION qualified
<testLibraryFragment> baz@84
  99 4:26 |.new| REFERENCE qualified
<testLibraryFragment> useConstructor@112
  134 7:4 || INVOCATION qualified
  142 8:4 |.new| REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  157 9:10 |new| DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
''');
  }

  test_searchReferences_ConstructorElement_extensionType_unnamed_typeName() async {
    await resolveTestCode('''
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
    var element = findElement2.unnamedConstructor('A');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> A@39
  10 1:11 || REFERENCE qualified
  18 1:19 |.new| REFERENCE qualified
<testLibraryFragment> bar@75
  87 4:17 || INVOCATION qualified
<testLibraryFragment> baz@104
  119 5:28 |.new| REFERENCE qualified
<testLibraryFragment> useConstructor@132
  154 8:4 || INVOCATION qualified
  162 9:4 |.new| REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  177 10:10 |new| DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
''');
  }

  test_searchReferences_ConstructorElement_extensionType_unnamed_typeName_explicitNew() async {
    await resolveTestCode('''
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
    var element = findElement2.unnamedConstructor('A');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> A@39
  10 1:11 || REFERENCE qualified
  18 1:19 |.new| REFERENCE qualified
<testLibraryFragment> bar@79
  91 4:17 |.new| INVOCATION qualified
<testLibraryFragment> baz@112
  127 5:28 |.new| REFERENCE qualified
<testLibraryFragment> useConstructor@140
  162 8:4 |.new| INVOCATION qualified
  174 9:4 |.new| REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
  189 10:10 |new| DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION qualified
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
    await resolveTestCode(r'''
class A {
  int? x;
  A({this.x});
}
''');
    // Look up field 'x' and assert that its reference is correctly found.
    var field = findElement2.fieldFormalParameter('x');
    await assertElementReferencesText(field, r'''
package:test/other.dart x@52
  52 4:12 |x| REFERENCE_BY_NAMED_ARGUMENT qualified
''');
  }

  test_searchReferences_EnumElement_reference_annotation() async {
    await resolveTestCode(r'''
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
    var element = findElement2.enum_('E');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> new@null
  48 5:9 |E| REFERENCE
<testLibraryFragment> named@63
  61 6:9 |E| REFERENCE
<testLibraryFragment> f@181
  111 10:2 |E| REFERENCE
  118 11:4 |E| REFERENCE qualified
  123 12:2 |E| REFERENCE
  136 13:4 |E| REFERENCE qualified
  147 14:2 |E| REFERENCE
  163 15:4 |E| REFERENCE qualified
''');
  }

  test_searchReferences_EnumElement_reference_comment() async {
    await resolveTestCode(r'''
import 'test.dart' as p;

enum E { v }

/// [E] and [p.E].
void f() {}
''');
    var element = findElement2.enum_('E');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@64
  45 5:6 |E| REFERENCE
  55 5:16 |E| REFERENCE qualified
''');
  }

  test_searchReferences_EnumElement_reference_instanceCreation() async {
    await resolveTestCode(r'''
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
    var element = findElement2.enum_('E');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> new@null
  48 5:9 |E| REFERENCE
<testLibraryFragment> f@61
  75 9:9 |E| REFERENCE
  90 10:11 |E| REFERENCE qualified
''');
  }

  test_searchReferences_EnumElement_reference_memberAccess() async {
    await resolveTestCode(r'''
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
    var element = findElement2.enum_('E');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@71
  79 9:3 |E| REFERENCE
  92 10:5 |E| REFERENCE qualified
''');
  }

  test_searchReferences_EnumElement_reference_namedType() async {
    await resolveTestCode(r'''
import 'test.dart' as p;

enum E { v }

void f() {
  E v1;
  p.E v2;
}
''');
    var element = findElement2.enum_('E');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@45
  53 6:3 |E| REFERENCE
  63 7:5 |E| REFERENCE qualified
''');
  }

  test_searchReferences_ExtensionElement() async {
    await resolveTestCode('''
extension E on int {
  void foo() {}
  static void bar() {}
}

main() {
  E(0).foo();
  E.bar();
}
''');
    var element = findElement2.extension_('E');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> main@63
  74 7:3 |E| REFERENCE
  88 8:3 |E| REFERENCE
''');
  }

  test_searchReferences_ExtensionTypeElement_reference_annotation() async {
    await resolveTestCode(r'''
import 'test.dart' as p;

extension type const A(int it) {}

@A(0)
@p.A(0)
void f() {}
''');
    var element = findElement2.extensionType('A');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@80
  62 5:2 |A| REFERENCE
  70 6:4 |A| REFERENCE qualified
''');
  }

  test_searchReferences_ExtensionTypeElement_reference_comment() async {
    await resolveTestCode(r'''
import 'test.dart' as p;

extension type A(int it) {}

/// [A] and [p.A].
void f() {}
''');
    var element = findElement2.extensionType('A');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@79
  60 5:6 |A| REFERENCE
  70 5:16 |A| REFERENCE qualified
''');
  }

  test_searchReferences_ExtensionTypeElement_reference_instanceCreation() async {
    await resolveTestCode(r'''
import 'test.dart' as p;

extension type A(int it) {}

void f() {
  A(0);
  p.A(0);
}
''');
    var element = findElement2.extensionType('A');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@60
  68 6:3 |A| REFERENCE
  78 7:5 |A| REFERENCE qualified
''');
  }

  test_searchReferences_ExtensionTypeElement_reference_memberAccess() async {
    await resolveTestCode(r'''
import 'test.dart' as p;

extension type A(int it) {
  static void foo() {}
}

void f() {
  A.foo();
  p.A.foo();
}
''');
    var element = findElement2.extensionType('A');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@84
  92 8:3 |A| REFERENCE
  105 9:5 |A| REFERENCE qualified
''');
  }

  test_searchReferences_ExtensionTypeElement_reference_namedType() async {
    await resolveTestCode(r'''
import 'test.dart' as p;

extension type A(int it) {}

void f() {
  A v1;
  p.A v2;
}
''');
    var element = findElement2.extensionType('A');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@60
  68 6:3 |A| REFERENCE
  78 7:5 |A| REFERENCE qualified
''');
  }

  test_searchReferences_FieldElement_ofClass_instance() async {
    await resolveTestCode('''
/// [foo] and [A.foo]
class A {
  int foo;
  A({this.foo});
  A.foo() : foo = 0;

  void useField() {
    foo;
    foo = 0;
    this.foo;
    this.foo = 0;
  }
}

void useField(A a) {
  a.foo;
  a.foo = 0;
  A(foo: 0);
}
''');
    var element = findElement2.field('foo');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> A@28
  5 1:6 |foo| READ
  17 1:18 |foo| READ qualified
<testLibraryFragment> foo@53
  53 4:11 |foo| WRITE qualified
<testLibraryFragment> foo@64
  72 5:13 |foo| WRITE qualified
<testLibraryFragment> useField@89
  106 8:5 |foo| READ
  115 9:5 |foo| WRITE
  133 10:10 |foo| READ qualified
  147 11:10 |foo| WRITE qualified
<testLibraryFragment> useField@168
  188 16:5 |foo| READ qualified
  197 17:5 |foo| WRITE qualified
''');
  }

  test_searchReferences_FieldElement_ofClass_instance_synthetic_hasGetter() async {
    await resolveTestCode('''
class A {
  A() : foo = 0;
  int get foo => 0;
}
''');
    var element = findElement2.field('foo');

    await assertElementReferencesText(element, r'''
''');
  }

  test_searchReferences_FieldElement_ofClass_instance_synthetic_hasGetterSetter() async {
    await resolveTestCode('''
class A {
  A() : foo = 0;
  int get foo => 0;
  set foo(_) {}
}
''');
    var element = findElement2.field('foo');

    await assertElementReferencesText(element, r'''
''');
  }

  test_searchReferences_FieldElement_ofClass_instance_synthetic_hasSetter() async {
    await resolveTestCode('''
class A {
  A() : foo = 0;
  set foo(_) {}
}
''');
    var element = findElement2.field('foo');

    await assertElementReferencesText(element, r'''
''');
  }

  test_searchReferences_FieldElement_ofClass_static() async {
    await resolveTestCode('''
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
    var element = findElement2.field('foo');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> A@28
  5 1:6 |foo| READ
  17 1:18 |foo| READ qualified
<testLibraryFragment> useField@68
  85 5:5 |foo| READ
  94 6:5 |foo| WRITE
  109 7:7 |foo| READ qualified
  120 8:7 |foo| WRITE qualified
<testLibraryFragment> useField@141
  158 13:5 |foo| READ qualified
  167 14:5 |foo| WRITE qualified
  185 15:10 |foo| READ qualified
''');
  }

  test_searchReferences_FieldElement_ofEnum_instance() async {
    await resolveTestCode('''
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
    var element = findElement2.field('foo');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> E@27
  5 1:6 |foo| READ
  17 1:18 |foo| READ qualified
<testLibraryFragment> foo@82
  82 5:11 |foo| WRITE qualified
<testLibraryFragment> useField@96
  113 7:5 |foo| READ
  122 8:5 |foo| WRITE
<testLibraryFragment> useField@142
  162 12:5 |foo| READ qualified
  171 13:5 |foo| WRITE qualified
''');
  }

  test_searchReferences_FieldElement_ofEnum_instance_index() async {
    await resolveTestCode('''
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
    var index = typeProvider.enumElement!.getField('index')!;
    await assertElementReferencesText(index, r'''
<testLibraryFragment> main@29
  50 5:13 |index| READ qualified
''');
  }

  test_searchReferences_FieldElement_ofEnum_instance_synthetic_hasGetter() async {
    await resolveTestCode('''
enum E {
  v;
  E() : foo = 0;
  int get foo => 0;
}
''');
    var element = findElement2.field('foo');

    await assertElementReferencesText(element, r'''
''');
  }

  test_searchReferences_FieldElement_ofEnum_instance_synthetic_hasGetterSetter() async {
    await resolveTestCode('''
enum E {
  v;
  E() : foo = 0;
  int get foo => 0;
  set foo(_) {}
}
''');
    var element = findElement2.field('foo');

    await assertElementReferencesText(element, r'''
''');
  }

  test_searchReferences_FieldElement_ofEnum_instance_synthetic_hasSetter() async {
    await resolveTestCode('''
enum E {
  v;
  E() : foo = 0;
  set foo(_) {}
}
''');
    var element = findElement2.field('foo');

    await assertElementReferencesText(element, r'''
''');
  }

  test_searchReferences_FieldElement_ofEnum_static_constants() async {
    await resolveTestCode(r'''
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
    var values = findElement2.field('values');
    await assertElementReferencesText(values, r'''
<testLibraryFragment> main@96
  133 9:10 |values| READ qualified
  193 13:12 |values| READ qualified
''');

    var v1 = findElement2.field('v1');
    await assertElementReferencesText(v1, r'''
<testLibraryFragment> MyEnum@72
  31 3:6 |v1| READ
  44 3:19 |v1| READ qualified
  63 3:38 |v1| READ qualified
<testLibraryFragment> main@96
  114 8:10 |v1| READ qualified
  150 10:10 |v1| READ qualified
  178 12:12 |v1| READ qualified
''');

    var v2 = findElement2.field('v2');
    await assertElementReferencesText(v2, r'''
<testLibraryFragment> main@96
  163 11:10 |v2| READ qualified
''');
  }

  test_searchReferences_FieldElement_ofExtensionType_static() async {
    await resolveTestCode('''
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
    var element = findElement2.field('foo');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> A@37
  5 1:6 |foo| READ
  17 1:18 |foo| READ qualified
<testLibraryFragment> useField@78
  95 5:5 |foo| READ
  104 6:5 |foo| WRITE
<testLibraryFragment> useField@124
  141 10:5 |foo| READ qualified
  150 11:5 |foo| WRITE qualified
''');
  }

  test_searchReferences_FormalParameterElement_multiplyDefined_generic() async {
    newFile('$testPackageLibPath/a.dart', r'''
void foo<T>({T? test}) {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
void foo<T>({T? test}) {}
''');

    await resolveTestCode(r"""
import 'a.dart';
import 'b.dart';

void f() {
  foo(test: 0);
}
""");

    var elementA = findElement2
        .importFind('package:test/a.dart')
        .topFunction('foo')
        .parameter('test');
    await assertElementReferencesText(elementA, r'''
<testLibraryFragment> f@40
  52 5:7 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
''');

    var elementB = findElement2
        .importFind('package:test/b.dart')
        .topFunction('foo')
        .parameter('test');
    await assertElementReferencesText(elementB, r'''
''');
  }

  test_searchReferences_FormalParameterElement_ofConstructor_primary_optionalNamed() async {
    await resolveTestCode('''
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
    var element = findElement2.unnamedConstructor('A').parameter('test');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> A@6
  30 2:8 |test| REFERENCE
  52 3:17 |test| READ
  72 4:5 |test| READ
  82 5:5 |test| WRITE
  96 6:5 |test| READ_WRITE
  112 7:6 |test| WRITE
  136 8:10 |test| WRITE
<testLibraryFragment> redirect@161
  190 11:34 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
<testLibraryFragment> test@237
  237 15:12 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
<testLibraryFragment> new@null
  293 19:26 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
<testLibraryFragment> f@314
  324 23:5 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
  347 24:14 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
''');
  }

  test_searchReferences_FormalParameterElement_ofConstructor_primary_optionalNamed_genericClass() async {
    await resolveTestCode('''
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
    var element = findElement2.unnamedConstructor('A').parameter('test');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> A@6
  31 2:8 |test| REFERENCE
  53 3:17 |test| READ
  73 4:5 |test| READ
  83 5:5 |test| WRITE
  101 6:6 |test| WRITE
  128 7:10 |test| WRITE
<testLibraryFragment> redirect@156
  183 10:32 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
<testLibraryFragment> test@236
  236 14:12 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
<testLibraryFragment> new@null
  296 18:24 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
<testLibraryFragment> f@317
  327 22:5 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
  355 23:19 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
''');
  }

  test_searchReferences_FormalParameterElement_ofConstructor_primary_optionalPositional() async {
    await resolveTestCode('''
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
    var element = findElement2.unnamedConstructor('A').parameter('test');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> A@6
  30 2:8 |test| REFERENCE
  52 3:17 |test| READ
  72 4:5 |test| READ
  82 5:5 |test| WRITE
  96 6:5 |test| READ_WRITE
  112 7:6 |test| WRITE
  136 8:10 |test| WRITE
<testLibraryFragment> test@231
  231 15:12 |test| REFERENCE qualified
''');
  }

  test_searchReferences_FormalParameterElement_ofConstructor_primary_requiredNamed() async {
    await resolveTestCode('''
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
    var element = findElement2.unnamedConstructor('A').parameter('test');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> A@6
  38 2:8 |test| REFERENCE
  60 3:17 |test| READ
  78 4:5 |test| READ
  88 5:5 |test| WRITE
  102 6:5 |test| READ_WRITE
  118 7:6 |test| WRITE
  142 8:10 |test| WRITE
<testLibraryFragment> redirect@167
  204 11:42 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
<testLibraryFragment> test@260
  260 15:21 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
<testLibraryFragment> new@null
  324 19:34 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
<testLibraryFragment> f@345
  355 23:5 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
  378 24:14 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
''');
  }

  test_searchReferences_FormalParameterElement_ofConstructor_primary_requiredPositional() async {
    await resolveTestCode('''
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
    var element = findElement2.unnamedConstructor('A').parameter('test');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> A@6
  27 2:8 |test| REFERENCE
  49 3:17 |test| READ
  67 4:5 |test| READ
  77 5:5 |test| WRITE
  91 6:5 |test| READ_WRITE
  107 7:6 |test| WRITE
  131 8:10 |test| WRITE
<testLibraryFragment> test@222
  222 15:11 |test| REFERENCE qualified
''');
  }

  test_searchReferences_FormalParameterElement_ofConstructor_typeName_optionalNamed() async {
    await resolveTestCode('''
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
    var element = findElement2.unnamedConstructor('A').parameter('test');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> new@null
  17 2:8 |test| REFERENCE
  49 3:27 |test| READ
  69 4:5 |test| READ
  79 5:5 |test| WRITE
  93 6:5 |test| READ_WRITE
  109 7:6 |test| WRITE
  133 8:10 |test| WRITE
<testLibraryFragment> redirect@158
  187 11:34 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
<testLibraryFragment> test@234
  234 15:12 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
<testLibraryFragment> new@null
  290 19:26 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
<testLibraryFragment> f@311
  321 23:5 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
  344 24:14 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
''');
  }

  test_searchReferences_FormalParameterElement_ofConstructor_typeName_optionalNamed_genericClass() async {
    await resolveTestCode('''
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
    var element = findElement2.unnamedConstructor('A').parameter('test');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> new@null
  20 2:8 |test| REFERENCE
  50 3:25 |test| READ
  70 4:5 |test| READ
  80 5:5 |test| WRITE
  98 6:6 |test| WRITE
  125 7:10 |test| WRITE
<testLibraryFragment> redirect@153
  180 10:32 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
<testLibraryFragment> test@233
  233 14:12 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
<testLibraryFragment> new@null
  293 18:24 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
<testLibraryFragment> f@314
  324 22:5 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
  352 23:19 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
''');
  }

  test_searchReferences_FormalParameterElement_ofConstructor_typeName_optionalPositional() async {
    await resolveTestCode('''
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
    var element = findElement2.unnamedConstructor('A').parameter('test');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> new@null
  17 2:8 |test| REFERENCE
  49 3:27 |test| READ
  69 4:5 |test| READ
  79 5:5 |test| WRITE
  93 6:5 |test| READ_WRITE
  109 7:6 |test| WRITE
  133 8:10 |test| WRITE
<testLibraryFragment> test@228
  228 15:12 |test| REFERENCE qualified
''');
  }

  test_searchReferences_FormalParameterElement_ofConstructor_typeName_requiredNamed() async {
    await resolveTestCode('''
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
    var element = findElement2.unnamedConstructor('A').parameter('test');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> new@null
  17 2:8 |test| REFERENCE
  57 3:35 |test| READ
  75 4:5 |test| READ
  85 5:5 |test| WRITE
  99 6:5 |test| READ_WRITE
  115 7:6 |test| WRITE
  139 8:10 |test| WRITE
<testLibraryFragment> redirect@164
  201 11:42 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
<testLibraryFragment> test@257
  257 15:21 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
<testLibraryFragment> new@null
  321 19:34 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
<testLibraryFragment> f@342
  352 23:5 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
  375 24:14 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
''');
  }

  test_searchReferences_FormalParameterElement_ofConstructor_typeName_requiredPositional() async {
    await resolveTestCode('''
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
    var element = findElement2.unnamedConstructor('A').parameter('test');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> new@null
  17 2:8 |test| REFERENCE
  46 3:24 |test| READ
  64 4:5 |test| READ
  74 5:5 |test| WRITE
  88 6:5 |test| READ_WRITE
  104 7:6 |test| WRITE
  128 8:10 |test| WRITE
<testLibraryFragment> test@219
  219 15:11 |test| REFERENCE qualified
''');
  }

  test_searchReferences_FormalParameterElement_ofGenericFunctionType_optionalNamed() async {
    await resolveTestCode('''
typedef F = void Function({int? test});

void g(F f) {
  f(test: 0);
}
''');
    var element = findElement2.parameter('test');
    await assertElementReferencesText(element, r'''
''');
  }

  test_searchReferences_FormalParameterElement_ofGenericFunctionType_optionalNamed_call() async {
    await resolveTestCode('''
typedef F<T> = void Function({T? test});

void g(F<int> f) {
  f.call(test: 0);
}
''');
    var element = findElement2.parameter('test');
    await assertElementReferencesText(element, r'''
''');
  }

  test_searchReferences_FormalParameterElement_ofLocalFunction_optionalNamed() async {
    _makeTestFilePriority();
    await resolveTestCode('''
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
    var element = findElement2.parameter('test');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@5
  54 4:5 |test| READ
  64 5:5 |test| WRITE
  78 6:5 |test| READ_WRITE
  94 7:6 |test| WRITE
  118 8:10 |test| WRITE
  145 11:7 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
  166 12:12 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
  184 13:9 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
''');
  }

  test_searchReferences_FormalParameterElement_ofLocalFunction_optionalPositional() async {
    _makeTestFilePriority();
    await resolveTestCode('''
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
    var element = findElement2.parameter('test');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@5
  54 4:5 |test| READ
  64 5:5 |test| WRITE
  78 6:5 |test| READ_WRITE
  94 7:6 |test| WRITE
  118 8:10 |test| WRITE
''');
  }

  test_searchReferences_FormalParameterElement_ofLocalFunction_requiredNamed() async {
    _makeTestFilePriority();
    await resolveTestCode('''
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
    var element = findElement2.parameter('test');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@5
  62 4:5 |test| READ
  72 5:5 |test| WRITE
  86 6:5 |test| READ_WRITE
  102 7:6 |test| WRITE
  126 8:10 |test| WRITE
  153 11:7 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
  174 12:12 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
  192 13:9 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
''');
  }

  test_searchReferences_FormalParameterElement_ofLocalFunction_requiredPositional() async {
    _makeTestFilePriority();
    await resolveTestCode('''
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
    var element = findElement2.parameter('test');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@5
  51 4:5 |test| READ
  61 5:5 |test| WRITE
  75 6:5 |test| READ_WRITE
  91 7:6 |test| WRITE
  115 8:10 |test| WRITE
''');
  }

  test_searchReferences_FormalParameterElement_ofMethod_optionalNamed() async {
    await resolveTestCode('''
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
    var element = findElement2.parameter('test');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> foo@30
  17 2:8 |test| REFERENCE
  53 4:5 |test| READ
  63 5:5 |test| WRITE
  77 6:5 |test| READ_WRITE
  93 7:6 |test| WRITE
  117 8:10 |test| WRITE
<testLibraryFragment> f@145
  162 13:9 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
  185 14:14 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
  205 15:11 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
''');
  }

  test_searchReferences_FormalParameterElement_ofMethod_optionalNamed_genericClass() async {
    await resolveTestCode('''
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
    var element = findElement2.parameter('test');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> foo@33
  20 2:8 |test| REFERENCE
  54 4:5 |test| READ
  64 5:5 |test| WRITE
  81 6:5 |test| WRITE
  88 6:12 |test| READ
  99 7:6 |test| WRITE
  126 8:10 |test| WRITE
<testLibraryFragment> f@157
  179 13:9 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
''');
  }

  test_searchReferences_FormalParameterElement_ofMethod_optionalPositional() async {
    await resolveTestCode('''
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
    var element = findElement2.parameter('test');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> foo@30
  17 2:8 |test| REFERENCE
  53 4:5 |test| READ
  63 5:5 |test| WRITE
  77 6:5 |test| READ_WRITE
  93 7:6 |test| WRITE
  117 8:10 |test| WRITE
''');
  }

  test_searchReferences_FormalParameterElement_ofMethod_requiredNamed() async {
    await resolveTestCode('''
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
    var element = findElement2.parameter('test');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> foo@30
  17 2:8 |test| REFERENCE
  61 4:5 |test| READ
  71 5:5 |test| WRITE
  85 6:5 |test| READ_WRITE
  101 7:6 |test| WRITE
  125 8:10 |test| WRITE
<testLibraryFragment> f@153
  170 13:9 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
  193 14:14 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
  213 15:11 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
''');
  }

  test_searchReferences_FormalParameterElement_ofMethod_requiredPositional() async {
    await resolveTestCode('''
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
    var element = findElement2.parameter('test');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> foo@30
  17 2:8 |test| REFERENCE
  50 4:5 |test| READ
  60 5:5 |test| WRITE
  74 6:5 |test| READ_WRITE
  90 7:6 |test| WRITE
  114 8:10 |test| WRITE
''');
  }

  test_searchReferences_FormalParameterElement_ofTopLevelFunction_optionalNamed() async {
    await resolveTestCode('''
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
    var element = findElement2.parameter('test');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> foo@16
  5 1:6 |test| REFERENCE
  37 3:3 |test| READ
  45 4:3 |test| WRITE
  57 5:3 |test| READ_WRITE
  71 6:4 |test| WRITE
  93 7:8 |test| WRITE
<testLibraryFragment> f@116
  128 10:7 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
  149 11:12 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
  167 12:9 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
''');
  }

  test_searchReferences_FormalParameterElement_ofTopLevelFunction_optionalNamed_argumentAnywhere() async {
    await resolveTestCode('''
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
    var element = findElement2.parameter('test');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> foo@16
  5 1:6 |test| REFERENCE
  51 3:3 |test| READ
  59 4:3 |test| WRITE
  71 5:3 |test| READ_WRITE
  85 6:4 |test| WRITE
  107 7:8 |test| WRITE
<testLibraryFragment> f@131
  146 11:10 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
  173 12:15 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
  197 13:12 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
''');
  }

  test_searchReferences_FormalParameterElement_ofTopLevelFunction_optionalPositional() async {
    await resolveTestCode('''
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
    var element = findElement2.parameter('test');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> foo@16
  5 1:6 |test| REFERENCE
  37 3:3 |test| READ
  45 4:3 |test| WRITE
  57 5:3 |test| READ_WRITE
  71 6:4 |test| WRITE
  93 7:8 |test| WRITE
''');
  }

  test_searchReferences_FormalParameterElement_ofTopLevelFunction_requiredNamed() async {
    await resolveTestCode('''
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
    var element = findElement2.parameter('test');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> foo@16
  5 1:6 |test| REFERENCE
  45 3:3 |test| READ
  53 4:3 |test| WRITE
  65 5:3 |test| READ_WRITE
  79 6:4 |test| WRITE
  101 7:8 |test| WRITE
<testLibraryFragment> f@125
  137 11:7 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
  158 12:12 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
  176 13:9 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
''');
  }

  test_searchReferences_FormalParameterElement_ofTopLevelFunction_requiredPositional() async {
    await resolveTestCode('''
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
    var element = findElement2.parameter('test');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> foo@16
  5 1:6 |test| REFERENCE
  34 3:3 |test| READ
  42 4:3 |test| WRITE
  54 5:3 |test| READ_WRITE
  68 6:4 |test| WRITE
  90 7:8 |test| WRITE
''');
  }

  test_searchReferences_FormalParameterElement_synthetic_leastUpperBound() async {
    await resolveTestCode('''
int f1({int? test}) => 0;
int f2({int? test}) => 0;
void g(bool b) {
  var f = b ? f1 : f2;
  f(test: 0);
}''');

    var element1 = findElement2.function('f1').parameter('test');
    await assertElementReferencesText(element1, r'''
''');

    var element2 = findElement2.function('f2').parameter('test');
    await assertElementReferencesText(element2, r'''
''');
  }

  test_searchReferences_FunctionElement() async {
    await resolveTestCode('''
test() {}
main() {
  test();
  test;
}
''');
    var element = findElement2.function('test');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> main@10
  21 3:3 |test| INVOCATION
  31 4:3 |test| REFERENCE
''');
  }

  test_searchReferences_FunctionElement_local() async {
    makeFilePriority(testFile);
    await resolveTestCode('''
main() {
  test() {}
  test();
  test;
}
''');
    var element = findElement2.localFunction('test');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> main@0
  23 3:3 |test| INVOCATION
  33 4:3 |test| REFERENCE
''');
  }

  test_searchReferences_GetterElement_ofClass_instance() async {
    await resolveTestCode('''
/// [foo] and [A.foo]
class A {
  int get foo => 0;
  void useGetter() {
    foo;
    this.foo;
  }
}

void useGetter(A a) {
  a.foo;
}
''');
    var element = findElement2.getter('foo');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> A@28
  5 1:6 |foo| REFERENCE
  17 1:18 |foo| REFERENCE qualified
<testLibraryFragment> useGetter@59
  77 5:5 |foo| REFERENCE
  91 6:10 |foo| REFERENCE qualified
<testLibraryFragment> useGetter@108
  129 11:5 |foo| REFERENCE qualified
''');
  }

  test_searchReferences_GetterElement_ofClass_invocation() async {
    await resolveTestCode('''
class A {
  get foo => null;
  void useGetter() {
    this.foo();
    foo();
  }
}''');
    var element = findElement2.getter('foo');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> useGetter@36
  59 4:10 |foo| REFERENCE qualified
  70 5:5 |foo| REFERENCE
''');
  }

  test_searchReferences_GetterElement_ofClass_objectPattern() async {
    await resolveTestCode('''
class A {
  int get foo => 0;
}

void useGetter(Object? x) {
  if (x case A(foo: 0)) {}
  if (x case A(: var foo)) {}
}
''');
    var element = findElement2.getter('foo');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> useGetter@38
  76 6:16 |foo| REFERENCE_IN_PATTERN_FIELD qualified
  103 7:16 || REFERENCE_IN_PATTERN_FIELD qualified
''');
  }

  test_searchReferences_GetterElement_ofClass_static() async {
    await resolveTestCode('''
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
    var element = findElement2.getter('foo');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> A@62
  31 3:6 |foo| REFERENCE
  40 3:15 |foo| REFERENCE qualified
  51 3:26 |foo| REFERENCE qualified
<testLibraryFragment> useGetter@107
  125 7:5 |foo| REFERENCE
<testLibraryFragment> useGetter@142
  160 12:5 |foo| REFERENCE qualified
  171 13:7 |foo| REFERENCE qualified
''');
  }

  test_searchReferences_ImportElement_noPrefix() async {
    await resolveTestCode('''
import 'dart:math' show max, pi, Random hide min;
export 'dart:math' show max, pi, Random hide min;
main() {
  pi;
  new Random();
  max(1, 2);
}
Random bar() => null;
''');
    var element = findElement2.import('dart:math', mustBeUnique: false);
    await assertLibraryImportReferencesText(element, r'''
#F0
  111 4:3 ||
  121 5:7 ||
  133 6:3 ||
  146 8:1 ||
''');
  }

  test_searchReferences_ImportElement_noPrefix_inPackage() async {
    var aaaPackageRootPath = '$packagesRootPath/aaa';
    var aaaFilePath = convertPath('$aaaPackageRootPath/lib/a.dart');

    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: aaaPackageRootPath),
    );

    fileForContextSelection = testFile;

    await resolveFileCode(aaaFilePath, '''
import 'dart:math' show max, pi, Random hide min;
export 'dart:math' show max, pi, Random hide min;
main() {
  pi;
  new Random();
  max(1, 2);
}
Random bar() => null;
''');

    var element = findElement2.import('dart:math');
    await assertLibraryImportReferencesText(element, r'''
#F0
  111 4:3 ||
  121 5:7 ||
  133 6:3 ||
  146 8:1 ||
''');
  }

  test_searchReferences_ImportElement_withPrefix() async {
    await resolveTestCode('''
import 'dart:math' as math show max, pi, Random hide min;
export 'dart:math' show max, pi, Random hide min;
main() {
  math.pi;
  new math.Random();
  math.max(1, 2);
}
math.Random bar() => null;
''');
    var element = findElement2.import('dart:math', mustBeUnique: false);
    await assertLibraryImportReferencesText(element, r'''
#F0
  119 4:3 |math.|
  134 5:7 |math.|
  151 6:3 |math.|
  169 8:1 |math.|
''');
  }

  test_searchReferences_ImportElement_withPrefix_forMultipleImports() async {
    await resolveTestCode('''
import 'dart:async' as p;
import 'dart:math' as p;
main() {
  p.Random r;
  p.Future f;
}
''');
    {
      var element = findElement2.import('dart:async');
      await assertLibraryImportReferencesText(element, r'''
#F0
  76 5:3 |p.|
''');
    }
    {
      var element = findElement2.import('dart:math');
      await assertLibraryImportReferencesText(element, r'''
#F0
  62 4:3 |p.|
''');
    }
  }

  test_searchReferences_LabelElement() async {
    makeFilePriority(testFile);
    await resolveTestCode('''
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
    var element = findElement2.label('label');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> main@0
  61 5:13 |label| REFERENCE
  84 7:11 |label| REFERENCE
''');
  }

  test_searchReferences_LibraryElement_inPackage() async {
    var aaaPackageRootPath = '$packagesRootPath/aaa';

    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: aaaPackageRootPath),
    );

    var libPath = convertPath('$aaaPackageRootPath/lib/a.dart');
    var partPathA = convertPath('$aaaPackageRootPath/lib/unitA.dart');
    var partPathB = convertPath('$aaaPackageRootPath/lib/unitB.dart');

    newFile(partPathA, 'part of lib;');
    newFile(partPathB, 'part of lib;');

    fileForContextSelection = testFile;

    await resolveFileCode(libPath, '''
library lib;
part 'unitA.dart';
part 'unitB.dart';
''');
    var element = result.libraryElement;
    await assertElementReferencesText(element, r'''
#F0
  8 1:9 |lib| REFERENCE
#F1
  8 1:9 |lib| REFERENCE
''');
  }

  test_searchReferences_LibraryElement_partOfName() async {
    newFile('$testPackageLibPath/unitA.dart', 'part of lib;');
    newFile('$testPackageLibPath/unitB.dart', 'part of lib;');
    await resolveTestCode('''
library lib;
part 'unitA.dart';
part 'unitB.dart';
''');
    var element = result.libraryElement;
    await assertElementReferencesText(element, r'''
#F0
  8 1:9 |lib| REFERENCE
#F1
  8 1:9 |lib| REFERENCE
''');
  }

  test_searchReferences_LibraryElement_partOfUri() async {
    newFile('$testPackageLibPath/unitA.dart', r'''
part of 'test.dart';
''');

    newFile('$testPackageLibPath/unitB.dart', r'''
part of 'test.dart';
''');

    await resolveTestCode('''
part 'unitA.dart';
part 'unitB.dart';
''');

    var element = result.libraryElement;
    await assertElementReferencesText(element, r'''
#F0
  8 1:9 |'test.dart'| REFERENCE
#F1
  8 1:9 |'test.dart'| REFERENCE
''');
  }

  test_searchReferences_LibraryFragment_reference_export() async {
    newFile('$testPackageLibPath/foo.dart', '');
    await resolveTestCode('''
export 'foo.dart';
''');
    var element = findElement2
        .export('package:test/foo.dart')
        .exportedLibrary!
        .firstFragment;
    await assertLibraryFragmentReferencesText(element, r'''
#F0
  7 1:8 |'foo.dart'|
''');
  }

  test_searchReferences_LibraryFragment_reference_import() async {
    newFile('$testPackageLibPath/foo.dart', '');
    await resolveTestCode('''
import 'foo.dart';
''');
    var element = findElement2
        .importFind('package:test/foo.dart')
        .libraryFragment;
    await assertLibraryFragmentReferencesText(element, r'''
#F0
  7 1:8 |'foo.dart'|
''');
  }

  test_searchReferences_LibraryFragment_reference_part() async {
    newFile('$testPackageLibPath/foo.dart', r'''
part of 'test.dart';
''');

    await resolveTestCode('''
part 'foo.dart';
''');

    var element = findElement2.part('package:test/foo.dart');
    await assertLibraryFragmentReferencesText(element, r'''
#F0
  5 1:6 |'foo.dart'|
''');
  }

  test_searchReferences_LocalVariableElement() async {
    makeFilePriority(testFile);
    await resolveTestCode(r'''
main() {
  var v;
  v = 1;
  v += 2;
  v;
  v();
}
''');
    var element = findElement2.localVar('v');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> main@0
  20 3:3 |v| WRITE
  29 4:3 |v| READ_WRITE
  39 5:3 |v| READ
  44 6:3 |v| READ
''');
  }

  test_searchReferences_LocalVariableElement_inForEachElement_expressionBody() async {
    makeFilePriority(testFile);
    await resolveTestCode('''
Object f() => [
  for (var v in []) v,
];
''');
    var element = findElement2.localVar('v');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@7
  36 2:21 |v| READ
''');
  }

  test_searchReferences_LocalVariableElement_inForEachElement_inBlock() async {
    makeFilePriority(testFile);
    await resolveTestCode('''
Object f() {
  {
    return [
      for (var v in []) v,
    ];
  }
}
''');
    var element = findElement2.localVar('v');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@7
  54 4:25 |v| READ
''');
  }

  test_searchReferences_LocalVariableElement_inForEachElement_inFunctionBody() async {
    makeFilePriority(testFile);
    await resolveTestCode('''
Object f() {
  return [
    for (var v in []) v,
  ];
}
''');
    var element = findElement2.localVar('v');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@7
  46 3:23 |v| READ
''');
  }

  test_searchReferences_LocalVariableElement_inForEachElement_topLevel() async {
    makeFilePriority(testFile);
    await resolveTestCode('''
var x = [
  for (var v in []) v,
];
''');
    var element = findElement2.localVar('v');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> x@4
  30 2:21 |v| READ
''');
  }

  test_searchReferences_LocalVariableElement_inForEachLoop() async {
    makeFilePriority(testFile);
    await resolveTestCode('''
main() {
  for (var v in []) {
    v = 1;
    v += 2;
    v;
    v();
  }
}
''');
    var element = findElement2.localVar('v');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> main@0
  35 3:5 |v| WRITE
  46 4:5 |v| READ_WRITE
  58 5:5 |v| READ
  65 6:5 |v| READ
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
        ..add(name: 'aaa', rootPath: aaaPackageRootPath),
    );

    fileForContextSelection = testFile;

    driverFor(testFile).priorityFiles2 = [a_file];
    await resolveFile2(a_file);

    var element = findElement2.localVar('v');
    await assertElementReferencesText(element, r'''
package:aaa/a.dart main@0
  20 3:3 |v| WRITE
  29 4:3 |v| READ_WRITE
  39 5:3 |v| READ
  44 6:3 |v| READ
''');
  }

  test_searchReferences_MethodElement_normal_ofClass_instance() async {
    await resolveTestCode('''
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
    var element = findElement2.method('foo');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> A@28
  5 1:6 |foo| REFERENCE
  17 1:18 |foo| REFERENCE qualified
<testLibraryFragment> useFoo@55
  84 5:10 |foo| INVOCATION qualified
  95 6:5 |foo| INVOCATION
  111 7:10 |foo| REFERENCE qualified
  120 8:5 |foo| REFERENCE
  142 9:18 |foo| REFERENCE qualified
  171 10:18 || REFERENCE qualified
<testLibraryFragment> useFoo@197
  215 14:5 |foo| INVOCATION qualified
  226 15:5 |foo| REFERENCE qualified
''');
  }

  test_searchReferences_MethodElement_normal_ofClass_instance_generic() async {
    await resolveTestCode('''
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
    var element = findElement2.method('foo');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> A@28
  5 1:6 |foo| REFERENCE
  17 1:18 |foo| REFERENCE qualified
<testLibraryFragment> useFoo@58
  87 5:10 |foo| INVOCATION qualified
  98 6:5 |foo| INVOCATION
  114 7:10 |foo| REFERENCE qualified
  123 8:5 |foo| REFERENCE
  150 9:23 |foo| REFERENCE qualified
  184 10:23 || REFERENCE qualified
<testLibraryFragment> useFoo@210
  233 14:5 |foo| INVOCATION qualified
  244 15:5 |foo| REFERENCE qualified
''');
  }

  test_searchReferences_MethodElement_normal_ofClass_static() async {
    await resolveTestCode('''
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
    var element = findElement2.method('foo');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> A@62
  31 3:6 |foo| REFERENCE
  40 3:15 |foo| REFERENCE qualified
  51 3:26 |foo| REFERENCE qualified
<testLibraryFragment> useFoo@105
  120 7:5 |foo| INVOCATION
  131 8:5 |foo| REFERENCE
<testLibraryFragment> useFoo@148
  163 13:5 |foo| INVOCATION qualified
  174 14:5 |foo| REFERENCE qualified
  188 15:10 |foo| INVOCATION qualified
  205 16:11 |foo| REFERENCE qualified
  216 17:7 |foo| INVOCATION qualified
  229 18:7 |foo| REFERENCE qualified
''');
  }

  test_searchReferences_MethodElement_normal_ofEnum_instance() async {
    await resolveTestCode('''
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
    var element = findElement2.method('foo');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> E@27
  5 1:6 |foo| REFERENCE
  17 1:18 |foo| REFERENCE qualified
<testLibraryFragment> useFoo@59
  79 6:10 |foo| INVOCATION qualified
  90 7:5 |foo| INVOCATION
  106 8:10 |foo| REFERENCE qualified
  115 9:5 |foo| REFERENCE
<testLibraryFragment> useFoo@131
  149 13:5 |foo| INVOCATION qualified
  160 14:5 |foo| REFERENCE qualified
''');
  }

  test_searchReferences_MethodElement_normal_ofEnum_static() async {
    await resolveTestCode('''
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
    var element = findElement2.method('foo');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> E@27
  5 1:6 |foo| REFERENCE
  17 1:18 |foo| REFERENCE qualified
<testLibraryFragment> useFoo@73
  88 6:5 |foo| INVOCATION
  99 7:5 |foo| REFERENCE
<testLibraryFragment> useFoo@115
  130 11:5 |foo| INVOCATION qualified
  141 12:5 |foo| REFERENCE qualified
''');
  }

  test_searchReferences_MethodElement_normal_ofExtension_named_instance() async {
    await resolveTestCode('''
/// [foo] and [E.foo]
extension E on int {
  void foo() {}
}

void useFoo() {
  0.foo();
  0.foo;
}
''');
    var element = findElement2.method('foo');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> E@32
  5 1:6 |foo| REFERENCE
  17 1:18 |foo| REFERENCE qualified
<testLibraryFragment> useFoo@67
  82 7:5 |foo| INVOCATION qualified
  93 8:5 |foo| REFERENCE qualified
''');
  }

  test_searchReferences_MethodElement_normal_ofExtension_named_static() async {
    await resolveTestCode('''
/// [foo] and [E.foo]
extension E on int {
  static void foo() {}
}

void useFoo() {
  E.foo();
  E.foo;
}
''');
    var element = findElement2.method('foo');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> E@32
  5 1:6 |foo| REFERENCE
  17 1:18 |foo| REFERENCE qualified
<testLibraryFragment> useFoo@74
  89 7:5 |foo| INVOCATION qualified
  100 8:5 |foo| REFERENCE qualified
''');
  }

  test_searchReferences_MethodElement_normal_ofExtension_unnamed_instance() async {
    await resolveTestCode('''
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

    var intMethod = findNode.methodDeclaration('foo() {} // int');
    var intMethodElement = intMethod.declaredFragment!.element;
    await assertElementReferencesText(intMethodElement, r'''
<testLibraryFragment> null@null
  5 1:6 |foo| REFERENCE
<testLibraryFragment> useFoo@152
  167 12:5 |foo| INVOCATION qualified
  178 13:5 |foo| REFERENCE qualified
''');

    var doubleMethod = findNode.methodDeclaration('foo() {} // double');
    var doubleMethodElement = doubleMethod.declaredFragment!.element;
    await assertElementReferencesText(doubleMethodElement, r'''
<testLibraryFragment> null@null
  74 6:6 |foo| REFERENCE
<testLibraryFragment> useFoo@152
  191 14:9 |foo| INVOCATION qualified
  206 15:9 |foo| REFERENCE qualified
''');
  }

  test_searchReferences_MethodElement_normal_ofExtensionType_instance() async {
    await resolveTestCode('''
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
    var element = findElement2.method('foo');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> A@37
  5 1:6 |foo| REFERENCE
  17 1:18 |foo| REFERENCE qualified
<testLibraryFragment> useFoo@72
  92 5:10 |foo| INVOCATION qualified
  103 6:5 |foo| INVOCATION
  119 7:10 |foo| REFERENCE qualified
  128 8:5 |foo| REFERENCE
<testLibraryFragment> useFoo@144
  175 13:5 |foo| INVOCATION qualified
  186 14:5 |foo| REFERENCE qualified
''');
  }

  test_searchReferences_MethodElement_normal_ofExtensionType_static() async {
    await resolveTestCode('''
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
    var element = findElement2.method('foo');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> A@37
  5 1:6 |foo| REFERENCE
  17 1:18 |foo| REFERENCE qualified
<testLibraryFragment> useFoo@86
  101 5:5 |foo| INVOCATION
  112 6:5 |foo| REFERENCE
<testLibraryFragment> useFoo@128
  143 10:5 |foo| INVOCATION qualified
  154 11:5 |foo| REFERENCE qualified
''');
  }

  test_searchReferences_MethodElement_normal_ofMixin_instance() async {
    await resolveTestCode('''
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
    var element = findElement2.method('foo');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> M@28
  5 1:6 |foo| REFERENCE
  17 1:18 |foo| REFERENCE qualified
<testLibraryFragment> useFoo@55
  75 5:10 |foo| INVOCATION qualified
  86 6:5 |foo| INVOCATION
  102 7:10 |foo| REFERENCE qualified
  111 8:5 |foo| REFERENCE
<testLibraryFragment> useFoo@127
  145 12:5 |foo| INVOCATION qualified
  156 13:5 |foo| REFERENCE qualified
''');
  }

  test_searchReferences_MethodElement_normal_ofMixin_static() async {
    await resolveTestCode('''
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
    var element = findElement2.method('foo');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> M@28
  5 1:6 |foo| REFERENCE
  17 1:18 |foo| REFERENCE qualified
<testLibraryFragment> useFoo@69
  84 5:5 |foo| INVOCATION
  95 6:5 |foo| REFERENCE
<testLibraryFragment> useFoo@111
  126 10:5 |foo| INVOCATION qualified
  137 11:5 |foo| REFERENCE qualified
  151 12:10 |foo| INVOCATION qualified
''');
  }

  test_searchReferences_MethodElement_operator_ofClass_binary() async {
    await resolveTestCode('''
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
    var element = findElement2.method('+');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> A@42
  14 1:15 |+| REFERENCE
  33 1:34 |+| REFERENCE qualified
<testLibraryFragment> useOperator@82
  105 6:5 |+| INVOCATION qualified
  114 7:5 |+=| INVOCATION qualified
  122 8:3 |++| INVOCATION qualified
  130 9:4 |++| INVOCATION qualified
''');
  }

  test_searchReferences_MethodElement_operator_ofClass_index() async {
    await resolveTestCode('''
/// [operator []] and [A.operator []]
class A {
  operator [](i) => null;
}
void useOperator(A a) {
  a[0];
}
''');
    var element = findElement2.method('[]');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> useOperator@81
  103 6:4 |[| INVOCATION qualified
''');
  }

  test_searchReferences_MethodElement_operator_ofClass_indexEq() async {
    await resolveTestCode('''
/// [operator []=] and [A.operator []=]
class A {
  operator []=(i, v) {}
}
void useOperator(A a) {
  a[1] = 42;
}
''');
    var element = findElement2.method('[]=');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> useOperator@81
  103 6:4 |[| INVOCATION qualified
''');
  }

  test_searchReferences_MethodElement_operator_ofClass_prefix() async {
    await resolveTestCode('''
/// [operator ~] and [A.operator ~]
class A {
  A operator ~() => this;
}
void useOperator(A a) {
  ~a;
}
''');
    var element = findElement2.method('~');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> A@42
  14 1:15 |~| REFERENCE
  33 1:34 |~| REFERENCE qualified
<testLibraryFragment> useOperator@79
  100 6:3 |~| INVOCATION qualified
''');
  }

  test_searchReferences_MethodElement_operator_ofEnum_binary() async {
    await resolveTestCode('''
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
    var element = findElement2.method('+');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> E@41
  14 1:15 |+| REFERENCE
  33 1:34 |+| REFERENCE qualified
<testLibraryFragment> useOperator@87
  110 7:5 |+| INVOCATION qualified
  119 8:5 |+=| INVOCATION qualified
  127 9:3 |++| INVOCATION qualified
  135 10:4 |++| INVOCATION qualified
''');
  }

  test_searchReferences_MethodElement_operator_ofEnum_index() async {
    await resolveTestCode('''
/// [operator []] and [E.operator []]
enum E {
  v;
  int operator [](int index) => 0;
}
void useOperator(E e) {
  e[0];
}
''');
    var element = findElement2.method('[]');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> useOperator@94
  116 7:4 |[| INVOCATION qualified
''');
  }

  test_searchReferences_MethodElement_operator_ofEnum_indexEq() async {
    await resolveTestCode('''
/// [operator []=] and [E.operator []=]
enum E {
  v;
  operator []=(int index, int value) {}
}
void useOperator(E e) {
  e[1] = 42;
}
''');
    var element = findElement2.method('[]=');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> useOperator@101
  123 7:4 |[| INVOCATION qualified
''');
  }

  test_searchReferences_MethodElement_operator_ofEnum_prefix() async {
    await resolveTestCode('''
/// [operator ~] and [E.operator ~]
enum E {
  e;
  int operator ~() => 0;
}
void useOperator(E e) {
  ~e;
}
''');
    var element = findElement2.method('~');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> E@41
  14 1:15 |~| REFERENCE
  33 1:34 |~| REFERENCE qualified
<testLibraryFragment> useOperator@82
  103 7:3 |~| INVOCATION qualified
''');
  }

  test_searchReferences_MethodElement_operator_ofExtension_binary() async {
    await resolveTestCode('''
/// [operator +] and [E.operator +]
extension E on int {
  int operator +(int other) => 0;
}
void useOperator(int e) {
  E(e) + 1;
}
''');
    var element = findElement2.method('+');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> E@46
  14 1:15 |+| REFERENCE
  33 1:34 |+| REFERENCE qualified
<testLibraryFragment> useOperator@98
  126 6:8 |+| INVOCATION qualified
''');
  }

  test_searchReferences_MethodElement_operator_ofExtension_index() async {
    await resolveTestCode('''
/// [operator []] and [E.operator []]
extension E on int {
  int operator [](int index) => 0;
}
void useOperator(int e) {
  E(e)[0];
}
''');
    var element = findElement2.method('[]');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> useOperator@101
  128 6:7 |[| INVOCATION qualified
''');
  }

  test_searchReferences_MethodElement_operator_ofExtension_indexEq() async {
    await resolveTestCode('''
/// [operator []=] and [E.operator []=]
extension E on int {
  operator []=(int index, int value) {}
}
void useOperator(int e) {
  E(e)[1] = 42;
}
''');
    var element = findElement2.method('[]=');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> useOperator@108
  135 6:7 |[| INVOCATION qualified
''');
  }

  test_searchReferences_MethodElement_operator_ofExtension_prefix() async {
    await resolveTestCode('''
/// [operator ~] and [E.operator ~]
extension E on int {
  int operator ~() => 0;
}
void useOperator(int e) {
  ~E(e);
}
''');
    var element = findElement2.method('~');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> E@46
  14 1:15 |~| REFERENCE
  33 1:34 |~| REFERENCE qualified
<testLibraryFragment> useOperator@89
  112 6:3 |~| INVOCATION qualified
''');
  }

  test_searchReferences_MethodElement_operator_ofExtensionType_binary() async {
    await resolveTestCode('''
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
    var element = findElement2.method('+');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> A@51
  14 1:15 |+| REFERENCE
  33 1:34 |+| REFERENCE qualified
<testLibraryFragment> useOperator@104
  127 6:5 |+| INVOCATION qualified
  136 7:5 |+=| INVOCATION qualified
  144 8:3 |++| INVOCATION qualified
  152 9:4 |++| INVOCATION qualified
''');
  }

  test_searchReferences_MethodElement_operator_ofExtensionType_index() async {
    await resolveTestCode('''
/// [operator []] and [A.operator []]
extension type A(int it) {
  int operator [](int index) => 0;
}
void useOperator(A a) {
  a[0];
}
''');
    var element = findElement2.method('[]');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> useOperator@107
  129 6:4 |[| INVOCATION qualified
''');
  }

  test_searchReferences_MethodElement_operator_ofExtensionType_indexEq() async {
    await resolveTestCode('''
/// [operator []=] and [A.operator []=]
extension type A(int it) {
  operator []=(int index, int value) {}
}
void useOperator(A a) {
  a[1] = 42;
}
''');
    var element = findElement2.method('[]=');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> useOperator@114
  136 6:4 |[| INVOCATION qualified
''');
  }

  test_searchReferences_MethodElement_operator_ofExtensionType_prefix() async {
    await resolveTestCode('''
/// [operator ~] and [A.operator ~]
extension type A(int it) {
  int operator ~() => 0;
}
void useOperator(A a) {
  ~a;
}
''');
    var element = findElement2.method('~');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> A@51
  14 1:15 |~| REFERENCE
  33 1:34 |~| REFERENCE qualified
<testLibraryFragment> useOperator@95
  116 6:3 |~| INVOCATION qualified
''');
  }

  test_searchReferences_MethodElement_operator_ofMixin_binary() async {
    await resolveTestCode('''
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
    var element = findElement2.method('+');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> M@42
  14 1:15 |+| REFERENCE
  33 1:34 |+| REFERENCE qualified
<testLibraryFragment> useOperator@87
  110 6:5 |+| INVOCATION qualified
  119 7:5 |+=| INVOCATION qualified
  127 8:3 |++| INVOCATION qualified
  135 9:4 |++| INVOCATION qualified
''');
  }

  test_searchReferences_MethodElement_operator_ofMixin_index() async {
    await resolveTestCode('''
/// [operator []] and [M.operator []]
mixin M {
  int operator [](int index) => 0;
}
void useOperator(M m) {
  m[0];
}
''');
    var element = findElement2.method('[]');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> useOperator@90
  112 6:4 |[| INVOCATION qualified
''');
  }

  test_searchReferences_MethodElement_operator_ofMixin_indexEq() async {
    await resolveTestCode('''
/// [operator []=] and [M.operator []=]
mixin M {
  operator []=(int index, int value) {}
}
void useOperator(M m) {
  m[1] = 42;
}
''');
    var element = findElement2.method('[]=');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> useOperator@97
  119 6:4 |[| INVOCATION qualified
''');
  }

  test_searchReferences_MethodElement_operator_ofMixin_prefix() async {
    await resolveTestCode('''
/// [operator ~] and [M.operator ~]
mixin M {
  int operator ~() => 0;
}
void useOperator(M m) {
  ~m;
}
''');
    var element = findElement2.method('~');

    await assertElementReferencesText(element, r'''
<testLibraryFragment> M@42
  14 1:15 |~| REFERENCE
  33 1:34 |~| REFERENCE qualified
<testLibraryFragment> useOperator@78
  99 6:3 |~| INVOCATION qualified
''');
  }

  test_searchReferences_MixinElement_reference_annotation() async {
    await resolveTestCode(r'''
import 'test.dart' as p;

mixin A {
  static const int myConstant = 0;
}

@A.myConstant
@p.A.myConstant
void f() {}
''');
    var element = findElement2.mixin('A');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@109
  75 7:2 |A| REFERENCE
  91 8:4 |A| REFERENCE qualified
''');
  }

  test_searchReferences_MixinElement_reference_comment() async {
    await resolveTestCode(r'''
import 'test.dart' as p;

mixin A {}

/// [A] and [p.A].
void f() {}
''');
    var element = findElement2.mixin('A');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@62
  43 5:6 |A| REFERENCE
  53 5:16 |A| REFERENCE qualified
''');
  }

  test_searchReferences_MixinElement_reference_memberAccess() async {
    await resolveTestCode(r'''
import 'test.dart' as p;

mixin A {
  static void foo() {}
}

void f() {
  A.foo();
  p.A.foo();
}
''');
    var element = findElement2.mixin('A');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@67
  75 8:3 |A| REFERENCE
  88 9:5 |A| REFERENCE qualified
''');
  }

  test_searchReferences_MixinElement_reference_namedType() async {
    await resolveTestCode(r'''
import 'test.dart' as p;

mixin A {}

void f(A v1, p.A v2) {}
''');
    var element = findElement2.mixin('A');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> v1@47
  45 5:8 |A| REFERENCE
<testLibraryFragment> v2@55
  53 5:16 |A| REFERENCE qualified
''');
  }

  test_searchReferences_ParameterElement_generic_atDeclaration() async {
    await resolveTestCode('''
void f() {
  B().m(p: null); // 1
  B().m(p: null); // 2
}

class A<T> {
  void m({T? p}) {} // 3
}

class B extends A<String> {}
''');
    var element = findElement2.parameter('p');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@5
  19 2:9 |p| REFERENCE_BY_NAMED_ARGUMENT qualified
  42 3:9 |p| REFERENCE_BY_NAMED_ARGUMENT qualified
''');
  }

  @SkippedTest(
    // When this test begins passing, the temporary test
    // test_searchReferences_ParameterElement_generic_atInvocation_doesNotThrow_issue60005
    // can be removed.
    issue: 'https://github.com/dart-lang/sdk/issues/60200',
  )
  test_searchReferences_ParameterElement_generic_atInvocation() async {
    await resolveTestCode('''
void f() {
  B().m(p: null); // 1
  B().m(p: null); // 2
}

class A<T> {
  void m({T? p}) {} // 3
}

class B extends A<String> {}
''');
    var element = findNode
        .namedExpression('p: null); // 1')
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
    await resolveTestCode('''
void f() {
  B().m(p: null); // 1
  B().m(p: null); // 2
}

class A<T> {
  void m({T? p}) {} // 3
}

class B extends A<String> {}
''');
    var element = findNode
        .namedExpression('p: null); // 1')
        .correspondingParameter!;
    expect(driver.search.references(element, SearchedFiles()), completes);
  }

  test_searchReferences_PrefixElement() async {
    String partCode = r'''
part of my_lib;
ppp.Future c;
''';
    newFile('$testPackageLibPath/my_part.dart', partCode);
    await resolveTestCode('''
library my_lib;
import 'dart:async' as ppp;
part 'my_part.dart';
main() {
  ppp.Future a;
  ppp.Stream b;
}
''');
    var element = findElement2.prefix('ppp');
    await assertElementReferencesText(element, r'''
package:test/my_part.dart c@27
  16 2:1 |ppp| REFERENCE
<testLibraryFragment> main@65
  76 5:3 |ppp| REFERENCE
  92 6:3 |ppp| REFERENCE
''');
  }

  test_searchReferences_PrefixElement_extensionOverride() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension E on int {
  void foo() {}
}
''');

    await resolveTestCode('''
import 'a.dart' as prefix;

void f() {
  prefix.E(0).foo();
}
''');
    var element = findElement2.prefix('prefix');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@33
  41 4:3 |prefix| REFERENCE
''');
  }

  test_searchReferences_PrefixElement_inPackage() async {
    var aaaPackageRootPath = '$packagesRootPath/aaa';

    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: aaaPackageRootPath),
    );

    fileForContextSelection = testFile;

    var libPath = convertPath('$aaaPackageRootPath/lib/a.dart');
    var partPath = convertPath('$aaaPackageRootPath/lib/my_part.dart');

    String partCode = r'''
part of my_lib;
ppp.Future c;
''';
    newFile(partPath, partCode);
    await resolveFileCode(libPath, '''
library my_lib;
import 'dart:async' as ppp;
part 'my_part.dart';
main() {
  ppp.Future a;
  ppp.Stream b;
}
''');

    var element = findElement2.prefix('ppp');
    await assertElementReferencesText(element, r'''
package:aaa/a.dart main@65
  76 5:3 |ppp| REFERENCE
  92 6:3 |ppp| REFERENCE
package:aaa/my_part.dart c@27
  16 2:1 |ppp| REFERENCE
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

    await resolveTestCode('''
library lib;
part 'part1.dart';
part 'part2.dart';
part 'part3.dart';
class _C {}
_C v;
''');
    var element = findElement2.class_('_C');
    await assertElementReferencesText(element, r'''
package:test/part1.dart v1@16
  13 1:14 |_C| REFERENCE
package:test/part2.dart v2@16
  13 1:14 |_C| REFERENCE
<testLibraryFragment> v@85
  82 6:1 |_C| REFERENCE
''');
  }

  test_searchReferences_private_declaredInPart() async {
    String p = convertPath('$testPackageLibPath/lib.dart');
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

    newFile(p, code);
    newFile(p1, code1);
    newFile(p2, code2);

    await resolveTestCode(code);

    var element = findElement2.partFind('package:test/part1.dart').class_('_C');
    await assertElementReferencesText(element, r'''
package:test/part1.dart v1@28
  25 3:1 |_C| REFERENCE
package:test/part2.dart v2@16
  13 1:14 |_C| REFERENCE
<testLibraryFragment> v@54
  51 4:1 |_C| REFERENCE
''');
  }

  test_searchReferences_private_inPackage() async {
    var aaaPackageRootPath = '$packagesRootPath/aaa';
    var testFile = convertPath('$aaaPackageRootPath/lib/a.dart');
    var p1 = convertPath('$aaaPackageRootPath/lib/part1.dart');
    var p2 = convertPath('$aaaPackageRootPath/lib/part2.dart');

    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: aaaPackageRootPath),
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

    await resolveFileCode(testFile, testCode);

    var element = findElement2.class_('_C');
    await assertElementReferencesText(element, r'''
package:aaa/a.dart v@66
  63 5:1 |_C| REFERENCE
package:aaa/part1.dart v1@16
  13 1:14 |_C| REFERENCE
package:aaa/part2.dart v2@16
  13 1:14 |_C| REFERENCE
''');
  }

  test_searchReferences_PropertyAccessor_getter_ofExtension_instance() async {
    await resolveTestCode('''
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
    var element = findElement2.getter('foo');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> bar@49
  61 5:5 |foo| REFERENCE
  75 6:10 |foo| REFERENCE qualified
<testLibraryFragment> main@87
  103 11:8 |foo| REFERENCE qualified
  112 12:5 |foo| REFERENCE qualified
''');
  }

  test_searchReferences_PropertyAccessor_setter_ofExtension_instance() async {
    await resolveTestCode('''
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
    var element = findElement2.setter('foo');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> bar@49
  61 5:5 |foo| REFERENCE
  79 6:10 |foo| REFERENCE qualified
<testLibraryFragment> main@95
  111 11:8 |foo| REFERENCE qualified
  124 12:5 |foo| REFERENCE qualified
''');
  }

  test_searchReferences_PropertyAccessorElement_getter() async {
    await resolveTestCode('''
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
    var element = findElement2.getter('ggg');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> main@31
  44 4:5 |ggg| REFERENCE
  58 5:10 |ggg| REFERENCE qualified
  67 6:5 |ggg| REFERENCE
  83 7:10 |ggg| REFERENCE qualified
''');
  }

  test_searchReferences_PropertyAccessorElement_setter() async {
    await resolveTestCode('''
class A {
  set s(x) {}
  main() {
    s = 1;
    this.s = 2;
  }
}
''');
    var element = findElement2.setter('s');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> main@26
  39 4:5 |s| REFERENCE
  55 5:10 |s| REFERENCE qualified
''');
  }

  test_searchReferences_SetterElement_ofClass_instance() async {
    await resolveTestCode('''
/// [foo] and [A.foo]
class A {
  set foo(int _) {}
  void useSetter() {
    foo = 0;
    this.foo = 0;
  }
}

void useSetter(A a) {
  a.foo = 0;
}
''');
    var element = findElement2.setter('foo');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> A@28
  5 1:6 |foo| REFERENCE
  17 1:18 |foo| REFERENCE qualified
<testLibraryFragment> useSetter@59
  77 5:5 |foo| REFERENCE
  95 6:10 |foo| REFERENCE qualified
<testLibraryFragment> useSetter@116
  137 11:5 |foo| REFERENCE qualified
''');
  }

  test_searchReferences_SetterElement_ofClass_static() async {
    await resolveTestCode('''
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
    var element = findElement2.setter('foo');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> A@62
  31 3:6 |foo| REFERENCE
  40 3:15 |foo| REFERENCE qualified
  51 3:26 |foo| REFERENCE qualified
<testLibraryFragment> useSetter@107
  125 7:5 |foo| REFERENCE
<testLibraryFragment> useSetter@146
  164 12:5 |foo| REFERENCE qualified
  179 13:7 |foo| REFERENCE qualified
''');
  }

  test_searchReferences_SuperFormalParameterElement_ofConstructor_optionalNamed() async {
    await resolveTestCode('''
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
    var element = findElement2.unnamedConstructor('B').parameter('test');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> new@null
  58 6:8 |test| REFERENCE
  91 7:28 |test| READ
<testLibraryFragment> f@114
  124 11:5 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
  147 12:14 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
''');
  }

  test_searchReferences_SuperFormalParameterElement_ofConstructor_optionalPositional() async {
    await resolveTestCode('''
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
    var element = findElement2.unnamedConstructor('B').parameter('test');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> new@null
  58 6:8 |test| REFERENCE
  91 7:28 |test| READ
''');
  }

  test_searchReferences_SuperFormalParameterElement_ofConstructor_requiredNamed() async {
    await resolveTestCode('''
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
    var element = findElement2.unnamedConstructor('B').parameter('test');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> new@null
  66 6:8 |test| REFERENCE
  108 7:37 |test| READ
<testLibraryFragment> f@129
  139 11:5 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
  162 12:14 |test| REFERENCE_BY_NAMED_ARGUMENT qualified
''');
  }

  test_searchReferences_SuperFormalParameterElement_ofConstructor_requiredPositional() async {
    await resolveTestCode('''
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
    var element = findElement2.unnamedConstructor('B').parameter('test');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> new@null
  55 6:8 |test| REFERENCE
  86 7:26 |test| READ
''');
  }

  test_searchReferences_TopLevelFunctionElement() async {
    await resolveTestCode(r'''
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
    var element = findElement2.topFunction('foo');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@68
  46 5:6 |foo| REFERENCE
  58 5:18 |foo| REFERENCE qualified
  76 7:3 |foo| INVOCATION
  87 8:5 |foo| INVOCATION qualified
  96 9:3 |foo| REFERENCE
  105 10:5 |foo| REFERENCE qualified
''');
  }

  test_searchReferences_TopLevelFunctionElement_loadLibrary() async {
    await resolveTestCode('''
import 'dart:math' deferred as math;

void f() {
  math.loadLibrary();
}
''');
    var mathLib = findElement2.import('dart:math').importedLibrary!;
    var element = mathLib.loadLibraryFunction;
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@43
  56 4:8 |loadLibrary| INVOCATION qualified
''');
  }

  test_searchReferences_TopLevelVariableElement() async {
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
var V;
''');
    await resolveTestCode('''
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
    var element = findElement2
        .importFind('package:test/lib.dart', mustBeUnique: false)
        .topVar('V');
    await assertElementReferencesText(element, r'''
#F0
  23 1:24 |V| REFERENCE qualified
<testLibraryFragment> main@53
  69 4:8 |V| WRITE qualified
  83 5:8 |V| READ qualified
  93 6:8 |V| READ qualified
  100 7:3 |V| WRITE
  109 8:3 |V| READ
  114 9:3 |V| READ
''');
  }

  test_searchReferences_TopLevelVariableElement_reference() async {
    await resolveTestCode('''
import 'test.dart' as p;

var foo = 0;

/// [foo] and [p.foo].
@foo
@p.foo
void f() {
  foo;
  foo = 0;
  p.foo;
  p.foo = 0;
}
''');
    var element = findElement2.topVar('foo');
    var getter = element.getter!;
    var setter = element.setter!;

    await assertElementReferencesText(getter, r'''
<testLibraryFragment> f@80
  45 5:6 |foo| REFERENCE
  57 5:18 |foo| REFERENCE qualified
  64 6:2 |foo| REFERENCE
  71 7:4 |foo| REFERENCE qualified
  88 9:3 |foo| REFERENCE
  108 11:5 |foo| REFERENCE qualified
''');

    await assertElementReferencesText(setter, r'''
<testLibraryFragment> f@80
  95 10:3 |foo| REFERENCE
  117 12:5 |foo| REFERENCE qualified
''');
  }

  test_searchReferences_TopLevelVariableElement_reference_combinator_show_hasGetterSetter() async {
    await resolveTestCode('''
import 'test.dart' show foo;

int get foo => 0;
void set foo(_) {}
''');
    var element = findElement2.topVar('foo');
    await assertElementReferencesText(element, r'''
''');
  }

  test_searchReferences_TopLevelVariableElement_reference_combinator_show_hasSetter() async {
    await resolveTestCode('''
import 'test.dart' show foo;

void set foo(_) {}
''');
    var element = findElement2.topVar('foo');
    await assertElementReferencesText(element, r'''
''');
  }

  test_searchReferences_TypeAliasElement_inConstructorName() async {
    await resolveTestCode('''
class A<T> {}

typedef B = A<int>;

void f() {
  B();
}
''');

    var element = findElement2.typeAlias('B');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@41
  49 6:3 |B| REFERENCE
''');
  }

  test_searchReferences_TypeAliasElement_legacy_reference() async {
    await resolveTestCode('''
typedef void A();
/// [A]
void f(A p) {}
''');
    var element = findElement2.typeAlias('A');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@31
  23 2:6 |A| REFERENCE
<testLibraryFragment> p@35
  33 3:8 |A| REFERENCE
''');
  }

  test_searchReferences_TypeAliasElement_modern_reference() async {
    await resolveTestCode('''
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
    var element = findElement2.typeAlias('B');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@100
  92 8:6 |B| REFERENCE
  111 10:3 |B| REFERENCE
  118 11:3 |B| REFERENCE
  125 12:3 |B| REFERENCE
  136 13:3 |B| REFERENCE
  151 14:3 |B| REFERENCE
<testLibraryFragment> p@104
  102 9:8 |B| REFERENCE
''');
  }

  test_searchReferences_TypeAliasElement_modern_reference_comment() async {
    await resolveTestCode(r'''
import 'test.dart' as p;

class A<T> {}
typedef B = A<int>;

/// [B] and [p.B].
void f() {}
''');
    var element = findElement2.typeAlias('B');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@85
  66 6:6 |B| REFERENCE
  76 6:16 |B| REFERENCE qualified
''');
  }

  test_searchReferences_TypeParameterElement_ofClass() async {
    await resolveTestCode('''
class A<T> {
  foo(T a) {}
  bar(T b) {}
}
''');
    var element = findElement2.typeParameter('T');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> a@21
  19 2:7 |T| REFERENCE
<testLibraryFragment> b@35
  33 3:7 |T| REFERENCE
''');
  }

  test_searchReferences_TypeParameterElement_ofEnum() async {
    await resolveTestCode('''
enum E<T> {
  v;
  final T a;
  void foo(T b) {}
}
''');
    var element = findElement2.typeParameter('T');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> a@27
  25 3:9 |T| REFERENCE
<testLibraryFragment> b@43
  41 4:12 |T| REFERENCE
''');
  }

  test_searchReferences_TypeParameterElement_ofLocalFunction() async {
    makeFilePriority(testFile);
    await resolveTestCode('''
main() {
  void foo<T>(T a) {
    void bar(T b) {}
  }
}
''');
    var element = findElement2.typeParameter('T');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> main@0
  23 2:15 |T| REFERENCE
  43 3:14 |T| REFERENCE
''');
  }

  test_searchReferences_TypeParameterElement_ofMethod() async {
    await resolveTestCode('''
class A {
  foo<T>(T p) {}
}
''');
    var element = findElement2.typeParameter('T');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> p@21
  19 2:10 |T| REFERENCE
''');
  }

  test_searchReferences_TypeParameterElement_ofTopLevelFunction() async {
    await resolveTestCode('''
foo<T>(T a) {
  bar(T b) {}
}
''');
    var element = findElement2.typeParameter('T');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> a@9
  7 1:8 |T| REFERENCE
<testLibraryFragment> foo@0
  20 2:7 |T| REFERENCE
''');
  }

  test_searchReferences_VariablePatternElement_declaration() async {
    await resolveTestCode('''
void f(x) {
  var (v) = x;
  v = 1;
  v += 2;
  v;
  v();
}
''');
    var element = findNode.bindPatternVariableElement('v) =');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@5
  29 3:3 |v| WRITE
  38 4:3 |v| READ_WRITE
  48 5:3 |v| READ
  53 6:3 |v| READ
''');
  }

  test_searchReferences_VariablePatternElement_expressionFunctionBody() async {
    await resolveTestCode('''
List<int> f(Map<int, String> map) => [
  for (var MapEntry(:key) in map.entries)
    key,
];
''');
    var element = findNode.bindPatternVariableElement('key)');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@10
  85 3:5 |key| READ
''');
  }

  test_searchReferences_VariablePatternElement_ifCase() async {
    await resolveTestCode('''
void f(Object? x) {
  if (x case int v) {
    v;
  }
}
''');
    var element = findNode.bindPatternVariableElement('v)');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@5
  46 3:5 |v| READ
''');
  }

  test_searchReferences_VariablePatternElement_ifCase_logicalOr() async {
    await resolveTestCode('''
void f(Object? x) {
  if (x case int v || [int v]) {
    v;
    v = 1;
  }
}
''');
    var element = findNode.bindPatternVariableElement('v]');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@5
  57 3:5 |v| READ
  64 4:5 |v| WRITE
''');
  }

  test_searchReferences_VariablePatternElement_patternAssignment() async {
    makeFilePriority(testFile);
    await resolveTestCode('''
void f() {
  int v;
  (v, _) = (0, 1);
  v;
}
''');
    var element = findElement2.localVar('v');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@5
  23 3:4 |v| WRITE
  41 4:3 |v| READ
''');
  }

  test_searchReferences_VariablePatternElement_switchExpression() async {
    await resolveTestCode('''
Object f(Object? x) => switch (0) {
  int v when v > 0 => v + 1 + (v = 2),
  _ => -1,
}
''');
    var element = findNode.bindPatternVariableElement('int v');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@7
  49 2:14 |v| READ
  58 2:23 |v| READ
  67 2:32 |v| WRITE
''');
  }

  test_searchReferences_VariablePatternElement_switchExpression_topLevel() async {
    await resolveTestCode('''
var f = switch (0) {
  int v when v > 0 => v + 1 + (v = 2),
  _ => -1,
}
''');
    var element = findNode.bindPatternVariableElement('int v');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@4
  34 2:14 |v| READ
  43 2:23 |v| READ
  52 2:32 |v| WRITE
''');
  }

  test_searchReferences_VariablePatternElement_switchStatement_shared() async {
    await resolveTestCode('''
void f(Object? x) {
  switch (0) {
    case int v when v > 0:
    case [int v] when v < 0:
      v;
      v = 1;
  }
}
''');
    var element = findNode.bindPatternVariableElement('int v when');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@5
  55 3:21 |v| READ
  84 4:23 |v| READ
  97 5:7 |v| READ
  106 6:7 |v| WRITE
''');
  }

  test_searchReferences_VariablePatternElement_switchStatement_shared_hasLogicalOr() async {
    await resolveTestCode('''
void f(Object? x) {
  switch (0) {
    case int v when v > 0:
    case [int v] || [..., int v] when v < 0:
      v;
      v = 1;
  }
}
''');
    var element = findNode.bindPatternVariableElement('int v when');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> f@5
  55 3:21 |v| READ
  100 4:39 |v| READ
  113 5:7 |v| READ
  122 6:7 |v| WRITE
''');
  }

  test_searchSubtypes() async {
    await resolveTestCode('''
class T {}
class A extends T {}
class B = Object with T;
class C implements T {}
''');
    var element = findElement2.class_('T');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> A@17
  27 2:17 |T| REFERENCE
<testLibraryFragment> B@38
  54 3:23 |T| REFERENCE
<testLibraryFragment> C@63
  76 4:20 |T| REFERENCE
''');
  }

  test_searchSubtypes_mixinDeclaration() async {
    await resolveTestCode('''
class T {}
mixin A on T {}
mixin B implements T {}
''');
    var element = findElement2.class_('T');
    await assertElementReferencesText(element, r'''
<testLibraryFragment> A@17
  22 2:12 |T| REFERENCE
<testLibraryFragment> B@33
  46 3:20 |T| REFERENCE
''');
  }

  test_subtypes_class() async {
    await resolveTestCode('''
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
    var a = findElement2.class_('A');

    // Search by 'type'.
    List<SubtypeResult> subtypes = await driver.search.subtypes(
      SearchedFiles(),
      type: a,
    );
    expect(subtypes, hasLength(3));

    SubtypeResult b = subtypes.singleWhere((r) => r.name == 'B');
    SubtypeResult c = subtypes.singleWhere((r) => r.name == 'C');
    SubtypeResult d = subtypes.singleWhere((r) => r.name == 'D');

    expect(b.libraryUri, testUriStr);
    expect(b.id, '$testUriStr;$testUriStr;B');
    expect(b.members, ['methodB']);

    expect(c.libraryUri, testUriStr);
    expect(c.id, '$testUriStr;$testUriStr;C');
    expect(c.members, ['methodC']);

    expect(d.libraryUri, testUriStr);
    expect(d.id, '$testUriStr;$testUriStr;D');
    expect(d.members, ['methodD']);

    // Search by 'id'.
    {
      List<SubtypeResult> subtypes = await driver.search.subtypes(
        SearchedFiles(),
        subtype: b,
      );
      expect(subtypes, hasLength(1));
      SubtypeResult e = subtypes.singleWhere((r) => r.name == 'E');
      expect(e.members, ['methodE']);
    }
  }

  test_subTypes_class_discover() async {
    var aaaPackageRootPath = '$packagesRootPath/aaa';
    var bbbPackageRootPath = '$packagesRootPath/bbb';

    var aaaFilePath = convertPath('$aaaPackageRootPath/lib/a.dart');
    var bbbFilePath = convertPath('$bbbPackageRootPath/lib/b.dart');

    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: aaaPackageRootPath)
        ..add(name: 'bbb', rootPath: bbbPackageRootPath),
    );

    var tUri = 'package:test/test.dart';
    var aUri = 'package:aaa/a.dart';
    var bUri = 'package:bbb/b.dart';

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
    List<SubtypeResult> subtypes = await driver.search.subtypes(
      SearchedFiles(),
      type: aClass,
    );
    expect(subtypes, hasLength(3));

    SubtypeResult t1 = subtypes.singleWhere((r) => r.name == 'T1');
    SubtypeResult t2 = subtypes.singleWhere((r) => r.name == 'T2');
    SubtypeResult b = subtypes.singleWhere((r) => r.name == 'B');

    expect(t1.libraryUri, tUri);
    expect(t1.id, '$tUri;$tUri;T1');
    expect(t1.members, ['method1']);

    expect(t2.libraryUri, tUri);
    expect(t2.id, '$tUri;$tUri;T2');
    expect(t2.members, ['method2']);

    expect(b.libraryUri, bUri);
    expect(b.id, '$bUri;$bUri;B');
    expect(b.members, ['method1']);
  }

  test_subTypes_class_discover2() async {
    var aaaPackageRootPath = '$packagesRootPath/aaa';
    var bbbPackageRootPath = '$packagesRootPath/bbb';
    var cccPackageRootPath = '$packagesRootPath/ccc';

    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: aaaPackageRootPath)
        ..add(name: 'bbb', rootPath: bbbPackageRootPath),
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

    var searchedFiles = SearchedFiles();
    var results = await driver.search.subTypes(listElement, searchedFiles);

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

  test_subtypes_class_files() async {
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

    await resolveTestCode('''
class A {}
''');
    var a = findElement2.class_('A');

    List<SubtypeResult> subtypes = await driver.search.subtypes(
      SearchedFiles(),
      type: a,
    );
    expect(subtypes, hasLength(2));

    SubtypeResult b = subtypes.singleWhere((r) => r.name == 'B');
    SubtypeResult c = subtypes.singleWhere((r) => r.name == 'C');

    expect(b.id, endsWith('b.dart;B'));
    expect(c.id, endsWith('c.dart;C'));
  }

  test_subtypes_class_missingName() async {
    await resolveTestCode('''
class {}
''');
    var a = findElement2.libraryElement.classes.single;
    var subtypes = await driver.search.subtypes(SearchedFiles(), type: a);
    expect(subtypes, isEmpty);
  }

  test_subtypes_enum() async {
    await resolveTestCode('''
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

    var subtypes = await driver.search.subtypes(
      SearchedFiles(),
      type: findElement2.class_('A'),
    );
    expect(subtypes, hasLength(2));

    var resultE1 = subtypes.singleWhere((r) => r.name == 'E1');
    var resultE2 = subtypes.singleWhere((r) => r.name == 'E2');

    expect(resultE1.libraryUri, testUriStr);
    expect(resultE1.id, '$testUriStr;$testUriStr;E1');
    expect(resultE1.members, ['methodE1']);

    expect(resultE2.libraryUri, testUriStr);
    expect(resultE2.id, '$testUriStr;$testUriStr;E2');
    expect(resultE2.members, ['methodE2']);
  }

  test_subtypes_extensionType() async {
    await resolveTestCode('''
class A {}

extension type E1(A it) implements A {
  void methodE1() {}
}

extension type E2(A it) implements A {
  void methodE2() {}
}
''');

    var subtypes = await driver.search.subtypes(
      SearchedFiles(),
      type: findElement2.class_('A'),
    );
    expect(subtypes, hasLength(2));

    var resultE1 = subtypes.singleWhere((r) => r.name == 'E1');
    var resultE2 = subtypes.singleWhere((r) => r.name == 'E2');

    expect(resultE1.libraryUri, testUriStr);
    expect(resultE1.id, '$testUriStr;$testUriStr;E1');
    expect(resultE1.members, ['methodE1']);

    expect(resultE2.libraryUri, testUriStr);
    expect(resultE2.id, '$testUriStr;$testUriStr;E2');
    expect(resultE2.members, ['methodE2']);
  }

  test_subtypes_extensionType2() async {
    await resolveTestCode('''
extension type A(int it) {}

extension type B(int it) implements A {
  void methodB() {}
}
''');

    var subtypes = await driver.search.subtypes(
      SearchedFiles(),
      type: findElement2.extensionType('A'),
    );
    expect(subtypes, hasLength(1));

    var B = subtypes.singleWhere((r) => r.name == 'B');

    expect(B.libraryUri, testUriStr);
    expect(B.id, '$testUriStr;$testUriStr;B');
    expect(B.members, ['methodB']);
  }

  test_subtypes_mixin_superclassConstraints() async {
    await resolveTestCode('''
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
    var a = findElement2.class_('A');
    var b = findElement2.class_('B');

    {
      var subtypes = await driver.search.subtypes(SearchedFiles(), type: a);
      expect(subtypes, hasLength(1));

      var m = subtypes.singleWhere((r) => r.name == 'M');
      expect(m.libraryUri, testUriStr);
      expect(m.id, '$testUriStr;$testUriStr;M');
      expect(m.members, ['methodA', 'methodM']);
    }

    {
      var subtypes = await driver.search.subtypes(SearchedFiles(), type: b);
      expect(subtypes, hasLength(1));

      var m = subtypes.singleWhere((r) => r.name == 'M');
      expect(m.libraryUri, testUriStr);
      expect(m.id, '$testUriStr;$testUriStr;M');
      expect(m.members, ['methodA', 'methodM']);
    }
  }

  test_topLevelElements() async {
    await resolveTestCode('''
class A {}
class B = Object with A;
mixin C {}
typedef D();
f() {}
var g = null;
class NoMatchABCDEF {}
''');
    var a = findElement2.class_('A');
    var b = findElement2.class_('B');
    var c = findElement2.mixin('C');
    var d = findElement2.typeAlias('D');
    var f = findElement2.function('f');
    var g = findElement2.topVar('g');
    RegExp regExp = RegExp(r'^[ABCDfg]$');
    expect(
      await driver.search.topLevelElements(regExp),
      unorderedEquals([a, b, c, d, f, g]),
    );
  }

  Future<List<Element>> _findClassMembers(String name) {
    var searchedFiles = SearchedFiles();
    return driver.search.classMembers(name, searchedFiles);
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
    var analysisSession = result.session;

    var groups = results
        .groupListsBy((result) => result.enclosingFragment)
        .entries
        .where((entry) {
          if (includedLibraryUris case var included?) {
            var uri = entry.key.libraryFragment?.source.uri;
            return uri != null && included.contains(uri);
          }
          return true;
        })
        .map((entry) {
          var enclosingFragment = entry.key;
          return _GroupToPrint(
            enclosingFragment: enclosingFragment,
            results: entry.value.sortedBy<num>((e) => e.offset),
          );
        })
        .sorted((first, second) {
          var firstPath = first.path;
          var secondPath = second.path;
          var byPath = firstPath.compareTo(secondPath);
          if (byPath != 0) {
            return byPath;
          }
          return first.results.first.offset - second.results.first.offset;
        });

    var buffer = StringBuffer();
    var sink = TreeStringSink(sink: buffer, indent: '');
    var elementPrinter = ElementPrinter(
      sink: sink,
      configuration: ElementPrinterConfiguration(),
    );

    for (var group in groups) {
      var unitPath = group.path;
      var unitResult = analysisSession.getParsedUnit(unitPath);
      unitResult as ParsedUnitResult;
      elementPrinter.writelnFragmentReference(group.enclosingFragment);
      for (var result in group.results) {
        var offset = result.offset;
        var length = result.length;
        var end = offset + length;
        var location = unitResult.lineInfo.getLocation(offset);
        var snippet = unitResult.content.substring(offset, end);

        buffer.write('  ');
        buffer.write(result.offset);
        buffer.write(' ');
        buffer.write(location.lineNumber);
        buffer.write(':');
        buffer.write(location.columnNumber);
        buffer.write(' |$snippet|');
        buffer.write(' ');
        buffer.write(result.kind.name);
        if (result.isQualified) {
          buffer.write(' qualified');
        }
        if (!result.isResolved) {
          buffer.write(' unresolved');
        }
        buffer.writeln();
      }
    }
    return buffer.toString();
  }

  String _getSearchResultsText2(List<LibraryFragmentSearchMatch> results) {
    var analysisSession = result.session;

    var groups = results
        .groupListsBy((result) => result.libraryFragment)
        .entries
        .map((entry) {
          var enclosingFragment = entry.key;
          return _GroupToPrint2(
            enclosingFragment: enclosingFragment,
            results: entry.value.sortedBy<num>((e) => e.range.offset),
          );
        })
        .sorted((first, second) {
          var firstPath = first.path;
          var secondPath = second.path;
          var byPath = firstPath.compareTo(secondPath);
          if (byPath != 0) {
            return byPath;
          }
          var firstOffset = first.results.first.range.offset;
          var secondOffset = second.results.first.range.offset;
          return firstOffset - secondOffset;
        });

    var buffer = StringBuffer();
    var sink = TreeStringSink(sink: buffer, indent: '');
    var elementPrinter = ElementPrinter(
      sink: sink,
      configuration: ElementPrinterConfiguration(),
    );

    for (var group in groups) {
      var unitPath = group.path;
      var unitResult = analysisSession.getParsedUnit(unitPath);
      unitResult as ParsedUnitResult;
      elementPrinter.writelnFragmentReference(group.enclosingFragment);
      for (var result in group.results) {
        var offset = result.range.offset;
        var length = result.range.length;
        var end = offset + length;
        var location = unitResult.lineInfo.getLocation(offset);
        var snippet = unitResult.content.substring(offset, end);

        buffer.write('  ');
        buffer.write(result.range.offset);
        buffer.write(' ');
        buffer.write(location.lineNumber);
        buffer.write(':');
        buffer.write(location.columnNumber);
        buffer.write(' |$snippet|');
        buffer.writeln();
      }
    }
    return buffer.toString();
  }

  /// When the file is priority, its resolved result is cached, so when
  /// [Search] uses AST to find local references, it can see the same elements
  /// for formal parameters.
  void _makeTestFilePriority() {
    makeFilePriority(testFile);
  }
}

class _GroupToPrint {
  final Fragment enclosingFragment;
  final List<SearchResult> results;

  _GroupToPrint({required this.enclosingFragment, required this.results});

  String get path {
    return enclosingFragment.libraryFragment!.source.fullName;
  }
}

class _GroupToPrint2 {
  final Fragment enclosingFragment;
  final List<LibraryFragmentSearchMatch> results;

  _GroupToPrint2({required this.enclosingFragment, required this.results});

  String get path {
    return enclosingFragment.libraryFragment!.source.fullName;
  }
}
