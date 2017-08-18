// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/index.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IndexTest);
  });
}

class ExpectedLocation {
  final CompilationUnitElement unitElement;
  final int offset;
  final int length;
  final bool isQualified;

  ExpectedLocation(
      this.unitElement, this.offset, this.length, this.isQualified);

  @override
  String toString() {
    return '(unit=$unitElement; offset=$offset; length=$length;'
        ' isQualified=$isQualified)';
  }
}

@reflectiveTest
class IndexTest extends BaseAnalysisDriverTest {
  CompilationUnit testUnit;
  CompilationUnitElement testUnitElement;
  LibraryElement testLibraryElement;

  AnalysisDriverUnitIndex index;

  _ElementIndexAssert assertThat(Element element) {
    List<_Relation> relations = _getElementRelations(element);
    return new _ElementIndexAssert(this, element, relations);
  }

  _NameIndexAssert assertThatName(String name) {
    return new _NameIndexAssert(this, name);
  }

  Element findElement(String name, [ElementKind kind]) {
    return findChildElement(testUnitElement, name, kind);
  }

  CompilationUnitElement importedUnit({int index: 0}) {
    List<ImportElement> imports = testLibraryElement.imports;
    return imports[index].importedLibrary.definingCompilationUnit;
  }

  test_hasAncestor_ClassDeclaration() async {
    await _indexTestUnit('''
class A {}
class B1 extends A {}
class B2 implements A {}
class C1 extends B1 {}
class C2 extends B2 {}
class C3 implements B1 {}
class C4 implements B2 {}
class M extends Object with A {}
''');
    ClassElement classElementA = findElement("A");
    assertThat(classElementA)
      ..isAncestorOf('B1 extends A')
      ..isAncestorOf('B2 implements A')
      ..isAncestorOf('C1 extends B1')
      ..isAncestorOf('C2 extends B2')
      ..isAncestorOf('C3 implements B1')
      ..isAncestorOf('C4 implements B2')
      ..isAncestorOf('M extends Object with A');
  }

  test_hasAncestor_ClassTypeAlias() async {
    await _indexTestUnit('''
class A {}
class B extends A {}
class C1 = Object with A;
class C2 = Object with B;
''');
    ClassElement classElementA = findElement('A');
    ClassElement classElementB = findElement('B');
    assertThat(classElementA)
      ..isAncestorOf('C1 = Object with A')
      ..isAncestorOf('C2 = Object with B');
    assertThat(classElementB)..isAncestorOf('C2 = Object with B');
  }

  test_isExtendedBy_ClassDeclaration() async {
    await _indexTestUnit('''
class A {} // 1
class B extends A {} // 2
''');
    ClassElement elementA = findElement('A');
    assertThat(elementA)
      ..isExtendedAt('A {} // 2', false)
      ..isReferencedAt('A {} // 2', false);
  }

  test_isExtendedBy_ClassDeclaration_isQualified() async {
    provider.newFile(_p('$testProject/lib.dart'), '''
class A {}
''');
    await _indexTestUnit('''
import 'lib.dart' as p;
class B extends p.A {} // 2
''');
    ClassElement elementA = importedUnit().getType('A');
    assertThat(elementA).isExtendedAt('A {} // 2', true);
  }

  test_isExtendedBy_ClassDeclaration_Object() async {
    await _indexTestUnit('''
class A {}
''');
    ClassElement elementA = findElement('A');
    ClassElement elementObject = elementA.supertype.element;
    assertThat(elementObject).isExtendedAt('A {}', true, length: 0);
  }

  test_isExtendedBy_ClassTypeAlias() async {
    await _indexTestUnit('''
class A {}
class B {}
class C = A with B;
''');
    ClassElement elementA = findElement('A');
    assertThat(elementA)
      ..isExtendedAt('A with', false)
      ..isReferencedAt('A with', false);
  }

  test_isExtendedBy_ClassTypeAlias_isQualified() async {
    provider.newFile(_p('$testProject/lib.dart'), '''
class A {}
''');
    await _indexTestUnit('''
import 'lib.dart' as p;
class B {}
class C = p.A with B;
''');
    ClassElement elementA = importedUnit().getType('A');
    assertThat(elementA)
      ..isExtendedAt('A with', true)
      ..isReferencedAt('A with', true);
  }

  test_isImplementedBy_ClassDeclaration() async {
    await _indexTestUnit('''
class A {} // 1
class B implements A {} // 2
''');
    ClassElement elementA = findElement('A');
    assertThat(elementA)
      ..isImplementedAt('A {} // 2', false)
      ..isReferencedAt('A {} // 2', false);
  }

  test_isImplementedBy_ClassDeclaration_isQualified() async {
    provider.newFile(_p('$testProject/lib.dart'), '''
class A {}
''');
    await _indexTestUnit('''
import 'lib.dart' as p;
class B implements p.A {} // 2
''');
    ClassElement elementA = importedUnit().getType('A');
    assertThat(elementA)
      ..isImplementedAt('A {} // 2', true)
      ..isReferencedAt('A {} // 2', true);
  }

  test_isImplementedBy_ClassTypeAlias() async {
    await _indexTestUnit('''
class A {} // 1
class B {} // 2
class C = Object with A implements B; // 3
''');
    ClassElement elementB = findElement('B');
    assertThat(elementB)
      ..isImplementedAt('B; // 3', false)
      ..isReferencedAt('B; // 3', false);
  }

  test_isInvokedBy_FieldElement() async {
    await _indexTestUnit('''
class A {
  var field;
  main() {
    this.field(); // q
    field(); // nq
  }
}''');
    FieldElement field = findElement('field');
    assertThat(field.getter)
      ..isInvokedAt('field(); // q', true)
      ..isInvokedAt('field(); // nq', false);
  }

  test_isInvokedBy_FunctionElement() async {
    provider.newFile(_p('$testProject/lib.dart'), '''
library lib;
foo() {}
''');
    await _indexTestUnit('''
import 'lib.dart';
import 'lib.dart' as pref;
main() {
  pref.foo(); // q
  foo(); // nq
}''');
    FunctionElement element = importedUnit().functions[0];
    assertThat(element)
      ..isInvokedAt('foo(); // q', true)
      ..isInvokedAt('foo(); // nq', false);
  }

  test_isInvokedBy_FunctionElement_synthetic_loadLibrary() async {
    await _indexTestUnit('''
import 'dart:math' deferred as math;
main() {
  math.loadLibrary(); // 1
  math.loadLibrary(); // 2
}
''');
    LibraryElement mathLib = testLibraryElement.imports[0].importedLibrary;
    FunctionElement element = mathLib.loadLibraryFunction;
    assertThat(element).isInvokedAt('loadLibrary(); // 1', true);
    assertThat(element).isInvokedAt('loadLibrary(); // 2', true);
  }

  test_isInvokedBy_MethodElement() async {
    await _indexTestUnit('''
class A {
  foo() {}
  main() {
    this.foo(); // q
    foo(); // nq
  }
}''');
    Element element = findElement('foo');
    assertThat(element)
      ..isInvokedAt('foo(); // q', true)
      ..isInvokedAt('foo(); // nq', false);
  }

  test_isInvokedBy_MethodElement_propagatedType() async {
    await _indexTestUnit('''
class A {
  foo() {}
}
main() {
  var a = new A();
  a.foo();
}
''');
    Element element = findElement('foo');
    assertThat(element).isInvokedAt('foo();', true);
  }

  test_isInvokedBy_operator_binary() async {
    await _indexTestUnit('''
class A {
  operator +(other) => this;
}
main(A a) {
  print(a + 1);
  a += 2;
  ++a;
  a++;
}
''');
    MethodElement element = findElement('+');
    assertThat(element)
      ..isInvokedAt('+ 1', true, length: 1)
      ..isInvokedAt('+= 2', true, length: 2)
      ..isInvokedAt('++a', true, length: 2)
      ..isInvokedAt('++;', true, length: 2);
  }

  test_isInvokedBy_operator_index() async {
    await _indexTestUnit('''
class A {
  operator [](i) => null;
  operator []=(i, v) {}
}
main(A a) {
  print(a[0]);
  a[1] = 42;
}
''');
    MethodElement readElement = findElement('[]');
    MethodElement writeElement = findElement('[]=');
    assertThat(readElement).isInvokedAt('[0]', true, length: 1);
    assertThat(writeElement).isInvokedAt('[1]', true, length: 1);
  }

  test_isInvokedBy_operator_prefix() async {
    await _indexTestUnit('''
class A {
  A operator ~() => this;
}
main(A a) {
  print(~a);
}
''');
    MethodElement element = findElement('~');
    assertThat(element).isInvokedAt('~a', true, length: 1);
  }

  test_isInvokedBy_PropertyAccessorElement_getter() async {
    await _indexTestUnit('''
class A {
  get ggg => null;
  main() {
    this.ggg(); // q
    ggg(); // nq
  }
}''');
    PropertyAccessorElement element = findElement('ggg', ElementKind.GETTER);
    assertThat(element)
      ..isInvokedAt('ggg(); // q', true)
      ..isInvokedAt('ggg(); // nq', false);
  }

  test_isMixedInBy_ClassDeclaration() async {
    await _indexTestUnit('''
class A {} // 1
class B extends Object with A {} // 2
''');
    ClassElement elementA = findElement('A');
    assertThat(elementA)
      ..isMixedInAt('A {} // 2', false)
      ..isReferencedAt('A {} // 2', false);
  }

  test_isMixedInBy_ClassDeclaration_isQualified() async {
    provider.newFile(_p('$testProject/lib.dart'), '''
class A {}
''');
    await _indexTestUnit('''
import 'lib.dart' as p;
class B extends Object with p.A {} // 2
''');
    ClassElement elementA = importedUnit().getType('A');
    assertThat(elementA).isMixedInAt('A {} // 2', true);
  }

  test_isMixedInBy_ClassTypeAlias() async {
    await _indexTestUnit('''
class A {} // 1
class B = Object with A; // 2
''');
    ClassElement elementA = findElement('A');
    assertThat(elementA).isMixedInAt('A; // 2', false);
  }

  test_isReferencedBy_ClassElement() async {
    await _indexTestUnit('''
class A {
  static var field;
}
main(A p) {
  A v;
  new A(); // 2
  A.field = 1;
  print(A.field); // 3
}
''');
    ClassElement element = findElement('A');
    assertThat(element)
      ..isReferencedAt('A p) {', false)
      ..isReferencedAt('A v;', false)
      ..isReferencedAt('A(); // 2', false)
      ..isReferencedAt('A.field = 1;', false)
      ..isReferencedAt('A.field); // 3', false);
  }

  test_isReferencedBy_ClassElement_invocation() async {
    await _indexTestUnit('''
class A {}
main() {
  A(); // invalid code, but still a reference
}''');
    Element element = findElement('A');
    assertThat(element).isReferencedAt('A();', false);
  }

  test_isReferencedBy_ClassElement_invocation_isQualified() async {
    provider.newFile(_p('$testProject/lib.dart'), '''
class A {}
''');
    await _indexTestUnit('''
import 'lib.dart' as p;
main() {
  p.A(); // invalid code, but still a reference
}''');
    Element element = importedUnit().getType('A');
    assertThat(element).isReferencedAt('A();', true);
  }

  test_isReferencedBy_ClassTypeAlias() async {
    await _indexTestUnit('''
class A {}
class B = Object with A;
main(B p) {
  B v;
}
''');
    ClassElement element = findElement('B');
    assertThat(element)
      ..isReferencedAt('B p) {', false)
      ..isReferencedAt('B v;', false);
  }

  test_isReferencedBy_CompilationUnitElement_export() async {
    provider.newFile(_p('$testProject/lib.dart'), '''
library lib;
''');
    await _indexTestUnit('''
export 'lib.dart';
''');
    LibraryElement element = testLibraryElement.exports[0].exportedLibrary;
    assertThat(element)..isReferencedAt("'lib.dart'", true, length: 10);
  }

  test_isReferencedBy_CompilationUnitElement_import() async {
    provider.newFile(_p('$testProject/lib.dart'), '''
library lib;
''');
    await _indexTestUnit('''
import 'lib.dart';
''');
    LibraryElement element = testLibraryElement.imports[0].importedLibrary;
    assertThat(element)..isReferencedAt("'lib.dart'", true, length: 10);
  }

  test_isReferencedBy_CompilationUnitElement_part() async {
    provider.newFile(_p('$testProject/my_unit.dart'), 'part of my_lib;');
    await _indexTestUnit('''
library my_lib;
part 'my_unit.dart';
''');
    CompilationUnitElement element = testLibraryElement.parts[0];
    assertThat(element)..isReferencedAt("'my_unit.dart';", true, length: 14);
  }

  test_isReferencedBy_CompilationUnitElement_part_inPart() async {
    provider.newFile(_p('$testProject/a.dart'), 'part of lib;');
    provider.newFile(_p('$testProject/b.dart'), '''
library lib;
part 'a.dart';
''');
    await _indexTestUnit('''
part 'b.dart';
''');
    // No exception, even though a.dart is a part of b.dart part.
  }

  test_isReferencedBy_ConstructorElement() async {
    await _indexTestUnit('''
class A implements B {
  A() {}
  A.foo() {}
}
class B extends A {
  B() : super(); // 1
  B.foo() : super.foo(); // 2
  factory B.bar() = A.foo; // 3
}
main() {
  new A(); // 4
  new A.foo(); // 5
}
''');
    ClassElement classA = findElement('A');
    ConstructorElement constA = classA.constructors[0];
    ConstructorElement constA_foo = classA.constructors[1];
    // A()
    assertThat(constA)
      ..hasRelationCount(2)
      ..isReferencedAt('(); // 1', true, length: 0)
      ..isReferencedAt('(); // 4', true, length: 0);
    // A.foo()
    assertThat(constA_foo)
      ..hasRelationCount(3)
      ..isReferencedAt('.foo(); // 2', true, length: 4)
      ..isReferencedAt('.foo; // 3', true, length: 4)
      ..isReferencedAt('.foo(); // 5', true, length: 4);
  }

  test_isReferencedBy_ConstructorElement_classTypeAlias() async {
    await _indexTestUnit('''
class M {}
class A implements B {
  A() {}
  A.named() {}
}
class B = A with M;
class C = B with M;
main() {
  new B(); // B1
  new B.named(); // B2
  new C(); // C1
  new C.named(); // C2
}
''');
    ClassElement classA = findElement('A');
    ConstructorElement constA = classA.constructors[0];
    ConstructorElement constA_named = classA.constructors[1];
    assertThat(constA)
      ..isReferencedAt('(); // B1', true, length: 0)
      ..isReferencedAt('(); // C1', true, length: 0);
    assertThat(constA_named)
      ..isReferencedAt('.named(); // B2', true, length: 6)
      ..isReferencedAt('.named(); // C2', true, length: 6);
  }

  test_isReferencedBy_ConstructorElement_classTypeAlias_cycle() async {
    await _indexTestUnit('''
class M {}
class A = B with M;
class B = A with M;
main() {
  new A();
  new B();
}
''');
    // No additional validation, but it should not fail with stack overflow.
  }

  test_isReferencedBy_ConstructorElement_namedOnlyWithDot() async {
    await _indexTestUnit('''
class A {
  A.named() {}
}
main() {
  new A.named();
}
''');
    // has ".named()", but does not have "named()"
    int offsetWithoutDot = findOffset('named();');
    int offsetWithDot = findOffset('.named();');
    expect(index.usedElementOffsets, isNot(contains(offsetWithoutDot)));
    expect(index.usedElementOffsets, contains(offsetWithDot));
  }

  test_isReferencedBy_ConstructorElement_redirection() async {
    await _indexTestUnit('''
class A {
  A() : this.bar(); // 1
  A.foo() : this(); // 2
  A.bar();
}
''');
    ClassElement classA = findElement('A');
    ConstructorElement constA = classA.constructors[0];
    ConstructorElement constA_bar = classA.constructors[2];
    assertThat(constA).isReferencedAt('(); // 2', true, length: 0);
    assertThat(constA_bar).isReferencedAt('.bar(); // 1', true, length: 4);
  }

  test_isReferencedBy_ConstructorElement_synthetic() async {
    await _indexTestUnit('''
class A {}
main() {
  new A(); // 1
}
''');
    ClassElement classA = findElement('A');
    ConstructorElement constA = classA.constructors[0];
    // A()
    assertThat(constA)..isReferencedAt('(); // 1', true, length: 0);
  }

  test_isReferencedBy_DynamicElement() async {
    await _indexTestUnit('''
dynamic f() {
}''');
    expect(index.usedElementOffsets, isEmpty);
  }

  test_isReferencedBy_FieldElement() async {
    await _indexTestUnit('''
class A {
  var field;
  A({this.field});
  m() {
    field = 2; // nq
    print(field); // nq
  }
}
main(A a) {
  a.field = 3; // q
  print(a.field); // q
  new A(field: 4);
}
''');
    FieldElement field = findElement('field', ElementKind.FIELD);
    PropertyAccessorElement getter = field.getter;
    PropertyAccessorElement setter = field.setter;
    // A()
    assertThat(field)..isWrittenAt('field});', true);
    // m()
    assertThat(setter)..isReferencedAt('field = 2; // nq', false);
    assertThat(getter)..isReferencedAt('field); // nq', false);
    // main()
    assertThat(setter)..isReferencedAt('field = 3; // q', true);
    assertThat(getter)..isReferencedAt('field); // q', true);
    assertThat(field)..isReferencedAt('field: 4', true);
  }

  test_isReferencedBy_FieldElement_multiple() async {
    await _indexTestUnit('''
class A {
  var aaa;
  var bbb;
  A(this.aaa, this.bbb) {}
  m() {
    print(aaa);
    aaa = 1;
    print(bbb);
    bbb = 2;
  }
}
''');
    // aaa
    {
      FieldElement field = findElement('aaa', ElementKind.FIELD);
      PropertyAccessorElement getter = field.getter;
      PropertyAccessorElement setter = field.setter;
      assertThat(field)..isWrittenAt('aaa, ', true);
      assertThat(getter)..isReferencedAt('aaa);', false);
      assertThat(setter)..isReferencedAt('aaa = 1;', false);
    }
    // bbb
    {
      FieldElement field = findElement('bbb', ElementKind.FIELD);
      PropertyAccessorElement getter = field.getter;
      PropertyAccessorElement setter = field.setter;
      assertThat(field)..isWrittenAt('bbb) {}', true);
      assertThat(getter)..isReferencedAt('bbb);', false);
      assertThat(setter)..isReferencedAt('bbb = 2;', false);
    }
  }

  test_isReferencedBy_FieldElement_ofEnum() async {
    await _indexTestUnit('''
enum MyEnum {
  A, B, C
}
main() {
  print(MyEnum.values);
  print(MyEnum.A.index);
  print(MyEnum.A);
  print(MyEnum.B);
}
''');
    ClassElement enumElement = findElement('MyEnum');
    assertThat(enumElement.getGetter('values'))
      ..isReferencedAt('values);', true);
    assertThat(enumElement.getGetter('index'))..isReferencedAt('index);', true);
    assertThat(enumElement.getGetter('A'))..isReferencedAt('A);', true);
    assertThat(enumElement.getGetter('B'))..isReferencedAt('B);', true);
  }

  test_isReferencedBy_FieldElement_synthetic_hasGetter() async {
    await _indexTestUnit('''
class A {
  A() : f = 42;
  int get f => 0;
}
''');
    ClassElement element2 = findElement('A');
    assertThat(element2.getField('f')).isWrittenAt('f = 42', true);
  }

  test_isReferencedBy_FieldElement_synthetic_hasGetterSetter() async {
    await _indexTestUnit('''
class A {
  A() : f = 42;
  int get f => 0;
  set f(_) {}
}
''');
    ClassElement element2 = findElement('A');
    assertThat(element2.getField('f')).isWrittenAt('f = 42', true);
  }

  test_isReferencedBy_FieldElement_synthetic_hasSetter() async {
    await _indexTestUnit('''
class A {
  A() : f = 42;
  set f(_) {}
}
''');
    ClassElement element2 = findElement('A');
    assertThat(element2.getField('f')).isWrittenAt('f = 42', true);
  }

  test_isReferencedBy_FunctionElement() async {
    await _indexTestUnit('''
foo() {}
main() {
  print(foo);
  print(foo());
}
''');
    FunctionElement element = findElement('foo');
    assertThat(element)
      ..isReferencedAt('foo);', false)
      ..isInvokedAt('foo());', false);
  }

  test_isReferencedBy_FunctionElement_with_LibraryElement() async {
    provider.newFile(_p('$testProject/foo.dart'), r'''
bar() {}
''');
    await _indexTestUnit('''
import "foo.dart";
main() {
  bar();
}
''');
    LibraryElement fooLibrary = testLibraryElement.imports[0].importedLibrary;
    assertThat(fooLibrary)..isReferencedAt('"foo.dart";', true, length: 10);
    {
      FunctionElement bar = fooLibrary.definingCompilationUnit.functions[0];
      assertThat(bar)..isInvokedAt('bar();', false);
    }
  }

  test_isReferencedBy_FunctionTypeAliasElement() async {
    await _indexTestUnit('''
typedef A();
main(A p) {
}
''');
    Element element = findElement('A');
    assertThat(element)..isReferencedAt('A p) {', false);
  }

  /**
   * There was a bug in the AST structure, when single [Comment] was cloned and
   * assigned to both [FieldDeclaration] and [VariableDeclaration].
   *
   * This caused duplicate indexing.
   * Here we test that the problem is fixed one way or another.
   */
  test_isReferencedBy_identifierInComment() async {
    await _indexTestUnit('''
class A {}
/// [A] text
var myVariable = null;
''');
    Element element = findElement('A');
    assertThat(element)..isReferencedAt('A] text', false);
  }

  test_isReferencedBy_MethodElement() async {
    await _indexTestUnit('''
class A {
  method() {}
  main() {
    print(this.method); // q
    print(method); // nq
  }
}''');
    MethodElement element = findElement('method');
    assertThat(element)
      ..isReferencedAt('method); // q', true)
      ..isReferencedAt('method); // nq', false);
  }

  test_isReferencedBy_MultiplyDefinedElement() async {
    provider.newFile(_p('$testProject/a1.dart'), 'class A {}');
    provider.newFile(_p('$testProject/a2.dart'), 'class A {}');
    await _indexTestUnit('''
import 'a1.dart';
import 'a2.dart';
A v = null;
''');
  }

  test_isReferencedBy_ParameterElement() async {
    await _indexTestUnit('''
foo({var p}) {}
main() {
  foo(p: 1);
}
''');
    Element element = findElement('p');
    assertThat(element)..isReferencedAt('p: 1', true);
  }

  test_isReferencedBy_synthetic_leastUpperBound() async {
    await _indexTestUnit('''
int f1({int p}) => 1;
int f2({int p}) => 2;
main(bool b) {
  var f = b ? f1 : f2;
  f(p: 0);
}''');
    // We should not crash because of reference to "p" - a named parameter
    // of a synthetic LUB FunctionElement created for "f".
  }

  test_isReferencedBy_TopLevelVariableElement() async {
    provider.newFile(_p('$testProject/lib.dart'), '''
library lib;
var V;
''');
    await _indexTestUnit('''
import 'lib.dart' show V; // imp
import 'lib.dart' as pref;
main() {
  pref.V = 5; // q
  print(pref.V); // q
  V = 5; // nq
  print(V); // nq
}''');
    TopLevelVariableElement variable = importedUnit().topLevelVariables[0];
    assertThat(variable)..isReferencedAt('V; // imp', true);
    assertThat(variable.getter)
      ..isReferencedAt('V); // q', true)
      ..isReferencedAt('V); // nq', false);
    assertThat(variable.setter)
      ..isReferencedAt('V = 5; // q', true)
      ..isReferencedAt('V = 5; // nq', false);
  }

  test_isReferencedBy_TopLevelVariableElement_synthetic_hasGetterSetter() async {
    provider.newFile(_p('$testProject/lib.dart'), '''
int get V => 0;
void set V(_) {}
''');
    await _indexTestUnit('''
import 'lib.dart' show V;
''');
    TopLevelVariableElement element = importedUnit().topLevelVariables[0];
    assertThat(element).isReferencedAt('V;', true);
  }

  test_isReferencedBy_TopLevelVariableElement_synthetic_hasSetter() async {
    provider.newFile(_p('$testProject/lib.dart'), '''
void set V(_) {}
''');
    await _indexTestUnit('''
import 'lib.dart' show V;
''');
    TopLevelVariableElement element = importedUnit().topLevelVariables[0];
    assertThat(element).isReferencedAt('V;', true);
  }

  test_isReferencedBy_typeInVariableList() async {
    await _indexTestUnit('''
class A {}
A myVariable = null;
''');
    Element element = findElement('A');
    assertThat(element).isReferencedAt('A myVariable', false);
  }

  test_isWrittenBy_FieldElement() async {
    await _indexTestUnit('''
class A {
  int field;
  A.foo({this.field});
  A.bar() : field = 5;
}
''');
    FieldElement element = findElement('field', ElementKind.FIELD);
    assertThat(element)
      ..isWrittenAt('field})', true)
      ..isWrittenAt('field = 5', true);
  }

  test_subtypes_classDeclaration() async {
    String libP = 'package:test/lib.dart;package:test/lib.dart';
    provider.newFile(_p('$testProject/lib.dart'), '''
class A {}
class B {}
class C {}
class D {}
class E {}
''');
    await _indexTestUnit('''
import 'lib.dart';

class X extends A {
  X();
  X.namedConstructor();

  int field1, field2;
  int get getter1 => null;
  void set setter1(_) {}
  void method1() {}
  
  static int staticField;
  static void staticMethod() {}
}

class Y extends Object with B, C {
  void methodY() {}
}

class Z implements E, D {
  void methodZ() {}
}
''');

    {
      AnalysisDriverSubtype X =
          index.subtypes.singleWhere((t) => t.name == 'X');
      expect(X.supertypes, ['$libP;A']);
      expect(X.members, ['field1', 'field2', 'getter1', 'method1', 'setter1']);
    }

    {
      AnalysisDriverSubtype Y =
          index.subtypes.singleWhere((t) => t.name == 'Y');
      expect(
          Y.supertypes, ['dart:core;dart:core;Object', '$libP;B', '$libP;C']);
      expect(Y.members, ['methodY']);
    }

    {
      AnalysisDriverSubtype Z =
          index.subtypes.singleWhere((t) => t.name == 'Z');
      expect(Z.supertypes, ['$libP;D', '$libP;E']);
      expect(Z.members, ['methodZ']);
    }
  }

  test_subtypes_classTypeAlias() async {
    String libP = 'package:test/lib.dart;package:test/lib.dart';
    provider.newFile(_p('$testProject/lib.dart'), '''
class A {}
class B {}
class C {}
class D {}
''');
    await _indexTestUnit('''
import 'lib.dart';

class X = A with B, C;
class Y = A with B implements C, D;
''');

    {
      AnalysisDriverSubtype X =
          index.subtypes.singleWhere((t) => t.name == 'X');
      expect(X.supertypes, ['$libP;A', '$libP;B', '$libP;C']);
      expect(X.members, isEmpty);
    }

    {
      AnalysisDriverSubtype Y =
          index.subtypes.singleWhere((t) => t.name == 'Y');
      expect(Y.supertypes, ['$libP;A', '$libP;B', '$libP;C', '$libP;D']);
      expect(Y.members, isEmpty);
    }
  }

  test_subtypes_dynamic() async {
    await _indexTestUnit('''
class X extends dynamic {
  void foo() {}
}
''');

    AnalysisDriverSubtype X = index.subtypes.singleWhere((t) => t.name == 'X');
    expect(X.supertypes, isEmpty);
    expect(X.members, ['foo']);
  }

  test_usedName_inLibraryIdentifier() async {
    await _indexTestUnit('''
library aaa.bbb.ccc;
class C {
  var bbb;
}
main(p) {
  p.bbb = 1;
}
''');
    assertThatName('bbb')
      ..isNotUsed('bbb.ccc', IndexRelationKind.IS_READ_BY)
      ..isUsedQ('bbb = 1;', IndexRelationKind.IS_WRITTEN_BY);
  }

  test_usedName_qualified_resolved() async {
    await _indexTestUnit('''
class C {
  var x;
}
main(C c) {
  c.x;
  c.x = 1;
  c.x += 2;
  c.x();
}
''');
    assertThatName('x')
      ..isNotUsedQ('x;', IndexRelationKind.IS_READ_BY)
      ..isNotUsedQ('x = 1;', IndexRelationKind.IS_WRITTEN_BY)
      ..isNotUsedQ('x += 2;', IndexRelationKind.IS_READ_WRITTEN_BY)
      ..isNotUsedQ('x();', IndexRelationKind.IS_INVOKED_BY);
  }

  test_usedName_qualified_unresolved() async {
    await _indexTestUnit('''
main(p) {
  p.x;
  p.x = 1;
  p.x += 2;
  p.x();
}
''');
    assertThatName('x')
      ..isUsedQ('x;', IndexRelationKind.IS_READ_BY)
      ..isUsedQ('x = 1;', IndexRelationKind.IS_WRITTEN_BY)
      ..isUsedQ('x += 2;', IndexRelationKind.IS_READ_WRITTEN_BY)
      ..isUsedQ('x();', IndexRelationKind.IS_INVOKED_BY);
  }

  test_usedName_unqualified_resolved() async {
    await _indexTestUnit('''
class C {
  var x;
  m() {
    x;
    x = 1;
    x += 2;
    x();
  }
}
''');
    assertThatName('x')
      ..isNotUsedQ('x;', IndexRelationKind.IS_READ_BY)
      ..isNotUsedQ('x = 1;', IndexRelationKind.IS_WRITTEN_BY)
      ..isNotUsedQ('x += 2;', IndexRelationKind.IS_READ_WRITTEN_BY)
      ..isNotUsedQ('x();', IndexRelationKind.IS_INVOKED_BY);
  }

  test_usedName_unqualified_unresolved() async {
    await _indexTestUnit('''
main() {
  x;
  x = 1;
  x += 2;
  x();
}
''');
    assertThatName('x')
      ..isUsed('x;', IndexRelationKind.IS_READ_BY)
      ..isUsed('x = 1;', IndexRelationKind.IS_WRITTEN_BY)
      ..isUsed('x += 2;', IndexRelationKind.IS_READ_WRITTEN_BY)
      ..isUsed('x();', IndexRelationKind.IS_INVOKED_BY);
  }

  /**
   * Asserts that [index] has an item with the expected properties.
   */
  void _assertHasRelation(
      Element element,
      List<_Relation> relations,
      IndexRelationKind expectedRelationKind,
      ExpectedLocation expectedLocation) {
    for (_Relation relation in relations) {
      if (relation.kind == expectedRelationKind &&
          relation.offset == expectedLocation.offset &&
          relation.length == expectedLocation.length &&
          relation.isQualified == expectedLocation.isQualified) {
        return;
      }
    }
    _failWithIndexDump(
        'not found\n$element $expectedRelationKind at $expectedLocation');
  }

  void _assertUsedName(String name, IndexRelationKind kind,
      ExpectedLocation expectedLocation, bool isNot) {
    int nameId = _getStringId(name);
    for (int i = 0; i < index.usedNames.length; i++) {
      if (index.usedNames[i] == nameId &&
          index.usedNameKinds[i] == kind &&
          index.usedNameOffsets[i] == expectedLocation.offset &&
          index.usedNameIsQualifiedFlags[i] == expectedLocation.isQualified) {
        if (isNot) {
          _failWithIndexDump('Unexpected $name $kind at $expectedLocation');
        }
        return;
      }
    }
    if (isNot) {
      return;
    }
    _failWithIndexDump('Not found $name $kind at $expectedLocation');
  }

  ExpectedLocation _expectedLocation(String search, bool isQualified,
      {int length}) {
    int offset = findOffset(search);
    if (length == null) {
      length = getLeadingIdentifierLength(search);
    }
    return new ExpectedLocation(testUnitElement, offset, length, isQualified);
  }

  void _failWithIndexDump(String msg) {
    String packageIndexJsonString =
        new JsonEncoder.withIndent('  ').convert(index.toJson());
    fail('$msg in\n' + packageIndexJsonString);
  }

  /**
   * Return the [element] identifier in [index] or fail.
   */
  int _findElementId(Element element) {
    int unitId = _getUnitId(element);
    // Prepare the element that was put into the index.
    IndexElementInfo info = new IndexElementInfo(element);
    element = info.element;
    // Prepare element's name components.
    int unitMemberId = index.nullStringId;
    int classMemberId = index.nullStringId;
    int parameterId = index.nullStringId;
    for (Element e = element; e != null; e = e.enclosingElement) {
      if (e.enclosingElement is CompilationUnitElement) {
        unitMemberId = _getStringId(e.name);
        break;
      }
    }
    for (Element e = element; e != null; e = e.enclosingElement) {
      if (e.enclosingElement is ClassElement) {
        classMemberId = _getStringId(e.name);
        break;
      }
    }
    if (element is ParameterElement) {
      parameterId = _getStringId(element.name);
    }
    // Find the element's id.
    for (int elementId = 0;
        elementId < index.elementUnits.length;
        elementId++) {
      if (index.elementUnits[elementId] == unitId &&
          index.elementNameUnitMemberIds[elementId] == unitMemberId &&
          index.elementNameClassMemberIds[elementId] == classMemberId &&
          index.elementNameParameterIds[elementId] == parameterId &&
          index.elementKinds[elementId] == info.kind) {
        return elementId;
      }
    }
    _failWithIndexDump('Element $element is not referenced');
    return 0;
  }

  /**
   * Return all relations with [element] in [index].
   */
  List<_Relation> _getElementRelations(Element element) {
    int elementId = _findElementId(element);
    List<_Relation> relations = <_Relation>[];
    for (int i = 0; i < index.usedElementOffsets.length; i++) {
      if (index.usedElements[i] == elementId) {
        relations.add(new _Relation(
            index.usedElementKinds[i],
            index.usedElementOffsets[i],
            index.usedElementLengths[i],
            index.usedElementIsQualifiedFlags[i]));
      }
    }
    return relations;
  }

  int _getStringId(String str) {
    int id = index.strings.indexOf(str);
    if (id < 0) {
      _failWithIndexDump('String "$str" is not referenced');
    }
    return id;
  }

  int _getUnitId(Element element) {
    CompilationUnitElement unitElement = getUnitElement(element);
    int libraryUriId = _getUriId(unitElement.library.source.uri);
    int unitUriId = _getUriId(unitElement.source.uri);
    expect(index.unitLibraryUris, hasLength(index.unitUnitUris.length));
    for (int i = 0; i < index.unitLibraryUris.length; i++) {
      if (index.unitLibraryUris[i] == libraryUriId &&
          index.unitUnitUris[i] == unitUriId) {
        return i;
      }
    }
    _failWithIndexDump('Unit $unitElement of $element is not referenced');
    return -1;
  }

  int _getUriId(Uri uri) {
    String str = uri.toString();
    return _getStringId(str);
  }

  Future<Null> _indexTestUnit(String code) async {
    addTestFile(code);

    AnalysisResult result = await driver.getResult(testFile);
    testUnit = result.unit;
    testUnitElement = testUnit.element;
    testLibraryElement = testUnitElement.library;

    AnalysisDriverUnitIndexBuilder indexBuilder = indexUnit(testUnit);
    List<int> indexBytes = indexBuilder.toBuffer();
    index = new AnalysisDriverUnitIndex.fromBuffer(indexBytes);
  }

  String _p(String path) => provider.convertPath(path);
}

class _ElementIndexAssert {
  final IndexTest test;
  final Element element;
  final List<_Relation> relations;

  _ElementIndexAssert(this.test, this.element, this.relations);

  void hasRelationCount(int expectedCount) {
    expect(relations, hasLength(expectedCount));
  }

  void isAncestorOf(String search, {int length}) {
    test._assertHasRelation(
        element,
        relations,
        IndexRelationKind.IS_ANCESTOR_OF,
        test._expectedLocation(search, false, length: length));
  }

  void isExtendedAt(String search, bool isQualified, {int length}) {
    test._assertHasRelation(
        element,
        relations,
        IndexRelationKind.IS_EXTENDED_BY,
        test._expectedLocation(search, isQualified, length: length));
  }

  void isImplementedAt(String search, bool isQualified, {int length}) {
    test._assertHasRelation(
        element,
        relations,
        IndexRelationKind.IS_IMPLEMENTED_BY,
        test._expectedLocation(search, isQualified, length: length));
  }

  void isInvokedAt(String search, bool isQualified, {int length}) {
    test._assertHasRelation(element, relations, IndexRelationKind.IS_INVOKED_BY,
        test._expectedLocation(search, isQualified, length: length));
  }

  void isMixedInAt(String search, bool isQualified, {int length}) {
    test._assertHasRelation(
        element,
        relations,
        IndexRelationKind.IS_MIXED_IN_BY,
        test._expectedLocation(search, isQualified, length: length));
  }

  void isReferencedAt(String search, bool isQualified, {int length}) {
    test._assertHasRelation(
        element,
        relations,
        IndexRelationKind.IS_REFERENCED_BY,
        test._expectedLocation(search, isQualified, length: length));
  }

  void isWrittenAt(String search, bool isQualified, {int length}) {
    test._assertHasRelation(element, relations, IndexRelationKind.IS_WRITTEN_BY,
        test._expectedLocation(search, isQualified, length: length));
  }
}

class _NameIndexAssert {
  final IndexTest test;
  final String name;

  _NameIndexAssert(this.test, this.name);

  void isNotUsed(String search, IndexRelationKind kind) {
    test._assertUsedName(
        name, kind, test._expectedLocation(search, false), true);
  }

  void isNotUsedQ(String search, IndexRelationKind kind) {
    test._assertUsedName(
        name, kind, test._expectedLocation(search, true), true);
  }

  void isUsed(String search, IndexRelationKind kind) {
    test._assertUsedName(
        name, kind, test._expectedLocation(search, false), false);
  }

  void isUsedQ(String search, IndexRelationKind kind) {
    test._assertUsedName(
        name, kind, test._expectedLocation(search, true), false);
  }
}

class _Relation {
  final IndexRelationKind kind;
  final int offset;
  final int length;
  final bool isQualified;

  _Relation(this.kind, this.offset, this.length, this.isQualified);

  @override
  String toString() {
    return '_Relation{kind: $kind, offset: $offset, length: $length, '
        'isQualified: $isQualified}lified)';
  }
}
