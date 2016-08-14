// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/index_unit.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import '../abstract_single_unit.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(PackageIndexAssemblerTest);
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
class PackageIndexAssemblerTest extends AbstractSingleUnitTest {
  PackageIndex packageIndex;
  UnitIndex unitIndex;

  _ElementIndexAssert assertThat(Element element) {
    List<_Relation> relations = _getElementRelations(element);
    return new _ElementIndexAssert(this, element, relations);
  }

  _NameIndexAssert assertThatName(String name) {
    return new _NameIndexAssert(this, name);
  }

  CompilationUnitElement importedUnit({int index: 0}) {
    List<ImportElement> imports = testLibraryElement.imports;
    return imports[index].importedLibrary.definingCompilationUnit;
  }

  void test_definedName_classMember_field() {
    _indexTestUnit('''
class A {
  int f;
}''');
    _assertDefinedName('f', IndexNameKind.classMember, 'f;');
  }

  void test_definedName_classMember_getter() {
    _indexTestUnit('''
class A {
  int get g => 0;
}''');
    _assertDefinedName('g', IndexNameKind.classMember, 'g => 0;');
  }

  void test_definedName_classMember_method() {
    _indexTestUnit('''
class A {
  m() {}
}''');
    _assertDefinedName('m', IndexNameKind.classMember, 'm() {}');
  }

  void test_definedName_classMember_operator() {
    _indexTestUnit('''
class A {
  operator +(o) {}
}''');
    _assertDefinedName('+', IndexNameKind.classMember, '+(o) {}');
  }

  void test_definedName_classMember_setter() {
    _indexTestUnit('''
class A {
  int set s (_) {}
}''');
    _assertDefinedName('s', IndexNameKind.classMember, 's (_) {}');
  }

  void test_definedName_topLevel_class() {
    _indexTestUnit('class A {}');
    _assertDefinedName('A', IndexNameKind.topLevel, 'A {}');
  }

  void test_definedName_topLevel_class2() {
    _indexTestUnit('class A {}', declOnly: true);
    _assertDefinedName('A', IndexNameKind.topLevel, 'A {}');
  }

  void test_definedName_topLevel_classAlias() {
    _indexTestUnit('''
class M {}
class C = Object with M;''');
    _assertDefinedName('C', IndexNameKind.topLevel, 'C =');
  }

  void test_definedName_topLevel_enum() {
    _indexTestUnit('enum E {a, b, c}');
    _assertDefinedName('E', IndexNameKind.topLevel, 'E {');
  }

  void test_definedName_topLevel_function() {
    _indexTestUnit('foo() {}');
    _assertDefinedName('foo', IndexNameKind.topLevel, 'foo() {}');
  }

  void test_definedName_topLevel_functionTypeAlias() {
    _indexTestUnit('typedef F(int p);');
    _assertDefinedName('F', IndexNameKind.topLevel, 'F(int p);');
  }

  void test_definedName_topLevel_getter() {
    _indexTestUnit('''
int get g => 0;
''');
    _assertDefinedName('g', IndexNameKind.topLevel, 'g => 0;');
  }

  void test_definedName_topLevel_setter() {
    _indexTestUnit('''
int set s (_) {}
''');
    _assertDefinedName('s', IndexNameKind.topLevel, 's (_) {}');
  }

  void test_definedName_topLevel_topLevelVariable() {
    _indexTestUnit('var V = 42;');
    _assertDefinedName('V', IndexNameKind.topLevel, 'V = 42;');
  }

  void test_hasAncestor_ClassDeclaration() {
    _indexTestUnit('''
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

  void test_hasAncestor_ClassTypeAlias() {
    _indexTestUnit('''
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

  void test_isExtendedBy_ClassDeclaration() {
    _indexTestUnit('''
class A {} // 1
class B extends A {} // 2
''');
    ClassElement elementA = findElement('A');
    assertThat(elementA)
      ..isExtendedAt('A {} // 2', false)
      ..isReferencedAt('A {} // 2', false);
  }

  void test_isExtendedBy_ClassDeclaration_isQualified() {
    addSource(
        '/lib.dart',
        '''
class A {}
''');
    _indexTestUnit('''
import 'lib.dart' as p;
class B extends p.A {} // 2
''');
    ClassElement elementA = importedUnit().getType('A');
    assertThat(elementA).isExtendedAt('A {} // 2', true);
  }

  void test_isExtendedBy_ClassDeclaration_Object() {
    _indexTestUnit('''
class A {}
''');
    ClassElement elementA = findElement('A');
    ClassElement elementObject = elementA.supertype.element;
    assertThat(elementObject).isExtendedAt('A {}', true, length: 0);
  }

  void test_isExtendedBy_ClassTypeAlias() {
    _indexTestUnit('''
class A {}
class B {}
class C = A with B;
''');
    ClassElement elementA = findElement('A');
    assertThat(elementA)
      ..isExtendedAt('A with', false)
      ..isReferencedAt('A with', false);
  }

  void test_isExtendedBy_ClassTypeAlias_isQualified() {
    addSource(
        '/lib.dart',
        '''
class A {}
''');
    _indexTestUnit('''
import 'lib.dart' as p;
class B {}
class C = p.A with B;
''');
    ClassElement elementA = importedUnit().getType('A');
    assertThat(elementA)
      ..isExtendedAt('A with', true)
      ..isReferencedAt('A with', true);
  }

  void test_isImplementedBy_ClassDeclaration() {
    _indexTestUnit('''
class A {} // 1
class B implements A {} // 2
''');
    ClassElement elementA = findElement('A');
    assertThat(elementA)
      ..isImplementedAt('A {} // 2', false)
      ..isReferencedAt('A {} // 2', false);
  }

  void test_isImplementedBy_ClassDeclaration_isQualified() {
    addSource(
        '/lib.dart',
        '''
class A {}
''');
    _indexTestUnit('''
import 'lib.dart' as p;
class B implements p.A {} // 2
''');
    ClassElement elementA = importedUnit().getType('A');
    assertThat(elementA)
      ..isImplementedAt('A {} // 2', true)
      ..isReferencedAt('A {} // 2', true);
  }

  void test_isImplementedBy_ClassTypeAlias() {
    _indexTestUnit('''
class A {} // 1
class B {} // 2
class C = Object with A implements B; // 3
''');
    ClassElement elementB = findElement('B');
    assertThat(elementB)
      ..isImplementedAt('B; // 3', false)
      ..isReferencedAt('B; // 3', false);
  }

  void test_isInvokedBy_FieldElement() {
    _indexTestUnit('''
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

  void test_isInvokedBy_FunctionElement() {
    addSource(
        '/lib.dart',
        '''
library lib;
foo() {}
''');
    _indexTestUnit('''
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

  void test_isInvokedBy_FunctionElement_synthetic_loadLibrary() {
    verifyNoTestUnitErrors = false;
    _indexTestUnit('''
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

  void test_isInvokedBy_MethodElement() {
    _indexTestUnit('''
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

  void test_isInvokedBy_MethodElement_propagatedType() {
    _indexTestUnit('''
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

  void test_isInvokedBy_operator_binary() {
    _indexTestUnit('''
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

  void test_isInvokedBy_operator_index() {
    _indexTestUnit('''
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

  void test_isInvokedBy_operator_prefix() {
    _indexTestUnit('''
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

  void test_isInvokedBy_PropertyAccessorElement_getter() {
    _indexTestUnit('''
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

  void test_isMixedInBy_ClassDeclaration() {
    _indexTestUnit('''
class A {} // 1
class B extends Object with A {} // 2
''');
    ClassElement elementA = findElement('A');
    assertThat(elementA)
      ..isMixedInAt('A {} // 2', false)
      ..isReferencedAt('A {} // 2', false);
  }

  void test_isMixedInBy_ClassDeclaration_isQualified() {
    addSource(
        '/lib.dart',
        '''
class A {}
''');
    _indexTestUnit('''
import 'lib.dart' as p;
class B extends Object with p.A {} // 2
''');
    ClassElement elementA = importedUnit().getType('A');
    assertThat(elementA).isMixedInAt('A {} // 2', true);
  }

  void test_isMixedInBy_ClassTypeAlias() {
    _indexTestUnit('''
class A {} // 1
class B = Object with A; // 2
''');
    ClassElement elementA = findElement('A');
    assertThat(elementA).isMixedInAt('A; // 2', false);
  }

  void test_isReferencedBy_ClassElement() {
    _indexTestUnit('''
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

  void test_isReferencedBy_ClassElement_invocation() {
    verifyNoTestUnitErrors = false;
    _indexTestUnit('''
class A {}
main() {
  A(); // invalid code, but still a reference
}''');
    Element element = findElement('A');
    assertThat(element).isReferencedAt('A();', false);
  }

  void test_isReferencedBy_ClassElement_invocation_isQualified() {
    verifyNoTestUnitErrors = false;
    addSource(
        '/lib.dart',
        '''
class A {}
''');
    _indexTestUnit('''
import 'lib.dart' as p;
main() {
  p.A(); // invalid code, but still a reference
}''');
    Element element = importedUnit().getType('A');
    assertThat(element).isReferencedAt('A();', true);
  }

  void test_isReferencedBy_ClassTypeAlias() {
    _indexTestUnit('''
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

  void test_isReferencedBy_CompilationUnitElement_export() {
    addSource(
        '/lib.dart',
        '''
library lib;
''');
    _indexTestUnit('''
export 'lib.dart';
''');
    LibraryElement element = testLibraryElement.exports[0].exportedLibrary;
    assertThat(element)..isReferencedAt("'lib.dart'", true, length: 10);
  }

  void test_isReferencedBy_CompilationUnitElement_import() {
    addSource(
        '/lib.dart',
        '''
library lib;
''');
    _indexTestUnit('''
import 'lib.dart';
''');
    LibraryElement element = testLibraryElement.imports[0].importedLibrary;
    assertThat(element)..isReferencedAt("'lib.dart'", true, length: 10);
  }

  void test_isReferencedBy_CompilationUnitElement_part() {
    addSource('/my_unit.dart', 'part of my_lib;');
    _indexTestUnit('''
library my_lib;
part 'my_unit.dart';
''');
    CompilationUnitElement element = testLibraryElement.parts[0];
    assertThat(element)..isReferencedAt("'my_unit.dart';", true, length: 14);
  }

  void test_isReferencedBy_ConstructorElement() {
    _indexTestUnit('''
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

  void test_isReferencedBy_ConstructorElement_classTypeAlias() {
    _indexTestUnit('''
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

  void test_isReferencedBy_ConstructorElement_classTypeAlias_cycle() {
    _indexTestUnit('''
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

  void test_isReferencedBy_ConstructorElement_namedOnlyWithDot() {
    _indexTestUnit('''
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
    expect(unitIndex.usedElementOffsets, isNot(contains(offsetWithoutDot)));
    expect(unitIndex.usedElementOffsets, contains(offsetWithDot));
  }

  void test_isReferencedBy_ConstructorElement_redirection() {
    _indexTestUnit('''
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

  void test_isReferencedBy_ConstructorElement_synthetic() {
    _indexTestUnit('''
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

  void test_isReferencedBy_DynamicElement() {
    _indexTestUnit('''
dynamic f() {
}''');
    expect(unitIndex.usedElementOffsets, isEmpty);
  }

  void test_isReferencedBy_FieldElement() {
    _indexTestUnit('''
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

  void test_isReferencedBy_FieldElement_multiple() {
    _indexTestUnit('''
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

  void test_isReferencedBy_FieldElement_ofEnum() {
    verifyNoTestUnitErrors = false;
    _indexTestUnit('''
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

  void test_isReferencedBy_FieldElement_synthetic_hasGetter() {
    verifyNoTestUnitErrors = false;
    _indexTestUnit('''
class A {
  A() : f = 42;
  int get f => 0;
}
''');
    ClassElement element2 = findElement('A');
    assertThat(element2.getField('f')).isWrittenAt('f = 42', true);
  }

  void test_isReferencedBy_FieldElement_synthetic_hasGetterSetter() {
    verifyNoTestUnitErrors = false;
    _indexTestUnit('''
class A {
  A() : f = 42;
  int get f => 0;
  set f(_) {}
}
''');
    ClassElement element2 = findElement('A');
    assertThat(element2.getField('f')).isWrittenAt('f = 42', true);
  }

  void test_isReferencedBy_FieldElement_synthetic_hasSetter() {
    verifyNoTestUnitErrors = false;
    _indexTestUnit('''
class A {
  A() : f = 42;
  set f(_) {}
}
''');
    ClassElement element2 = findElement('A');
    assertThat(element2.getField('f')).isWrittenAt('f = 42', true);
  }

  void test_isReferencedBy_FunctionElement() {
    _indexTestUnit('''
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

  void test_isReferencedBy_FunctionElement_with_LibraryElement() {
    addSource(
        '/foo.dart',
        r'''
bar() {}
''');
    _indexTestUnit('''
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

  void test_isReferencedBy_FunctionTypeAliasElement() {
    _indexTestUnit('''
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
  void test_isReferencedBy_identifierInComment() {
    _indexTestUnit('''
class A {}
/// [A] text
var myVariable = null;
''');
    Element element = findElement('A');
    assertThat(element)..isReferencedAt('A] text', false);
  }

  void test_isReferencedBy_MethodElement() {
    _indexTestUnit('''
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

  void test_isReferencedBy_ParameterElement() {
    _indexTestUnit('''
foo({var p}) {}
main() {
  foo(p: 1);
}
''');
    Element element = findElement('p');
    assertThat(element)..isReferencedAt('p: 1', true);
  }

  void test_isReferencedBy_TopLevelVariableElement() {
    addSource(
        '/lib.dart',
        '''
library lib;
var V;
''');
    _indexTestUnit('''
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

  void test_isReferencedBy_TopLevelVariableElement_synthetic_hasGetterSetter() {
    verifyNoTestUnitErrors = false;
    addSource(
        '/lib.dart',
        '''
int get V => 0;
void set V(_) {}
''');
    _indexTestUnit('''
import 'lib.dart' show V;
''');
    TopLevelVariableElement element = importedUnit().topLevelVariables[0];
    assertThat(element).isReferencedAt('V;', true);
  }

  void test_isReferencedBy_TopLevelVariableElement_synthetic_hasSetter() {
    verifyNoTestUnitErrors = false;
    addSource(
        '/lib.dart',
        '''
void set V(_) {}
''');
    _indexTestUnit('''
import 'lib.dart' show V;
''');
    TopLevelVariableElement element = importedUnit().topLevelVariables[0];
    assertThat(element).isReferencedAt('V;', true);
  }

  void test_isReferencedBy_typeInVariableList() {
    _indexTestUnit('''
class A {}
A myVariable = null;
''');
    Element element = findElement('A');
    assertThat(element).isReferencedAt('A myVariable', false);
  }

  void test_isWrittenBy_FieldElement() {
    _indexTestUnit('''
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

  void test_usedName_inLibraryIdentifier() {
    verifyNoTestUnitErrors = false;
    _indexTestUnit('''
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

  void test_usedName_qualified_resolved() {
    verifyNoTestUnitErrors = false;
    _indexTestUnit('''
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

  void test_usedName_qualified_unresolved() {
    verifyNoTestUnitErrors = false;
    _indexTestUnit('''
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

  void test_usedName_unqualified_resolved() {
    verifyNoTestUnitErrors = false;
    _indexTestUnit('''
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

  void test_usedName_unqualified_unresolved() {
    verifyNoTestUnitErrors = false;
    _indexTestUnit('''
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

  void _assertDefinedName(String name, IndexNameKind kind, String search) {
    int offset = findOffset(search);
    int nameId = _getStringId(name);
    for (int i = 0; i < unitIndex.definedNames.length; i++) {
      if (unitIndex.definedNames[i] == nameId &&
          unitIndex.definedNameKinds[i] == kind &&
          unitIndex.definedNameOffsets[i] == offset) {
        return;
      }
    }
    _failWithIndexDump('Not found $name $kind at $offset');
  }

  /**
   * Asserts that [unitIndex] has an item with the expected properties.
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
    for (int i = 0; i < unitIndex.usedNames.length; i++) {
      if (unitIndex.usedNames[i] == nameId &&
          unitIndex.usedNameKinds[i] == kind &&
          unitIndex.usedNameOffsets[i] == expectedLocation.offset &&
          unitIndex.usedNameIsQualifiedFlags[i] ==
              expectedLocation.isQualified) {
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
        new JsonEncoder.withIndent('  ').convert(packageIndex.toJson());
    fail('$msg in\n' + packageIndexJsonString);
  }

  /**
   * Return the [element] identifier in [packageIndex] or fail.
   */
  int _findElementId(Element element) {
    int unitId = _getUnitId(element);
    // Prepare the element that was put into the index.
    IndexElementInfo info = new IndexElementInfo(element);
    element = info.element;
    // Prepare element's name components.
    int unitMemberId = _getStringId(PackageIndexAssembler.NULL_STRING);
    int classMemberId = _getStringId(PackageIndexAssembler.NULL_STRING);
    int parameterId = _getStringId(PackageIndexAssembler.NULL_STRING);
    for (Element e = element; e != null; e = e.enclosingElement) {
      if (e.enclosingElement is CompilationUnitElement) {
        unitMemberId = _getStringId(e.name);
      }
    }
    for (Element e = element; e != null; e = e.enclosingElement) {
      if (e.enclosingElement is ClassElement) {
        classMemberId = _getStringId(e.name);
      }
    }
    if (element is ParameterElement) {
      parameterId = _getStringId(element.name);
    }
    // Find the element's id.
    for (int elementId = 0;
        elementId < packageIndex.elementUnits.length;
        elementId++) {
      if (packageIndex.elementUnits[elementId] == unitId &&
          packageIndex.elementNameUnitMemberIds[elementId] == unitMemberId &&
          packageIndex.elementNameClassMemberIds[elementId] == classMemberId &&
          packageIndex.elementNameParameterIds[elementId] == parameterId &&
          packageIndex.elementKinds[elementId] == info.kind) {
        return elementId;
      }
    }
    _failWithIndexDump('Element $element is not referenced');
    return 0;
  }

  /**
   * Return all relations with [element] in [unitIndex].
   */
  List<_Relation> _getElementRelations(Element element) {
    int elementId = _findElementId(element);
    List<_Relation> relations = <_Relation>[];
    for (int i = 0; i < unitIndex.usedElementOffsets.length; i++) {
      if (unitIndex.usedElements[i] == elementId) {
        relations.add(new _Relation(
            unitIndex.usedElementKinds[i],
            unitIndex.usedElementOffsets[i],
            unitIndex.usedElementLengths[i],
            unitIndex.usedElementIsQualifiedFlags[i]));
      }
    }
    return relations;
  }

  int _getStringId(String str) {
    int id = packageIndex.strings.indexOf(str);
    expect(id, isNonNegative);
    return id;
  }

  int _getUnitId(Element element) {
    CompilationUnitElement unitElement =
        PackageIndexAssembler.getUnitElement(element);
    int libraryUriId = _getUriId(unitElement.library.source.uri);
    int unitUriId = _getUriId(unitElement.source.uri);
    expect(packageIndex.unitLibraryUris,
        hasLength(packageIndex.unitUnitUris.length));
    for (int i = 0; i < packageIndex.unitLibraryUris.length; i++) {
      if (packageIndex.unitLibraryUris[i] == libraryUriId &&
          packageIndex.unitUnitUris[i] == unitUriId) {
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

  void _indexTestUnit(String code, {bool declOnly: false}) {
    resolveTestUnit(code);
    PackageIndexAssembler assembler = new PackageIndexAssembler();
    if (declOnly) {
      assembler.indexDeclarations(testUnit);
    } else {
      assembler.indexUnit(testUnit);
    }
    // assemble, write and read
    PackageIndexBuilder indexBuilder = assembler.assemble();
    List<int> indexBytes = indexBuilder.toBuffer();
    packageIndex = new PackageIndex.fromBuffer(indexBytes);
    // prepare the only unit index
    expect(packageIndex.units, hasLength(1));
    unitIndex = packageIndex.units[0];
    expect(unitIndex.unit, _getUnitId(testUnitElement));
  }
}

class _ElementIndexAssert {
  final PackageIndexAssemblerTest test;
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
  final PackageIndexAssemblerTest test;
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
        'isQualified: $isQualified}';
  }
}
