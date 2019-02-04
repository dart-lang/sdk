// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart' hide Declaration;
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/search.dart';
import 'package:analyzer/src/dart/ast/element_locator.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/generated/testing/element_search.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SearchTest);
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
      {this.isResolved: true, this.isQualified: false});

  bool operator ==(Object result) {
    return result is SearchResult &&
        result.kind == this.kind &&
        result.isResolved == this.isResolved &&
        result.isQualified == this.isQualified &&
        result.offset == this.offset &&
        result.length == this.length &&
        result.enclosingElement == this.enclosingElement;
  }

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
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
class SearchTest extends BaseAnalysisDriverTest {
  static const testUri = 'package:test/test.dart';

  CompilationUnit testUnit;
  CompilationUnitElement testUnitElement;
  LibraryElement testLibraryElement;

  test_classMembers_class() async {
    await _resolveTestUnit('''
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
    ClassElement a = _findElement('A');
    ClassElement b = _findElement('B');
    expect(await driver.search.classMembers('test'),
        unorderedEquals([a.methods[0], b.fields[0]]));
  }

  test_classMembers_importNotDart() async {
    await _resolveTestUnit('''
import 'not-dart.txt';
''');
    expect(await driver.search.classMembers('test'), isEmpty);
  }

  test_classMembers_mixin() async {
    await _resolveTestUnit('''
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
    ClassElement a = _findElement('A');
    ClassElement b = _findElement('B');
    expect(await driver.search.classMembers('test'),
        unorderedEquals([a.methods[0], b.fields[0]]));
  }

  test_declarations_class() async {
    await _resolveTestUnit('''
class C {
  int f;
  C();
  C.named();
  int get g => 0;
  void set s(_) {}
  void m() {}
}
''');
    var files = new LinkedHashSet<String>();
    List<Declaration> declarations =
        await driver.search.declarations(null, null, files);
    _assertHasDeclaration(declarations, 'C', DeclarationKind.CLASS,
        offset: 6, codeOffset: 0, codeLength: 91);
    _assertHasDeclaration(declarations, 'f', DeclarationKind.FIELD,
        offset: 16, codeOffset: 12, codeLength: 5, className: 'C');
    _assertHasDeclaration(declarations, '', DeclarationKind.CONSTRUCTOR,
        offset: 21, codeOffset: 21, codeLength: 4, className: 'C');
    _assertHasDeclaration(declarations, 'named', DeclarationKind.CONSTRUCTOR,
        offset: 30, codeOffset: 28, codeLength: 10, className: 'C');
    _assertHasDeclaration(declarations, 'g', DeclarationKind.GETTER,
        offset: 49, codeOffset: 41, codeLength: 15, className: 'C');
    _assertHasDeclaration(declarations, 's', DeclarationKind.SETTER,
        offset: 68, codeOffset: 59, codeLength: 16, className: 'C');
    _assertHasDeclaration(declarations, 'm', DeclarationKind.METHOD,
        offset: 83, codeOffset: 78, codeLength: 11, className: 'C');
  }

  test_declarations_discover() async {
    var t = convertPath('/test/lib/t.dart');
    var a = convertPath('/aaa/lib/a.dart');
    var b = convertPath('/bbb/lib/b.dart');
    var c = convertPath('/ccc/lib/c.dart');

    newFile(t, content: 'class T {}');
    newFile(a, content: 'class A {}');
    newFile(b, content: 'class B {}');
    newFile(c, content: 'class C {}');

    driver.addFile(t);

    var files = new LinkedHashSet<String>();
    var declarations = await driver.search.declarations(null, null, files);
    _assertHasDeclaration(declarations, 'T', DeclarationKind.CLASS);
    _assertHasDeclaration(declarations, 'A', DeclarationKind.CLASS);
    _assertHasDeclaration(declarations, 'B', DeclarationKind.CLASS);
    _assertNoDeclaration(declarations, 'C');
  }

  test_declarations_duplicateFile() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');

    newFile(a, content: 'class A {}');
    newFile(b, content: 'class B {}');

    driver.addFile(a);
    driver.addFile(b);

    var files = new LinkedHashSet<String>();
    files.add(b);

    var declarations = await driver.search.declarations(null, null, files);
    _assertHasDeclaration(declarations, 'A', DeclarationKind.CLASS);
    _assertNoDeclaration(declarations, 'B');
  }

  test_declarations_enum() async {
    await _resolveTestUnit('''
enum E {
  a, bb, ccc
}
''');
    var files = new LinkedHashSet<String>();
    List<Declaration> declarations =
        await driver.search.declarations(null, null, files);
    _assertHasDeclaration(declarations, 'E', DeclarationKind.ENUM,
        offset: 5, codeOffset: 0, codeLength: 23);
    _assertHasDeclaration(declarations, 'a', DeclarationKind.ENUM_CONSTANT,
        offset: 11, codeOffset: 11, codeLength: 1);
    _assertHasDeclaration(declarations, 'bb', DeclarationKind.ENUM_CONSTANT,
        offset: 14, codeOffset: 14, codeLength: 2);
    _assertHasDeclaration(declarations, 'ccc', DeclarationKind.ENUM_CONSTANT,
        offset: 18, codeOffset: 18, codeLength: 3);
  }

  test_declarations_maxResults() async {
    await _resolveTestUnit('''
class A {}
class B {}
class C {}
''');
    var files = new LinkedHashSet<String>();
    List<Declaration> declarations =
        await driver.search.declarations(null, 2, files);
    expect(declarations, hasLength(2));
  }

  test_declarations_mixin() async {
    await _resolveTestUnit('''
mixin M {
  int f;
  int get g => 0;
  void set s(_) {}
  void m() {}
}
''');
    var files = new LinkedHashSet<String>();
    List<Declaration> declarations =
        await driver.search.declarations(null, null, files);
    _assertHasDeclaration(declarations, 'M', DeclarationKind.MIXIN,
        offset: 6, codeOffset: 0, codeLength: 71);
    _assertHasDeclaration(declarations, 'f', DeclarationKind.FIELD,
        offset: 16, codeOffset: 12, codeLength: 5, mixinName: 'M');
    _assertHasDeclaration(declarations, 'g', DeclarationKind.GETTER,
        offset: 29, codeOffset: 21, codeLength: 15, mixinName: 'M');
    _assertHasDeclaration(declarations, 's', DeclarationKind.SETTER,
        offset: 48, codeOffset: 39, codeLength: 16, mixinName: 'M');
    _assertHasDeclaration(declarations, 'm', DeclarationKind.METHOD,
        offset: 63, codeOffset: 58, codeLength: 11, mixinName: 'M');
  }

  test_declarations_onlyForFile() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    newFile(a, content: 'class A {}');
    newFile(b, content: 'class B {}');

    driver.addFile(a);
    driver.addFile(b);

    var files = new LinkedHashSet<String>();
    List<Declaration> declarations =
        await driver.search.declarations(null, null, files, onlyForFile: b);

    expect(files, [b]);

    _assertNoDeclaration(declarations, 'A');
    _assertHasDeclaration(declarations, 'B', DeclarationKind.CLASS);
  }

  test_declarations_parameters() async {
    await _resolveTestUnit('''
class C {
  int get g => 0;
  void m(int a, double b) {}
}
void f(bool a, String b) {}
typedef F(int a);
typedef T F2<T, U>(U a);
''');
    var files = new LinkedHashSet<String>();
    List<Declaration> declarations =
        await driver.search.declarations(null, null, files);

    Declaration declaration;

    declaration =
        _assertHasDeclaration(declarations, 'C', DeclarationKind.CLASS);
    expect(declaration.parameters, isNull);

    declaration = _assertHasDeclaration(
        declarations, 'g', DeclarationKind.GETTER,
        className: 'C');
    expect(declaration.parameters, isNull);

    declaration = _assertHasDeclaration(
        declarations, 'm', DeclarationKind.METHOD,
        className: 'C');
    expect(declaration.parameters, '(int a, double b)');

    declaration =
        _assertHasDeclaration(declarations, 'f', DeclarationKind.FUNCTION);
    expect(declaration.parameters, '(bool a, String b)');

    declaration = _assertHasDeclaration(
        declarations, 'F', DeclarationKind.FUNCTION_TYPE_ALIAS);
    expect(declaration.parameters, '(int a)');

    declaration = _assertHasDeclaration(
        declarations, 'F2', DeclarationKind.FUNCTION_TYPE_ALIAS);
    expect(declaration.parameters, '(U a)');
  }

  test_declarations_parameters_functionTyped() async {
    await _resolveTestUnit('''
void f1(bool a(int b, String c)) {}
void f2(a(b, c)) {}
void f3(bool Function(int a, String b) c) {}
void f4(bool Function(int, String) a) {}
''');
    var files = new LinkedHashSet<String>();
    List<Declaration> declarations =
        await driver.search.declarations(null, null, files);

    Declaration declaration;

    declaration =
        _assertHasDeclaration(declarations, 'f1', DeclarationKind.FUNCTION);
    expect(declaration.parameters, '(bool a(int b, String c))');

    declaration =
        _assertHasDeclaration(declarations, 'f2', DeclarationKind.FUNCTION);
    expect(declaration.parameters, '(a(b, c))');

    declaration =
        _assertHasDeclaration(declarations, 'f3', DeclarationKind.FUNCTION);
    expect(declaration.parameters, '(bool Function(int a, String b) c)');

    declaration =
        _assertHasDeclaration(declarations, 'f4', DeclarationKind.FUNCTION);
    expect(declaration.parameters, '(bool Function(int, String) a)');
  }

  test_declarations_parameters_typeArguments() async {
    await _resolveTestUnit('''
class A<T, T2> {
  void m1(Map<int, String> a) {}
  void m2<U>(Map<T, U> a) {}
  void m3<U1, U2>(Map<Map<T2, U2>, Map<U1, T>> a) {}
}
''');
    var files = new LinkedHashSet<String>();
    List<Declaration> declarations =
        await driver.search.declarations(null, null, files);

    Declaration declaration;

    declaration = _assertHasDeclaration(
        declarations, 'm1', DeclarationKind.METHOD,
        className: 'A');
    expect(declaration.parameters, '(Map<int, String> a)');

    declaration = _assertHasDeclaration(
        declarations, 'm2', DeclarationKind.METHOD,
        className: 'A');
    expect(declaration.parameters, '(Map<T, U> a)');

    declaration = _assertHasDeclaration(
        declarations, 'm3', DeclarationKind.METHOD,
        className: 'A');
    expect(declaration.parameters, '(Map<Map<T2, U2>, Map<U1, T>> a)');
  }

  test_declarations_regExp() async {
    await _resolveTestUnit('''
class A {}
class B {}
class C {}
class D {}
''');
    var files = new LinkedHashSet<String>();
    List<Declaration> declarations =
        await driver.search.declarations(new RegExp(r'[A-C]'), null, files);
    _assertHasDeclaration(declarations, 'A', DeclarationKind.CLASS);
    _assertHasDeclaration(declarations, 'B', DeclarationKind.CLASS);
    _assertHasDeclaration(declarations, 'C', DeclarationKind.CLASS);
    _assertNoDeclaration(declarations, 'D');
  }

  test_declarations_top() async {
    await _resolveTestUnit('''
int get g => 0;
void set s(_) {}
void f(int p) {}
int v;
typedef void tf1();
typedef tf2<T> = int Function<S>(T tp, S sp);
''');
    var files = new LinkedHashSet<String>();
    List<Declaration> declarations =
        await driver.search.declarations(null, null, files);
    _assertHasDeclaration(declarations, 'g', DeclarationKind.GETTER,
        offset: 8, codeOffset: 0, codeLength: 15);
    _assertHasDeclaration(declarations, 's', DeclarationKind.SETTER,
        offset: 25, codeOffset: 16, codeLength: 16);
    _assertHasDeclaration(
      declarations,
      'f',
      DeclarationKind.FUNCTION,
      offset: 38,
      codeOffset: 33,
      codeLength: 16,
    );
    _assertHasDeclaration(declarations, 'v', DeclarationKind.VARIABLE,
        offset: 54, codeOffset: 50, codeLength: 5);
    _assertHasDeclaration(
        declarations, 'tf1', DeclarationKind.FUNCTION_TYPE_ALIAS,
        offset: 70, codeOffset: 57, codeLength: 19);
    _assertHasDeclaration(
        declarations, 'tf2', DeclarationKind.FUNCTION_TYPE_ALIAS,
        offset: 85, codeOffset: 77, codeLength: 45);
    // No declaration for type variables.
    _assertNoDeclaration(declarations, 'T');
    _assertNoDeclaration(declarations, 'S');
    // No declarations for parameters.
    _assertNoDeclaration(declarations, '_');
    _assertNoDeclaration(declarations, 'p');
    _assertNoDeclaration(declarations, 'tp');
    _assertNoDeclaration(declarations, 'sp');
  }

  test_references_discover() async {
    var t = convertPath('/test/lib/t.dart');
    var a = convertPath('/aaa/lib/a.dart');
    var b = convertPath('/bbb/lib/b.dart');
    var c = convertPath('/ccc/lib/c.dart');

    newFile(t, content: 'List t;');
    newFile(a, content: 'List a;');
    newFile(b, content: 'List b;');
    newFile(c, content: 'List c;');

    driver.addFile(t);

    LibraryElement coreLib = await driver.getLibraryByUri('dart:core');
    ClassElement listElement = coreLib.getType('List');

    var searchedFiles = new SearchedFiles();
    var results = await driver.search.references(listElement, searchedFiles);

    void assertHasResult(String path, String name, {bool not: false}) {
      var matcher = contains(predicate((SearchResult r) {
        var element = r.enclosingElement;
        return element.name == name && element.source.fullName == path;
      }));
      expect(results, not ? isNot(matcher) : matcher);
    }

    assertHasResult(t, 't');
    assertHasResult(a, 'a');
    assertHasResult(b, 'b');
    assertHasResult(c, 'c', not: true);
  }

  test_references_discover_onlyOwned() async {
    var t = convertPath('/test/lib/t.dart');
    var a = convertPath('/aaa/lib/a.dart');
    var b = convertPath('/bbb/lib/b.dart');

    newFile(t, content: 'List t;');
    newFile(a, content: 'List a;');
    newFile(b, content: 'List b;');

    driver.addFile(t);
    driver.addFile(a);

    LibraryElement coreLib = await driver.getLibraryByUri('dart:core');
    ClassElement listElement = coreLib.getType('List');

    var searchedFiles = new SearchedFiles();

    // Make b.dart owned by a different driver.
    var driver2 = createAnalysisDriver();
    searchedFiles.add(b, driver2.search);

    var results = await driver.search.references(listElement, searchedFiles);

    void assertHasResult(String path, String name, {bool not: false}) {
      var matcher = contains(predicate((SearchResult r) {
        var element = r.enclosingElement;
        return element.name == name && element.source.fullName == path;
      }));
      expect(results, not ? isNot(matcher) : matcher);
    }

    assertHasResult(t, 't');
    assertHasResult(a, 'a');
    assertHasResult(b, 'b', not: true);
  }

  test_references_discover_onlyOwned_samePath() async {
    var p = convertPath('/test/lib/t.dart');
    newFile(p, content: 'int t;');

    var driver1 = createAnalysisDriver(packageMap: {
      'test': [newFolder('/test/lib')]
    });
    var driver2 = createAnalysisDriver(packageMap: {});

    var searchedFiles = new SearchedFiles();
    searchedFiles.ownAdded(driver1.search);
    searchedFiles.ownAdded(driver2.search); // does not own any file, but...

    // driver1 owns both path and URI.
    expect(searchedFiles.add(p, driver1.search), isTrue);

    // The path is already owned by driver1, so cannot be handled in driver2.
    expect(searchedFiles.add(p, driver2.search), isFalse);
  }

  test_references_discover_onlyOwned_sameUri() async {
    var a = convertPath('/aaa/lib/t.dart');
    var b = convertPath('/bbb/lib/t.dart');

    newFile(a, content: 'int t;');
    newFile(b, content: 'double t;');

    var driver1 = createAnalysisDriver(packageMap: {
      'ttt': [newFolder('/aaa/lib')]
    });
    var driver2 = createAnalysisDriver(packageMap: {
      'ttt': [newFolder('/bbb/lib')]
    });

    // driver1 owns `/aaa/lib/t.dart` with `package:ttt/t.dart`.
    driver1.addFile(a);

    var searchedFiles = new SearchedFiles();

    searchedFiles.ownAdded(driver1.search);
    searchedFiles.ownAdded(driver2.search); // does not own any file, but...

    // driver1 owns both path and URI.
    expect(searchedFiles.add(a, driver1.search), isTrue);

    // The URI is already owned by driver1, so cannot be handled in driver2.
    expect(searchedFiles.add(b, driver2.search), isFalse);
  }

  test_searchMemberReferences_qualified_resolved() async {
    await _resolveTestUnit('''
class C {
  var test;
}
main(C c) {
  print(c.test);
  c.test = 1;
  c.test += 2;
  c.test();
}
''');
    await _verifyNameReferences('test', []);
  }

  test_searchMemberReferences_qualified_unresolved() async {
    await _resolveTestUnit('''
main(p) {
  print(p.test);
  p.test = 1;
  p.test += 2;
  p.test();
}
''');
    Element main = _findElement('main');
    await _verifyNameReferences('test', <ExpectedResult>[
      _expectIdQU(main, SearchResultKind.READ, 'test);'),
      _expectIdQU(main, SearchResultKind.WRITE, 'test = 1;'),
      _expectIdQU(main, SearchResultKind.READ_WRITE, 'test += 2;'),
      _expectIdQU(main, SearchResultKind.INVOCATION, 'test();'),
    ]);
  }

  test_searchMemberReferences_unqualified_resolved() async {
    await _resolveTestUnit('''
class C {
  var test;
  main() {
    print(test);
    test = 1;
    test += 2;
    test();
  }
}
''');
    await _verifyNameReferences('test', []);
  }

  test_searchMemberReferences_unqualified_unresolved() async {
    await _resolveTestUnit('''
class C {
  main() {
    print(test);
    test = 1;
    test += 2;
    test();
  }
}
''');
    Element main = _findElement('main');
    await _verifyNameReferences('test', <ExpectedResult>[
      _expectIdU(main, SearchResultKind.READ, 'test);'),
      _expectIdU(main, SearchResultKind.WRITE, 'test = 1;'),
      _expectIdU(main, SearchResultKind.READ_WRITE, 'test += 2;'),
      _expectIdU(main, SearchResultKind.INVOCATION, 'test();'),
    ]);
  }

  test_searchReferences_ClassElement_definedInSdk_declarationSite() async {
    await _resolveTestUnit('''
import 'dart:math';
Random v1;
Random v2;
''');

    // Find the Random class element in the SDK source.
    // IDEA performs search always at declaration, never at reference.
    ClassElement randomElement;
    {
      String randomPath = sdk.mapDartUri('dart:math').fullName;
      ResolvedUnitResult result = await driver.getResult(randomPath);
      randomElement = result.unit.declaredElement.getType('Random');
    }

    Element v1 = _findElement('v1');
    Element v2 = _findElement('v2');
    var expected = [
      _expectId(v1, SearchResultKind.REFERENCE, 'Random v1;'),
      _expectId(v2, SearchResultKind.REFERENCE, 'Random v2;'),
    ];
    await _verifyReferences(randomElement, expected);
  }

  test_searchReferences_ClassElement_definedInSdk_useSite() async {
    await _resolveTestUnit('''
import 'dart:math';
Random v1;
Random v2;
''');

    var v1 = _findElement('v1') as VariableElement;
    var v2 = _findElement('v2') as VariableElement;
    var randomElement = v1.type.element as ClassElement;
    var expected = [
      _expectId(v1, SearchResultKind.REFERENCE, 'Random v1;'),
      _expectId(v2, SearchResultKind.REFERENCE, 'Random v2;'),
    ];
    await _verifyReferences(randomElement, expected);
  }

  test_searchReferences_ClassElement_definedInside() async {
    await _resolveTestUnit('''
class A {};
main(A p) {
  A v;
}
class B1 extends A {} // extends
class B2 implements A {} // implements
class B3 extends Object with A {} // with
List<A> v2 = null;
''');
    ClassElement element = _findElementAtString('A {}');
    Element p = _findElement('p');
    Element main = _findElement('main');
    Element b1 = _findElement('B1');
    Element b2 = _findElement('B2');
    Element b3 = _findElement('B3');
    Element v2 = _findElement('v2');
    var expected = [
      _expectId(p, SearchResultKind.REFERENCE, 'A p'),
      _expectId(main, SearchResultKind.REFERENCE, 'A v'),
      _expectId(b1, SearchResultKind.REFERENCE, 'A {} // extends'),
      _expectId(b2, SearchResultKind.REFERENCE, 'A {} // implements'),
      _expectId(b3, SearchResultKind.REFERENCE, 'A {} // with'),
      _expectId(v2, SearchResultKind.REFERENCE, 'A> v2'),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_ClassElement_definedOutside() async {
    newFile('$testProject/lib.dart', content: r'''
class A {};
''');
    await _resolveTestUnit('''
import 'lib.dart';
main(A p) {
  A v;
}
''');
    ClassElement element = _findElementAtString('A p');
    Element p = _findElement('p');
    Element main = _findElement('main');
    var expected = [
      _expectId(p, SearchResultKind.REFERENCE, 'A p'),
      _expectId(main, SearchResultKind.REFERENCE, 'A v')
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_ClassElement_mixin() async {
    await _resolveTestUnit('''
mixin A {}
class B extends Object with A {} // with
''');
    ClassElement element = _findElementAtString('A {}');
    Element b = _findElement('B');
    var expected = [
      _expectId(b, SearchResultKind.REFERENCE, 'A {} // with'),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_CompilationUnitElement() async {
    newFile('$testProject/foo.dart');
    await _resolveTestUnit('''
import 'foo.dart'; // import
export 'foo.dart'; // export
''');
    CompilationUnitElement element =
        testLibraryElement.imports[0].importedLibrary.definingCompilationUnit;
    int uriLength = "'foo.dart'".length;
    var expected = [
      _expectIdQ(
          testUnitElement, SearchResultKind.REFERENCE, "'foo.dart'; // import",
          length: uriLength),
      _expectIdQ(
          testUnitElement, SearchResultKind.REFERENCE, "'foo.dart'; // export",
          length: uriLength),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_ConstructorElement_default() async {
    await _resolveTestUnit('''
class A {
  A() {}
}
main() {
  new A();
}
''');
    ConstructorElement element = _findElementAtString('A() {}');
    Element mainElement = _findElement('main');
    var expected = [
      _expectIdQ(mainElement, SearchResultKind.REFERENCE, '();', length: 0)
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_ConstructorElement_default_otherFile() async {
    String other = convertPath('$testProject/other.dart');
    String otherCode = '''
import 'test.dart';
main() {
  new A(); // in other
}
''';
    newFile(other, content: otherCode);
    driver.addFile(other);

    await _resolveTestUnit('''
class A {
  A() {}
}
''');
    ConstructorElement element = _findElementAtString('A() {}');

    CompilationUnit otherUnit = (await driver.getResult(other)).unit;
    Element main =
        resolutionMap.elementDeclaredByCompilationUnit(otherUnit).functions[0];
    var expected = [
      new ExpectedResult(main, SearchResultKind.REFERENCE,
          otherCode.indexOf('(); // in other'), 0,
          isResolved: true, isQualified: true)
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_ConstructorElement_named() async {
    await _resolveTestUnit('''
class A {
  A.named() {}
}
main() {
  new A.named();
}
''');
    ConstructorElement element = _findElement('named');
    Element mainElement = _findElement('main');
    var expected = [
      _expectIdQ(mainElement, SearchResultKind.REFERENCE, '.named();',
          length: '.named'.length)
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_ConstructorElement_synthetic() async {
    await _resolveTestUnit('''
class A {
}
main() {
  new A();
}
''');
    ClassElement classElement = _findElement('A');
    ConstructorElement element = classElement.unnamedConstructor;
    Element mainElement = _findElement('main');
    var expected = [
      _expectIdQ(mainElement, SearchResultKind.REFERENCE, '();', length: 0)
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_FieldElement() async {
    await _resolveTestUnit('''
class A {
  var field;
  A({this.field});
  main() {
    new A(field: 1);
    // getter
    print(field); // ref-nq
    print(this.field); // ref-q
    field(); // inv-nq
    this.field(); // inv-q
    // setter
    field = 2; // ref-nq;
    this.field = 3; // ref-q;
  }
}
''');
    FieldElement element = _findElement('field', ElementKind.FIELD);
    Element main = _findElement('main');
    Element fieldParameter = _findElement('field', ElementKind.PARAMETER);
    var expected = [
      _expectIdQ(fieldParameter, SearchResultKind.WRITE, 'field}'),
      _expectIdQ(main, SearchResultKind.REFERENCE, 'field: 1'),
      _expectId(main, SearchResultKind.READ, 'field); // ref-nq'),
      _expectIdQ(main, SearchResultKind.READ, 'field); // ref-q'),
      _expectId(main, SearchResultKind.INVOCATION, 'field(); // inv-nq'),
      _expectIdQ(main, SearchResultKind.INVOCATION, 'field(); // inv-q'),
      _expectId(main, SearchResultKind.WRITE, 'field = 2; // ref-nq'),
      _expectIdQ(main, SearchResultKind.WRITE, 'field = 3; // ref-q'),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_FieldElement_ofEnum() async {
    await _resolveTestUnit('''
enum MyEnum {
  A, B, C
}
main() {
  print(MyEnum.A.index);
  print(MyEnum.values);
  print(MyEnum.A);
  print(MyEnum.B);
}
''');
    ClassElement enumElement = _findElement('MyEnum');
    Element mainElement = _findElement('main');
    await _verifyReferences(enumElement.getField('index'),
        [_expectIdQ(mainElement, SearchResultKind.READ, 'index);')]);
    await _verifyReferences(enumElement.getField('values'),
        [_expectIdQ(mainElement, SearchResultKind.READ, 'values);')]);
    await _verifyReferences(enumElement.getField('A'), [
      _expectIdQ(mainElement, SearchResultKind.READ, 'A.index);'),
      _expectIdQ(mainElement, SearchResultKind.READ, 'A);')
    ]);
    await _verifyReferences(enumElement.getField('B'),
        [_expectIdQ(mainElement, SearchResultKind.READ, 'B);')]);
  }

  test_searchReferences_FieldElement_synthetic() async {
    await _resolveTestUnit('''
class A {
  get field => null;
  set field(x) {}
  main() {
    // getter
    print(field); // ref-nq
    print(this.field); // ref-q
    field(); // inv-nq
    this.field(); // inv-q
    // setter
    field = 2; // ref-nq;
    this.field = 3; // ref-q;
  }
}
''');
    FieldElement element = _findElement('field', ElementKind.FIELD);
    Element main = _findElement('main');
    var expected = [
      _expectId(main, SearchResultKind.READ, 'field); // ref-nq'),
      _expectIdQ(main, SearchResultKind.READ, 'field); // ref-q'),
      _expectId(main, SearchResultKind.INVOCATION, 'field(); // inv-nq'),
      _expectIdQ(main, SearchResultKind.INVOCATION, 'field(); // inv-q'),
      _expectId(main, SearchResultKind.WRITE, 'field = 2; // ref-nq'),
      _expectIdQ(main, SearchResultKind.WRITE, 'field = 3; // ref-q'),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_FunctionElement() async {
    await _resolveTestUnit('''
test() {}
main() {
  test();
  print(test);
}
''');
    FunctionElement element = _findElement('test');
    Element mainElement = _findElement('main');
    var expected = [
      _expectId(mainElement, SearchResultKind.INVOCATION, 'test();'),
      _expectId(mainElement, SearchResultKind.REFERENCE, 'test);')
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_FunctionElement_local() async {
    await _resolveTestUnit('''
main() {
  test() {}
  test();
  print(test);
}
''');
    FunctionElement element = findElementsByName(testUnit, 'test').single;
    Element main = _findElement('main');
    var expected = [
      _expectId(main, SearchResultKind.INVOCATION, 'test();'),
      _expectId(main, SearchResultKind.REFERENCE, 'test);')
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_ImportElement_noPrefix() async {
    await _resolveTestUnit('''
import 'dart:math' show max, PI, Random hide min;
export 'dart:math' show max, PI, Random hide min;
main() {
  print(PI);
  print(new Random());
  print(max(1, 2));
}
Random bar() => null;
''');
    ImportElement element = testLibraryElement.imports[0];
    Element mainElement = _findElement('main');
    Element barElement = _findElement('bar');
    var kind = SearchResultKind.REFERENCE;
    var expected = [
      _expectId(mainElement, kind, 'PI);', length: 0),
      _expectId(mainElement, kind, 'Random()', length: 0),
      _expectId(mainElement, kind, 'max(', length: 0),
      _expectId(barElement, kind, 'Random bar()', length: 0),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_ImportElement_noPrefix_inPackage() async {
    testFile = convertPath('/aaa/lib/a.dart');
    await _resolveTestUnit('''
import 'dart:math' show max, PI, Random hide min;
export 'dart:math' show max, PI, Random hide min;
main() {
  PI;
  new Random();
  max(1, 2);
}
Random bar() => null;
''', addToDriver: false);
    ImportElement element = testLibraryElement.imports[0];
    Element mainElement = _findElement('main');
    Element barElement = _findElement('bar');
    var kind = SearchResultKind.REFERENCE;
    var expected = [
      _expectId(mainElement, kind, 'PI;', length: 0),
      _expectId(mainElement, kind, 'Random();', length: 0),
      _expectId(mainElement, kind, 'max(1, 2);', length: 0),
      _expectId(barElement, kind, 'Random bar()', length: 0),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_ImportElement_withPrefix() async {
    await _resolveTestUnit('''
import 'dart:math' as math show max, PI, Random hide min;
export 'dart:math' show max, PI, Random hide min;
main() {
  print(math.PI);
  print(new math.Random());
  print(math.max(1, 2));
}
math.Random bar() => null;
''');
    ImportElement element = testLibraryElement.imports[0];
    Element mainElement = _findElement('main');
    Element barElement = _findElement('bar');
    var kind = SearchResultKind.REFERENCE;
    var length = 'math.'.length;
    var expected = [
      _expectId(mainElement, kind, 'math.PI);', length: length),
      _expectId(mainElement, kind, 'math.Random()', length: length),
      _expectId(mainElement, kind, 'math.max(', length: length),
      _expectId(barElement, kind, 'math.Random bar()', length: length),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_ImportElement_withPrefix_forMultipleImports() async {
    await _resolveTestUnit('''
import 'dart:async' as p;
import 'dart:math' as p;
main() {
  p.Random;
  p.Future;
}
''');
    Element mainElement = _findElement('main');
    var kind = SearchResultKind.REFERENCE;
    var length = 'p.'.length;
    {
      ImportElement element = testLibraryElement.imports[0];
      var expected = [
        _expectId(mainElement, kind, 'p.Future;', length: length),
      ];
      await _verifyReferences(element, expected);
    }
    {
      ImportElement element = testLibraryElement.imports[1];
      var expected = [
        _expectId(mainElement, kind, 'p.Random', length: length),
      ];
      await _verifyReferences(element, expected);
    }
  }

  test_searchReferences_LabelElement() async {
    await _resolveTestUnit('''
main() {
label:
  while (true) {
    if (true) {
      break label; // 1
    }
    break label; // 2
  }
}
''');
    Element element = findElementsByName(testUnit, 'label').single;
    Element main = _findElement('main');
    var expected = [
      _expectId(main, SearchResultKind.REFERENCE, 'label; // 1'),
      _expectId(main, SearchResultKind.REFERENCE, 'label; // 2')
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_LibraryElement() async {
    var codeA = 'part of lib; // A';
    var codeB = 'part of lib; // B';
    newFile('$testProject/unitA.dart', content: codeA);
    newFile('$testProject/unitB.dart', content: codeB);
    await _resolveTestUnit('''
library lib;
part 'unitA.dart';
part 'unitB.dart';
''');
    LibraryElement element = testLibraryElement;
    CompilationUnitElement unitElementA = element.parts[0];
    CompilationUnitElement unitElementB = element.parts[1];
    var expected = [
      new ExpectedResult(unitElementA, SearchResultKind.REFERENCE,
          codeA.indexOf('lib; // A'), 'lib'.length),
      new ExpectedResult(unitElementB, SearchResultKind.REFERENCE,
          codeB.indexOf('lib; // B'), 'lib'.length),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_LibraryElement_inPackage() async {
    testFile = convertPath('/aaa/lib/a.dart');
    var partPathA = convertPath('/aaa/lib/unitA.dart');
    var partPathB = convertPath('/aaa/lib/unitB.dart');

    var codeA = 'part of lib; // A';
    var codeB = 'part of lib; // B';
    newFile(partPathA, content: codeA);
    newFile(partPathB, content: codeB);
    await _resolveTestUnit('''
library lib;
part 'unitA.dart';
part 'unitB.dart';
''', addToDriver: false);
    LibraryElement element = testLibraryElement;
    CompilationUnitElement unitElementA = element.parts[0];
    CompilationUnitElement unitElementB = element.parts[1];
    var expected = [
      new ExpectedResult(unitElementA, SearchResultKind.REFERENCE,
          codeA.indexOf('lib; // A'), 'lib'.length),
      new ExpectedResult(unitElementB, SearchResultKind.REFERENCE,
          codeB.indexOf('lib; // B'), 'lib'.length),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_LocalVariableElement() async {
    await _resolveTestUnit(r'''
main() {
  var v;
  v = 1;
  v += 2;
  print(v);
  v();
}
''');
    Element element = findElementsByName(testUnit, 'v').single;
    Element main = _findElement('main');
    var expected = [
      _expectId(main, SearchResultKind.WRITE, 'v = 1;'),
      _expectId(main, SearchResultKind.READ_WRITE, 'v += 2;'),
      _expectId(main, SearchResultKind.READ, 'v);'),
      _expectId(main, SearchResultKind.INVOCATION, 'v();')
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_LocalVariableElement_inForEachLoop() async {
    await _resolveTestUnit('''
main() {
  for (var v in []) {
    v = 1;
    v += 2;
    print(v);
    v();
  }
}
''');
    Element element = findElementsByName(testUnit, 'v').single;
    Element main = _findElement('main');
    var expected = [
      _expectId(main, SearchResultKind.WRITE, 'v = 1;'),
      _expectId(main, SearchResultKind.READ_WRITE, 'v += 2;'),
      _expectId(main, SearchResultKind.READ, 'v);'),
      _expectId(main, SearchResultKind.INVOCATION, 'v();')
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_LocalVariableElement_inPackage() async {
    testFile = convertPath('/aaa/lib/a.dart');

    await _resolveTestUnit('''
main() {
  var v;
  v = 1;
  v += 2;
  print(v);
  v();
}
''', addToDriver: false);
    Element element = findElementsByName(testUnit, 'v').single;
    Element main = _findElement('main');

    var expected = [
      _expectId(main, SearchResultKind.WRITE, 'v = 1;'),
      _expectId(main, SearchResultKind.READ_WRITE, 'v += 2;'),
      _expectId(main, SearchResultKind.READ, 'v);'),
      _expectId(main, SearchResultKind.INVOCATION, 'v();')
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_MethodElement() async {
    await _resolveTestUnit('''
class A {
  m() {}
  main() {
    m(); // 1
    this.m(); // 2
    print(m); // 3
    print(this.m); // 4
  }
}
''');
    MethodElement method = _findElement('m');
    Element mainElement = _findElement('main');
    var expected = [
      _expectId(mainElement, SearchResultKind.INVOCATION, 'm(); // 1'),
      _expectIdQ(mainElement, SearchResultKind.INVOCATION, 'm(); // 2'),
      _expectId(mainElement, SearchResultKind.REFERENCE, 'm); // 3'),
      _expectIdQ(mainElement, SearchResultKind.REFERENCE, 'm); // 4')
    ];
    await _verifyReferences(method, expected);
  }

  test_searchReferences_MethodMember() async {
    await _resolveTestUnit('''
class A<T> {
  T m() => null;
}
main(A<int> a) {
  a.m(); // ref
}
''');
    MethodMember method = _findElementAtString('m(); // ref');
    Element mainElement = _findElement('main');
    var expected = [
      _expectIdQ(mainElement, SearchResultKind.INVOCATION, 'm(); // ref')
    ];
    await _verifyReferences(method, expected);
  }

  test_searchReferences_ParameterElement_named() async {
    await _resolveTestUnit('''
foo({p}) {
  p = 1;
  p += 2;
  print(p);
  p();
}
main() {
  foo(p: 42);
}
''');
    ParameterElement element = _findElement('p');
    Element fooElement = _findElement('foo');
    Element mainElement = _findElement('main');
    var expected = [
      _expectId(fooElement, SearchResultKind.WRITE, 'p = 1;'),
      _expectId(fooElement, SearchResultKind.READ_WRITE, 'p += 2;'),
      _expectId(fooElement, SearchResultKind.READ, 'p);'),
      _expectId(fooElement, SearchResultKind.INVOCATION, 'p();'),
      _expectIdQ(mainElement, SearchResultKind.REFERENCE, 'p: 42')
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_ParameterElement_ofConstructor() async {
    await _resolveTestUnit('''
class C {
  var f;
  C(p) : f = p + 1 {
    p = 2;
    p += 3;
    print(p);
    p();
  }
}
main() {
  new C(42);
}
''');
    ParameterElement element = _findElement('p');
    ClassElement classC = _findElement('C');
    ConstructorElement constructorA = classC.unnamedConstructor;
    var expected = [
      _expectId(constructorA, SearchResultKind.READ, 'p + 1 {'),
      _expectId(constructorA, SearchResultKind.WRITE, 'p = 2;'),
      _expectId(constructorA, SearchResultKind.READ_WRITE, 'p += 3;'),
      _expectId(constructorA, SearchResultKind.READ, 'p);'),
      _expectId(constructorA, SearchResultKind.INVOCATION, 'p();')
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_ParameterElement_ofLocalFunction() async {
    await _resolveTestUnit('''
main() {
  foo(p) {
    p = 1;
    p += 2;
    print(p);
    p();
  }
  foo(42);
}
''');
    Element main = _findElement('main');
    FunctionElement foo = findElementsByName(testUnit, 'foo').single;
    ParameterElement element = foo.parameters.single;
    var expected = [
      _expectId(main, SearchResultKind.WRITE, 'p = 1;'),
      _expectId(main, SearchResultKind.READ_WRITE, 'p += 2;'),
      _expectId(main, SearchResultKind.READ, 'p);'),
      _expectId(main, SearchResultKind.INVOCATION, 'p();')
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_ParameterElement_ofMethod() async {
    await _resolveTestUnit('''
class C {
  foo(p) {
    p = 1;
    p += 2;
    print(p);
    p();
  }
}
main(C c) {
  c.foo(42);
}
''');
    ParameterElement element = _findElement('p');
    Element fooElement = _findElement('foo');
    var expected = [
      _expectId(fooElement, SearchResultKind.WRITE, 'p = 1;'),
      _expectId(fooElement, SearchResultKind.READ_WRITE, 'p += 2;'),
      _expectId(fooElement, SearchResultKind.READ, 'p);'),
      _expectId(fooElement, SearchResultKind.INVOCATION, 'p();')
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_ParameterElement_ofTopLevelFunction() async {
    await _resolveTestUnit('''
foo(p) {
  p = 1;
  p += 2;
  print(p);
  p();
}
main() {
  foo(42);
}
''');
    ParameterElement element = _findElement('p');
    Element fooElement = _findElement('foo');
    var expected = [
      _expectId(fooElement, SearchResultKind.WRITE, 'p = 1;'),
      _expectId(fooElement, SearchResultKind.READ_WRITE, 'p += 2;'),
      _expectId(fooElement, SearchResultKind.READ, 'p);'),
      _expectId(fooElement, SearchResultKind.INVOCATION, 'p();')
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_ParameterElement_optionalPositional() async {
    await _resolveTestUnit('''
foo([p]) {
  p = 1;
  p += 2;
  print(p);
  p();
}
main() {
  foo(42);
}
''');
    ParameterElement element = _findElement('p');
    Element fooElement = _findElement('foo');
    Element mainElement = _findElement('main');
    var expected = [
      _expectId(fooElement, SearchResultKind.WRITE, 'p = 1;'),
      _expectId(fooElement, SearchResultKind.READ_WRITE, 'p += 2;'),
      _expectId(fooElement, SearchResultKind.READ, 'p);'),
      _expectId(fooElement, SearchResultKind.INVOCATION, 'p();'),
      _expectIdQ(mainElement, SearchResultKind.REFERENCE, '42', length: 0)
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_PrefixElement() async {
    String partCode = r'''
part of my_lib;
ppp.Future c;
''';
    newFile('$testProject/my_part.dart', content: partCode);
    await _resolveTestUnit('''
library my_lib;
import 'dart:async' as ppp;
part 'my_part.dart';
main() {
  ppp.Future a;
  ppp.Stream b;
}
''');
    PrefixElement element = _findElementAtString('ppp;');
    Element main = _findElement('main');
    Element c = findChildElement(testLibraryElement, 'c');
    var expected = [
      _expectId(main, SearchResultKind.REFERENCE, 'ppp.Future'),
      _expectId(main, SearchResultKind.REFERENCE, 'ppp.Stream'),
      new ExpectedResult(c, SearchResultKind.REFERENCE,
          partCode.indexOf('ppp.Future c'), 'ppp'.length)
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_PrefixElement_inPackage() async {
    testFile = convertPath('/aaa/lib/a.dart');
    var partPath = convertPath('/aaa/lib/my_part.dart');

    String partCode = r'''
part of my_lib;
ppp.Future c;
''';
    newFile(partPath, content: partCode);
    await _resolveTestUnit('''
library my_lib;
import 'dart:async' as ppp;
part 'my_part.dart';
main() {
  ppp.Future a;
  ppp.Stream b;
}
''', addToDriver: false);
    PrefixElement element = _findElementAtString('ppp;');
    Element main = _findElement('main');
    Element c = findChildElement(testLibraryElement, 'c');
    var expected = [
      _expectId(main, SearchResultKind.REFERENCE, 'ppp.Future'),
      _expectId(main, SearchResultKind.REFERENCE, 'ppp.Stream'),
      new ExpectedResult(c, SearchResultKind.REFERENCE,
          partCode.indexOf('ppp.Future c'), 'ppp'.length)
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_private_declaredInDefiningUnit() async {
    String p1 = convertPath('$testProject/part1.dart');
    String p2 = convertPath('$testProject/part2.dart');
    String p3 = convertPath('$testProject/part3.dart');
    String code1 = 'part of lib; _C v1;';
    String code2 = 'part of lib; _C v2;';
    newFile(p1, content: code1);
    newFile(p2, content: code2);
    newFile(p3, content: 'part of lib; int v3;');

    driver.addFile(p1);
    driver.addFile(p2);
    driver.addFile(p3);

    await _resolveTestUnit('''
library lib;
part 'part1.dart';
part 'part2.dart';
part 'part3.dart';
class _C {}
_C v;
''');
    ClassElement element = _findElementAtString('_C {}');
    Element v = testUnitElement.topLevelVariables[0];
    Element v1 = testLibraryElement.parts[0].topLevelVariables[0];
    Element v2 = testLibraryElement.parts[1].topLevelVariables[0];
    var expected = [
      _expectId(v, SearchResultKind.REFERENCE, '_C v;', length: 2),
      new ExpectedResult(
          v1, SearchResultKind.REFERENCE, code1.indexOf('_C v1;'), 2),
      new ExpectedResult(
          v2, SearchResultKind.REFERENCE, code2.indexOf('_C v2;'), 2),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_private_declaredInPart() async {
    String p = convertPath('$testProject/lib.dart');
    String p1 = convertPath('$testProject/part1.dart');
    String p2 = convertPath('$testProject/part2.dart');

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

    newFile(p, content: code);
    newFile(p1, content: code1);
    newFile(p2, content: code2);

    driver.addFile(p);
    driver.addFile(p1);
    driver.addFile(p2);

    ResolvedUnitResult result = await driver.getResult(p);
    testUnit = result.unit;
    testUnitElement = testUnit.declaredElement;
    testLibraryElement = testUnitElement.library;

    ClassElement element = testLibraryElement.parts[0].types[0];
    Element v = testUnitElement.topLevelVariables[0];
    Element v1 = testLibraryElement.parts[0].topLevelVariables[0];
    Element v2 = testLibraryElement.parts[1].topLevelVariables[0];
    var expected = [
      new ExpectedResult(
          v, SearchResultKind.REFERENCE, code.indexOf('_C v;'), 2),
      new ExpectedResult(
          v1, SearchResultKind.REFERENCE, code1.indexOf('_C v1;'), 2),
      new ExpectedResult(
          v2, SearchResultKind.REFERENCE, code2.indexOf('_C v2;'), 2),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_private_inPackage() async {
    testFile = convertPath('/aaa/lib/a.dart');
    var p1 = convertPath('/aaa/lib/part1.dart');
    var p2 = convertPath('/aaa/lib/part2.dart');

    String code1 = 'part of lib; _C v1;';
    String code2 = 'part of lib; _C v2;';

    newFile(p1, content: code1);
    newFile(p2, content: code2);

    await _resolveTestUnit('''
library lib;
part 'part1.dart';
part 'part2.dart';
class _C {}
_C v;
''', addToDriver: false);

    Element element = testUnitElement.types.single;
    Element v = testUnitElement.topLevelVariables[0];
    Element v1 = testLibraryElement.parts[0].topLevelVariables[0];
    Element v2 = testLibraryElement.parts[1].topLevelVariables[0];
    var expected = [
      new ExpectedResult(
          v, SearchResultKind.REFERENCE, testCode.indexOf('_C v;'), 2),
      new ExpectedResult(
          v1, SearchResultKind.REFERENCE, code1.indexOf('_C v1;'), 2),
      new ExpectedResult(
          v2, SearchResultKind.REFERENCE, code2.indexOf('_C v2;'), 2),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_PropertyAccessorElement_getter() async {
    await _resolveTestUnit('''
class A {
  get ggg => null;
  main() {
    print(ggg); // ref-nq
    print(this.ggg); // ref-q
    ggg(); // inv-nq
    this.ggg(); // inv-q
  }
}
''');
    PropertyAccessorElement element = _findElement('ggg', ElementKind.GETTER);
    Element main = _findElement('main');
    var expected = [
      _expectId(main, SearchResultKind.REFERENCE, 'ggg); // ref-nq'),
      _expectIdQ(main, SearchResultKind.REFERENCE, 'ggg); // ref-q'),
      _expectId(main, SearchResultKind.INVOCATION, 'ggg(); // inv-nq'),
      _expectIdQ(main, SearchResultKind.INVOCATION, 'ggg(); // inv-q'),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_PropertyAccessorElement_setter() async {
    await _resolveTestUnit('''
class A {
  set s(x) {}
  main() {
    s = 1;
    this.s = 2;
  }
}
''');
    PropertyAccessorElement element = _findElement('s=');
    Element mainElement = _findElement('main');
    var expected = [
      _expectId(mainElement, SearchResultKind.REFERENCE, 's = 1'),
      _expectIdQ(mainElement, SearchResultKind.REFERENCE, 's = 2')
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_TopLevelVariableElement() async {
    newFile('$testProject/lib.dart', content: '''
library lib;
var V;
''');
    await _resolveTestUnit('''
import 'lib.dart' show V; // imp
import 'lib.dart' as pref;
main() {
  pref.V = 1; // q
  print(pref.V); // q
  pref.V(); // q
  V = 1; // nq
  print(V); // nq
  V(); // nq
}
''');
    ImportElement importElement = testLibraryElement.imports[0];
    CompilationUnitElement impUnit =
        importElement.importedLibrary.definingCompilationUnit;
    TopLevelVariableElement variable = impUnit.topLevelVariables[0];
    Element main = _findElement('main');
    var expected = [
      _expectIdQ(testUnitElement, SearchResultKind.REFERENCE, 'V; // imp'),
      _expectIdQ(main, SearchResultKind.WRITE, 'V = 1; // q'),
      _expectIdQ(main, SearchResultKind.READ, 'V); // q'),
      _expectIdQ(main, SearchResultKind.INVOCATION, 'V(); // q'),
      _expectId(main, SearchResultKind.WRITE, 'V = 1; // nq'),
      _expectId(main, SearchResultKind.READ, 'V); // nq'),
      _expectId(main, SearchResultKind.INVOCATION, 'V(); // nq'),
    ];
    await _verifyReferences(variable, expected);
  }

  test_searchReferences_TypeParameterElement_ofClass() async {
    await _resolveTestUnit('''
class A<T> {
  foo(T a) {}
  bar(T b) {}
}
''');
    TypeParameterElement element = _findElement('T');
    Element a = _findElement('a');
    Element b = _findElement('b');
    var expected = [
      _expectId(a, SearchResultKind.REFERENCE, 'T a'),
      _expectId(b, SearchResultKind.REFERENCE, 'T b'),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_TypeParameterElement_ofLocalFunction() async {
    await _resolveTestUnit('''
main() {
  void foo<T>(T a) {
    void bar(T b) {}
  }
}
''');
    Element main = _findElement('main');
    FunctionElement foo = findElementsByName(testUnit, 'foo').single;
    TypeParameterElement element = foo.typeParameters.single;
    var expected = [
      _expectId(main, SearchResultKind.REFERENCE, 'T a'),
      _expectId(main, SearchResultKind.REFERENCE, 'T b'),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_TypeParameterElement_ofMethod() async {
    await _resolveTestUnit('''
class A {
  foo<T>(T p) {}
}
''');
    TypeParameterElement element = _findElement('T');
    Element p = _findElement('p');
    var expected = [
      _expectId(p, SearchResultKind.REFERENCE, 'T p'),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_TypeParameterElement_ofTopLevelFunction() async {
    await _resolveTestUnit('''
foo<T>(T a) {
  bar(T b) {}
}
''');
    FunctionElement foo = _findElement('foo');
    TypeParameterElement element = _findElement('T');
    Element a = _findElement('a');
    var expected = [
      _expectId(a, SearchResultKind.REFERENCE, 'T a'),
      _expectId(foo, SearchResultKind.REFERENCE, 'T b'),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchSubtypes() async {
    await _resolveTestUnit('''
class T {}
class A extends T {} // A
class B = Object with T; // B
class C implements T {} // C
''');
    ClassElement element = _findElement('T');
    ClassElement a = _findElement('A');
    ClassElement b = _findElement('B');
    ClassElement c = _findElement('C');
    var expected = [
      _expectId(a, SearchResultKind.REFERENCE, 'T {} // A'),
      _expectId(b, SearchResultKind.REFERENCE, 'T; // B'),
      _expectId(c, SearchResultKind.REFERENCE, 'T {} // C'),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchSubtypes_mixinDeclaration() async {
    await _resolveTestUnit('''
class T {}
mixin A on T {} // A
mixin B implements T {} // B
''');
    ClassElement element = _findElement('T');
    ClassElement a = _findElement('A');
    ClassElement b = _findElement('B');
    var expected = [
      _expectId(a, SearchResultKind.REFERENCE, 'T {} // A'),
      _expectId(b, SearchResultKind.REFERENCE, 'T {} // B'),
    ];
    await _verifyReferences(element, expected);
  }

  test_subtypes() async {
    await _resolveTestUnit('''
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
    ClassElement a = _findElement('A');

    // Search by 'type'.
    List<SubtypeResult> subtypes = await driver.search.subtypes(type: a);
    expect(subtypes, hasLength(3));

    SubtypeResult b = subtypes.singleWhere((r) => r.name == 'B');
    SubtypeResult c = subtypes.singleWhere((r) => r.name == 'C');
    SubtypeResult d = subtypes.singleWhere((r) => r.name == 'D');

    expect(b.libraryUri, testUri);
    expect(b.id, '$testUri;$testUri;B');
    expect(b.members, ['methodB']);

    expect(c.libraryUri, testUri);
    expect(c.id, '$testUri;$testUri;C');
    expect(c.members, ['methodC']);

    expect(d.libraryUri, testUri);
    expect(d.id, '$testUri;$testUri;D');
    expect(d.members, ['methodD']);

    // Search by 'id'.
    {
      List<SubtypeResult> subtypes = await driver.search.subtypes(subtype: b);
      expect(subtypes, hasLength(1));
      SubtypeResult e = subtypes.singleWhere((r) => r.name == 'E');
      expect(e.members, ['methodE']);
    }
  }

  test_subtypes_discover() async {
    var pathT = convertPath('/test/lib/t.dart');
    var pathA = convertPath('/aaa/lib/a.dart');
    var pathB = convertPath('/bbb/lib/b.dart');

    var tUri = 'package:test/t.dart';
    var aUri = 'package:aaa/a.dart';
    var bUri = 'package:bbb/b.dart';

    newFile(pathT, content: r'''
import 'package:aaa/a.dart';

class T1 extends A {
  void method1() {}
}

class T2 extends A {
  void method2() {}
}
''');

    newFile(pathB, content: r'''
import 'package:aaa/a.dart';

class B extends A {
  void method1() {}
}
''');

    newFile(pathA, content: r'''
class A {
  void method1() {}
  void method2() {}
}
''');

    driver.addFile(pathT);

    var aLibrary = await driver.getLibraryByUri(aUri);
    ClassElement aClass = aLibrary.getType('A');

    // Search by 'type'.
    List<SubtypeResult> subtypes = await driver.search.subtypes(type: aClass);
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

  test_subTypes_discover() async {
    var t = convertPath('/test/lib/t.dart');
    var a = convertPath('/aaa/lib/a.dart');
    var b = convertPath('/bbb/lib/b.dart');
    var c = convertPath('/ccc/lib/c.dart');

    newFile(t, content: 'class T implements List {}');
    newFile(a, content: 'class A implements List {}');
    newFile(b, content: 'class B implements List {}');
    newFile(c, content: 'class C implements List {}');

    driver.addFile(t);

    LibraryElement coreLib = await driver.getLibraryByUri('dart:core');
    ClassElement listElement = coreLib.getType('List');

    var searchedFiles = new SearchedFiles();
    var results = await driver.search.subTypes(listElement, searchedFiles);

    void assertHasResult(String path, String name, {bool not: false}) {
      var matcher = contains(predicate((SearchResult r) {
        var element = r.enclosingElement;
        return element.name == name && element.source.fullName == path;
      }));
      expect(results, not ? isNot(matcher) : matcher);
    }

    assertHasResult(t, 'T');
    assertHasResult(a, 'A');
    assertHasResult(b, 'B');
    assertHasResult(c, 'C', not: true);
  }

  test_subtypes_files() async {
    String pathB = convertPath('$testProject/b.dart');
    String pathC = convertPath('$testProject/c.dart');
    newFile(pathB, content: r'''
import 'test.dart';
class B extends A {}
''');
    newFile(pathC, content: r'''
import 'test.dart';
class C extends A {}
class D {}
''');

    await _resolveTestUnit('''
class A {}
''');
    ClassElement a = _findElement('A');

    driver.addFile(pathB);
    driver.addFile(pathC);
    await scheduler.waitForIdle();

    List<SubtypeResult> subtypes = await driver.search.subtypes(type: a);
    expect(subtypes, hasLength(2));

    SubtypeResult b = subtypes.singleWhere((r) => r.name == 'B');
    SubtypeResult c = subtypes.singleWhere((r) => r.name == 'C');

    expect(b.id, endsWith('b.dart;B'));
    expect(c.id, endsWith('c.dart;C'));
  }

  test_subtypes_mixin_superclassConstraints() async {
    await _resolveTestUnit('''
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
    ClassElement a = _findElement('A');
    ClassElement b = _findElement('B');

    {
      var subtypes = await driver.search.subtypes(type: a);
      expect(subtypes, hasLength(1));

      var m = subtypes.singleWhere((r) => r.name == 'M');
      expect(m.libraryUri, testUri);
      expect(m.id, '$testUri;$testUri;M');
      expect(m.members, ['methodA', 'methodM']);
    }

    {
      var subtypes = await driver.search.subtypes(type: b);
      expect(subtypes, hasLength(1));

      var m = subtypes.singleWhere((r) => r.name == 'M');
      expect(m.libraryUri, testUri);
      expect(m.id, '$testUri;$testUri;M');
      expect(m.members, ['methodA', 'methodM']);
    }
  }

  test_subtypes_partWithoutLibrary() async {
    await _resolveTestUnit('''
part of lib;

class A {}
class B extends A {}
''');
    ClassElement a = _findElement('A');

    List<SubtypeResult> subtypes = await driver.search.subtypes(type: a);
    expect(subtypes, hasLength(1));

    SubtypeResult b = subtypes.singleWhere((r) => r.name == 'B');
    expect(b.libraryUri, testUri);
    expect(b.id, '$testUri;$testUri;B');
  }

  test_topLevelElements() async {
    await _resolveTestUnit('''
class A {} // A
class B = Object with A;
mixin C {}
typedef D();
e() {}
var f = null;
class NoMatchABCDEF {}
''');
    Element a = _findElement('A');
    Element b = _findElement('B');
    Element c = _findElement('C');
    Element d = _findElement('D');
    Element e = _findElement('e');
    Element f = _findElement('f');
    RegExp regExp = new RegExp(r'^[ABCDef]$');
    expect(await driver.search.topLevelElements(regExp),
        unorderedEquals([a, b, c, d, e, f]));
  }

  Declaration _assertHasDeclaration(
      List<Declaration> declarations, String name, DeclarationKind kind,
      {int offset,
      int codeOffset,
      int codeLength,
      String className,
      String mixinName}) {
    for (var declaration in declarations) {
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
    var actual = declarations
        .map((d) => '(name=${d.name}, kind=${d.kind}, offset=${d.offset}, '
            'codeOffset=${d.codeOffset}, codeLength=${d.codeLength})')
        .join('\n');
    fail('Exected to find (name=$name, kind=$kind, offset=$offset, '
        'codeOffset=$codeOffset, codeLength=$codeLength) in\n$actual');
  }

  void _assertNoDeclaration(List<Declaration> declarations, String name) {
    for (var declaration in declarations) {
      if (declaration.name == name) {
        fail('Unexpected declaration $name');
      }
    }
  }

  ExpectedResult _expectId(
      Element enclosingElement, SearchResultKind kind, String search,
      {int length, bool isResolved: true, bool isQualified: false}) {
    int offset = findOffset(search);
    if (length == null) {
      length = getLeadingIdentifierLength(search);
    }
    return new ExpectedResult(enclosingElement, kind, offset, length,
        isResolved: isResolved, isQualified: isQualified);
  }

  /**
   * Create [ExpectedResult] for a qualified and resolved match.
   */
  ExpectedResult _expectIdQ(
      Element element, SearchResultKind kind, String search,
      {int length, bool isResolved: true}) {
    return _expectId(element, kind, search, isQualified: true, length: length);
  }

  /**
   * Create [ExpectedResult] for a qualified and unresolved match.
   */
  ExpectedResult _expectIdQU(
      Element element, SearchResultKind kind, String search,
      {int length}) {
    return _expectId(element, kind, search,
        isQualified: true, isResolved: false, length: length);
  }

  /**
   * Create [ExpectedResult] for a unqualified and unresolved match.
   */
  ExpectedResult _expectIdU(
      Element element, SearchResultKind kind, String search,
      {int length}) {
    return _expectId(element, kind, search,
        isQualified: false, isResolved: false, length: length);
  }

  Element _findElement(String name, [ElementKind kind]) {
    return findChildElement(testUnit.declaredElement, name, kind);
  }

  Element _findElementAtString(String search) {
    int offset = findOffset(search);
    AstNode node = new NodeLocator(offset).searchWithin(testUnit);
    return ElementLocator.locate(node);
  }

  Future<void> _resolveTestUnit(String code, {bool addToDriver: true}) async {
    if (addToDriver) {
      addTestFile(code);
    } else {
      testCode = code;
      newFile(testFile, content: testCode);
    }
    if (testUnit == null) {
      ResolvedUnitResult result = await driver.getResult(testFile);
      testUnit = result.unit;
      testUnitElement = testUnit.declaredElement;
      testLibraryElement = testUnitElement.library;
    }
  }

  Future<void> _verifyNameReferences(
      String name, List<ExpectedResult> expectedMatches) async {
    var searchedFiles = new SearchedFiles();
    List<SearchResult> results =
        await driver.search.unresolvedMemberReferences(name, searchedFiles);
    _assertResults(results, expectedMatches);
    expect(results, hasLength(expectedMatches.length));
  }

  Future _verifyReferences(
      Element element, List<ExpectedResult> expectedMatches) async {
    var searchedFiles = new SearchedFiles();
    var results = await driver.search.references(element, searchedFiles);
    _assertResults(results, expectedMatches);
    expect(results, hasLength(expectedMatches.length));
  }

  static void _assertResults(
      List<SearchResult> matches, List<ExpectedResult> expectedMatches) {
    expect(matches, unorderedEquals(expectedMatches));
  }
}
