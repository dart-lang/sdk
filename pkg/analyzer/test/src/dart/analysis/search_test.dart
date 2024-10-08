// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/search.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/test_utilities/find_element.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer/src/utilities/cancellation.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

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
  List<String> get collectionIncludedPaths =>
      [workspaceRootPath, otherPackageRootPath];

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
    expect(declarations.where((element) => element.name == 'Duration'),
        hasLength(1));
  }
}

@reflectiveTest
class SearchTest extends PubPackageResolutionTest {
  final OperationPerformanceImpl performance =
      OperationPerformanceImpl('<root>');

  AnalysisDriver get driver => driverFor(testFile);

  String get testUriStr => 'package:test/test.dart';

  void assertDeclarationsText(
    WorkspaceSymbols symbols,
    Map<File, String> inFiles,
    String expected,
  ) {
    var actual = _getDeclarationsText(symbols, inFiles);
    if (actual != expected) {
      print(actual);
      NodeTextExpectationsCollector.add(actual);
    }
    expect(actual, expected);
  }

  Future<void> assertElementReferencesText(
    Element element,
    String expected,
  ) async {
    var searchedFiles = SearchedFiles();
    var results = await driver.search.references(element, searchedFiles);
    var actual = _getSearchResultsText(results);
    if (actual != expected) {
      print(actual);
      NodeTextExpectationsCollector.add(actual);
    }
    expect(actual, expected);
  }

  Future<void> assertUnresolvedMemberReferencesText(
    String name,
    String expected,
  ) async {
    var searchedFiles = SearchedFiles();
    var results =
        await driver.search.unresolvedMemberReferences(name, searchedFiles);
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
        findElement.method('test', of: 'A'),
        findElement.field('test', of: 'B'),
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
        findElement.method('test', of: 'E1'),
        findElement.field('test', of: 'E2'),
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
        findElement.method('test', of: 'A'),
        findElement.field('test', of: 'B'),
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
    assertDeclarationsText(results, {testFile: 'testFile'}, r'''
testFile
  CLASS C
    offset: 6 1:7
    codeOffset: 0 + 91
  FIELD f
    offset: 16 2:7
    codeOffset: 12 + 5
    className: C
  CONSTRUCTOR <unnamed>
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
''');
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

    assertDeclarationsText(results, {
      testFile: 'testFile',
      file_a: 'file_a',
      file_b: 'file_b',
      file_c: 'file_c',
    }, r'''
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
''');
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
    assertDeclarationsText(results, {testFile: 'testFile'}, r'''
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
''');
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
    assertDeclarationsText(results, {testFile: 'testFile'}, r'''
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
''');
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
    assertDeclarationsText(results, {testFile: 'testFile'}, r'''
testFile
  EXTENSION_TYPE E
    offset: 15 1:16
    codeOffset: 0 + 79
  CONSTRUCTOR <unnamed>
    offset: 15 1:16
    codeOffset: 16 + 8
    className: E
    parameters: (int it)
  FIELD it
    offset: 21 1:22
    codeOffset: 17 + 6
    className: E
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
''');
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
    assertDeclarationsText(results, {testFile: 'testFile'}, r'''
testFile
  CLASS A
    offset: 6 1:7
    codeOffset: 0 + 10
''');
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
    assertDeclarationsText(results, {testFile: 'testFile'}, r'''
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
''');
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

    assertDeclarationsText(results, {testFile: 'testFile', b: 'file_b'}, r'''
file_b
  CLASS B
    offset: 6 1:7
    codeOffset: 0 + 10
''');
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
    assertDeclarationsText(results, {testFile: 'testFile'}, r'''
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
''');
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
    assertDeclarationsText(results, {testFile: 'testFile'}, r'''
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
''');
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
    assertDeclarationsText(results, {testFile: 'testFile'}, r'''
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
''');
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
    assertDeclarationsText(results, {testFile: 'testFile'}, r'''
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
''');
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
    var libraryElementResult =
        await mySession.getLibraryByUri('package:my/my.dart');
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
self::@function::f
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
self::@class::C::@method::main
  31 3:11 |test| READ unresolved
  42 4:5 |test| WRITE unresolved
  56 5:5 |test| READ_WRITE unresolved
  71 6:5 |test| INVOCATION unresolved
''');
  }

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

    var A = findElement.class_('A');
    var element = A.augmented.constructors.single;
    expect(element.name, 'named');

    await assertElementReferencesText(element, r'''
self::@class::A::@method::foo
  46 5:6 |.named| INVOCATION qualified
self::@function::f
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
    var element = findElement.getter('foo');
    await assertElementReferencesText(element, r'''
self::@function::f
  35 2:16 |foo| REFERENCE qualified
  62 3:16 || REFERENCE qualified
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
    var element = findElement.method('foo');
    await assertElementReferencesText(element, r'''
self::@function::f
  35 2:16 |foo| REFERENCE qualified
  62 3:16 || REFERENCE qualified
''');
  }

  test_searchReferences_ClassElement_definedInSdk() async {
    await resolveTestCode('''
import 'dart:math';
Random v1;
Random v2;
''');

    var element = findElement.importFind('dart:math').class_('Random');
    await assertElementReferencesText(element, r'''
self::@topLevelVariable::v1
  20 2:1 |Random| REFERENCE
self::@topLevelVariable::v2
  31 3:1 |Random| REFERENCE
''');
  }

  test_searchReferences_ClassElement_definedInside() async {
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
    var element = findElement.class_('A');
    await assertElementReferencesText(element, r'''
self::@function::main::@parameter::p
  17 2:6 |A| REFERENCE
self::@function::main
  26 3:3 |A| REFERENCE
self::@class::B1
  50 5:18 |A| REFERENCE
self::@class::B2
  75 6:21 |A| REFERENCE
self::@class::B3
  109 7:30 |A| REFERENCE
self::@topLevelVariable::v2
  119 8:6 |A| REFERENCE
''');
  }

  test_searchReferences_ClassElement_definedOutside() async {
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
self::@function::main::@parameter::p
  24 2:6 |A| REFERENCE
self::@function::main
  33 3:3 |A| REFERENCE
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
    var element = findElement.enum_('MyEnum');
    await assertElementReferencesText(element, r'''
self::@function::main::@parameter::p
  22 3:6 |MyEnum| REFERENCE
self::@function::main
  36 4:3 |MyEnum| REFERENCE
  48 5:3 |MyEnum| REFERENCE
''');
  }

  test_searchReferences_ClassElement_inRecordTypeAnnotation_named() async {
    await resolveTestCode('''
class A {}

void f(({int foo, A bar}) r) {}
''');
    var element = findElement.class_('A');
    await assertElementReferencesText(element, r'''
self::@function::f::@parameter::r
  30 3:19 |A| REFERENCE
''');
  }

  test_searchReferences_ClassElement_inRecordTypeAnnotation_positional() async {
    await resolveTestCode('''
class A {}

void f((int, A) r) {}
''');
    var element = findElement.class_('A');
    await assertElementReferencesText(element, r'''
self::@function::f::@parameter::r
  25 3:14 |A| REFERENCE
''');
  }

  test_searchReferences_ClassElement_mixin() async {
    await resolveTestCode('''
mixin A {}
class B extends Object with A {}
''');
    var element = findElement.mixin('A');
    await assertElementReferencesText(element, r'''
self::@class::B
  39 2:29 |A| REFERENCE
''');
  }

  test_searchReferences_ClassElement_typeArgument_ofGenericAnnotation() async {
    await resolveTestCode('''
class A<T> {
  const A();
}

class B {}

@A<B>()
void f() {}
''');

    var element = findElement.class_('B');
    await assertElementReferencesText(element, r'''
self::@function::f
  44 7:4 |B| REFERENCE
''');
  }

  test_searchReferences_CompilationUnitElement_export() async {
    newFile('$testPackageLibPath/foo.dart', '');
    await resolveTestCode('''
export 'foo.dart';
''');
    var element = findElement
        .export('package:test/foo.dart')
        .exportedLibrary!
        .definingCompilationUnit;
    await assertElementReferencesText(element, r'''
self
  7 1:8 |'foo.dart'| REFERENCE qualified
''');
  }

  test_searchReferences_CompilationUnitElement_import() async {
    newFile('$testPackageLibPath/foo.dart', '');
    await resolveTestCode('''
import 'foo.dart';
''');
    var element = findElement.importFind('package:test/foo.dart').unitElement;
    await assertElementReferencesText(element, r'''
self
  7 1:8 |'foo.dart'| REFERENCE qualified
''');
  }

  test_searchReferences_CompilationUnitElement_part() async {
    newFile('$testPackageLibPath/foo.dart', r'''
part of 'test.dart';
''');

    await resolveTestCode('''
part 'foo.dart';
''');

    var element = findElement.part('package:test/foo.dart');
    await assertElementReferencesText(element, r'''
self
  5 1:6 |'foo.dart'| REFERENCE qualified
''');
  }

  test_searchReferences_ConstructorElement_class_named() async {
    await resolveTestCode('''
/// [new A.named] 1
class A {
  A.named() {}
  A.other() : this.named();
}

class B extends A {
  B() : super.named();
  factory B.other() = A.named;
}

void f() {
  A.named();
  A.named;
}
''');
    var element = findElement.constructor('named');
    await assertElementReferencesText(element, r'''
self::@class::A
  10 1:11 |.named| REFERENCE qualified
self::@class::A::@constructor::other
  63 4:19 |.named| INVOCATION qualified
self::@class::B::@constructor::new
  109 8:14 |.named| INVOCATION qualified
self::@class::B::@constructor::other
  142 9:24 |.named| REFERENCE qualified
self::@function::f
  167 13:4 |.named| INVOCATION qualified
  180 14:4 |.named| REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
''');
  }

  test_searchReferences_ConstructorElement_class_named_viaTypeAlias() async {
    await resolveTestCode('''
class A<T> {
  A.named();
}

typedef B = A<int>;

void f() {
  B.named();
  B.named;
}
''');

    var element = findElement.constructor('named');
    await assertElementReferencesText(element, r'''
self::@function::f
  64 8:4 |.named| INVOCATION qualified
  77 9:4 |.named| REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
''');
  }

  test_searchReferences_ConstructorElement_class_unnamed_declared() async {
    await resolveTestCode('''
/// [new A] 1
class A {
  A() {}
  A.other() : this();
}

class B extends A {
  B() : super();
  factory B.other() = A;
}

void f() {
  A();
  A.new;
}
''');
    var element = findElement.unnamedConstructor('A');
    await assertElementReferencesText(element, r'''
self::@class::A
  10 1:11 || REFERENCE qualified
self::@class::A::@constructor::other
  51 4:19 || INVOCATION qualified
self::@class::B::@constructor::new
  91 8:14 || INVOCATION qualified
self::@class::B::@constructor::other
  118 9:24 || REFERENCE qualified
self::@function::f
  137 13:4 || INVOCATION qualified
  144 14:4 |.new| REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
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
    var element = findElement.unnamedConstructor('A');
    await assertElementReferencesText(element, r'''
package:test/other.dart::@fragment::package:test/other.dart::@function::f
  35 4:4 || INVOCATION qualified
''');
  }

  test_searchReferences_ConstructorElement_class_unnamed_synthetic() async {
    await resolveTestCode('''
/// [new A] 1
class A {}

class B extends A {
  B() : super();
  factory B.other() = A;
}

void f() {
  A();
  A.new;
}
''');
    var element = findElement.unnamedConstructor('A');
    await assertElementReferencesText(element, r'''
self::@class::A
  10 1:11 || REFERENCE qualified
self::@class::B::@constructor::new
  59 5:14 || INVOCATION qualified
self::@class::B::@constructor::other
  86 6:24 || REFERENCE qualified
self::@function::f
  105 10:4 || INVOCATION qualified
  112 11:4 |.new| REFERENCE_BY_CONSTRUCTOR_TEAR_OFF qualified
''');
  }

  test_searchReferences_ConstructorElement_enum_named() async {
    await resolveTestCode('''
/// [new E.named] 1
enum E {
  v.named();
  const E.named();
  const E.other() : this.named();
}
''');
    var element = findElement.constructor('named');
    await assertElementReferencesText(element, r'''
self::@enum::E
  10 1:11 |.named| REFERENCE qualified
self::@enum::E::@field::v
  32 3:4 |.named| INVOCATION qualified
self::@enum::E::@constructor::other
  85 5:25 |.named| INVOCATION qualified
''');
  }

  test_searchReferences_ConstructorElement_enum_unnamed_declared() async {
    await resolveTestCode('''
/// [new E]
enum E {
  v1,
  v2(),
  v3.new();
  const E();
  const E.other() : this();
}
''');
    var element = findElement.unnamedConstructor('E');
    await assertElementReferencesText(element, r'''
self::@enum::E
  10 1:11 || REFERENCE qualified
self::@enum::E::@field::v1
  25 3:5 || INVOCATION_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS qualified
self::@enum::E::@field::v2
  31 4:5 || INVOCATION qualified
self::@enum::E::@field::v3
  39 5:5 |.new| INVOCATION qualified
self::@enum::E::@constructor::other
  84 7:25 || INVOCATION qualified
''');
  }

  test_searchReferences_ConstructorElement_enum_unnamed_synthetic() async {
    await resolveTestCode('''
/// [new E]
enum E {
  v1,
  v2(),
  v3.new();
}
''');
    var element = findElement.unnamedConstructor('E');
    await assertElementReferencesText(element, r'''
self::@enum::E
  10 1:11 || REFERENCE qualified
self::@enum::E::@field::v1
  25 3:5 || INVOCATION_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS qualified
self::@enum::E::@field::v2
  31 4:5 || INVOCATION qualified
self::@enum::E::@field::v3
  39 5:5 |.new| INVOCATION qualified
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
    var element = findElement.extension_('E');
    await assertElementReferencesText(element, r'''
self::@function::main
  74 7:3 |E| REFERENCE
  88 8:3 |E| REFERENCE
''');
  }

  test_searchReferences_ExtensionTypeElement() async {
    await resolveTestCode('''
extension type E(int it) {
  static void bar() {}
}

void f(E e) {
  E.bar();
}
''');
    var element = findElement.extensionType('E');
    await assertElementReferencesText(element, r'''
self::@function::f::@parameter::e
  60 5:8 |E| REFERENCE
self::@function::f
  69 6:3 |E| REFERENCE
''');
  }

  test_searchReferences_FieldElement_class() async {
    await resolveTestCode('''
class A {
  var field;
  A({this.field});
  main() {
    new A(field: 1);
    // getter
    field;
    this.field;
    field();
    this.field();
    // setter
    field = 2;
    this.field = 3;
  }
}
''');
    var element = findElement.field('field');
    await assertElementReferencesText(element, r'''
self::@class::A::@constructor::new::@parameter::field
  33 3:11 |field| WRITE qualified
self::@class::A::@method::main
  92 7:5 |field| READ
  108 8:10 |field| READ qualified
  119 9:5 |field| READ
  137 10:10 |field| READ qualified
  164 12:5 |field| WRITE
  184 13:10 |field| WRITE qualified
''');
  }

  test_searchReferences_FieldElement_class_synthetic() async {
    await resolveTestCode('''
class A {
  get field => null;
  set field(x) {}
  main() {
    // getter
    field;
    this.field;
    field();
    this.field();
    // setter
    field = 2;
    this.field = 3;
  }
}
''');
    var element = findElement.field('field');
    await assertElementReferencesText(element, r'''
self::@class::A::@method::main
  78 6:5 |field| READ
  94 7:10 |field| READ qualified
  105 8:5 |field| READ
  123 9:10 |field| READ qualified
  150 11:5 |field| WRITE
  170 12:10 |field| WRITE qualified
''');
  }

  test_searchReferences_FieldElement_enum() async {
    await resolveTestCode('''
enum E {
  v(field: 0);
  final int field;
  const E({required this.field});
}

void f(E e) {
  e.field;
}
''');
    var element = findElement.field('field');
    await assertElementReferencesText(element, r'''
self::@enum::E::@constructor::new::@parameter::field
  68 4:26 |field| WRITE qualified
self::@function::f
  98 8:5 |field| READ qualified
''');
  }

  test_searchReferences_FieldElement_enum_values() async {
    await resolveTestCode('''
enum MyEnum {
  A, B, C
}
main() {
  MyEnum.A.index;
  MyEnum.values;
  MyEnum.A;
  MyEnum.B;
}
''');
    var index = typeProvider.enumElement!.getField('index')!;
    await assertElementReferencesText(index, r'''
self::@function::main
  46 5:12 |index| READ qualified
''');

    var values = findElement.field('values');
    await assertElementReferencesText(values, r'''
self::@function::main
  62 6:10 |values| READ qualified
''');

    var A = findElement.field('A');
    await assertElementReferencesText(A, r'''
self::@function::main
  44 5:10 |A| READ qualified
  79 7:10 |A| READ qualified
''');

    var B = findElement.field('B');
    await assertElementReferencesText(B, r'''
self::@function::main
  91 8:10 |B| READ qualified
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
    var element = findElement.function('test');
    await assertElementReferencesText(element, r'''
self::@function::main
  21 3:3 |test| INVOCATION
  31 4:3 |test| REFERENCE
''');
  }

  test_searchReferences_FunctionElement_local() async {
    await resolveTestCode('''
main() {
  test() {}
  test();
  test;
}
''');
    var element = findElement.localFunction('test');
    await assertElementReferencesText(element, r'''
self::@function::main
  23 3:3 |test| INVOCATION
  33 4:3 |test| REFERENCE
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
    var element = findElement.import('dart:math', mustBeUnique: false);
    await assertElementReferencesText(element, r'''
self::@function::main
  111 4:3 || REFERENCE
  121 5:7 || REFERENCE
  133 6:3 || REFERENCE
self::@function::bar
  146 8:1 || REFERENCE
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

    var element = findElement.import('dart:math');
    await assertElementReferencesText(element, r'''
self::@function::main
  111 4:3 || REFERENCE
  121 5:7 || REFERENCE
  133 6:3 || REFERENCE
self::@function::bar
  146 8:1 || REFERENCE
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
    var element = findElement.import('dart:math', mustBeUnique: false);
    await assertElementReferencesText(element, r'''
self::@function::main
  119 4:3 |math.| REFERENCE
  134 5:7 |math.| REFERENCE
  151 6:3 |math.| REFERENCE
self::@function::bar
  169 8:1 |math.| REFERENCE
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
      var element = findElement.import('dart:async');
      await assertElementReferencesText(element, r'''
self::@function::main
  76 5:3 |p.| REFERENCE
''');
    }
    {
      var element = findElement.import('dart:math');
      await assertElementReferencesText(element, r'''
self::@function::main
  62 4:3 |p.| REFERENCE
''');
    }
  }

  test_searchReferences_LabelElement() async {
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
    var element = findElement.label('label');
    await assertElementReferencesText(element, r'''
self::@function::main
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
self::@fragment::package:aaa/unitA.dart
  8 1:9 |lib| REFERENCE
self::@fragment::package:aaa/unitB.dart
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
self::@fragment::package:test/unitA.dart
  8 1:9 |lib| REFERENCE
self::@fragment::package:test/unitB.dart
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
self::@fragment::package:test/unitA.dart
  8 1:9 |'test.dart'| REFERENCE
self::@fragment::package:test/unitB.dart
  8 1:9 |'test.dart'| REFERENCE
''');
  }

  test_searchReferences_LocalVariableElement() async {
    await resolveTestCode(r'''
main() {
  var v;
  v = 1;
  v += 2;
  v;
  v();
}
''');
    var element = findElement.localVar('v');
    await assertElementReferencesText(element, r'''
self::@function::main
  20 3:3 |v| WRITE
  29 4:3 |v| READ_WRITE
  39 5:3 |v| READ
  44 6:3 |v| READ
''');
  }

  test_searchReferences_LocalVariableElement_inForEachElement_expressionBody() async {
    await resolveTestCode('''
Object f() => [
  for (var v in []) v,
];
''');
    var element = findElement.localVar('v');
    await assertElementReferencesText(element, r'''
self::@function::f
  36 2:21 |v| READ
''');
  }

  test_searchReferences_LocalVariableElement_inForEachElement_inBlock() async {
    await resolveTestCode('''
Object f() {
  {
    return [
      for (var v in []) v,
    ];
  }
}
''');
    var element = findElement.localVar('v');
    await assertElementReferencesText(element, r'''
self::@function::f
  54 4:25 |v| READ
''');
  }

  test_searchReferences_LocalVariableElement_inForEachElement_inFunctionBody() async {
    await resolveTestCode('''
Object f() {
  return [
    for (var v in []) v,
  ];
}
''');
    var element = findElement.localVar('v');
    await assertElementReferencesText(element, r'''
self::@function::f
  46 3:23 |v| READ
''');
  }

  test_searchReferences_LocalVariableElement_inForEachElement_topLevel() async {
    await resolveTestCode('''
var x = [
  for (var v in []) v,
];
''');
    var element = findElement.localVar('v');
    await assertElementReferencesText(element, r'''
self::@topLevelVariable::x
  30 2:21 |v| READ
''');
  }

  test_searchReferences_LocalVariableElement_inForEachLoop() async {
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
    var element = findElement.localVar('v');
    await assertElementReferencesText(element, r'''
self::@function::main
  35 3:5 |v| WRITE
  46 4:5 |v| READ_WRITE
  58 5:5 |v| READ
  65 6:5 |v| READ
''');
  }

  test_searchReferences_LocalVariableElement_inPackage() async {
    var aaaPackageRootPath = '$packagesRootPath/aaa';
    var testPath = convertPath('$aaaPackageRootPath/lib/a.dart');

    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: aaaPackageRootPath),
    );

    fileForContextSelection = testFile;

    await resolveFileCode(testPath, '''
main() {
  var v;
  v = 1;
  v += 2;
  v;
  v();
}
''');
    var element = findElement.localVar('v');
    await assertElementReferencesText(element, r'''
self::@function::main
  20 3:3 |v| WRITE
  29 4:3 |v| READ_WRITE
  39 5:3 |v| READ
  44 6:3 |v| READ
''');
  }

  test_searchReferences_macroGenerated_references() async {
    if (!configureWithCommonMacros()) {
      return;
    }

    await resolveTestCode('''
import 'append.dart';

class A {}

@DeclareInLibrary('void f() { A; }')
class B {
  void foo() { A; }
}
''');

    var element = findElement.class_('A');
    await assertElementReferencesText(element, r'''
self::@class::B::@method::foo
  97 7:16 |A| REFERENCE
self::@fragment::package:test/test.macro.dart::@function::f
  46 3:12 |A| REFERENCE
''');
  }

  test_searchReferences_MethodElement_class() async {
    await resolveTestCode('''
class A {
  m() {}
  main() {
    m();
    this.m();
    m;
    this.m;
  }
}
''');
    var element = findElement.method('m');
    await assertElementReferencesText(element, r'''
self::@class::A::@method::main
  34 4:5 |m| INVOCATION
  48 5:10 |m| INVOCATION qualified
  57 6:5 |m| REFERENCE
  69 7:10 |m| REFERENCE qualified
''');
  }

  test_searchReferences_MethodElement_enum() async {
    await resolveTestCode('''
enum E {
  v;
  void foo() {}
  void bar() {
    foo();
    this.foo();
  }
}

void f(E e) {
  e.foo();
  e.foo;
}
''');
    var element = findElement.method('foo');
    await assertElementReferencesText(element, r'''
self::@enum::E::@method::bar
  49 5:5 |foo| INVOCATION
  65 6:10 |foo| INVOCATION qualified
self::@function::f
  97 11:5 |foo| INVOCATION qualified
  108 12:5 |foo| REFERENCE qualified
''');
  }

  test_searchReferences_MethodElement_extension_instance() async {
    await resolveTestCode('''
extension E on int {
  void foo() {}

  void bar() {
    foo();
    this.foo();
    foo;
    this.foo;
  }
}

main() {
  E(0).foo();
  0.foo();
  E(0).foo;
  0.foo;
}
''');
    var element = findElement.method('foo');
    await assertElementReferencesText(element, r'''
self::@extension::E::@method::bar
  57 5:5 |foo| INVOCATION
  73 6:10 |foo| INVOCATION qualified
  84 7:5 |foo| REFERENCE
  98 8:10 |foo| REFERENCE qualified
self::@function::main
  126 13:8 |foo| INVOCATION qualified
  137 14:5 |foo| INVOCATION qualified
  151 15:8 |foo| REFERENCE qualified
  160 16:5 |foo| REFERENCE qualified
''');
  }

  test_searchReferences_MethodElement_extension_named() async {
    await resolveTestCode('''
extension E on int {
  void foo() {}

  void bar() {
    foo();
    this.foo();
    foo;
    this.foo;
  }
}
''');
    var element = findElement.method('foo');
    await assertElementReferencesText(element, r'''
self::@extension::E::@method::bar
  57 5:5 |foo| INVOCATION
  73 6:10 |foo| INVOCATION qualified
  84 7:5 |foo| REFERENCE
  98 8:10 |foo| REFERENCE qualified
''');
  }

  test_searchReferences_MethodElement_extension_static() async {
    await resolveTestCode('''
extension E on int {
  static void foo() {}

  static void bar() {
    foo();
    foo;
  }
}

main() {
  E.foo();
  E.foo;
}
''');
    var element = findElement.method('foo');
    await assertElementReferencesText(element, r'''
self::@extension::E::@method::bar
  71 5:5 |foo| INVOCATION
  82 6:5 |foo| REFERENCE
self::@function::main
  107 11:5 |foo| INVOCATION qualified
  118 12:5 |foo| REFERENCE qualified
''');
  }

  test_searchReferences_MethodElement_extension_unnamed() async {
    await resolveTestCode('''
extension on int {
  void foo() {}

  void bar() {
    foo();
    this.foo();
    foo;
    this.foo;
  }
}
''');
    var element = findElement.method('foo');
    await assertElementReferencesText(element, r'''
self::@extension::0::@method::bar
  55 5:5 |foo| INVOCATION
  71 6:10 |foo| INVOCATION qualified
  82 7:5 |foo| REFERENCE
  96 8:10 |foo| REFERENCE qualified
''');
  }

  test_searchReferences_MethodElement_extensionType() async {
    await resolveTestCode('''
extension type E(int it) {
  void foo() {}

  void bar() {
    foo();
  }
}

void f(E e) {
  e.foo();
}
''');
    var element = findElement.method('foo');
    await assertElementReferencesText(element, r'''
self::@extensionType::E::@method::bar
  63 5:5 |foo| INVOCATION
self::@function::f
  95 10:5 |foo| INVOCATION qualified
''');
  }

  test_searchReferences_MethodMember_class() async {
    await resolveTestCode('''
class A<T> {
  T m() => null;
}
main(A<int> a) {
  a.m();
}
''');
    var element = findElement.method('m');
    await assertElementReferencesText(element, r'''
self::@function::main
  53 5:5 |m| INVOCATION qualified
''');
  }

  test_searchReferences_ParameterElement_ofConstructor_super_named() async {
    await resolveTestCode('''
class A {
  A({required int a});
}
class B extends A {
  B({required super.a});
}
''');
    var element = findElement.unnamedConstructor('A').parameter('a');
    await assertElementReferencesText(element, r'''
self::@class::B::@constructor::new::@parameter::a
  75 5:21 |a| REFERENCE qualified
''');
  }

  test_searchReferences_ParameterElement_ofConstructor_super_positional() async {
    await resolveTestCode('''
class A {
  A(int a);
}
class B extends A {
  B(super.a);
}
''');
    var element = findElement.unnamedConstructor('A').parameter('a');
    await assertElementReferencesText(element, r'''
self::@class::B::@constructor::new::@parameter::a
  54 5:11 |a| REFERENCE qualified
''');
  }

  test_searchReferences_ParameterElement_optionalNamed() async {
    await resolveTestCode('''
foo({p}) {
  p = 1;
  p += 2;
  p;
  p();
}
main() {
  foo(p: 42);
}
''');
    var element = findElement.parameter('p');
    await assertElementReferencesText(element, r'''
self::@function::foo
  13 2:3 |p| WRITE
  22 3:3 |p| READ_WRITE
  32 4:3 |p| READ
  37 5:3 |p| READ
self::@function::main
  59 8:7 |p| REFERENCE qualified
''');
  }

  test_searchReferences_ParameterElement_optionalNamed_anywhere() async {
    await resolveTestCode('''
foo(int a, int b, {p}) {
  p;
}
main() {
  foo(0, p: 1, 2);
}
''');
    var element = findElement.parameter('p');
    await assertElementReferencesText(element, r'''
self::@function::foo
  27 2:3 |p| READ
self::@function::main
  50 5:10 |p| REFERENCE qualified
''');
  }

  test_searchReferences_ParameterElement_optionalPositional() async {
    await resolveTestCode('''
foo([p]) {
  p = 1;
  p += 2;
  p;
  p();
}
main() {
  foo(42);
}
''');
    var element = findElement.parameter('p');
    await assertElementReferencesText(element, r'''
self::@function::foo
  13 2:3 |p| WRITE
  22 3:3 |p| READ_WRITE
  32 4:3 |p| READ
  37 5:3 |p| READ
self::@function::main
  59 8:7 || REFERENCE qualified
''');
  }

  test_searchReferences_ParameterElement_requiredNamed() async {
    await resolveTestCode('''
foo({required int p}) {
  p = 1;
  p += 2;
  p;
  p();
}
main() {
  foo(p: 42);
}
''');
    var element = findElement.parameter('p');
    await assertElementReferencesText(element, r'''
self::@function::foo
  26 2:3 |p| WRITE
  35 3:3 |p| READ_WRITE
  45 4:3 |p| READ
  50 5:3 |p| READ
self::@function::main
  72 8:7 |p| REFERENCE qualified
''');
  }

  test_searchReferences_ParameterElement_requiredPositional_ofConstructor() async {
    await resolveTestCode('''
class C {
  var f;
  C(p) : f = p + 1 {
    p = 2;
    p += 3;
    p;
    p();
  }
}
main() {
  new C(42);
}
''');
    var element = findElement.parameter('p');
    await assertElementReferencesText(element, r'''
self::@class::C::@constructor::new
  32 3:14 |p| READ
  44 4:5 |p| WRITE
  55 5:5 |p| READ_WRITE
  67 6:5 |p| READ
  74 7:5 |p| READ
''');
  }

  test_searchReferences_ParameterElement_requiredPositional_ofLocalFunction() async {
    await resolveTestCode('''
main() {
  foo(p) {
    p = 1;
    p += 2;
    p;
    p();
  }
  foo(42);
}
''');
    var element = findElement.parameter('p');
    await assertElementReferencesText(element, r'''
self::@function::main
  24 3:5 |p| WRITE
  35 4:5 |p| READ_WRITE
  47 5:5 |p| READ
  54 6:5 |p| READ
''');
  }

  test_searchReferences_ParameterElement_requiredPositional_ofMethod() async {
    await resolveTestCode('''
class C {
  foo(p) {
    p = 1;
    p += 2;
    p;
    p();
  }
}
main(C c) {
  c.foo(42);
}
''');
    var element = findElement.parameter('p');
    await assertElementReferencesText(element, r'''
self::@class::C::@method::foo
  25 3:5 |p| WRITE
  36 4:5 |p| READ_WRITE
  48 5:5 |p| READ
  55 6:5 |p| READ
''');
  }

  test_searchReferences_ParameterElement_requiredPositional_ofTopLevelFunction() async {
    await resolveTestCode('''
foo(p) {
  p = 1;
  p += 2;
  p;
  p();
}
main() {
  foo(42);
}
''');
    var element = findElement.parameter('p');
    await assertElementReferencesText(element, r'''
self::@function::foo
  11 2:3 |p| WRITE
  20 3:3 |p| READ_WRITE
  30 4:3 |p| READ
  35 5:3 |p| READ
''');
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
    var element = findElement.prefix('ppp');
    await assertElementReferencesText(element, r'''
self::@fragment::package:test/my_part.dart::@topLevelVariable::c
  16 2:1 |ppp| REFERENCE
self::@function::main
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
    var element = findElement.prefix('prefix');
    await assertElementReferencesText(element, r'''
self::@function::f
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

    var element = findElement.prefix('ppp');
    await assertElementReferencesText(element, r'''
self::@function::main
  76 5:3 |ppp| REFERENCE
  92 6:3 |ppp| REFERENCE
self::@fragment::package:aaa/my_part.dart::@topLevelVariable::c
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
    var element = findElement.class_('_C');
    await assertElementReferencesText(element, r'''
self::@fragment::package:test/part1.dart::@topLevelVariable::v1
  13 1:14 |_C| REFERENCE
self::@fragment::package:test/part2.dart::@topLevelVariable::v2
  13 1:14 |_C| REFERENCE
self::@topLevelVariable::v
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

    var element = findElement.partFind('package:test/part1.dart').class_('_C');
    await assertElementReferencesText(element, r'''
self::@fragment::package:test/part1.dart::@topLevelVariable::v1
  25 3:1 |_C| REFERENCE
self::@fragment::package:test/part2.dart::@topLevelVariable::v2
  13 1:14 |_C| REFERENCE
self::@topLevelVariable::v
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

    var element = findElement.class_('_C');
    await assertElementReferencesText(element, r'''
self::@topLevelVariable::v
  63 5:1 |_C| REFERENCE
self::@fragment::package:aaa/part1.dart::@topLevelVariable::v1
  13 1:14 |_C| REFERENCE
self::@fragment::package:aaa/part2.dart::@topLevelVariable::v2
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
    var element = findElement.getter('foo');
    await assertElementReferencesText(element, r'''
self::@extension::E::@method::bar
  61 5:5 |foo| REFERENCE
  75 6:10 |foo| REFERENCE qualified
self::@function::main
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
    var element = findElement.setter('foo');
    await assertElementReferencesText(element, r'''
self::@extension::E::@method::bar
  61 5:5 |foo| REFERENCE
  79 6:10 |foo| REFERENCE qualified
self::@function::main
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
    var element = findElement.getter('ggg');
    await assertElementReferencesText(element, r'''
self::@class::A::@method::main
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
    var element = findElement.setter('s');
    await assertElementReferencesText(element, r'''
self::@class::A::@method::main
  39 4:5 |s| REFERENCE
  55 5:10 |s| REFERENCE qualified
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
    var element = findElement
        .importFind('package:test/lib.dart', mustBeUnique: false)
        .topVar('V');
    await assertElementReferencesText(element, r'''
self
  23 1:24 |V| REFERENCE qualified
self::@function::main
  69 4:8 |V| WRITE qualified
  83 5:8 |V| READ qualified
  93 6:8 |V| READ qualified
  100 7:3 |V| WRITE
  109 8:3 |V| READ
  114 9:3 |V| READ
''');
  }

  test_searchReferences_TypeAliasElement() async {
    await resolveTestCode('''
class A<T> {
  static int field = 0;
  static void method() {}
}

typedef B = A<int>;

class C extends B {}

void f(B p) {
  B v;
  B.field = 1;
  B.field;
  B.method();
}
''');

    var element = findElement.typeAlias('B');
    await assertElementReferencesText(element, r'''
self::@class::C
  103 8:17 |B| REFERENCE
self::@function::f::@parameter::p
  116 10:8 |B| REFERENCE
self::@function::f
  125 11:3 |B| REFERENCE
  132 12:3 |B| REFERENCE
  147 13:3 |B| REFERENCE
  158 14:3 |B| REFERENCE
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

    var element = findElement.typeAlias('B');
    await assertElementReferencesText(element, r'''
self::@function::f
  49 6:3 |B| REFERENCE
''');
  }

  test_searchReferences_TypeParameterElement_ofClass() async {
    await resolveTestCode('''
class A<T> {
  foo(T a) {}
  bar(T b) {}
}
''');
    var element = findElement.typeParameter('T');
    await assertElementReferencesText(element, r'''
self::@class::A::@method::foo::@parameter::a
  19 2:7 |T| REFERENCE
self::@class::A::@method::bar::@parameter::b
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
    var element = findElement.typeParameter('T');
    await assertElementReferencesText(element, r'''
self::@enum::E::@field::a
  25 3:9 |T| REFERENCE
self::@enum::E::@method::foo::@parameter::b
  41 4:12 |T| REFERENCE
''');
  }

  test_searchReferences_TypeParameterElement_ofLocalFunction() async {
    await resolveTestCode('''
main() {
  void foo<T>(T a) {
    void bar(T b) {}
  }
}
''');
    var element = findElement.typeParameter('T');
    await assertElementReferencesText(element, r'''
self::@function::main
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
    var element = findElement.typeParameter('T');
    await assertElementReferencesText(element, r'''
self::@class::A::@method::foo::@parameter::p
  19 2:10 |T| REFERENCE
''');
  }

  test_searchReferences_TypeParameterElement_ofTopLevelFunction() async {
    await resolveTestCode('''
foo<T>(T a) {
  bar(T b) {}
}
''');
    var element = findElement.typeParameter('T');
    await assertElementReferencesText(element, r'''
self::@function::foo::@parameter::a
  7 1:8 |T| REFERENCE
self::@function::foo
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
self::@function::f
  29 3:3 |v| WRITE
  38 4:3 |v| READ_WRITE
  48 5:3 |v| READ
  53 6:3 |v| READ
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
self::@function::f
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
self::@function::f
  57 3:5 |v| READ
  64 4:5 |v| WRITE
''');
  }

  test_searchReferences_VariablePatternElement_patternAssignment() async {
    await resolveTestCode('''
void f() {
  int v;
  (v, _) = (0, 1);
  v;
}
''');
    var element = findElement.localVar('v');
    await assertElementReferencesText(element, r'''
self::@function::f
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
self::@function::f
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
self::@topLevelVariable::f
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
self::@function::f
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
self::@function::f
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
    var element = findElement.class_('T');
    await assertElementReferencesText(element, r'''
self::@class::A
  27 2:17 |T| REFERENCE
self::@class::B
  54 3:23 |T| REFERENCE
self::@class::C
  76 4:20 |T| REFERENCE
''');
  }

  test_searchSubtypes_mixinDeclaration() async {
    await resolveTestCode('''
class T {}
mixin A on T {}
mixin B implements T {}
''');
    var element = findElement.class_('T');
    await assertElementReferencesText(element, r'''
self::@mixin::A
  22 2:12 |T| REFERENCE
self::@mixin::B
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
    var a = findElement.class_('A');

    // Search by 'type'.
    List<SubtypeResult> subtypes =
        await driver.search.subtypes(SearchedFiles(), type: a);
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
      List<SubtypeResult> subtypes =
          await driver.search.subtypes(SearchedFiles(), subtype: b);
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
    ClassElement aClass = aLibraryResult.element.getClass('A')!;

    // Search by 'type'.
    List<SubtypeResult> subtypes =
        await driver.search.subtypes(SearchedFiles(), type: aClass);
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

    var aaaFilePath = convertPath('$aaaPackageRootPath/lib/a.dart');
    var bbbFilePath = convertPath('$bbbPackageRootPath/lib/b.dart');
    var cccFilePath = convertPath('$cccPackageRootPath/lib/c.dart');

    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: aaaPackageRootPath)
        ..add(name: 'bbb', rootPath: bbbPackageRootPath),
    );

    addTestFile('class T implements List {}');
    newFile(aaaFilePath, 'class A implements List {}');
    newFile(bbbFilePath, 'class B implements List {}');
    newFile(cccFilePath, 'class C implements List {}');

    var coreLibResult =
        await driver.getLibraryByUri('dart:core') as LibraryElementResult;
    ClassElement listElement = coreLibResult.element.getClass('List')!;

    var searchedFiles = SearchedFiles();
    var results = await driver.search.subTypes(listElement, searchedFiles);

    void assertHasResult(String path, String name, {bool not = false}) {
      var matcher = contains(predicate((SearchResult r) {
        var element = r.enclosingElement;
        return element.name == name && element.source!.fullName == path;
      }));
      expect(results, not ? isNot(matcher) : matcher);
    }

    assertHasResult(testFile.path, 'T');
    assertHasResult(aaaFilePath, 'A');
    assertHasResult(bbbFilePath, 'B');
    assertHasResult(cccFilePath, 'C', not: true);
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
    var a = findElement.class_('A');

    List<SubtypeResult> subtypes =
        await driver.search.subtypes(SearchedFiles(), type: a);
    expect(subtypes, hasLength(2));

    SubtypeResult b = subtypes.singleWhere((r) => r.name == 'B');
    SubtypeResult c = subtypes.singleWhere((r) => r.name == 'C');

    expect(b.id, endsWith('b.dart;B'));
    expect(c.id, endsWith('c.dart;C'));
  }

  test_subtypes_class_macroGenerated() async {
    if (!configureWithCommonMacros()) {
      return;
    }

    await resolveTestCode('''
import 'append.dart';

class A {}

@DeclareTypesPhase('C', """
class C extends A {
  void methodC() {}
}
""")
class B extends A {
  void methodB() {}
}
''');
    var A = findElement.class_('A');

    // Search by 'type'.
    var subtypes = await driver.search.subtypes(
      SearchedFiles(),
      type: A,
    );
    expect(subtypes, hasLength(2));

    var B = subtypes.singleWhere((r) => r.name == 'B');
    var C = subtypes.singleWhere((r) => r.name == 'C');

    expect(B.libraryUri, testUriStr);
    expect(B.id, '$testUriStr;$testUriStr;B');
    expect(B.members, ['methodB']);

    expect(C.libraryUri, testUriStr);
    expect(C.id, 'package:test/test.dart;package:test/test.macro.dart;C');
    expect(C.members, ['methodC']);
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
      type: findElement.class_('A'),
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
      type: findElement.class_('A'),
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
      type: findElement.extensionType('A'),
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
    var a = findElement.class_('A');
    var b = findElement.class_('B');

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
    var a = findElement.class_('A');
    var b = findElement.class_('B');
    var c = findElement.mixin('C');
    var d = findElement.typeAlias('D');
    var f = findElement.function('f');
    var g = findElement.topVar('g');
    RegExp regExp = RegExp(r'^[ABCDfg]$');
    expect(await driver.search.topLevelElements(regExp),
        unorderedEquals([a, b, c, d, f, g]));
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
    var selfUriStr = '${result.uri}';

    String referenceToString(Reference reference) {
      var name = reference.name;
      if (name == selfUriStr) {
        name = 'self';
      }

      var parent = reference.parent ??
          (throw StateError('Should not go past libraries'));

      // A library.
      if (parent.parent == null) {
        return name;
      }

      // A unit of the self library.
      if (parent.name == '@fragment' && name == 'self') {
        return 'self';
      }

      return '${referenceToString(parent)}::$name';
    }

    String elementToReferenceString(Element element) {
      var enclosingElement = element.enclosingElement3;
      var reference = (element as ElementImpl).reference;
      if (reference != null) {
        return referenceToString(reference);
      } else if (element is ParameterElement) {
        var enclosingStr = enclosingElement != null
            ? elementToReferenceString(enclosingElement)
            : 'root';
        return '$enclosingStr::@parameter::${element.name}';
      } else {
        return '${element.name}@${element.nameOffset}';
      }
    }

    var analysisSession = result.session;

    var groups = results
        .groupListsBy((result) => result.enclosingElement)
        .entries
        .map((e) {
      var enclosingElement = e.key;
      return _GroupToPrint(
        enclosingElement: enclosingElement,
        enclosingElementStr: elementToReferenceString(enclosingElement),
        results: e.value.sortedBy<num>((e) => e.offset),
      );
    }).sorted((first, second) {
      var firstPath = first.path;
      var secondPath = second.path;
      var byPath = firstPath.compareTo(secondPath);
      if (byPath != 0) {
        return byPath;
      }
      return first.results.first.offset - second.results.first.offset;
    });

    var buffer = StringBuffer();
    for (var group in groups) {
      var unitPath = group.path;
      var unitResult = analysisSession.getParsedUnit(unitPath);
      unitResult as ParsedUnitResult;
      buffer.writeln(group.enclosingElementStr);
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
}

class _GroupToPrint {
  final Element enclosingElement;
  final String enclosingElementStr;
  final List<SearchResult> results;

  _GroupToPrint({
    required this.enclosingElement,
    required this.enclosingElementStr,
    required this.results,
  });

  String get path {
    return enclosingElement
        .thisOrAncestorOfType<CompilationUnitElement>()!
        .source
        .fullName;
  }
}
