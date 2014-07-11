// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.src.index.dart_index_contributor;

import 'package:analysis_services/index/index.dart';
import 'package:analysis_services/index/index_store.dart';
import 'package:analysis_services/src/index/index_contributor.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:typed_mock/typed_mock.dart';
import 'package:unittest/unittest.dart';

import 'abstract_single_unit.dart';


main() {
  groupSep = ' | ';
  group('DartUnitContributor', () {
    runReflectiveTests(DartUnitContributorTest);
  });
}


/**
 * Returns `true` if the [actual] location the same properties as [expected].
 */
bool _equalsLocation(Location actual, ExpectedLocation expected) {
  return _equalsLocationProperties(
      actual,
      expected.element,
      expected.offset,
      expected.length);
}


/**
 * Returns `true` if the [actual] location the expected properties.
 */
bool _equalsLocationProperties(Location actual, Element expectedElement,
    int expectedOffset, int expectedLength) {
  return expectedElement == actual.element &&
      expectedOffset == actual.offset &&
      expectedLength == actual.length;
}


bool _equalsRecordedRelation(RecordedRelation recordedRelation,
    Element expectedElement, Relationship expectedRelationship,
    ExpectedLocation expectedLocation) {
  return expectedElement == recordedRelation.element &&
      expectedRelationship == recordedRelation.relationship &&
      (expectedLocation == null ||
          _equalsLocation(recordedRelation.location, expectedLocation));
}


@ReflectiveTestCase()
class DartUnitContributorTest extends AbstractSingleUnitTest {
  IndexStore store = new MockIndexStore();
  List<RecordedRelation> recordedRelations = <RecordedRelation>[];

  void setUp() {
    super.setUp();
    when(store.aboutToIndexDart(context, anyObject)).thenReturn(true);
    when(
        store.recordRelationship(
            anyObject,
            anyObject,
            anyObject)).thenInvoke(
                (Element element, Relationship relationship, Location location) {
      recordedRelations.add(
          new RecordedRelation(element, relationship, location));
    });
  }

  void test_FieldElement_noAssignedType_notLHS() {
    _indexTestUnit('''
class A {
  var myField;
  main() {
    print(myField);
  }
}''');
    // prepare elements
    Element mainElement = findElement("main");
    FieldElement fieldElement = findElement("myField");
    PropertyAccessorElement getterElement = fieldElement.getter;
    // verify
    _assertRecordedRelation(
        getterElement,
        IndexConstants.IS_REFERENCED_BY_UNQUALIFIED,
        _expectedLocation(mainElement, 'myField);'));
  }

  void test_definesClass() {
    _indexTestUnit('class A {}');
    // prepare elements
    ClassElement classElement = findElement("A");
    // verify
    _assertDefinesTopLevelElement(
        IndexConstants.DEFINES_CLASS,
        _expectedLocation(classElement, 'A {}'));
  }

  void test_definesClassAlias() {
    _indexTestUnit('''
class Mix {}
class MyClass = Object with Mix;''');
    // prepare elements
    Element classElement = findElement("MyClass");
    // verify
    _assertDefinesTopLevelElement(
        IndexConstants.DEFINES_CLASS_ALIAS,
        _expectedLocation(classElement, 'MyClass ='));
  }

  void test_definesFunction() {
    _indexTestUnit('myFunction() {}');
    // prepare elements
    FunctionElement functionElement = findElement("myFunction");
    // verify
    _assertDefinesTopLevelElement(
        IndexConstants.DEFINES_FUNCTION,
        _expectedLocation(functionElement, 'myFunction() {}'));
  }

  void test_definesFunctionType() {
    _indexTestUnit('typedef MyFunction(int p);');
    // prepare elements
    FunctionTypeAliasElement typeAliasElement = findElement("MyFunction");
    // verify
    _assertDefinesTopLevelElement(
        IndexConstants.DEFINES_FUNCTION_TYPE,
        _expectedLocation(typeAliasElement, 'MyFunction(int p);'));
  }


  void test_definesVariable() {
    _indexTestUnit('var myVar = 42;');
    // prepare elements
    VariableElement varElement = findElement("myVar");
    // verify
    _assertDefinesTopLevelElement(
        IndexConstants.DEFINES_VARIABLE,
        _expectedLocation(varElement, 'myVar = 42;'));
  }

  void test_forIn() {
    _indexTestUnit('''
main() {
  for (var v in []) {
  }
}''');
    // prepare elements
    Element mainElement = findElement("main");
    VariableElement variableElement = findElement("v");
    // verify
    _assertNoRecordedRelation(
        variableElement,
        IndexConstants.IS_READ_BY,
        _expectedLocation(mainElement, 'v in []'));
  }

  void test_isDefinedBy_ConstructorElement() {
    _indexTestUnit('''
class A {
  A() {}
  A.foo() {}
}''');
    // prepare elements
    ClassElement classA = findElement("A");
    ConstructorElement consA =
        findNodeElementAtString("A()", (node) => node is ConstructorDeclaration);
    ConstructorElement consA_foo =
        findNodeElementAtString("A.foo()", (node) => node is ConstructorDeclaration);
    // verify
    _assertRecordedRelation(
        consA,
        IndexConstants.IS_DEFINED_BY,
        _expectedLocation(classA, '() {}'));
    _assertRecordedRelation(
        consA_foo,
        IndexConstants.IS_DEFINED_BY,
        _expectedLocation(classA, '.foo() {}', '.foo'.length));
  }

  void test_isDefinedBy_NameElement_method() {
    _indexTestUnit('''
class A {
  m() {}
}''');
    // prepare elements
    Element methodElement = findElement("m");
    Element nameElement = new NameElement("m");
    // verify
    _assertRecordedRelation(
        nameElement,
        IndexConstants.IS_DEFINED_BY,
        _expectedLocation(methodElement, 'm() {}'));
  }


  void test_isDefinedBy_NameElement_operator() {
    _indexTestUnit('''
class A {
  operator +(o) {}
}''');
    // prepare elements
    Element methodElement = findElement("+");
    Element nameElement = new NameElement("+");
    // verify
    _assertRecordedRelation(
        nameElement,
        IndexConstants.IS_DEFINED_BY,
        _expectedLocation(methodElement, '+(o) {}', 1));
  }

  void test_isExtendedBy_ClassDeclaration() {
    _indexTestUnit('''
class A {} // 1
class B extends A {} // 2
''');
    // prepare elements
    ClassElement classElementA = findElement("A");
    ClassElement classElementB = findElement("B");
    // verify
    _assertRecordedRelation(
        classElementA,
        IndexConstants.IS_EXTENDED_BY,
        _expectedLocation(classElementB, 'A {} // 2'));
  }

  void test_isExtendedBy_ClassDeclaration_Object() {
    _indexTestUnit('''
class A {} // 1
''');
    // prepare elements
    ClassElement classElementA = findElement("A");
    ClassElement classElementObject = classElementA.supertype.element;
    // verify
    _assertRecordedRelation(
        classElementObject,
        IndexConstants.IS_EXTENDED_BY,
        _expectedLocation(classElementA, 'A {}', 0));
  }

  void test_isExtendedBy_ClassTypeAlias() {
    _indexTestUnit('''
class A {} // 1
class B {} // 2
class C = A with B; // 3
''');
    // prepare elements
    ClassElement classElementA = findElement("A");
    ClassElement classElementC = findElement("C");
    // verify
    _assertRecordedRelation(
        classElementA,
        IndexConstants.IS_EXTENDED_BY,
        _expectedLocation(classElementC, 'A with'));
  }

  void test_isImplementedBy_ClassDeclaration() {
    _indexTestUnit('''
class A {} // 1
class B implements A {} // 2
''');
    // prepare elements
    ClassElement classElementA = findElement("A");
    ClassElement classElementB = findElement("B");
    // verify
    _assertRecordedRelation(
        classElementA,
        IndexConstants.IS_IMPLEMENTED_BY,
        _expectedLocation(classElementB, 'A {} // 2'));
  }

  void test_isImplementedBy_ClassTypeAlias() {
    _indexTestUnit('''
class A {} // 1
class B {} // 2
class C = Object with A implements B; // 3
''');
    // prepare elements
    ClassElement classElementB = findElement("B");
    ClassElement classElementC = findElement("C");
    // verify
    _assertRecordedRelation(
        classElementB,
        IndexConstants.IS_IMPLEMENTED_BY,
        _expectedLocation(classElementC, 'B; // 3'));
  }


  void test_isInvokedByQualified_FieldElement() {
    _indexTestUnit('''
class A {
  var field;
  main() {
    this.field();
  }
}''');
    // prepare elements
    Element mainElement = findElement("main");
    FieldElement fieldElement = findElement("field");
    PropertyAccessorElement getterElement = fieldElement.getter;
    // verify
    _assertRecordedRelation(
        getterElement,
        IndexConstants.IS_INVOKED_BY_QUALIFIED,
        _expectedLocation(mainElement, 'field();'));
  }


  void test_isInvokedByQualified_MethodElement() {
    _indexTestUnit('''
class A {
  foo() {}
  main() {
    this.foo();
  }
}''');
    // prepare elements
    Element mainElement = findElement("main");
    Element methodElement = findElement("foo");
    // verify
    var location = _expectedLocation(mainElement, 'foo();');
    _assertRecordedRelation(
        methodElement,
        IndexConstants.IS_INVOKED_BY_QUALIFIED,
        location);
    _assertNoRecordedRelation(
        methodElement,
        IndexConstants.IS_REFERENCED_BY_QUALIFIED,
        location);
  }

  void test_isInvokedByQualified_MethodElement_propagatedType() {
    _indexTestUnit('''
class A {
  foo() {}
}
main() {
  var a = new A();
  a.foo();
}
''');
    // prepare elements
    Element mainElement = findElement("main");
    Element methodElement = findElement("foo");
    // verify
    _assertRecordedRelation(
        methodElement,
        IndexConstants.IS_INVOKED_BY_QUALIFIED,
        _expectedLocation(mainElement, 'foo();'));
  }

  void test_isInvokedByUnqualified_MethodElement() {
    _indexTestUnit('''
class A {
  foo() {}
  main() {
    foo();
  }
}''');
    // prepare elements
    Element mainElement = findElement("main");
    Element methodElement = findElement("foo");
    // verify
    _assertRecordedRelation(
        methodElement,
        IndexConstants.IS_INVOKED_BY_UNQUALIFIED,
        _expectedLocation(mainElement, 'foo();'));
  }

  void test_isInvokedBy_FunctionElement() {
    _indexTestUnit('''
foo() {}
main() {
  foo();
}''');
    // prepare elements
    Element mainElement = findElement("main");
    FunctionElement functionElement = findElement("foo");
    // verify
    _assertRecordedRelation(
        functionElement,
        IndexConstants.IS_INVOKED_BY,
        _expectedLocation(mainElement, 'foo();'));
  }

  void test_isInvokedBy_LocalVariableElement() {
    _indexTestUnit('''
main() {
  var v;
  v();
}''');
    // prepare elements
    Element mainElement = findElement("main");
    Element element = findElement("v");
    // verify
    _assertRecordedRelation(
        element,
        IndexConstants.IS_INVOKED_BY,
        _expectedLocation(mainElement, 'v();'));
  }

  void test_isInvokedBy_ParameterElement() {
    _indexTestUnit('''
main(p()) {
  p();
}''');
    // prepare elements
    Element mainElement = findElement("main");
    Element element = findElement("p");
    // verify
    _assertRecordedRelation(
        element,
        IndexConstants.IS_INVOKED_BY,
        _expectedLocation(mainElement, 'p();'));
  }

  void test_isMixedInBy_ClassDeclaration() {
    _indexTestUnit('''
class A {} // 1
class B extends Object with A {} // 2
''');
    // prepare elements
    ClassElement classElementA = findElement("A");
    ClassElement classElementB = findElement("B");
    // verify
    _assertRecordedRelation(
        classElementA,
        IndexConstants.IS_MIXED_IN_BY,
        _expectedLocation(classElementB, 'A {} // 2'));
  }

  void test_isMixedInBy_ClassTypeAlias() {
    _indexTestUnit('''
class A {} // 1
class B = Object with A; // 2
''');
    // prepare elements
    ClassElement classElementA = findElement("A");
    ClassElement classElementB = findElement("B");
    // verify
    _assertRecordedRelation(
        classElementA,
        IndexConstants.IS_MIXED_IN_BY,
        _expectedLocation(classElementB, 'A; // 2'));
  }

  void test_isReadBy_ParameterElement() {
    _indexTestUnit('''
main(var p) {
  print(p);
}
''');
    // prepare elements
    Element mainElement = findElement("main");
    Element parameterElement = findElement("p");
    // verify
    _assertRecordedRelation(
        parameterElement,
        IndexConstants.IS_READ_BY,
        _expectedLocation(mainElement, 'p);'));
  }

  void test_isReadBy_VariableElement() {
    _indexTestUnit('''
main() {
  var v = 0;
  print(v);
}
''');
    // prepare elements
    Element mainElement = findElement("main");
    Element variableElement = findElement("v");
    // verify
    _assertRecordedRelation(
        variableElement,
        IndexConstants.IS_READ_BY,
        _expectedLocation(mainElement, 'v);'));
  }

  void test_isReadWrittenBy_ParameterElement() {
    _indexTestUnit('''
main(int p) {
  p += 1;
}
''');
    // prepare elements
    Element mainElement = findElement("main");
    Element parameterElement = findElement("p");
    // verify
    _assertRecordedRelation(
        parameterElement,
        IndexConstants.IS_READ_WRITTEN_BY,
        _expectedLocation(mainElement, 'p += 1'));
  }

  void test_isReadWrittenBy_VariableElement() {
    _indexTestUnit('''
main() {
  var v = 0;
  v += 1;
}
''');
    // prepare elements
    Element mainElement = findElement("main");
    Element variableElement = findElement("v");
    // verify
    _assertRecordedRelation(
        variableElement,
        IndexConstants.IS_READ_WRITTEN_BY,
        _expectedLocation(mainElement, 'v += 1'));
  }

  void test_isReferencedByQualifiedResolved_NameElement_field() {
    _indexTestUnit('''
class A {
  int field;
}
main(A a) {
  print(a.field);
}
''');
    // prepare elements
    Element mainElement = findElement('main');
    Element nameElement = new NameElement('field');
    // verify
    _assertRecordedRelation(
        nameElement,
        IndexConstants.IS_REFERENCED_BY_QUALIFIED_RESOLVED,
        _expectedLocation(mainElement, 'field);'));
  }

  void test_isReferencedByQualifiedResolved_NameElement_method() {
    _indexTestUnit('''
class A {
  method() {}
}
main(A a) {
  a.method();
}
''');
    // prepare elements
    Element mainElement = findElement('main');
    Element nameElement = new NameElement('method');
    // verify
    _assertRecordedRelation(
        nameElement,
        IndexConstants.IS_REFERENCED_BY_QUALIFIED_RESOLVED,
        _expectedLocation(mainElement, 'method();'));
  }

  void test_isReferencedByQualifiedResolved_NameElement_operator() {
    _indexTestUnit('''
class A {
  operator +(o) {}
  operator -(o) {}
  operator ~() {}
  operator ==(o) {}
}
main(A a) {
  a + 5;
  a += 5;
  a == 5;
  ++a;
  --a;
  ~a;
  a++;
  a--;
}
''');
    // prepare elements
    Element mainElement = findElement('main');
    // binary
    _assertRecordedRelation(
        new NameElement('+'),
        IndexConstants.IS_REFERENCED_BY_QUALIFIED_RESOLVED,
        _expectedLocation(mainElement, '+ 5', '+'.length));
    _assertRecordedRelation(
        new NameElement('+'),
        IndexConstants.IS_REFERENCED_BY_QUALIFIED_RESOLVED,
        _expectedLocation(mainElement, '+= 5', '+='.length));
    _assertRecordedRelation(
        new NameElement('=='),
        IndexConstants.IS_REFERENCED_BY_QUALIFIED_RESOLVED,
        _expectedLocation(mainElement, '== 5', '=='.length));
    // prefix
    _assertRecordedRelation(
        new NameElement('+'),
        IndexConstants.IS_REFERENCED_BY_QUALIFIED_RESOLVED,
        _expectedLocation(mainElement, '++a', '++'.length));
    _assertRecordedRelation(
        new NameElement('-'),
        IndexConstants.IS_REFERENCED_BY_QUALIFIED_RESOLVED,
        _expectedLocation(mainElement, '--a', '--'.length));
    _assertRecordedRelation(
        new NameElement('~'),
        IndexConstants.IS_REFERENCED_BY_QUALIFIED_RESOLVED,
        _expectedLocation(mainElement, '~a', '~'.length));
    // postfix
    _assertRecordedRelation(
        new NameElement('+'),
        IndexConstants.IS_REFERENCED_BY_QUALIFIED_RESOLVED,
        _expectedLocation(mainElement, '++;', '++'.length));
    _assertRecordedRelation(
        new NameElement('-'),
        IndexConstants.IS_REFERENCED_BY_QUALIFIED_RESOLVED,
        _expectedLocation(mainElement, '--;', '--'.length));
  }

  void test_isReferencedByQualifiedUnresolved_NameElement_field() {
    _indexTestUnit('''
class A {
  int field;
}
main(var a) {
  print(a.field);
}
''');
    // prepare elements
    Element mainElement = findElement('main');
    FieldElement fieldElement = findElement('field');
    Element nameElement = new NameElement('field');
    // verify
    _assertRecordedRelation(
        nameElement,
        IndexConstants.IS_DEFINED_BY,
        _expectedLocation(fieldElement, 'field;'));
    _assertRecordedRelation(
        nameElement,
        IndexConstants.IS_REFERENCED_BY_QUALIFIED_UNRESOLVED,
        _expectedLocation(mainElement, 'field);'));
  }

  void test_isReferencedByQualifiedUnresolved_NameElement_method() {
    _indexTestUnit('''
class A {
  method() {}
}
main(var a) {
  a.method();
}
''');
    // prepare elements
    Element mainElement = findElement('main');
    MethodElement methodElement = findElement('method');
    Element nameElement = new NameElement('method');
    // verify
    _assertRecordedRelation(
        nameElement,
        IndexConstants.IS_DEFINED_BY,
        _expectedLocation(methodElement, 'method() {}'));
    _assertRecordedRelation(
        nameElement,
        IndexConstants.IS_REFERENCED_BY_QUALIFIED_UNRESOLVED,
        _expectedLocation(mainElement, 'method();'));
  }

  void test_isReferencedByQualifiedUnresolved_NameElement_operator() {
    _indexTestUnit('''
class A {
  operator +(o) {}
  operator -(o) {}
  operator ~() {}
  operator ==(o) {}
}
main(a) {
  a + 5;
  a += 5;
  a == 5;
  ++a;
  --a;
  ~a;
  a++;
  a--;
}
''');
    // prepare elements
    Element mainElement = findElement('main');
    // binary
    _assertRecordedRelation(
        new NameElement('+'),
        IndexConstants.IS_REFERENCED_BY_QUALIFIED_UNRESOLVED,
        _expectedLocation(mainElement, '+ 5', '+'.length));
    _assertRecordedRelation(
        new NameElement('+'),
        IndexConstants.IS_REFERENCED_BY_QUALIFIED_UNRESOLVED,
        _expectedLocation(mainElement, '+= 5', '+='.length));
    _assertRecordedRelation(
        new NameElement('=='),
        IndexConstants.IS_REFERENCED_BY_QUALIFIED_UNRESOLVED,
        _expectedLocation(mainElement, '== 5', '=='.length));
    // prefix
    _assertRecordedRelation(
        new NameElement('+'),
        IndexConstants.IS_REFERENCED_BY_QUALIFIED_UNRESOLVED,
        _expectedLocation(mainElement, '++a', '++'.length));
    _assertRecordedRelation(
        new NameElement('-'),
        IndexConstants.IS_REFERENCED_BY_QUALIFIED_UNRESOLVED,
        _expectedLocation(mainElement, '--a', '--'.length));
    _assertRecordedRelation(
        new NameElement('~'),
        IndexConstants.IS_REFERENCED_BY_QUALIFIED_UNRESOLVED,
        _expectedLocation(mainElement, '~a', '~'.length));
    // postfix
    _assertRecordedRelation(
        new NameElement('+'),
        IndexConstants.IS_REFERENCED_BY_QUALIFIED_UNRESOLVED,
        _expectedLocation(mainElement, '++;', '++'.length));
    _assertRecordedRelation(
        new NameElement('-'),
        IndexConstants.IS_REFERENCED_BY_QUALIFIED_UNRESOLVED,
        _expectedLocation(mainElement, '--;', '--'.length));
  }

  void test_isReferencedByQualified_ConstructorElement() {
    _indexTestUnit('''
class A implements B {
  A() {}
  A.foo() {}
}
class B extends A {
  B() : super(); // marker-1
  B.foo() : super.foo(); // marker-2
  factory B.bar() = A.foo; // marker-3
}
main() {
  new A(); // marker-main-1
  new A.foo(); // marker-main-2
}
''');
    // prepare elements
    Element mainElement = findElement('main');
    var isConstructor = (node) => node is ConstructorDeclaration;
    ConstructorElement consA = findNodeElementAtString("A()", isConstructor);
    ConstructorElement consA_foo =
        findNodeElementAtString("A.foo()", isConstructor);
    ConstructorElement consB = findNodeElementAtString("B()", isConstructor);
    ConstructorElement consB_foo =
        findNodeElementAtString("B.foo()", isConstructor);
    ConstructorElement consB_bar =
        findNodeElementAtString("B.bar()", isConstructor);
    // A()
    _assertRecordedRelation(
        consA,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(consB, '(); // marker-1', 0));
    _assertRecordedRelation(
        consA,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, '(); // marker-main-1', 0));
    // A.foo()
    _assertRecordedRelation(
        consA_foo,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(consB_foo, '.foo(); // marker-2', '.foo'.length));
    _assertRecordedRelation(
        consA_foo,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(consB_bar, '.foo; // marker-3', '.foo'.length));
    _assertRecordedRelation(
        consA_foo,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, '.foo(); // marker-main-2', '.foo'.length));
  }

  void test_isReferencedByQualified_ConstructorElement_classTypeAlias() {
    _indexTestUnit('''
class M {}
class A implements B {
  A() {}
  A.named() {}
}
class B = A with M;
main() {
  new B(); // marker-main-1
  new B.named(); // marker-main-2
}
''');
    // prepare elements
    Element mainElement = findElement('main');
    var isConstructor = (node) => node is ConstructorDeclaration;
    ConstructorElement consA = findNodeElementAtString("A()", isConstructor);
    ConstructorElement consA_named =
        findNodeElementAtString("A.named()", isConstructor);
    // verify
    _assertRecordedRelation(
        consA,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, '(); // marker-main-1', 0));
    _assertRecordedRelation(
        consA_named,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, '.named(); // marker-main-2', '.named'.length));
  }

  void test_isReferencedByQualified_FieldElement() {
    _indexTestUnit('''
class A {
  static var field;
}
main() {
  A.field = 1;
}
''');
    // prepare elements
    Element mainElement = findElement('main');
    FieldElement fieldElement = findElement('field');
    PropertyAccessorElement setterElement = fieldElement.setter;
    // verify
    _assertRecordedRelation(
        setterElement,
        IndexConstants.IS_REFERENCED_BY_QUALIFIED,
        _expectedLocation(mainElement, 'field = 1'));
  }

  void test_isReferencedByQualified_MethodElement() {
    _indexTestUnit('''
class A {
  foo() {}
  main() {
    print(this.foo);
  }
}
''');
    // prepare elements
    Element fooElement = findElement('foo');
    Element mainElement = findElement('main');
    // verify
    _assertRecordedRelation(
        fooElement,
        IndexConstants.IS_REFERENCED_BY_QUALIFIED,
        _expectedLocation(mainElement, 'foo);'));
  }

  void test_isReferencedByQualified_MethodElement_operator_binary() {
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
    // prepare elements
    Element element = findElement('+');
    Element mainElement = findElement('main');
    // verify
    _assertRecordedRelation(
        element,
        IndexConstants.IS_INVOKED_BY_QUALIFIED,
        _expectedLocation(mainElement, '+ 1', "+".length));
    _assertRecordedRelation(
        element,
        IndexConstants.IS_INVOKED_BY_QUALIFIED,
        _expectedLocation(mainElement, '+= 2', "+=".length));
    _assertRecordedRelation(
        element,
        IndexConstants.IS_INVOKED_BY_QUALIFIED,
        _expectedLocation(mainElement, '++a;', "++".length));
    _assertRecordedRelation(
        element,
        IndexConstants.IS_INVOKED_BY_QUALIFIED,
        _expectedLocation(mainElement, '++;', "++".length));
  }

  void test_isReferencedByQualified_MethodElement_operator_index() {
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
    // prepare elements
    MethodElement readElement = findElement("[]");
    MethodElement writeElement = findElement("[]=");
    Element mainElement = findElement('main');
    // verify
    _assertRecordedRelation(
        readElement,
        IndexConstants.IS_INVOKED_BY_QUALIFIED,
        _expectedLocation(mainElement, '[0]', "[".length));
    _assertRecordedRelation(
        writeElement,
        IndexConstants.IS_INVOKED_BY_QUALIFIED,
        _expectedLocation(mainElement, '[1] =', "[".length));
  }

  void test_isReferencedByQualified_MethodElement_operator_prefix() {
    _indexTestUnit('''
class A {
  A operator ~() => this;
}
main(A a) {
  print(~a);
}
''');
    // prepare elements
    MethodElement element = findElement("~");
    Element mainElement = findElement('main');
    // verify
    _assertRecordedRelation(
        element,
        IndexConstants.IS_INVOKED_BY_QUALIFIED,
        _expectedLocation(mainElement, '~a', "~".length));
  }

  void test_isReferencedByQualified_PropertyAccessorElement_method_getter() {
    _indexTestUnit('''
class A {
  get foo => 42;
  main() {
    print(this.foo);
  }
}
''');
    // prepare elements
    PropertyAccessorElement element = findNodeElementAtString('foo =>');
    Element mainElement = findElement('main');
    // verify
    _assertRecordedRelation(
        element,
        IndexConstants.IS_REFERENCED_BY_QUALIFIED,
        _expectedLocation(mainElement, 'foo);'));
    _assertNoRecordedRelation(element, IndexConstants.IS_REFERENCED_BY, null);
  }

  void test_isReferencedByQualified_PropertyAccessorElement_method_setter() {
    _indexTestUnit('''
class A {
  set foo(x) {}
  main() {
    this.foo = 42;
  }
}
''');
    // prepare elements
    PropertyAccessorElement element = findNodeElementAtString('foo(x)');
    Element mainElement = findElement('main');
    // verify
    _assertRecordedRelation(
        element,
        IndexConstants.IS_REFERENCED_BY_QUALIFIED,
        _expectedLocation(mainElement, 'foo = 42;'));
    _assertNoRecordedRelation(element, IndexConstants.IS_REFERENCED_BY, null);
  }

  void test_isReferencedByQualified_PropertyAccessorElement_topLevelField() {
    addSource('/lib.dart', '''
library lib;
var myVar;
''');
    _indexTestUnit('''
import 'lib.dart' as pref;
main() {
  pref.myVar = 1;
  print(pref.myVar);
}
''');
    // prepare elements
    Element mainElement = findElement('main');
    ImportElement importElement = testLibraryElement.imports[0];
    CompilationUnitElement impUnit =
        importElement.importedLibrary.definingCompilationUnit;
    TopLevelVariableElement myVar = impUnit.topLevelVariables[0];
    PropertyAccessorElement getter = myVar.getter;
    PropertyAccessorElement setter = myVar.setter;
    // verify
    _assertRecordedRelation(
        setter,
        IndexConstants.IS_REFERENCED_BY_QUALIFIED,
        _expectedLocation(mainElement, 'myVar = 1'));
    _assertRecordedRelation(
        getter,
        IndexConstants.IS_REFERENCED_BY_QUALIFIED,
        _expectedLocation(mainElement, 'myVar);'));
  }

  void test_isReferencedByUnqualified_FieldElement() {
    _indexTestUnit('''
class A {
  var field;
  main() {
    field = 5;
    print(field);
  }
}''');
    // prepare elements
    Element mainElement = findElement("main");
    FieldElement fieldElement = findElement("field");
    PropertyAccessorElement getter = fieldElement.getter;
    PropertyAccessorElement setter = fieldElement.setter;
    // verify
    _assertRecordedRelation(
        setter,
        IndexConstants.IS_REFERENCED_BY_UNQUALIFIED,
        _expectedLocation(mainElement, 'field = 5'));
    _assertRecordedRelation(
        getter,
        IndexConstants.IS_REFERENCED_BY_UNQUALIFIED,
        _expectedLocation(mainElement, 'field);'));
  }

  void test_isReferencedByUnqualified_MethodElement() {
    _indexTestUnit('''
class A {
  method() {}
  main() {
    print(method);
  }
}''');
    // prepare elements
    Element mainElement = findElement("main");
    MethodElement methodElement = findElement("method");
    // verify
    _assertRecordedRelation(
        methodElement,
        IndexConstants.IS_REFERENCED_BY_UNQUALIFIED,
        _expectedLocation(mainElement, 'method);'));
    _assertNoRecordedRelation(
        methodElement,
        IndexConstants.IS_REFERENCED_BY,
        null);
  }

  void test_isReferencedByUnqualified_TopLevelVariableElement() {
    _indexTestUnit('''
var topVariable;
main() {
  topVariable = 5;
  print(topVariable);
}''');
    // prepare elements
    Element mainElement = findElement("main");
    TopLevelVariableElement variableElement = findElement("topVariable");
    // verify
    _assertRecordedRelation(
        variableElement.setter,
        IndexConstants.IS_REFERENCED_BY_UNQUALIFIED,
        _expectedLocation(mainElement, 'topVariable = 5'));
    _assertRecordedRelation(
        variableElement.getter,
        IndexConstants.IS_REFERENCED_BY_UNQUALIFIED,
        _expectedLocation(mainElement, 'topVariable);'));
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
    // prepare elements
    ClassElement aElement = findElement("A");
    Element mainElement = findElement("main");
    ParameterElement pElement = findElement("p");
    VariableElement vElement = findElement("v");
    // verify
    _assertRecordedRelation(
        aElement,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(pElement, 'A p) {'));
    _assertRecordedRelation(
        aElement,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(vElement, 'A v;'));
    _assertRecordedRelation(
        aElement,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, 'A(); // 2'));
    _assertRecordedRelation(
        aElement,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, 'A.field = 1;'));
    _assertRecordedRelation(
        aElement,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, 'A.field); // 3'));
  }

  void test_isReferencedBy_ClassTypeAlias() {
    _indexTestUnit('''
class A {}
class B = Object with A;
main(B p) {
  B v;
}
''');
    // prepare elements
    ClassElement bElement = findElement("B");
    ParameterElement pElement = findElement("p");
    VariableElement vElement = findElement("v");
    // verify
    _assertRecordedRelation(
        bElement,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(pElement, 'B p) {'));
    _assertRecordedRelation(
        bElement,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(vElement, 'B v;'));
  }

  void test_isReferencedBy_CompilationUnitElement() {
    addSource('/my_unit.dart', 'part of my_lib;');
    _indexTestUnit('''
library my_lib;
part 'my_unit.dart';
''');
    // prepare elements
    CompilationUnitElement myUnitElement = testLibraryElement.parts[0];
    // verify
    _assertRecordedRelation(
        myUnitElement,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(testUnitElement, "'my_unit.dart';", "'my_unit.dart'".length));
  }

  void test_isReferencedBy_ConstructorFieldInitializer() {
    _indexTestUnit('''
class A {
  int field;
  A() : field = 5;
}
''');
    // prepare elements
    ConstructorElement constructorElement =
        findNodeElementAtString("A()", (node) => node is ConstructorDeclaration);
    FieldElement fieldElement = findElement("field");
    // verify
    _assertRecordedRelation(
        fieldElement,
        IndexConstants.IS_REFERENCED_BY_QUALIFIED,
        _expectedLocation(constructorElement, 'field = 5'));
  }

  void test_isReferencedBy_FieldFormalParameterElement() {
    _indexTestUnit('''
class A {
  int field;
  A(this.field);
}
''');
    // prepare elements
    FieldElement fieldElement = findElement("field");
    Element fieldParameterElement = findNodeElementAtString("field);");
    // verify
    _assertRecordedRelation(
        fieldElement,
        IndexConstants.IS_REFERENCED_BY_QUALIFIED,
        _expectedLocation(fieldParameterElement, 'field);'));
  }

  void test_isReferencedBy_TopLevelVariableElement() {
    addSource('/lib.dart', '''
library lib;
var V;
''');
    _indexTestUnit('''
import 'lib.dart' show V; // imp
''');
    // prepare elements
    var libElement = testLibraryElement.imports[0].importedLibrary;
    var libUnit = libElement.definingCompilationUnit;
    TopLevelVariableElement fieldElement = libUnit.topLevelVariables[0];
    // verify
    _assertRecordedRelation(
        fieldElement,
        IndexConstants.IS_REFERENCED_BY_QUALIFIED,
        _expectedLocation(testUnitElement, 'V; // imp'));
  }

  void test_isReferencedBy_FunctionElement() {
    _indexTestUnit('''
foo() {}
main() {
  print(foo);
  print(foo());
}
''');
    // prepare elements
    FunctionElement element = findElement("foo");
    Element mainElement = findElement("main");
    // "referenced" here
    _assertRecordedRelation(
        element,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, 'foo);'));
    // only "invoked", but not "referenced"
    {
      _assertRecordedRelation(
          element,
          IndexConstants.IS_INVOKED_BY,
          _expectedLocation(mainElement, 'foo());'));
      _assertNoRecordedRelation(
          element,
          IndexConstants.IS_REFERENCED_BY,
          _expectedLocation(mainElement, 'foo());'));
    }
  }

  void test_isReferencedBy_FunctionTypeAliasElement() {
    _indexTestUnit('''
typedef A();
main(A p) {
}
''');
    // prepare elements
    Element aElement = findElement('A');
    Element pElement = findElement('p');
    // verify
    _assertRecordedRelation(
        aElement,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(pElement, 'A p) {'));
  }

  void test_isReferencedBy_ImportElement_noPrefix() {
    addSource('/lib.dart', '''
library lib;
var myVar;
myFunction() {}
myToHide() {}
''');
    _indexTestUnit('''
import 'lib.dart' show myVar, myFunction hide myToHide;
main() {
  myVar = 1;
  myFunction();
  print(0);
}
''');
    // prepare elements
    ImportElement importElement = testLibraryElement.imports[0];
    Element mainElement = findElement('main');
    // verify
    _assertRecordedRelation(
        importElement,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, 'myVar = 1;', 0));
    _assertRecordedRelation(
        importElement,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, 'myFunction();', 0));
    _assertNoRecordedRelation(
        importElement,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, 'print(0);', 0));
    // no references from import combinators
    _assertNoRecordedRelation(
        importElement,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(testUnitElement, 'myVar, ', 0));
    _assertNoRecordedRelation(
        importElement,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(testUnitElement, 'myFunction hide', 0));
    _assertNoRecordedRelation(
        importElement,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(testUnitElement, 'myToHide;', 0));
  }

  void test_isReferencedBy_ImportElement_withPrefix() {
    addSource('/libA.dart', '''
library libA;
var myVar;
''');
    addSource('/libB.dart', '''
library libB;
class MyClass {}
''');
    _indexTestUnit('''
import 'libA.dart' as pref;
import 'libB.dart' as pref;
main() {
  pref.myVar = 1;
  new pref.MyClass();
}
''');
    // prepare elements
    ImportElement importElementA = testLibraryElement.imports[0];
    ImportElement importElementB = testLibraryElement.imports[1];
    Element mainElement = findElement('main');
    // verify
    _assertRecordedRelation(
        importElementA,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, 'pref.myVar = 1;', 'pref.'.length));
    _assertRecordedRelation(
        importElementB,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, 'pref.MyClass();', 'pref.'.length));
  }

  void test_isReferencedBy_ImportElement_withPrefix_combinators() {
    addSource('/lib.dart', '''
library lib;
class A {}
class B {}
''');
    _indexTestUnit('''
import 'lib.dart' as pref show A;
import 'lib.dart' as pref show B;
import 'lib.dart';
import 'lib.dart' as otherPrefix;
main() {
  new pref.A();
  new pref.B();
}
''');
    // prepare elements
    ImportElement importElementA = testLibraryElement.imports[0];
    ImportElement importElementB = testLibraryElement.imports[1];
    Element mainElement = findElement('main');
    // verify
    _assertRecordedRelation(
        importElementA,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, 'pref.A();', 'pref.'.length));
    _assertRecordedRelation(
        importElementB,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, 'pref.B();', 'pref.'.length));
  }

  void test_isReferencedBy_ImportElement_withPrefix_invocation() {
    addSource('/lib.dart', '''
library lib;
myFunc() {}
''');
    _indexTestUnit('''
import 'lib.dart' as pref;
main() {
  pref.myFunc();
}
''');
    // prepare elements
    ImportElement importElement = testLibraryElement.imports[0];
    Element mainElement = findElement('main');
    // verify
    _assertRecordedRelation(
        importElement,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, 'pref.myFunc();', 'pref.'.length));
  }

  void test_isReferencedBy_ImportElement_withPrefix_oneCandidate() {
    addSource('/lib.dart', '''
library lib;
class A {}
class B {}
''');
    _indexTestUnit('''
import 'lib.dart' as pref show A;
main() {
  new pref.A();
}
''');
    // prepare elements
    ImportElement importElement = testLibraryElement.imports[0];
    Element mainElement = findElement('main');
    // verify
    _assertRecordedRelation(
        importElement,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, 'pref.A();', 'pref.'.length));
  }

  void test_isReferencedBy_ImportElement_withPrefix_unresolvedElement() {
    verifyNoTestUnitErrors = false;
    addSource('/lib.dart', '''
library lib;
''');
    _indexTestUnit('''
import 'lib.dart' as pref;
main() {
  pref.myVar = 1;
}
''');
  }

  void test_isReferencedBy_ImportElement_withPrefix_wrongInvocation() {
    verifyNoTestUnitErrors = false;
    _indexTestUnit('''
import 'dart:math' as m;
main() {
  m();
}''');
  }

  void test_isReferencedBy_ImportElement_withPrefix_wrongPrefixedIdentifier() {
    verifyNoTestUnitErrors = false;
    _indexTestUnit('''
import 'dart:math' as m;
main() {
  x.m;
}
''');
  }

  void test_isReferencedBy_LabelElement() {
    _indexTestUnit('''
main() {
  L: while (true) {
    break L;
  }
}
''');
    // prepare elements
    Element mainElement = findElement('main');
    Element element = findElement('L');
    // verify
    _assertRecordedRelation(
        element,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, 'L;'));
  }

  void test_isReferencedBy_LibraryElement_export() {
    addSource('/lib.dart', '''
library lib;
''');
    _indexTestUnit('''
export 'lib.dart';
''');
    // prepare elements
    LibraryElement libElement = testLibraryElement.exportedLibraries[0];
    CompilationUnitElement libUnitElement = libElement.definingCompilationUnit;
    // verify
    _assertRecordedRelation(
        libUnitElement,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(testUnitElement, "'lib.dart'", "'lib.dart'".length));
  }

  void test_isReferencedBy_LibraryElement_import() {
    addSource('/lib.dart', '''
library lib;
''');
    _indexTestUnit('''
import 'lib.dart';
''');
    // prepare elements
    LibraryElement libElement = testLibraryElement.imports[0].importedLibrary;
    CompilationUnitElement libUnitElement = libElement.definingCompilationUnit;
    // verify
    _assertRecordedRelation(
        libUnitElement,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(testUnitElement, "'lib.dart'", "'lib.dart'".length));
  }

  void test_isReferencedBy_ParameterElement() {
    _indexTestUnit('''
foo({var p}) {}
main() {
  foo(p: 1);
}
''');
    // prepare elements
    Element mainElement = findElement('main');
    Element element = findElement('p');
    // verify
    _assertRecordedRelation(
        element,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, 'p: 1'));
  }

  void test_isReferencedBy_TypeParameterElement() {
    _indexTestUnit('''
class A<T> {
  T f;
  foo(T p) {
    T v;
  }
}
''');
    // prepare elements
    Element typeParameterElement = findElement('T');
    Element fieldElement = findElement('f');
    Element parameterElement = findElement('p');
    Element variableElement = findElement('v');
    // verify
    _assertRecordedRelation(
        typeParameterElement,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(fieldElement, 'T f'));
    _assertRecordedRelation(
        typeParameterElement,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(parameterElement, 'T p'));
    _assertRecordedRelation(
        typeParameterElement,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(variableElement, 'T v'));
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
    // prepare elements
    Element aElement = findElement('A');
    Element variableElement = findElement('myVariable');
    // verify
    _assertRecordedRelation(
        aElement,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(testUnitElement, 'A] text'));
    _assertNoRecordedRelation(
        aElement,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(variableElement, 'A] text'));
  }

  void test_isReferencedBy_libraryName() {
    Source libSource = addSource('/lib.dart', '''
library lib;
part 'test.dart';
''');
    testCode = 'part of lib;';
    testSource = addSource('/test.dart', testCode);
    testUnit = resolveDartUnit(testSource, libSource);
    testUnitElement = testUnit.element;
    testLibraryElement = testUnitElement.library;
    indexDartUnit(store, context, testUnit);
    // verify
    _assertRecordedRelation(
        testLibraryElement,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(testUnitElement, "lib;"));
  }

  void test_isReferencedBy_typeInVariableList() {
    _indexTestUnit('''
class A {}
A myVariable = null;
''');
    // prepare elements
    Element classElementA = findElement('A');
    Element variableElement = findElement('myVariable');
    // verify
    _assertRecordedRelation(
        classElementA,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(variableElement, 'A myVariable'));
  }

  void test_isWrittenBy_ParameterElement() {
    _indexTestUnit('''
main(var p) {
  p = 1;
}''');
    // prepare elements
    Element mainElement = findElement("main");
    ParameterElement pElement = findElement("p");
    // verify
    _assertRecordedRelation(
        pElement,
        IndexConstants.IS_WRITTEN_BY,
        _expectedLocation(mainElement, 'p = 1'));
  }

  void test_isWrittenBy_VariableElement() {
    _indexTestUnit('''
main() {
  var v = 0;
  v = 1;
}''');
    // prepare elements
    Element mainElement = findElement("main");
    LocalVariableElement vElement = findElement("v");
    // verify
    _assertRecordedRelation(
        vElement,
        IndexConstants.IS_WRITTEN_BY,
        _expectedLocation(mainElement, 'v = 1'));
  }

  void test_nameIsInvokedBy() {
    _indexTestUnit('''
class A {
  test(x) {}
}
main(A a, p) {
  a.test(1);
  p.test(2);
}''');
    // prepare elements
    Element mainElement = findElement("main");
    Element nameElement = new NameElement('test');
    // verify
    _assertRecordedRelation(
        nameElement,
        IndexConstants.NAME_IS_INVOKED_BY_RESOLVED,
        _expectedLocation(mainElement, 'test(1)'));
    _assertRecordedRelation(
        nameElement,
        IndexConstants.NAME_IS_INVOKED_BY_UNRESOLVED,
        _expectedLocation(mainElement, 'test(2)'));
    _assertNoRecordedRelation(
        nameElement,
        IndexConstants.NAME_IS_READ_BY_UNRESOLVED,
        _expectedLocation(mainElement, 'test(2)'));
  }

  void test_nameIsReadBy() {
    _indexTestUnit('''
class A {
  var test;
}
main(A a, p) {
  print(a.test); // a
  print(p.test); // p
}''');
    // prepare elements
    Element mainElement = findElement("main");
    Element nameElement = new NameElement('test');
    // verify
    _assertRecordedRelation(
        nameElement,
        IndexConstants.NAME_IS_READ_BY_RESOLVED,
        _expectedLocation(mainElement, 'test); // a'));
    _assertRecordedRelation(
        nameElement,
        IndexConstants.NAME_IS_READ_BY_UNRESOLVED,
        _expectedLocation(mainElement, 'test); // p'));
  }

  void test_nameIsReadWrittenBy() {
    _indexTestUnit('''
class A {
  var test;
}
main(A a, p) {
  a.test += 1;
  p.test += 2;
}''');
    // prepare elements
    Element mainElement = findElement("main");
    Element nameElement = new NameElement('test');
    // verify
    _assertRecordedRelation(
        nameElement,
        IndexConstants.NAME_IS_READ_WRITTEN_BY_RESOLVED,
        _expectedLocation(mainElement, 'test += 1'));
    _assertRecordedRelation(
        nameElement,
        IndexConstants.NAME_IS_READ_WRITTEN_BY_UNRESOLVED,
        _expectedLocation(mainElement, 'test += 2'));
  }

  void test_nameIsWrittenBy() {
    _indexTestUnit('''
class A {
  var test;
}
main(A a, p) {
  a.test = 1;
  p.test = 2;
}''');
    // prepare elements
    Element mainElement = findElement("main");
    Element nameElement = new NameElement('test');
    // verify
    _assertRecordedRelation(
        nameElement,
        IndexConstants.NAME_IS_WRITTEN_BY_RESOLVED,
        _expectedLocation(mainElement, 'test = 1'));
    _assertRecordedRelation(
        nameElement,
        IndexConstants.NAME_IS_WRITTEN_BY_UNRESOLVED,
        _expectedLocation(mainElement, 'test = 2'));
  }

  void test_nullUnit() {
    indexDartUnit(store, context, null);
  }

  void test_nullUnitElement() {
    CompilationUnit unit = new CompilationUnit(null, null, [], [], null);
    indexDartUnit(store, context, unit);
  }

  void _assertDefinesTopLevelElement(Relationship relationship,
      ExpectedLocation expectedLocation) {
    _assertRecordedRelation(testLibraryElement, relationship, expectedLocation);
    _assertRecordedRelation(
        UniverseElement.INSTANCE,
        relationship,
        expectedLocation);
  }

  /**
   * Asserts that [recordedRelations] has no item with the specified properties.
   */
  void _assertNoRecordedRelation(Element element, Relationship relationship,
      ExpectedLocation location) {
    for (RecordedRelation recordedRelation in recordedRelations) {
      if (_equalsRecordedRelation(
          recordedRelation,
          element,
          relationship,
          location)) {
        fail(
            'not expected: ${recordedRelation} in\n' + recordedRelations.join('\n'));
      }
    }
  }

  /**
   * Asserts that [recordedRelations] has an item with the expected properties.
   */
  Location _assertRecordedRelation(Element expectedElement,
      Relationship expectedRelationship, ExpectedLocation expectedLocation) {
    for (RecordedRelation recordedRelation in recordedRelations) {
      if (_equalsRecordedRelation(
          recordedRelation,
          expectedElement,
          expectedRelationship,
          expectedLocation)) {
        return recordedRelation.location;
      }
    }
    fail(
        "not found\n$expectedElement $expectedRelationship " "in $expectedLocation in\n"
            +
            recordedRelations.join('\n'));
    return null;
  }

  ExpectedLocation _expectedLocation(Element element, String search, [int length
      = -1]) {
    int offset = findOffset(search);
    if (length == -1) {
      length = getLeadingIdentifierLength(search);
    }
    return new ExpectedLocation(element, offset, length);
  }

  void _indexTestUnit(String code) {
    resolveTestUnit(code);
    indexDartUnit(store, context, testUnit);
  }
}

class ExpectedLocation {
  Element element;
  int offset;
  int length;

  ExpectedLocation(this.element, this.offset, this.length);

  @override
  String toString() {
    return 'ExpectedLocation(element=$element; offset=$offset; length=$length)';
  }
}

class MockIndexStore extends TypedMock implements IndexStore {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


/**
 * Information about a relation recorded into {@link IndexStore}.
 */
class RecordedRelation {
  final Element element;
  final Relationship relationship;
  final Location location;

  RecordedRelation(this.element, this.relationship, this.location);

  @override
  String toString() {
    return 'RecordedRelation(element=$element; relationship=$relationship; '
        'location=$location)';
  }
}
