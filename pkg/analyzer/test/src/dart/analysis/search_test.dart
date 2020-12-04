// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart' hide Declaration;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/search.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/testing/element_search.dart';
import 'package:analyzer/src/test_utilities/find_element.dart';
import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SearchTest);
    defineReflectiveTests(SearchWithNullSafetyTest);
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
class SearchTest extends BaseAnalysisDriverTest {
  static const testUri = 'package:test/test.dart';

  CompilationUnit testUnit;
  CompilationUnitElement testUnitElement;
  LibraryElement testLibraryElement;

  FindNode findNode;
  FindElement findElement;

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
    var a = findElement.class_('A');
    var b = findElement.class_('B');
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
    var a = findElement.mixin('A');
    var b = findElement.mixin('B');
    expect(await driver.search.classMembers('test'),
        unorderedEquals([a.methods[0], b.fields[0]]));
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
    var main = findElement.function('main');
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
    var main = findElement.method('main');
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

    var v1 = findElement.topVar('v1');
    var v2 = findElement.topVar('v2');
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

    var v1 = findElement.topVar('v1');
    var v2 = findElement.topVar('v2');
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
    var element = findElement.class_('A');
    var p = findElement.parameter('p');
    var main = findElement.function('main');
    var b1 = findElement.class_('B1');
    var b2 = findElement.class_('B2');
    var b3 = findElement.class_('B3');
    var v2 = findElement.topVar('v2');
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
    newFile('$testProject2/lib.dart', content: r'''
class A {};
''');
    await _resolveTestUnit('''
import 'lib.dart';
main(A p) {
  A v;
}
''');
    var element = findNode.simple('A p').staticElement;
    var p = findElement.parameter('p');
    var main = findElement.function('main');
    var expected = [
      _expectId(p, SearchResultKind.REFERENCE, 'A p'),
      _expectId(main, SearchResultKind.REFERENCE, 'A v')
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_ClassElement_enum() async {
    await _resolveTestUnit('''
enum MyEnum {a}

main(MyEnum p) {
  MyEnum v;
  MyEnum.a;
}
''');
    var element = findElement.enum_('MyEnum');
    var main = findElement.function('main');
    var expected = [
      _expectId(
        findElement.parameter('p'),
        SearchResultKind.REFERENCE,
        'MyEnum p',
      ),
      _expectId(main, SearchResultKind.REFERENCE, 'MyEnum v'),
      _expectId(main, SearchResultKind.REFERENCE, 'MyEnum.a'),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_ClassElement_mixin() async {
    await _resolveTestUnit('''
mixin A {}
class B extends Object with A {} // with
''');
    var element = findElement.mixin('A');
    var b = findElement.class_('B');
    var expected = [
      _expectId(b, SearchResultKind.REFERENCE, 'A {} // with'),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_CompilationUnitElement() async {
    newFile('$testProject2/foo.dart');
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
    var element = findElement.unnamedConstructor('A');
    var main = findElement.function('main');
    var expected = [
      _expectIdQ(main, SearchResultKind.REFERENCE, '();', length: 0)
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_ConstructorElement_default_otherFile() async {
    String other = convertPath('$testProject2/other.dart');
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
    var element = findElement.unnamedConstructor('A');

    CompilationUnit otherUnit = (await driver.getResult(other)).unit;
    Element main = otherUnit.declaredElement.functions[0];
    var expected = [
      ExpectedResult(main, SearchResultKind.REFERENCE,
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
    var element = findElement.constructor('named');
    var main = findElement.function('main');
    var expected = [
      _expectIdQ(main, SearchResultKind.REFERENCE, '.named();',
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
    var element = findElement.unnamedConstructor('A');
    var main = findElement.function('main');
    var expected = [
      _expectIdQ(main, SearchResultKind.REFERENCE, '();', length: 0)
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_ExtensionElement() async {
    await _resolveTestUnit('''
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
    var main = findElement.function('main');
    var expected = [
      _expectId(main, SearchResultKind.REFERENCE, 'E(0)'),
      _expectId(main, SearchResultKind.REFERENCE, 'E.bar()'),
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
    var element = findElement.field('field');
    var main = findElement.method('main');
    var fieldParameter = findElement.parameter('field');
    var expected = [
      _expectIdQ(fieldParameter, SearchResultKind.WRITE, 'field}'),
      _expectIdQ(main, SearchResultKind.REFERENCE, 'field: 1'),
      _expectId(main, SearchResultKind.READ, 'field); // ref-nq'),
      _expectIdQ(main, SearchResultKind.READ, 'field); // ref-q'),
      _expectId(main, SearchResultKind.READ, 'field(); // inv-nq'),
      _expectIdQ(main, SearchResultKind.READ, 'field(); // inv-q'),
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
    var enumElement = findElement.enum_('MyEnum');
    var main = findElement.function('main');
    await _verifyReferences(enumElement.getField('index'),
        [_expectIdQ(main, SearchResultKind.READ, 'index);')]);
    await _verifyReferences(enumElement.getField('values'),
        [_expectIdQ(main, SearchResultKind.READ, 'values);')]);
    await _verifyReferences(enumElement.getField('A'), [
      _expectIdQ(main, SearchResultKind.READ, 'A.index);'),
      _expectIdQ(main, SearchResultKind.READ, 'A);')
    ]);
    await _verifyReferences(enumElement.getField('B'),
        [_expectIdQ(main, SearchResultKind.READ, 'B);')]);
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
    var element = findElement.field('field');
    var main = findElement.method('main');
    var expected = [
      _expectId(main, SearchResultKind.READ, 'field); // ref-nq'),
      _expectIdQ(main, SearchResultKind.READ, 'field); // ref-q'),
      _expectId(main, SearchResultKind.READ, 'field(); // inv-nq'),
      _expectIdQ(main, SearchResultKind.READ, 'field(); // inv-q'),
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
    var element = findElement.function('test');
    var main = findElement.function('main');
    var expected = [
      _expectId(main, SearchResultKind.INVOCATION, 'test();'),
      _expectId(main, SearchResultKind.REFERENCE, 'test);')
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
    var main = findElement.function('main');
    var expected = [
      _expectId(main, SearchResultKind.INVOCATION, 'test();'),
      _expectId(main, SearchResultKind.REFERENCE, 'test);')
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_ImportElement_noPrefix() async {
    await _resolveTestUnit('''
import 'dart:math' show max, pi, Random hide min;
export 'dart:math' show max, pi, Random hide min;
main() {
  print(pi);
  print(new Random());
  print(max(1, 2));
}
Random bar() => null;
''');
    ImportElement element = testLibraryElement.imports[0];
    var main = findElement.function('main');
    var bar = findElement.function('bar');
    var kind = SearchResultKind.REFERENCE;
    var expected = [
      _expectId(main, kind, 'pi);', length: 0),
      _expectId(main, kind, 'Random()', length: 0),
      _expectId(main, kind, 'max(', length: 0),
      _expectId(bar, kind, 'Random bar()', length: 0),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_ImportElement_noPrefix_inPackage() async {
    testFile = convertPath('/aaa/lib/a.dart');
    await _resolveTestUnit('''
import 'dart:math' show max, pi, Random hide min;
export 'dart:math' show max, pi, Random hide min;
main() {
  pi;
  new Random();
  max(1, 2);
}
Random bar() => null;
''', addToDriver: false);
    ImportElement element = testLibraryElement.imports[0];
    var main = findElement.function('main');
    var bar = findElement.function('bar');
    var kind = SearchResultKind.REFERENCE;
    var expected = [
      _expectId(main, kind, 'pi;', length: 0),
      _expectId(main, kind, 'Random();', length: 0),
      _expectId(main, kind, 'max(1, 2);', length: 0),
      _expectId(bar, kind, 'Random bar()', length: 0),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_ImportElement_withPrefix() async {
    await _resolveTestUnit('''
import 'dart:math' as math show max, pi, Random hide min;
export 'dart:math' show max, pi, Random hide min;
main() {
  print(math.pi);
  print(new math.Random());
  print(math.max(1, 2));
}
math.Random bar() => null;
''');
    ImportElement element = testLibraryElement.imports[0];
    var main = findElement.function('main');
    var bar = findElement.function('bar');
    var kind = SearchResultKind.REFERENCE;
    var length = 'math.'.length;
    var expected = [
      _expectId(main, kind, 'math.pi);', length: length),
      _expectId(main, kind, 'math.Random()', length: length),
      _expectId(main, kind, 'math.max(', length: length),
      _expectId(bar, kind, 'math.Random bar()', length: length),
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
    var main = findElement.function('main');
    var kind = SearchResultKind.REFERENCE;
    var length = 'p.'.length;
    {
      ImportElement element = testLibraryElement.imports[0];
      var expected = [
        _expectId(main, kind, 'p.Future;', length: length),
      ];
      await _verifyReferences(element, expected);
    }
    {
      ImportElement element = testLibraryElement.imports[1];
      var expected = [
        _expectId(main, kind, 'p.Random', length: length),
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
    var main = findElement.function('main');
    var expected = [
      _expectId(main, SearchResultKind.REFERENCE, 'label; // 1'),
      _expectId(main, SearchResultKind.REFERENCE, 'label; // 2')
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_LibraryElement() async {
    var codeA = 'part of lib; // A';
    var codeB = 'part of lib; // B';
    newFile('$testProject2/unitA.dart', content: codeA);
    newFile('$testProject2/unitB.dart', content: codeB);
    await _resolveTestUnit('''
library lib;
part 'unitA.dart';
part 'unitB.dart';
''');
    LibraryElement element = testLibraryElement;
    CompilationUnitElement unitElementA = element.parts[0];
    CompilationUnitElement unitElementB = element.parts[1];
    var expected = [
      ExpectedResult(unitElementA, SearchResultKind.REFERENCE,
          codeA.indexOf('lib; // A'), 'lib'.length),
      ExpectedResult(unitElementB, SearchResultKind.REFERENCE,
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
      ExpectedResult(unitElementA, SearchResultKind.REFERENCE,
          codeA.indexOf('lib; // A'), 'lib'.length),
      ExpectedResult(unitElementB, SearchResultKind.REFERENCE,
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
    var main = findElement.function('main');
    var expected = [
      _expectId(main, SearchResultKind.WRITE, 'v = 1;'),
      _expectId(main, SearchResultKind.READ_WRITE, 'v += 2;'),
      _expectId(main, SearchResultKind.READ, 'v);'),
      _expectId(main, SearchResultKind.READ, 'v();')
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
    var main = findElement.function('main');
    var expected = [
      _expectId(main, SearchResultKind.WRITE, 'v = 1;'),
      _expectId(main, SearchResultKind.READ_WRITE, 'v += 2;'),
      _expectId(main, SearchResultKind.READ, 'v);'),
      _expectId(main, SearchResultKind.READ, 'v();')
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
    var main = findElement.function('main');

    var expected = [
      _expectId(main, SearchResultKind.WRITE, 'v = 1;'),
      _expectId(main, SearchResultKind.READ_WRITE, 'v += 2;'),
      _expectId(main, SearchResultKind.READ, 'v);'),
      _expectId(main, SearchResultKind.READ, 'v();')
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_MethodElement_class() async {
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
    var method = findElement.method('m');
    var main = findElement.method('main');
    var expected = [
      _expectId(main, SearchResultKind.INVOCATION, 'm(); // 1'),
      _expectIdQ(main, SearchResultKind.INVOCATION, 'm(); // 2'),
      _expectId(main, SearchResultKind.REFERENCE, 'm); // 3'),
      _expectIdQ(main, SearchResultKind.REFERENCE, 'm); // 4')
    ];
    await _verifyReferences(method, expected);
  }

  test_searchReferences_MethodElement_extension_named() async {
    await _resolveTestUnit('''
extension E on int {
  void foo() {}

  void bar() {
    foo(); // 1
    this.foo(); // 2
    print(foo); // 3
    print(this.foo); // 4
  }
}
''');
    var foo = findElement.method('foo');
    var bar = findElement.method('bar');
    var expected = [
      _expectId(bar, SearchResultKind.INVOCATION, 'foo(); // 1'),
      _expectIdQ(bar, SearchResultKind.INVOCATION, 'foo(); // 2'),
      _expectId(bar, SearchResultKind.REFERENCE, 'foo); // 3'),
      _expectIdQ(bar, SearchResultKind.REFERENCE, 'foo); // 4')
    ];
    await _verifyReferences(foo, expected);
  }

  test_searchReferences_MethodElement_extension_unnamed() async {
    await _resolveTestUnit('''
extension on int {
  void foo() {}

  void bar() {
    foo(); // 1
    this.foo(); // 2
    print(foo); // 3
    print(this.foo); // 4
  }
}
''');
    var foo = findElement.method('foo');
    var bar = findElement.method('bar');
    var expected = [
      _expectId(bar, SearchResultKind.INVOCATION, 'foo(); // 1'),
      _expectIdQ(bar, SearchResultKind.INVOCATION, 'foo(); // 2'),
      _expectId(bar, SearchResultKind.REFERENCE, 'foo); // 3'),
      _expectIdQ(bar, SearchResultKind.REFERENCE, 'foo); // 4')
    ];
    await _verifyReferences(foo, expected);
  }

  test_searchReferences_MethodElement_ofExtension_instance() async {
    await _resolveTestUnit('''
extension E on int {
  void foo() {}

  void bar() {
    foo(); // 1
    this.foo(); // 2
    foo; // 3
    this.foo; // 4
  }
}

main() {
  E(0).foo(); // 5
  0.foo(); // 6
  E(0).foo; // 7
  0.foo; // 8
}
''');
    var element = findElement.method('foo');
    var bar = findElement.method('bar');
    var main = findElement.function('main');
    var expected = [
      _expectId(bar, SearchResultKind.INVOCATION, 'foo(); // 1'),
      _expectIdQ(bar, SearchResultKind.INVOCATION, 'foo(); // 2'),
      _expectId(bar, SearchResultKind.REFERENCE, 'foo; // 3'),
      _expectIdQ(bar, SearchResultKind.REFERENCE, 'foo; // 4'),
      _expectIdQ(main, SearchResultKind.INVOCATION, 'foo(); // 5'),
      _expectIdQ(main, SearchResultKind.INVOCATION, 'foo(); // 6'),
      _expectIdQ(main, SearchResultKind.REFERENCE, 'foo; // 7'),
      _expectIdQ(main, SearchResultKind.REFERENCE, 'foo; // 8'),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_MethodElement_ofExtension_static() async {
    await _resolveTestUnit('''
extension E on int {
  static void foo() {}

  static void bar() {
    foo(); // 1
    foo; // 2
  }
}

main() {
  E.foo(); // 3
  E.foo; // 4
}
''');
    var element = findElement.method('foo');
    var bar = findElement.method('bar');
    var main = findElement.function('main');
    var expected = [
      _expectId(bar, SearchResultKind.INVOCATION, 'foo(); // 1'),
      _expectId(bar, SearchResultKind.REFERENCE, 'foo; // 2'),
      _expectIdQ(main, SearchResultKind.INVOCATION, 'foo(); // 3'),
      _expectIdQ(main, SearchResultKind.REFERENCE, 'foo; // 4'),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_MethodMember_class() async {
    await _resolveTestUnit('''
class A<T> {
  T m() => null;
}
main(A<int> a) {
  a.m(); // ref
}
''');
    var method = findElement.method('m');
    var main = findElement.function('main');
    var expected = [
      _expectIdQ(main, SearchResultKind.INVOCATION, 'm(); // ref')
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
    var element = findElement.parameter('p');
    var foo = findElement.function('foo');
    var main = findElement.function('main');
    var expected = [
      _expectId(foo, SearchResultKind.WRITE, 'p = 1;'),
      _expectId(foo, SearchResultKind.READ_WRITE, 'p += 2;'),
      _expectId(foo, SearchResultKind.READ, 'p);'),
      _expectId(foo, SearchResultKind.READ, 'p();'),
      _expectIdQ(main, SearchResultKind.REFERENCE, 'p: 42')
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
    var element = findElement.parameter('p');
    var constructor = findElement.unnamedConstructor('C');
    var expected = [
      _expectId(constructor, SearchResultKind.READ, 'p + 1 {'),
      _expectId(constructor, SearchResultKind.WRITE, 'p = 2;'),
      _expectId(constructor, SearchResultKind.READ_WRITE, 'p += 3;'),
      _expectId(constructor, SearchResultKind.READ, 'p);'),
      _expectId(constructor, SearchResultKind.READ, 'p();')
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
    var main = findElement.function('main');
    var element = findElement.parameter('p');
    var expected = [
      _expectId(main, SearchResultKind.WRITE, 'p = 1;'),
      _expectId(main, SearchResultKind.READ_WRITE, 'p += 2;'),
      _expectId(main, SearchResultKind.READ, 'p);'),
      _expectId(main, SearchResultKind.READ, 'p();')
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
    var element = findElement.parameter('p');
    var foo = findElement.method('foo');
    var expected = [
      _expectId(foo, SearchResultKind.WRITE, 'p = 1;'),
      _expectId(foo, SearchResultKind.READ_WRITE, 'p += 2;'),
      _expectId(foo, SearchResultKind.READ, 'p);'),
      _expectId(foo, SearchResultKind.READ, 'p();')
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
    var element = findElement.parameter('p');
    var foo = findElement.function('foo');
    var expected = [
      _expectId(foo, SearchResultKind.WRITE, 'p = 1;'),
      _expectId(foo, SearchResultKind.READ_WRITE, 'p += 2;'),
      _expectId(foo, SearchResultKind.READ, 'p);'),
      _expectId(foo, SearchResultKind.READ, 'p();')
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
    var element = findElement.parameter('p');
    var foo = findElement.function('foo');
    var main = findElement.function('main');
    var expected = [
      _expectId(foo, SearchResultKind.WRITE, 'p = 1;'),
      _expectId(foo, SearchResultKind.READ_WRITE, 'p += 2;'),
      _expectId(foo, SearchResultKind.READ, 'p);'),
      _expectId(foo, SearchResultKind.READ, 'p();'),
      _expectIdQ(main, SearchResultKind.REFERENCE, '42', length: 0)
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_PrefixElement() async {
    String partCode = r'''
part of my_lib;
ppp.Future c;
''';
    newFile('$testProject2/my_part.dart', content: partCode);
    await _resolveTestUnit('''
library my_lib;
import 'dart:async' as ppp;
part 'my_part.dart';
main() {
  ppp.Future a;
  ppp.Stream b;
}
''');
    var element = findElement.prefix('ppp');
    var main = findElement.function('main');
    Element c = findChildElement(testLibraryElement, 'c');
    var expected = [
      _expectId(main, SearchResultKind.REFERENCE, 'ppp.Future'),
      _expectId(main, SearchResultKind.REFERENCE, 'ppp.Stream'),
      ExpectedResult(c, SearchResultKind.REFERENCE,
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
    var element = findElement.prefix('ppp');
    var main = findElement.function('main');
    Element c = findChildElement(testLibraryElement, 'c');
    var expected = [
      _expectId(main, SearchResultKind.REFERENCE, 'ppp.Future'),
      _expectId(main, SearchResultKind.REFERENCE, 'ppp.Stream'),
      ExpectedResult(c, SearchResultKind.REFERENCE,
          partCode.indexOf('ppp.Future c'), 'ppp'.length)
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_private_declaredInDefiningUnit() async {
    String p1 = convertPath('$testProject2/part1.dart');
    String p2 = convertPath('$testProject2/part2.dart');
    String p3 = convertPath('$testProject2/part3.dart');
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
    var element = findElement.class_('_C');
    Element v = testUnitElement.topLevelVariables[0];
    Element v1 = testLibraryElement.parts[0].topLevelVariables[0];
    Element v2 = testLibraryElement.parts[1].topLevelVariables[0];
    var expected = [
      _expectId(v, SearchResultKind.REFERENCE, '_C v;', length: 2),
      ExpectedResult(
          v1, SearchResultKind.REFERENCE, code1.indexOf('_C v1;'), 2),
      ExpectedResult(
          v2, SearchResultKind.REFERENCE, code2.indexOf('_C v2;'), 2),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_private_declaredInPart() async {
    String p = convertPath('$testProject2/lib.dart');
    String p1 = convertPath('$testProject2/part1.dart');
    String p2 = convertPath('$testProject2/part2.dart');

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
      ExpectedResult(v, SearchResultKind.REFERENCE, code.indexOf('_C v;'), 2),
      ExpectedResult(
          v1, SearchResultKind.REFERENCE, code1.indexOf('_C v1;'), 2),
      ExpectedResult(
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
      ExpectedResult(
          v, SearchResultKind.REFERENCE, testCode.indexOf('_C v;'), 2),
      ExpectedResult(
          v1, SearchResultKind.REFERENCE, code1.indexOf('_C v1;'), 2),
      ExpectedResult(
          v2, SearchResultKind.REFERENCE, code2.indexOf('_C v2;'), 2),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_PropertyAccessor_getter_ofExtension_instance() async {
    await _resolveTestUnit('''
extension E on int {
  int get foo => 0;

  void bar() {
    foo; // 1
    this.foo; // 2
  }
}

main() {
  E(0).foo; // 3
  0.foo; // 4
}
''');
    var element = findElement.getter('foo');
    var bar = findElement.method('bar');
    var main = findElement.function('main');
    var expected = [
      _expectId(bar, SearchResultKind.REFERENCE, 'foo; // 1'),
      _expectIdQ(bar, SearchResultKind.REFERENCE, 'foo; // 2'),
      _expectIdQ(main, SearchResultKind.REFERENCE, 'foo; // 3'),
      _expectIdQ(main, SearchResultKind.REFERENCE, 'foo; // 4'),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_PropertyAccessor_setter_ofExtension_instance() async {
    await _resolveTestUnit('''
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
    var bar = findElement.method('bar');
    var main = findElement.function('main');
    var expected = [
      _expectId(bar, SearchResultKind.REFERENCE, 'foo = 1;'),
      _expectIdQ(bar, SearchResultKind.REFERENCE, 'foo = 2;'),
      _expectIdQ(main, SearchResultKind.REFERENCE, 'foo = 3;'),
      _expectIdQ(main, SearchResultKind.REFERENCE, 'foo = 4;'),
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
    var element = findElement.getter('ggg');
    var main = findElement.method('main');
    var expected = [
      _expectId(main, SearchResultKind.REFERENCE, 'ggg); // ref-nq'),
      _expectIdQ(main, SearchResultKind.REFERENCE, 'ggg); // ref-q'),
      _expectId(main, SearchResultKind.REFERENCE, 'ggg(); // inv-nq'),
      _expectIdQ(main, SearchResultKind.REFERENCE, 'ggg(); // inv-q'),
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
    var element = findElement.setter('s');
    var main = findElement.method('main');
    var expected = [
      _expectId(main, SearchResultKind.REFERENCE, 's = 1'),
      _expectIdQ(main, SearchResultKind.REFERENCE, 's = 2')
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_TopLevelVariableElement() async {
    newFile('$testProject2/lib.dart', content: '''
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
    var main = findElement.function('main');
    var expected = [
      _expectIdQ(testUnitElement, SearchResultKind.REFERENCE, 'V; // imp'),
      _expectIdQ(main, SearchResultKind.WRITE, 'V = 1; // q'),
      _expectIdQ(main, SearchResultKind.READ, 'V); // q'),
      _expectIdQ(main, SearchResultKind.READ, 'V(); // q'),
      _expectId(main, SearchResultKind.WRITE, 'V = 1; // nq'),
      _expectId(main, SearchResultKind.READ, 'V); // nq'),
      _expectId(main, SearchResultKind.READ, 'V(); // nq'),
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
    var element = findElement.typeParameter('T');
    var a = findElement.parameter('a');
    var b = findElement.parameter('b');
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
    var main = findElement.function('main');
    var foo = findElement.localFunction('foo');
    var element = foo.typeParameters.single;
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
    var element = findElement.typeParameter('T');
    var p = findElement.parameter('p');
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
    var foo = findElement.function('foo');
    var element = findElement.typeParameter('T');
    var a = findElement.parameter('a');
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
    var element = findElement.class_('T');
    var a = findElement.class_('A');
    var b = findElement.class_('B');
    var c = findElement.class_('C');
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
    var element = findElement.class_('T');
    var a = findElement.mixin('A');
    var b = findElement.mixin('B');
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
    var a = findElement.class_('A');

    // Search by 'type'.
    List<SubtypeResult> subtypes =
        await driver.search.subtypes(SearchedFiles(), type: a);
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
      List<SubtypeResult> subtypes =
          await driver.search.subtypes(SearchedFiles(), subtype: b);
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

    var searchedFiles = SearchedFiles();
    var results = await driver.search.subTypes(listElement, searchedFiles);

    void assertHasResult(String path, String name, {bool not = false}) {
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
    String pathB = convertPath('$testProject2/b.dart');
    String pathC = convertPath('$testProject2/c.dart');
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
    var a = findElement.class_('A');

    driver.addFile(pathB);
    driver.addFile(pathC);
    await scheduler.waitForIdle();

    List<SubtypeResult> subtypes =
        await driver.search.subtypes(SearchedFiles(), type: a);
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
    var a = findElement.class_('A');
    var b = findElement.class_('B');

    {
      var subtypes = await driver.search.subtypes(SearchedFiles(), type: a);
      expect(subtypes, hasLength(1));

      var m = subtypes.singleWhere((r) => r.name == 'M');
      expect(m.libraryUri, testUri);
      expect(m.id, '$testUri;$testUri;M');
      expect(m.members, ['methodA', 'methodM']);
    }

    {
      var subtypes = await driver.search.subtypes(SearchedFiles(), type: b);
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
    var a = findElement.class_('A');

    List<SubtypeResult> subtypes =
        await driver.search.subtypes(SearchedFiles(), type: a);
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
f() {}
var g = null;
class NoMatchABCDEF {}
''');
    var a = findElement.class_('A');
    var b = findElement.class_('B');
    var c = findElement.mixin('C');
    var d = findElement.functionTypeAlias('D');
    var f = findElement.function('f');
    var g = findElement.topVar('g');
    RegExp regExp = RegExp(r'^[ABCDfg]$');
    expect(await driver.search.topLevelElements(regExp),
        unorderedEquals([a, b, c, d, f, g]));
  }

  ExpectedResult _expectId(
      Element enclosingElement, SearchResultKind kind, String search,
      {int length, bool isResolved = true, bool isQualified = false}) {
    int offset = findOffset(search);
    length ??= getLeadingIdentifierLength(search);
    return ExpectedResult(enclosingElement, kind, offset, length,
        isResolved: isResolved, isQualified: isQualified);
  }

  /// Create [ExpectedResult] for a qualified and resolved match.
  ExpectedResult _expectIdQ(
      Element element, SearchResultKind kind, String search,
      {int length}) {
    return _expectId(element, kind, search, isQualified: true, length: length);
  }

  /// Create [ExpectedResult] for a qualified and unresolved match.
  ExpectedResult _expectIdQU(
      Element element, SearchResultKind kind, String search,
      {int length}) {
    return _expectId(element, kind, search,
        isQualified: true, isResolved: false, length: length);
  }

  /// Create [ExpectedResult] for a unqualified and unresolved match.
  ExpectedResult _expectIdU(
      Element element, SearchResultKind kind, String search,
      {int length}) {
    return _expectId(element, kind, search,
        isQualified: false, isResolved: false, length: length);
  }

  Future<void> _resolveTestUnit(String code, {bool addToDriver = true}) async {
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

      findNode = FindNode(result.content, result.unit);
      findElement = FindElement(result.unit);
    }
  }

  Future<void> _verifyNameReferences(
      String name, List<ExpectedResult> expectedMatches) async {
    var searchedFiles = SearchedFiles();
    List<SearchResult> results =
        await driver.search.unresolvedMemberReferences(name, searchedFiles);
    _assertResults(results, expectedMatches);
    expect(results, hasLength(expectedMatches.length));
  }

  Future _verifyReferences(
      Element element, List<ExpectedResult> expectedMatches) async {
    var searchedFiles = SearchedFiles();
    var results = await driver.search.references(element, searchedFiles);
    _assertResults(results, expectedMatches);
    expect(results, hasLength(expectedMatches.length));
  }

  static void _assertResults(
      List<SearchResult> matches, List<ExpectedResult> expectedMatches) {
    expect(matches, unorderedEquals(expectedMatches));
  }
}

@reflectiveTest
class SearchWithNullSafetyTest extends SearchTest {
  @override
  AnalysisOptionsImpl createAnalysisOptions() => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.forTesting(
        sdkVersion: '2.7.0', additionalFeatures: [Feature.non_nullable]);

  test_searchReferences_ImportElement_noPrefix_optIn_fromOptOut() async {
    newFile('/test/lib/a.dart', content: r'''
class N1 {}
void N2() {}
int get N3 => 0;
set N4(int _) {}
''');

    await _resolveTestUnit('''
// @dart = 2.7
import 'a.dart';

main() {
  N1;
  N2();
  N3;
  N4 = 0;
}
''');
    ImportElement element = testLibraryElement.imports[0];
    var main = findElement.function('main');
    var kind = SearchResultKind.REFERENCE;
    var expected = [
      _expectId(main, kind, 'N1;', length: 0),
      _expectId(main, kind, 'N2();', length: 0),
      _expectId(main, kind, 'N3;', length: 0),
      _expectId(main, kind, 'N4 =', length: 0),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_ImportElement_withPrefix_optIn_fromOptOut() async {
    newFile('/test/lib/a.dart', content: r'''
class N1 {}
void N2() {}
int get N3 => 0;
set N4(int _) {}
''');

    await _resolveTestUnit('''
// @dart = 2.7
import 'a.dart' as a;

main() {
  a.N1;
  a.N2();
  a.N3;
  a.N4 = 0;
}
''');
    ImportElement element = testLibraryElement.imports[0];
    var main = findElement.function('main');
    var kind = SearchResultKind.REFERENCE;
    var length = 'a.'.length;
    var expected = [
      _expectId(main, kind, 'a.N1;', length: length),
      _expectId(main, kind, 'a.N2()', length: length),
      _expectId(main, kind, 'a.N3', length: length),
      _expectId(main, kind, 'a.N4', length: length),
    ];
    await _verifyReferences(element, expected);
  }
}
