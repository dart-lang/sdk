// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/search.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/test_utilities/find_element.dart';
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

class ExpectedResult {
  final Element enclosingElement;
  final SearchResultKind kind;
  final int offset;
  final int length;
  final bool isResolved;
  final bool isQualified;

  ExpectedResult(this.enclosingElement, this.kind, this.offset, this.length,
      {this.isResolved = true, this.isQualified = false});

  @override
  bool operator ==(Object result) {
    return result is SearchResult &&
        result.kind == kind &&
        result.isResolved == isResolved &&
        result.isQualified == isQualified &&
        result.offset == offset &&
        result.length == length &&
        result.enclosingElement == enclosingElement;
  }

  @override
  String toString() {
    StringBuffer buffer = StringBuffer();
    buffer.write("ExpectedResult(kind=");
    buffer.write(kind);
    buffer.write(", enclosingElement=");
    buffer.write(enclosingElement);
    buffer.write(", offset=");
    buffer.write(offset);
    buffer.write(", length=");
    buffer.write(length);
    buffer.write(", isResolved=");
    buffer.write(isResolved);
    buffer.write(", isQualified=");
    buffer.write(isQualified);
    buffer.write(")");
    return buffer.toString();
  }
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
      null,
      null,
    ).compute();

    // Ensure only one result for an SDK class, and that the file was tracked as searched.
    var declarations = results.declarations;
    expect(declarations.where((element) => element.name == 'Duration'),
        hasLength(1));
  }
}

@reflectiveTest
class SearchTest extends PubPackageResolutionTest {
  AnalysisDriver get driver => driverFor(testFile);

  String get testUriStr => 'package:test/test.dart';

  Future<void> assertElementReferencesText(
    Element element,
    String expected,
  ) async {
    var actual = await _getElementReferencesText(element);
    if (actual != expected) {
      actual;
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
    var a = findElement.class_('A');
    var b = findElement.class_('B');

    expect(await _findClassMembers('test'),
        unorderedEquals([a.methods[0], b.fields[0]]));
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
    var a = findElement.mixin('A');
    var b = findElement.mixin('B');
    expect(await _findClassMembers('test'),
        unorderedEquals([a.methods[0], b.fields[0]]));
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
    var searchFuture =
        FindDeclarations([driver], results, null, null).compute(token);
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
    await FindDeclarations([driver], results, null, null).compute();
    var declarations = results.declarations;
    declarations.assertHas('C', DeclarationKind.CLASS,
        offset: 6, codeOffset: 0, codeLength: 91);
    declarations.assertHas('f', DeclarationKind.FIELD,
        offset: 16, codeOffset: 12, codeLength: 5, className: 'C');
    declarations.assertHas('named', DeclarationKind.CONSTRUCTOR,
        offset: 30, codeOffset: 28, codeLength: 10, className: 'C');
    declarations.assertHas('g', DeclarationKind.GETTER,
        offset: 49, codeOffset: 41, codeLength: 15, className: 'C');
    declarations.assertHas('s', DeclarationKind.SETTER,
        offset: 68, codeOffset: 59, codeLength: 16, className: 'C');
    declarations.assertHas('m', DeclarationKind.METHOD,
        offset: 83, codeOffset: 78, codeLength: 11, className: 'C');
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

    newFile(aaaFilePath, 'class A {}');
    newFile(bbbFilePath, 'class B {}');
    newFile(cccFilePath, 'class C {}');

    await resolveTestCode('class T {}');

    var results = WorkspaceSymbols();
    await FindDeclarations([driver], results, null, null).compute();
    var declarations = results.declarations;

    declarations.assertHas('T', DeclarationKind.CLASS);
    declarations.assertHas('A', DeclarationKind.CLASS);
    declarations.assertHas('B', DeclarationKind.CLASS);
    declarations.assertNo('C');
  }

  test_declarations_enum() async {
    await resolveTestCode('''
enum E {
  a, bb, ccc
}
''');

    var results = WorkspaceSymbols();
    await FindDeclarations([driver], results, null, null).compute();
    var declarations = results.declarations;

    declarations.assertHas('E', DeclarationKind.ENUM,
        offset: 5, codeOffset: 0, codeLength: 23);
    declarations.assertHas('a', DeclarationKind.ENUM_CONSTANT,
        offset: 11, codeOffset: 11, codeLength: 1);
    declarations.assertHas('bb', DeclarationKind.ENUM_CONSTANT,
        offset: 14, codeOffset: 14, codeLength: 2);
    declarations.assertHas('ccc', DeclarationKind.ENUM_CONSTANT,
        offset: 18, codeOffset: 18, codeLength: 3);
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
    await FindDeclarations([driver], results, null, null).compute();
    var declarations = results.declarations;
    declarations.assertHas('E', DeclarationKind.EXTENSION,
        offset: 10, codeOffset: 0, codeLength: 82);
    declarations.assertHas('f', DeclarationKind.FIELD,
        offset: 27, codeOffset: 23, codeLength: 5);
    declarations.assertHas('g', DeclarationKind.GETTER,
        offset: 40, codeOffset: 32, codeLength: 15);
    declarations.assertHas('s', DeclarationKind.SETTER,
        offset: 59, codeOffset: 50, codeLength: 16);
    declarations.assertHas('m', DeclarationKind.METHOD,
        offset: 74, codeOffset: 69, codeLength: 11);
  }

  test_declarations_maxResults() async {
    await resolveTestCode('''
class A {}
class B {}
class C {}
''');
    var results = WorkspaceSymbols();
    await FindDeclarations([driver], results, null, 2).compute();
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
    await FindDeclarations([driver], results, null, null).compute();
    var declarations = results.declarations;
    declarations.assertHas('M', DeclarationKind.MIXIN,
        offset: 6, codeOffset: 0, codeLength: 71);
    declarations.assertHas('f', DeclarationKind.FIELD,
        offset: 16, codeOffset: 12, codeLength: 5, mixinName: 'M');
    declarations.assertHas('g', DeclarationKind.GETTER,
        offset: 29, codeOffset: 21, codeLength: 15, mixinName: 'M');
    declarations.assertHas('s', DeclarationKind.SETTER,
        offset: 48, codeOffset: 39, codeLength: 16, mixinName: 'M');
    declarations.assertHas('m', DeclarationKind.METHOD,
        offset: 63, codeOffset: 58, codeLength: 11, mixinName: 'M');
  }

  test_declarations_onlyForFile() async {
    newFile('$testPackageLibPath/a.dart', 'class A {}');
    var b = newFile('$testPackageLibPath/b.dart', 'class B {}').path;

    var results = WorkspaceSymbols();
    await FindDeclarations([driver], results, null, null, onlyForFile: b)
        .compute();
    var declarations = results.declarations;

    expect(results.files, [b]);

    declarations.assertNo('A');
    declarations.assertHas('B', DeclarationKind.CLASS);
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
    await FindDeclarations([driver], results, null, null).compute();
    var declarations = results.declarations;

    var declaration = declarations.assertHas('C', DeclarationKind.CLASS);
    expect(declaration.parameters, isNull);

    declaration =
        declarations.assertHas('g', DeclarationKind.GETTER, className: 'C');
    expect(declaration.parameters, isNull);

    declaration =
        declarations.assertHas('m', DeclarationKind.METHOD, className: 'C');
    expect(declaration.parameters, '(int a, double b)');

    declaration = declarations.assertHas('f', DeclarationKind.FUNCTION);
    expect(declaration.parameters, '(bool a, String b)');
  }

  test_declarations_parameters_functionTyped() async {
    await resolveTestCode('''
void f1(bool a(int b, String c)) {}
void f2(a(b, c)) {}
void f3(bool Function(int a, String b) c) {}
void f4(bool Function(int, String) a) {}
''');
    var results = WorkspaceSymbols();
    await FindDeclarations([driver], results, null, null).compute();
    var declarations = results.declarations;

    var declaration = declarations.assertHas('f1', DeclarationKind.FUNCTION);
    expect(declaration.parameters, '(bool Function(int, String) a)');

    declaration = declarations.assertHas('f2', DeclarationKind.FUNCTION);
    expect(declaration.parameters, '(dynamic Function(dynamic, dynamic) a)');

    declaration = declarations.assertHas('f3', DeclarationKind.FUNCTION);
    expect(declaration.parameters, '(bool Function(int, String) c)');

    declaration = declarations.assertHas('f4', DeclarationKind.FUNCTION);
    expect(declaration.parameters, '(bool Function(int, String) a)');
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
    await FindDeclarations([driver], results, null, null).compute();
    var declarations = results.declarations;

    var declaration =
        declarations.assertHas('m1', DeclarationKind.METHOD, className: 'A');
    expect(declaration.parameters, '(Map<int, String> a)');

    declaration =
        declarations.assertHas('m2', DeclarationKind.METHOD, className: 'A');
    expect(declaration.parameters, '(Map<T, U> a)');

    declaration =
        declarations.assertHas('m3', DeclarationKind.METHOD, className: 'A');
    expect(declaration.parameters, '(Map<Map<T2, U2>, Map<U1, T>> a)');
  }

  test_declarations_regExp() async {
    await resolveTestCode('''
class A {}
class B {}
class C {}
class D {}
''');
    var results = WorkspaceSymbols();
    await FindDeclarations([driver], results, RegExp(r'[A-C]'), null).compute();
    var declarations = results.declarations;

    declarations.assertHas('A', DeclarationKind.CLASS);
    declarations.assertHas('B', DeclarationKind.CLASS);
    declarations.assertHas('C', DeclarationKind.CLASS);
    declarations.assertNo('D');
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
    await FindDeclarations([driver], results, null, null).compute();
    var declarations = results.declarations;

    declarations.assertHas('g', DeclarationKind.GETTER,
        offset: 8, codeOffset: 0, codeLength: 15);
    declarations.assertHas('s', DeclarationKind.SETTER,
        offset: 25, codeOffset: 16, codeLength: 16);
    declarations.assertHas(
      'f',
      DeclarationKind.FUNCTION,
      offset: 38,
      codeOffset: 33,
      codeLength: 16,
    );
    declarations.assertHas('v', DeclarationKind.VARIABLE,
        offset: 54, codeOffset: 50, codeLength: 5);
    declarations.assertHas('tf1', DeclarationKind.TYPE_ALIAS,
        offset: 70, codeOffset: 57, codeLength: 19);
    declarations.assertHas('tf2', DeclarationKind.TYPE_ALIAS,
        offset: 85, codeOffset: 77, codeLength: 45);
  }

  test_issue49951_references_dontAddToKnown_unrelated() async {
    final myRoot = newFolder('$workspaceRootPath/packages/my');

    final myFile = newFile('${myRoot.path}/lib/my.dart', r'''
class A {}
''');

    // Configure `package:my`.
    writePackageConfig(
      getFile('${myRoot.path}/.dart_tool/package_config.json').path,
      PackageConfigFileBuilder()..add(name: 'my', rootPath: myRoot.path),
    );

    final myDriver = driverFor(myFile);
    final mySession = contextFor(myFile).currentSession;
    final libraryElementResult =
        await mySession.getLibraryByUri('package:my/my.dart');
    libraryElementResult as LibraryElementResult;

    final A = libraryElementResult.element.getClass('A')!;

    final searchedFiles = SearchedFiles();
    searchedFiles.ownAnalyzed(myDriver.search);

    final testDriver = driverFor(testFile);

    // No references, but this is not the most important.
    final references = await testDriver.search.references(A, searchedFiles);
    expect(references, isEmpty);

    // We should not add the file to known files. It is not in the
    // `package:test` itself, and not in a package from its package config.
    // So, it is absolutely unrelated to `package:test`.
    for (final knowFile in testDriver.fsState.knownFiles) {
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
    await _verifyNameReferences('test', []);
  }

  test_searchMemberReferences_qualified_unresolved() async {
    await resolveTestCode('''
main(p) {
  print(p.test);
  p.test = 1;
  p.test += 2;
  p.test();
}
''');
    var main = findElement.function('main');
    await _verifyNameReferences('test', <ExpectedResult>[
      _expectIdQU(main, SearchResultKind.READ, 'test);'),
      _expectIdQU(main, SearchResultKind.WRITE, 'test = 1;'),
      _expectIdQU(main, SearchResultKind.READ_WRITE, 'test += 2;'),
      _expectIdQU(main, SearchResultKind.INVOCATION, 'test();'),
    ]);
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
    await _verifyNameReferences('test', []);
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
    var main = findElement.method('main');
    await _verifyNameReferences('test', <ExpectedResult>[
      _expectIdU(main, SearchResultKind.READ, 'test);'),
      _expectIdU(main, SearchResultKind.WRITE, 'test = 1;'),
      _expectIdU(main, SearchResultKind.READ_WRITE, 'test += 2;'),
      _expectIdU(main, SearchResultKind.INVOCATION, 'test();'),
    ]);
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
    final element = findElement.getter('foo');
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
    final element = findElement.method('foo');
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

    final element = findElement.importFind('dart:math').class_('Random');
    await assertElementReferencesText(element, r'''
self::@variable::v1
  20 2:1 |Random| REFERENCE
self::@variable::v2
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
    final element = findElement.class_('A');
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
self::@variable::v2
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
    final element = findNode.simple('A p').staticElement!;
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
    final element = findElement.enum_('MyEnum');
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
    final element = findElement.class_('A');
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
    final element = findElement.class_('A');
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
    final element = findElement.mixin('A');
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

    final element = findElement.class_('B');
    await assertElementReferencesText(element, r'''
self::@function::f
  44 7:4 |B| REFERENCE
''');
  }

  test_searchReferences_CompilationUnitElement() async {
    newFile('$testPackageLibPath/foo.dart', '');
    await resolveTestCode('''
import 'foo.dart';
export 'foo.dart';
''');
    final element = findElement.importFind('package:test/foo.dart').unitElement;
    await assertElementReferencesText(element, r'''
self
  7 1:8 |'foo.dart'| REFERENCE qualified
  26 2:8 |'foo.dart'| REFERENCE qualified
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
    final element = findElement.constructor('named');
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

    final element = findElement.constructor('named');
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
    final element = findElement.unnamedConstructor('A');
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
    final element = findElement.unnamedConstructor('A');
    await assertElementReferencesText(element, r'''
package:test/other.dart::@unit::package:test/other.dart::@function::f
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
    final element = findElement.unnamedConstructor('A');
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
    final element = findElement.constructor('named');
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
    final element = findElement.unnamedConstructor('E');
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
    final element = findElement.unnamedConstructor('E');
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
    final element = findElement.extension_('E');
    await assertElementReferencesText(element, r'''
self::@function::main
  74 7:3 |E| REFERENCE
  88 8:3 |E| REFERENCE
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
    final element = findElement.field('field');
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
    final element = findElement.field('field');
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
    final element = findElement.field('field');
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
    final index = typeProvider.enumElement!.getField('index')!;
    await assertElementReferencesText(index, r'''
self::@function::main
  46 5:12 |index| READ qualified
''');

    final values = findElement.field('values');
    await assertElementReferencesText(values, r'''
self::@function::main
  62 6:10 |values| READ qualified
''');

    final A = findElement.field('A');
    await assertElementReferencesText(A, r'''
self::@function::main
  44 5:10 |A| READ qualified
  79 7:10 |A| READ qualified
''');

    final B = findElement.field('B');
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
    final element = findElement.function('test');
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
    final element = findElement.localFunction('test');
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
    final element = findElement.import('dart:math', mustBeUnique: false);
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

    final element = findElement.import('dart:math');
    await assertElementReferencesText(element, r'''
self::@function::main
  111 4:3 || REFERENCE
  121 5:7 || REFERENCE
  133 6:3 || REFERENCE
self::@function::bar
  146 8:1 || REFERENCE
''');
  }

  test_searchReferences_ImportElement_noPrefix_optIn_fromOptOut() async {
    newFile('$testPackageLibPath/a.dart', r'''
class N1 {}
void N2() {}
int get N3 => 0;
set N4(int _) {}
''');

    await resolveTestCode('''
// @dart = 2.7
import 'a.dart';

main() {
  N1;
  N2();
  N3;
  N4 = 0;
}
''');
    final element = findElement.import('package:test/a.dart');
    await assertElementReferencesText(element, r'''
self::@function::main
  44 5:3 || REFERENCE
  50 6:3 || REFERENCE
  58 7:3 || REFERENCE
  64 8:3 || REFERENCE
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
    final element = findElement.import('dart:math', mustBeUnique: false);
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
  p.Random;
  p.Future;
}
''');
    {
      final element = findElement.import('dart:async');
      await assertElementReferencesText(element, r'''
self::@function::main
  74 5:3 |p.| REFERENCE
''');
    }
    {
      final element = findElement.import('dart:math');
      await assertElementReferencesText(element, r'''
self::@function::main
  62 4:3 |p.| REFERENCE
''');
    }
  }

  test_searchReferences_ImportElement_withPrefix_optIn_fromOptOut() async {
    newFile('$testPackageLibPath/a.dart', r'''
class N1 {}
void N2() {}
int get N3 => 0;
set N4(int _) {}
''');

    await resolveTestCode('''
// @dart = 2.7
import 'a.dart' as a;

main() {
  a.N1;
  a.N2();
  a.N3;
  a.N4 = 0;
}
''');
    final element = findElement.import('package:test/a.dart');
    await assertElementReferencesText(element, r'''
self::@function::main
  49 5:3 |a.| REFERENCE
  57 6:3 |a.| REFERENCE
  67 7:3 |a.| REFERENCE
  75 8:3 |a.| REFERENCE
''');
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
    final element = findElement.label('label');
    await assertElementReferencesText(element, r'''
self::@function::main
  61 5:13 |label| REFERENCE
  84 7:11 |label| REFERENCE
''');
  }

  test_searchReferences_LibraryElement() async {
    newFile('$testPackageLibPath/unitA.dart', 'part of lib;');
    newFile('$testPackageLibPath/unitB.dart', 'part of lib;');
    await resolveTestCode('''
library lib;
part 'unitA.dart';
part 'unitB.dart';
''');
    final element = result.libraryElement;
    await assertElementReferencesText(element, r'''
self::@unit::package:test/unitA.dart
  8 1:9 |lib| REFERENCE
self::@unit::package:test/unitB.dart
  8 1:9 |lib| REFERENCE
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
    final element = result.libraryElement;
    await assertElementReferencesText(element, r'''
self::@unit::package:aaa/unitA.dart
  8 1:9 |lib| REFERENCE
self::@unit::package:aaa/unitB.dart
  8 1:9 |lib| REFERENCE
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
    final element = findElement.localVar('v');
    await assertElementReferencesText(element, r'''
self::@function::main
  20 3:3 |v| WRITE
  29 4:3 |v| READ_WRITE
  39 5:3 |v| READ
  44 6:3 |v| READ
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
    final element = findElement.localVar('v');
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
    final element = findElement.localVar('v');
    await assertElementReferencesText(element, r'''
self::@function::main
  20 3:3 |v| WRITE
  29 4:3 |v| READ_WRITE
  39 5:3 |v| READ
  44 6:3 |v| READ
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
    final element = findElement.method('m');
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
    final element = findElement.method('foo');
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
    final element = findElement.method('foo');
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
    final element = findElement.method('foo');
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
    final element = findElement.method('foo');
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
    final element = findElement.method('foo');
    await assertElementReferencesText(element, r'''
self::@extension::0::@method::bar
  55 5:5 |foo| INVOCATION
  71 6:10 |foo| INVOCATION qualified
  82 7:5 |foo| REFERENCE
  96 8:10 |foo| REFERENCE qualified
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
    final element = findElement.method('m');
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
    final element = findElement.unnamedConstructor('A').parameter('a');
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
    final element = findElement.unnamedConstructor('A').parameter('a');
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
    final element = findElement.parameter('p');
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
    final element = findElement.parameter('p');
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
    final element = findElement.parameter('p');
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
    final element = findElement.parameter('p');
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
    final element = findElement.parameter('p');
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
    final element = findElement.parameter('p');
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
    final element = findElement.parameter('p');
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
    final element = findElement.parameter('p');
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
    final element = findElement.prefix('ppp');
    await assertElementReferencesText(element, r'''
self::@unit::package:test/my_part.dart::@variable::c
  16 2:1 |ppp| REFERENCE
self::@function::main
  76 5:3 |ppp| REFERENCE
  92 6:3 |ppp| REFERENCE
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

    final element = findElement.prefix('ppp');
    await assertElementReferencesText(element, r'''
self::@function::main
  76 5:3 |ppp| REFERENCE
  92 6:3 |ppp| REFERENCE
self::@unit::package:aaa/my_part.dart::@variable::c
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
    final element = findElement.class_('_C');
    await assertElementReferencesText(element, r'''
self::@unit::package:test/part1.dart::@variable::v1
  13 1:14 |_C| REFERENCE
self::@unit::package:test/part2.dart::@variable::v2
  13 1:14 |_C| REFERENCE
self::@variable::v
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

    final element =
        findElement.partFind('package:test/part1.dart').class_('_C');
    await assertElementReferencesText(element, r'''
self::@unit::package:test/part1.dart::@variable::v1
  25 3:1 |_C| REFERENCE
self::@unit::package:test/part2.dart::@variable::v2
  13 1:14 |_C| REFERENCE
self::@variable::v
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

    final element = findElement.class_('_C');
    await assertElementReferencesText(element, r'''
self::@variable::v
  63 5:1 |_C| REFERENCE
self::@unit::package:aaa/part1.dart::@variable::v1
  13 1:14 |_C| REFERENCE
self::@unit::package:aaa/part2.dart::@variable::v2
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
    final element = findElement.getter('foo');
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
    final element = findElement.setter('foo');
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
    final element = findElement.getter('ggg');
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
    final element = findElement.setter('s');
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
    final element = findElement
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

    final element = findElement.typeAlias('B');
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

  test_searchReferences_TypeAliasElement_fromLegacy() async {
    newFile('$testPackageLibPath/a.dart', r'''
typedef A<T> = Map<int, T>;
''');
    await resolveTestCode('''
// @dart = 2.9
import 'a.dart';

void f(A<String> a) {}
''');

    final element =
        findElement.importFind('package:test/a.dart').typeAlias('A');
    await assertElementReferencesText(element, r'''
self::@function::f::@parameter::a
  40 4:8 |A| REFERENCE
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

    final element = findElement.typeAlias('B');
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
    final element = findElement.typeParameter('T');
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
    final element = findElement.typeParameter('T');
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
    final element = findElement.typeParameter('T');
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
    final element = findElement.typeParameter('T');
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
    final element = findElement.typeParameter('T');
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
    final element = findNode.bindPatternVariableElement('v) =');
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
    final element = findNode.bindPatternVariableElement('v)');
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
    final element = findNode.bindPatternVariableElement('v]');
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
    final element = findElement.localVar('v');
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
    final element = findNode.bindPatternVariableElement('int v');
    await assertElementReferencesText(element, r'''
self::@function::f
  49 2:14 |v| READ
  58 2:23 |v| READ
  67 2:32 |v| WRITE
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
    final element = findNode.bindPatternVariableElement('int v when');
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
    final element = findNode.bindPatternVariableElement('int v when');
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
    final element = findElement.class_('T');
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
    final element = findElement.class_('T');
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
        final element = r.enclosingElement;
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

  ExpectedResult _expectId(
      Element enclosingElement, SearchResultKind kind, String search,
      {int? length, bool isResolved = true, bool isQualified = false}) {
    int offset = findNode.offset(search);
    length ??= findNode.simple(search).length;
    return ExpectedResult(enclosingElement, kind, offset, length,
        isResolved: isResolved, isQualified: isQualified);
  }

  /// Create [ExpectedResult] for a qualified and unresolved match.
  ExpectedResult _expectIdQU(
      Element element, SearchResultKind kind, String search,
      {int? length}) {
    return _expectId(element, kind, search,
        isQualified: true, isResolved: false, length: length);
  }

  /// Create [ExpectedResult] for a unqualified and unresolved match.
  ExpectedResult _expectIdU(
      Element element, SearchResultKind kind, String search,
      {int? length}) {
    return _expectId(element, kind, search,
        isQualified: false, isResolved: false, length: length);
  }

  Future<List<Element>> _findClassMembers(String name) {
    var searchedFiles = SearchedFiles();
    return driver.search.classMembers(name, searchedFiles);
  }

  Future<String> _getElementReferencesText(Element element) async {
    final selfUriStr = '${result.uri}';

    String referenceToString(Reference reference) {
      var name = reference.name;
      if (name == selfUriStr) {
        name = 'self';
      }

      final parent = reference.parent ??
          (throw StateError('Should not go past libraries'));

      // A library.
      if (parent.parent == null) {
        return name;
      }

      // A unit of the self library.
      if (parent.name == '@unit' && name == 'self') {
        return 'self';
      }

      return '${referenceToString(parent)}::$name';
    }

    String elementToReferenceString(Element element) {
      final enclosingElement = element.enclosingElement;
      final reference = (element as ElementImpl).reference;
      if (reference != null) {
        return referenceToString(reference);
      } else if (element is ParameterElement) {
        final enclosingStr = enclosingElement != null
            ? elementToReferenceString(enclosingElement)
            : 'root';
        return '$enclosingStr::@parameter::${element.name}';
      } else {
        return '${element.name}@${element.nameOffset}';
      }
    }

    final searchedFiles = SearchedFiles();
    final results = await driver.search.references(element, searchedFiles);

    final analysisSession = result.session;

    final groups = results
        .groupListsBy((result) => result.enclosingElement)
        .entries
        .map((e) {
      final enclosingElement = e.key;
      return _GroupToPrint(
        enclosingElement: enclosingElement,
        enclosingElementStr: elementToReferenceString(enclosingElement),
        results: e.value.sortedBy<num>((e) => e.offset),
      );
    }).sorted((first, second) {
      final firstPath = first.path;
      final secondPath = second.path;
      final byPath = firstPath.compareTo(secondPath);
      if (byPath != 0) {
        return byPath;
      }
      return first.results.first.offset - second.results.first.offset;
    });

    final buffer = StringBuffer();
    for (final group in groups) {
      final unitPath = group.path;
      final unitResult = analysisSession.getParsedUnit(unitPath);
      unitResult as ParsedUnitResult;
      buffer.writeln(group.enclosingElementStr);
      for (final result in group.results) {
        final offset = result.offset;
        final length = result.length;
        final end = offset + length;
        final location = unitResult.lineInfo.getLocation(offset);
        final snippet = unitResult.content.substring(offset, end);

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

  Future<void> _verifyNameReferences(
      String name, List<ExpectedResult> expectedMatches) async {
    var searchedFiles = SearchedFiles();
    List<SearchResult> results =
        await driver.search.unresolvedMemberReferences(name, searchedFiles);
    _assertResults(results, expectedMatches);
    expect(results, hasLength(expectedMatches.length));
  }

  static void _assertResults(
      List<SearchResult> matches, List<ExpectedResult> expectedMatches) {
    expect(matches, unorderedEquals(expectedMatches));
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

extension on List<Declaration> {
  Declaration assertHas(String name, DeclarationKind kind,
      {int? offset,
      int? codeOffset,
      int? codeLength,
      String? className,
      String? mixinName}) {
    for (var declaration in this) {
      if (declaration.name == name &&
          declaration.kind == kind &&
          (offset == null || declaration.offset == offset) &&
          (codeOffset == null || declaration.codeOffset == codeOffset) &&
          (codeLength == null || declaration.codeLength == codeLength) &&
          declaration.className == className &&
          declaration.mixinName == mixinName) {
        return declaration;
      }
    }
    var actual =
        map((d) => '(name=${d.name}, kind=${d.kind}, offset=${d.offset}, '
            'codeOffset=${d.codeOffset}, codeLength=${d.codeLength}, '
            'className=${d.className}, mixinName=${d.mixinName})').join('\n');
    fail('Expected to find (name=$name, kind=$kind, offset=$offset, '
        'codeOffset=$codeOffset, codeLength=$codeLength) in\n$actual');
  }

  void assertNo(String name) {
    for (var declaration in this) {
      if (declaration.name == name) {
        fail('Unexpected declaration $name');
      }
    }
  }
}
