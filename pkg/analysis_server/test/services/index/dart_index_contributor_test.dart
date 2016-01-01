// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.src.index.dart_index_contributor;

import 'package:analysis_server/src/provisional/index/index_core.dart';
import 'package:analysis_server/src/services/index/index.dart';
import 'package:analysis_server/src/services/index/index_contributor.dart';
import 'package:analysis_server/src/services/index/index_store.dart';
import 'package:analysis_server/src/services/index/indexable_element.dart';
import 'package:analysis_server/src/services/index/indexable_file.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:typed_mock/typed_mock.dart';
import 'package:unittest/unittest.dart';

import '../../abstract_single_unit.dart';
import '../../utils.dart';

main() {
  initializeTestEnvironment();
  defineReflectiveTests(DartUnitContributorTest);
}

void indexDartUnit(
    InternalIndexStore store, AnalysisContext context, CompilationUnit unit) {
  new DartIndexContributor().contributeTo(store, context, unit);
}

/**
 * Returns `true` if the [actual] location the same properties as [expected].
 */
bool _equalsLocation(LocationImpl actual, ExpectedLocation expected) {
  return _equalsLocationProperties(actual, expected.indexable, expected.offset,
      expected.length, expected.isQualified, expected.isResolved);
}

/**
 * Returns `true` if the [actual] location the expected properties.
 */
bool _equalsLocationProperties(
    LocationImpl actual,
    IndexableObject expectedIndexable,
    int expectedOffset,
    int expectedLength,
    bool isQualified,
    bool isResolved) {
  return (expectedIndexable == null || expectedIndexable == actual.indexable) &&
      expectedOffset == actual.offset &&
      expectedLength == actual.length &&
      isQualified == actual.isQualified &&
      isResolved == actual.isResolved;
}

bool _equalsRecordedRelation(
    RecordedRelation recordedRelation,
    IndexableObject expectedIndexable,
    RelationshipImpl expectedRelationship,
    ExpectedLocation expectedLocation) {
  return expectedIndexable == recordedRelation.indexable &&
      (expectedRelationship == null ||
          expectedRelationship == recordedRelation.relationship) &&
      (expectedLocation == null ||
          _equalsLocation(recordedRelation.location, expectedLocation));
}

@reflectiveTest
class DartUnitContributorTest extends AbstractSingleUnitTest {
  InternalIndexStore store = new MockIndexStore();
  List<RecordedRelation> recordedRelations = <RecordedRelation>[];
  List<Element> recordedTopElements = <Element>[];

  CompilationUnitElement importedUnit({int index: 0}) {
    List<ImportElement> imports = testLibraryElement.imports;
    return imports[index].importedLibrary.definingCompilationUnit;
  }

  void setUp() {
    super.setUp();
    when(store.aboutToIndex(context, anyObject)).thenReturn(true);
    when(store.recordRelationship(anyObject, anyObject, anyObject)).thenInvoke(
        (IndexableObject indexable, RelationshipImpl relationship,
            LocationImpl location) {
      recordedRelations
          .add(new RecordedRelation(indexable, relationship, location));
    });
    when(store.recordTopLevelDeclaration(anyObject))
        .thenInvoke((Element element) {
      recordedTopElements.add(element);
    });
  }

  void test_bad_unresolvedFieldFormalParameter() {
    verifyNoTestUnitErrors = false;
    _indexTestUnit('''
class Test {
  final field;
  Test(this.fie);
}''');
  }

  void test_definesClass() {
    _indexTestUnit('class A {}');
    // prepare elements
    ClassElement classElement = findElement("A");
    // verify
    _assertDefinesTopLevelElement(classElement);
  }

  void test_definesClassAlias() {
    _indexTestUnit('''
class Mix {}
class MyClass = Object with Mix;''');
    // prepare elements
    Element classElement = findElement("MyClass");
    // verify
    _assertDefinesTopLevelElement(classElement);
  }

  void test_definesClassEnum() {
    _indexTestUnit('enum MyEnum {A, B, c}');
    // prepare elements
    ClassElement classElement = findElement("MyEnum");
    // verify
    _assertDefinesTopLevelElement(classElement);
  }

  void test_definesFunction() {
    _indexTestUnit('myFunction() {}');
    // prepare elements
    FunctionElement functionElement = findElement("myFunction");
    // verify
    _assertDefinesTopLevelElement(functionElement);
  }

  void test_definesFunctionType() {
    _indexTestUnit('typedef MyFunction(int p);');
    // prepare elements
    FunctionTypeAliasElement typeAliasElement = findElement("MyFunction");
    // verify
    _assertDefinesTopLevelElement(typeAliasElement);
  }

  void test_definesVariable() {
    _indexTestUnit('var myVar = 42;');
    // prepare elements
    VariableElement varElement = findElement("myVar");
    // verify
    _assertDefinesTopLevelElement(varElement);
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
    _assertNoRecordedRelationForElement(variableElement,
        IndexConstants.IS_READ_BY, _expectedLocation(mainElement, 'v in []'));
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
    // prepare elements
    ClassElement classElementA = findElement("A");
    ClassElement classElementB1 = findElement("B1");
    ClassElement classElementB2 = findElement("B2");
    ClassElement classElementC1 = findElement("C1");
    ClassElement classElementC2 = findElement("C2");
    ClassElement classElementC3 = findElement("C3");
    ClassElement classElementC4 = findElement("C4");
    ClassElement classElementM = findElement("M");
    // verify
    _assertRecordedRelationForElement(
        classElementA,
        IndexConstants.HAS_ANCESTOR,
        _expectedLocation(classElementB1, 'B1 extends A'));
    _assertRecordedRelationForElement(
        classElementA,
        IndexConstants.HAS_ANCESTOR,
        _expectedLocation(classElementB2, 'B2 implements A'));
    _assertRecordedRelationForElement(
        classElementA,
        IndexConstants.HAS_ANCESTOR,
        _expectedLocation(classElementC1, 'C1 extends B1'));
    _assertRecordedRelationForElement(
        classElementA,
        IndexConstants.HAS_ANCESTOR,
        _expectedLocation(classElementC2, 'C2 extends B2'));
    _assertRecordedRelationForElement(
        classElementA,
        IndexConstants.HAS_ANCESTOR,
        _expectedLocation(classElementC3, 'C3 implements B1'));
    _assertRecordedRelationForElement(
        classElementA,
        IndexConstants.HAS_ANCESTOR,
        _expectedLocation(classElementC4, 'C4 implements B2'));
    _assertRecordedRelationForElement(
        classElementA,
        IndexConstants.HAS_ANCESTOR,
        _expectedLocation(classElementM, 'M extends Object with A'));
  }

  void test_hasAncestor_ClassTypeAlias() {
    _indexTestUnit('''
class A {}
class B extends A {}
class C1 = Object with A;
class C2 = Object with B;
''');
    // prepare elements
    ClassElement classElementA = findElement("A");
    ClassElement classElementB = findElement("B");
    ClassElement classElementC1 = findElement("C1");
    ClassElement classElementC2 = findElement("C2");
    // verify
    _assertRecordedRelationForElement(
        classElementA,
        IndexConstants.HAS_ANCESTOR,
        _expectedLocation(classElementC1, 'C1 = Object with A'));
    _assertRecordedRelationForElement(
        classElementA,
        IndexConstants.HAS_ANCESTOR,
        _expectedLocation(classElementC2, 'C2 = Object with B'));
    _assertRecordedRelationForElement(
        classElementB,
        IndexConstants.HAS_ANCESTOR,
        _expectedLocation(classElementC2, 'C2 = Object with B'));
  }

  void test_IndexableName_field() {
    _indexTestUnit('''
class A {
  int field;
}
main(A a, p) {
  print(a.field); // r
  print(p.field); // ur
  {
    var field = 42;
    print(field); // not a member
  }
}
''');
    // prepare elements
    Element mainElement = findElement('main');
    FieldElement fieldElement = findElement('field');
    IndexableName indexable = new IndexableName('field');
    // verify
    _assertRecordedRelation(indexable, IndexConstants.NAME_IS_DEFINED_BY,
        _expectedLocation(fieldElement, 'field;'));
    _assertRecordedRelation(indexable, IndexConstants.IS_READ_BY,
        _expectedLocationQ(mainElement, 'field); // r'));
    _assertRecordedRelation(indexable, IndexConstants.IS_READ_BY,
        _expectedLocationQU(mainElement, 'field); // ur'));
    _assertNoRecordedRelation(indexable, IndexConstants.IS_READ_BY,
        _expectedLocation(mainElement, 'field); // not a member'));
  }

  void test_IndexableName_isDefinedBy_localVariable_inForEach() {
    _indexTestUnit('''
class A {
  main() {
    for (int test in []) {
    }
  }
}
''');
    // prepare elements
    LocalVariableElement testElement = findElement('test');
    IndexableName indexable = new IndexableName('test');
    // verify
    _assertRecordedRelation(indexable, IndexConstants.NAME_IS_DEFINED_BY,
        _expectedLocation(testElement, 'test in []'));
  }

  void test_IndexableName_method() {
    _indexTestUnit('''
class A {
  method() {}
}
main(A a, p) {
  a.method(); // r
  p.method(); // ur
}
''');
    // prepare elements
    Element mainElement = findElement('main');
    MethodElement methodElement = findElement('method');
    IndexableName indexable = new IndexableName('method');
    // verify
    _assertRecordedRelation(indexable, IndexConstants.NAME_IS_DEFINED_BY,
        _expectedLocation(methodElement, 'method() {}'));
    _assertRecordedRelation(indexable, IndexConstants.IS_INVOKED_BY,
        _expectedLocationQ(mainElement, 'method(); // r'));
    _assertRecordedRelation(indexable, IndexConstants.IS_INVOKED_BY,
        _expectedLocationQU(mainElement, 'method(); // ur'));
  }

  void test_IndexableName_operator_resolved() {
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
    _assertRecordedRelationForName('+', IndexConstants.IS_INVOKED_BY,
        _expectedLocationQ(mainElement, '+ 5', length: 1));
    _assertRecordedRelationForName('+', IndexConstants.IS_INVOKED_BY,
        _expectedLocationQ(mainElement, '+= 5', length: 2));
    _assertRecordedRelationForName('==', IndexConstants.IS_INVOKED_BY,
        _expectedLocationQ(mainElement, '== 5', length: 2));
    // prefix
    _assertRecordedRelationForName('+', IndexConstants.IS_INVOKED_BY,
        _expectedLocationQ(mainElement, '++a', length: 2));
    _assertRecordedRelationForName('-', IndexConstants.IS_INVOKED_BY,
        _expectedLocationQ(mainElement, '--a', length: 2));
    _assertRecordedRelationForName('~', IndexConstants.IS_INVOKED_BY,
        _expectedLocationQ(mainElement, '~a', length: 1));
    // postfix
    _assertRecordedRelationForName('+', IndexConstants.IS_INVOKED_BY,
        _expectedLocationQ(mainElement, '++;', length: 2));
    _assertRecordedRelationForName('-', IndexConstants.IS_INVOKED_BY,
        _expectedLocationQ(mainElement, '--;', length: 2));
  }

  void test_IndexableName_operator_unresolved() {
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
    _assertRecordedRelationForName('+', IndexConstants.IS_INVOKED_BY,
        _expectedLocationQU(mainElement, '+ 5', length: 1));
    _assertRecordedRelationForName('+', IndexConstants.IS_INVOKED_BY,
        _expectedLocationQU(mainElement, '+= 5', length: 2));
    _assertRecordedRelationForName('==', IndexConstants.IS_INVOKED_BY,
        _expectedLocationQU(mainElement, '== 5', length: 2));
    // prefix
    _assertRecordedRelationForName('+', IndexConstants.IS_INVOKED_BY,
        _expectedLocationQU(mainElement, '++a', length: 2));
    _assertRecordedRelationForName('-', IndexConstants.IS_INVOKED_BY,
        _expectedLocationQU(mainElement, '--a', length: 2));
    _assertRecordedRelationForName('~', IndexConstants.IS_INVOKED_BY,
        _expectedLocationQU(mainElement, '~a', length: 1));
    // postfix
    _assertRecordedRelationForName('+', IndexConstants.IS_INVOKED_BY,
        _expectedLocationQU(mainElement, '++;', length: 2));
    _assertRecordedRelationForName('-', IndexConstants.IS_INVOKED_BY,
        _expectedLocationQU(mainElement, '--;', length: 2));
  }

  void test_isDefinedBy_IndexableName_method() {
    _indexTestUnit('''
class A {
  m() {}
}''');
    // prepare elements
    Element methodElement = findElement("m");
    IndexableName nameIndexable = new IndexableName("m");
    // verify
    _assertRecordedRelationForIndexable(
        nameIndexable,
        IndexConstants.NAME_IS_DEFINED_BY,
        _expectedLocation(methodElement, 'm() {}'));
  }

  void test_isDefinedBy_IndexableName_operator() {
    _indexTestUnit('''
class A {
  operator +(o) {}
}''');
    // prepare elements
    Element methodElement = findElement("+");
    IndexableName nameIndexable = new IndexableName("+");
    // verify
    _assertRecordedRelationForIndexable(
        nameIndexable,
        IndexConstants.NAME_IS_DEFINED_BY,
        _expectedLocation(methodElement, '+(o) {}', length: 1));
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
    _assertRecordedRelationForElement(
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
    _assertRecordedRelationForElement(
        classElementObject,
        IndexConstants.IS_EXTENDED_BY,
        _expectedLocation(classElementA, 'A {}', length: 0));
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
    _assertRecordedRelationForElement(
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
    _assertRecordedRelationForElement(
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
    _assertRecordedRelationForElement(
        classElementB,
        IndexConstants.IS_IMPLEMENTED_BY,
        _expectedLocation(classElementC, 'B; // 3'));
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
    // prepare elements
    Element mainElement = findElement("main");
    FieldElement fieldElement = findElement("field");
    PropertyAccessorElement getterElement = fieldElement.getter;
    IndexableElement indexable = new IndexableElement(getterElement);
    // verify
    _assertRecordedRelation(indexable, IndexConstants.IS_INVOKED_BY,
        _expectedLocationQ(mainElement, 'field(); // q'));
    _assertRecordedRelation(indexable, IndexConstants.IS_INVOKED_BY,
        _expectedLocation(mainElement, 'field(); // nq'));
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
    // prepare elements
    Element mainElement = findElement("main");
    FunctionElement functionElement = importedUnit().functions[0];
    IndexableElement indexable = new IndexableElement(functionElement);
    // verify
    _assertRecordedRelation(indexable, IndexConstants.IS_INVOKED_BY,
        _expectedLocation(mainElement, 'foo(); // q'));
    _assertRecordedRelation(indexable, IndexConstants.IS_INVOKED_BY,
        _expectedLocation(mainElement, 'foo(); // nq'));
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
    _assertRecordedRelationForElement(element, IndexConstants.IS_INVOKED_BY,
        _expectedLocation(mainElement, 'v();'));
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
    // prepare elements
    Element mainElement = findElement("main");
    Element methodElement = findElement("foo");
    IndexableElement indexable = new IndexableElement(methodElement);
    // verify
    _assertRecordedRelation(indexable, IndexConstants.IS_INVOKED_BY,
        _expectedLocationQ(mainElement, 'foo(); // q'));
    _assertRecordedRelation(indexable, IndexConstants.IS_INVOKED_BY,
        _expectedLocation(mainElement, 'foo(); // nq'));
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
    // prepare elements
    Element mainElement = findElement("main");
    Element methodElement = findElement("foo");
    // verify
    _assertRecordedRelationForElement(
        methodElement,
        IndexConstants.IS_INVOKED_BY,
        _expectedLocationQ(mainElement, 'foo();'));
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
    // prepare elements
    MethodElement element = findElement('+');
    Element mainElement = findElement('main');
    IndexableElement indexable = new IndexableElement(element);
    // verify
    _assertRecordedRelation(indexable, IndexConstants.IS_INVOKED_BY,
        _expectedLocationQ(mainElement, '+ 1', length: 1));
    _assertRecordedRelation(indexable, IndexConstants.IS_INVOKED_BY,
        _expectedLocationQ(mainElement, '+= 2', length: 2));
    _assertRecordedRelation(indexable, IndexConstants.IS_INVOKED_BY,
        _expectedLocationQ(mainElement, '++a;', length: 2));
    _assertRecordedRelation(indexable, IndexConstants.IS_INVOKED_BY,
        _expectedLocationQ(mainElement, '++;', length: 2));
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
    // prepare elements
    MethodElement readElement = findElement("[]");
    MethodElement writeElement = findElement("[]=");
    Element mainElement = findElement('main');
    // verify
    _assertRecordedRelationForElement(readElement, IndexConstants.IS_INVOKED_BY,
        _expectedLocationQ(mainElement, '[0]', length: 1));
    _assertRecordedRelationForElement(
        writeElement,
        IndexConstants.IS_INVOKED_BY,
        _expectedLocationQ(mainElement, '[1] =', length: 1));
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
    // prepare elements
    MethodElement element = findElement("~");
    Element mainElement = findElement('main');
    // verify
    _assertRecordedRelationForElement(element, IndexConstants.IS_INVOKED_BY,
        _expectedLocationQ(mainElement, '~a', length: 1));
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
    _assertRecordedRelationForElement(element, IndexConstants.IS_INVOKED_BY,
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
    _assertRecordedRelationForElement(
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
    _assertRecordedRelationForElement(
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
    _assertRecordedRelationForElement(parameterElement,
        IndexConstants.IS_READ_BY, _expectedLocation(mainElement, 'p);'));
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
    _assertRecordedRelationForElement(variableElement,
        IndexConstants.IS_READ_BY, _expectedLocation(mainElement, 'v);'));
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
    _assertRecordedRelationForElement(
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
    _assertRecordedRelationForElement(
        variableElement,
        IndexConstants.IS_READ_WRITTEN_BY,
        _expectedLocation(mainElement, 'v += 1'));
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
    IndexableElement indexable = new IndexableElement(aElement);
    // verify
    _assertRecordedRelation(indexable, IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(pElement, 'A p) {'));
    _assertRecordedRelation(indexable, IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(vElement, 'A v;'));
    _assertRecordedRelation(indexable, IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, 'A(); // 2'));
    _assertRecordedRelation(indexable, IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, 'A.field = 1;'));
    _assertRecordedRelation(indexable, IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, 'A.field); // 3'));
  }

  void test_isReferencedBy_ClassElement_invocation() {
    verifyNoTestUnitErrors = false;
    _indexTestUnit('''
class A {}
main() {
  A(); // invalid code, but still a reference
}''');
    // prepare elements
    Element mainElement = findElement('main');
    Element classElement = findElement('A');
    IndexableElement indexable = new IndexableElement(classElement);
    // verify
    _assertRecordedRelation(indexable, IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, 'A();'));
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
    IndexableElement indexable = new IndexableElement(bElement);
    // verify
    _assertRecordedRelation(indexable, IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(pElement, 'B p) {'));
    _assertRecordedRelation(indexable, IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(vElement, 'B v;'));
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
    // prepare elements
    LibraryElement libElement = testLibraryElement.exportedLibraries[0];
    CompilationUnitElement libUnitElement = libElement.definingCompilationUnit;
    // verify
    _assertRecordedRelationForElement(
        libUnitElement,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(testUnitElement, "'lib.dart'", length: 10));
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
    // prepare elements
    LibraryElement libElement = testLibraryElement.imports[0].importedLibrary;
    CompilationUnitElement libUnitElement = libElement.definingCompilationUnit;
    // verify
    _assertRecordedRelationForElement(
        libUnitElement,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(testUnitElement, "'lib.dart'", length: 10));
  }

  void test_isReferencedBy_CompilationUnitElement_part() {
    addSource('/my_unit.dart', 'part of my_lib;');
    _indexTestUnit('''
library my_lib;
part 'my_unit.dart';
''');
    // prepare elements
    CompilationUnitElement myUnitElement = testLibraryElement.parts[0];
    // verify
    _assertRecordedRelationForElement(
        myUnitElement,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(testUnitElement, "'my_unit.dart';", length: 14));
  }

  void test_isReferencedBy_ConstructorElement() {
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
    IndexableElement indexableA = new IndexableElement(consA);
    IndexableElement indexableA_foo = new IndexableElement(consA_foo);
    // A()
    _assertRecordedRelation(indexableA, IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(consB, '(); // marker-1', length: 0));
    _assertRecordedRelation(indexableA, IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, '(); // marker-main-1', length: 0));
    // A.foo()
    _assertRecordedRelation(indexableA_foo, IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(consB_foo, '.foo(); // marker-2', length: 4));
    _assertRecordedRelation(indexableA_foo, IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(consB_bar, '.foo; // marker-3', length: 4));
    _assertRecordedRelation(indexableA_foo, IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, '.foo(); // marker-main-2', length: 4));
  }

  void test_isReferencedBy_ConstructorElement_classTypeAlias() {
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
    _assertRecordedRelationForElement(consA, IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, '(); // marker-main-1', length: 0));
    _assertRecordedRelationForElement(
        consA_named,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, '.named(); // marker-main-2',
            length: 6));
  }

  void test_isReferencedBy_ConstructorElement_redirection() {
    _indexTestUnit('''
class A {
  A() : this.bar();
  A.foo() : this(); // marker
  A.bar();
}
''');
    // prepare elements
    var isConstructor = (node) => node is ConstructorDeclaration;
    ConstructorElement constructorA =
        findNodeElementAtString("A()", isConstructor);
    ConstructorElement constructorA_foo =
        findNodeElementAtString("A.foo()", isConstructor);
    ConstructorElement constructorA_bar =
        findNodeElementAtString("A.bar()", isConstructor);
    // A()
    _assertRecordedRelationForElement(
        constructorA,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(constructorA_foo, '(); // marker', length: 0));
    // A.foo()
    _assertRecordedRelationForElement(
        constructorA_bar,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(constructorA, '.bar();', length: 4));
  }

  void test_isReferencedBy_FieldElement() {
    _indexTestUnit('''
class A {
  var field;
  A({this.field});
  m() {
    field = 1; // nq
    print(field); // nq
  }
}
main(A a) {
  a.field = 2; // q
  print(a.field); // q
  new A(field: 3);
}
''');
    // prepare elements
    Element mElement = findElement("m");
    Element mainElement = findElement("main");
    FieldElement fieldElement = findElement("field");
    PropertyAccessorElement getter = fieldElement.getter;
    PropertyAccessorElement setter = fieldElement.setter;
    IndexableElement indexableGetter = new IndexableElement(getter);
    IndexableElement indexableSetter = new IndexableElement(setter);
    // m()
    _assertRecordedRelation(indexableSetter, IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mElement, 'field = 1; // nq'));
    _assertRecordedRelation(indexableGetter, IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mElement, 'field); // nq'));
    // main()
    _assertRecordedRelation(indexableSetter, IndexConstants.IS_REFERENCED_BY,
        _expectedLocationQ(mainElement, 'field = 2; // q'));
    _assertRecordedRelation(indexableGetter, IndexConstants.IS_REFERENCED_BY,
        _expectedLocationQ(mainElement, 'field); // q'));
    _assertRecordedRelationForElement(
        fieldElement,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, 'field: 3'));
  }

  void test_isReferencedBy_fileOfLibrary_byImportingExportingFile() {
    addSource('/lib.dart', '');
    _indexTestUnit('''
import 'lib.dart'; // 1
export 'lib.dart'; // 2
''');
    // verify
    IndexableFile libIndexableFile = new IndexableFile('/lib.dart');
    IndexableFile testIndexableFile = new IndexableFile(testFile);
    _assertRecordedRelationForIndexable(
        libIndexableFile,
        IndexConstants.IS_REFERENCED_BY,
        new ExpectedLocation(
            testIndexableFile,
            testCode.indexOf("'lib.dart'; // 1"),
            "'lib.dart'".length,
            false,
            true));
    _assertRecordedRelationForIndexable(
        libIndexableFile,
        IndexConstants.IS_REFERENCED_BY,
        new ExpectedLocation(
            testIndexableFile,
            testCode.indexOf("'lib.dart'; // 2"),
            "'lib.dart'".length,
            false,
            true));
  }

  void test_isReferencedBy_fileOfPart_bySourcingFile() {
    addSource('/part.dart', 'part of my.lib;');
    _indexTestUnit('''
library my.lib;
part 'part.dart';
''');
    // verify
    IndexableFile partIndexableFile = new IndexableFile('/part.dart');
    IndexableFile testIndexableFile = new IndexableFile(testFile);
    _assertRecordedRelationForIndexable(
        partIndexableFile,
        IndexConstants.IS_REFERENCED_BY,
        new ExpectedLocation(testIndexableFile, testCode.indexOf("'part.dart'"),
            "'part.dart'".length, false, true));
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
    IndexableElement indexable = new IndexableElement(element);
    // "referenced" here
    _assertRecordedRelation(indexable, IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, 'foo);'));
    // only "invoked", but not "referenced"
    {
      _assertRecordedRelation(indexable, IndexConstants.IS_INVOKED_BY,
          _expectedLocation(mainElement, 'foo());'));
      _assertNoRecordedRelation(indexable, IndexConstants.IS_REFERENCED_BY,
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
    _assertRecordedRelationForElement(aElement, IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(pElement, 'A p) {'));
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
    IndexableElement indexable = new IndexableElement(aElement);
    // verify
    _assertRecordedRelation(indexable, IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(testUnitElement, 'A] text'));
    _assertNoRecordedRelation(indexable, IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(variableElement, 'A] text'));
  }

  void test_isReferencedBy_ImportElement_noPrefix() {
    addSource(
        '/lib.dart',
        '''
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
    IndexableElement indexable = new IndexableElement(importElement);
    // verify
    _assertRecordedRelation(indexable, IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, 'myVar = 1;', length: 0));
    _assertRecordedRelation(indexable, IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, 'myFunction();', length: 0));
    _assertNoRecordedRelation(indexable, IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, 'print(0);', length: 0));
    // no references from import combinators
    _assertNoRecordedRelation(indexable, IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(testUnitElement, 'myVar, ', length: 0));
    _assertNoRecordedRelation(indexable, IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(testUnitElement, 'myFunction hide', length: 0));
    _assertNoRecordedRelation(indexable, IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(testUnitElement, 'myToHide;', length: 0));
  }

  void test_isReferencedBy_ImportElement_withPrefix() {
    addSource(
        '/libA.dart',
        '''
library libA;
var myVar;
''');
    addSource(
        '/libB.dart',
        '''
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
    _assertRecordedRelationForElement(
        importElementA,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, 'pref.myVar = 1;', length: 5));
    _assertRecordedRelationForElement(
        importElementB,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, 'pref.MyClass();', length: 5));
  }

  void test_isReferencedBy_ImportElement_withPrefix_combinators() {
    addSource(
        '/lib.dart',
        '''
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
    _assertRecordedRelationForElement(
        importElementA,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, 'pref.A();', length: 5));
    _assertRecordedRelationForElement(
        importElementB,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, 'pref.B();', length: 5));
  }

  void test_isReferencedBy_ImportElement_withPrefix_invocation() {
    addSource(
        '/lib.dart',
        '''
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
    _assertRecordedRelationForElement(
        importElement,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, 'pref.myFunc();', length: 5));
  }

  void test_isReferencedBy_ImportElement_withPrefix_oneCandidate() {
    addSource(
        '/lib.dart',
        '''
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
    _assertRecordedRelationForElement(
        importElement,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, 'pref.A();', length: 5));
  }

  void test_isReferencedBy_ImportElement_withPrefix_unresolvedElement() {
    verifyNoTestUnitErrors = false;
    addSource(
        '/lib.dart',
        '''
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
    _assertRecordedRelationForElement(element, IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, 'L;'));
  }

  void test_isReferencedBy_libraryName_byPartOf() {
    Source libSource = addSource(
        '/lib.dart',
        '''
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
    _assertRecordedRelationForElement(
        testLibraryElement,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(testUnitElement, "lib;"));
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
    // prepare elements
    Element mainElement = findElement("main");
    MethodElement methodElement = findElement("method");
    IndexableElement indexable = new IndexableElement(methodElement);
    // verify
    _assertRecordedRelation(indexable, IndexConstants.IS_REFERENCED_BY,
        _expectedLocationQ(mainElement, 'method); // q'));
    _assertRecordedRelation(indexable, IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, 'method); // nq'));
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
    _assertRecordedRelationForElement(element, IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, 'p: 1'));
  }

  void test_isReferencedBy_PrefixElement() {
    _indexTestUnit('''
import 'dart:async' as ppp;
main() {
  ppp.Future a;
  ppp.Stream b;
}
''');
    // prepare elements
    PrefixElement element = findNodeElementAtString('ppp;');
    Element elementA = findElement('a');
    Element elementB = findElement('b');
    IndexableElement indexable = new IndexableElement(element);
    // verify
    _assertRecordedRelation(indexable, IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(elementA, 'ppp.Future'));
    _assertRecordedRelation(indexable, IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(elementB, 'ppp.Stream'));
    _assertNoRecordedRelation(indexable, null, _expectedLocation(null, 'ppp;'));
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
    // prepare elements
    TopLevelVariableElement variable = importedUnit().topLevelVariables[0];
    Element mainElement = findElement("main");
    IndexableElement indexableGetter = new IndexableElement(variable.getter);
    IndexableElement indexableSetter = new IndexableElement(variable.setter);
    // verify
    _assertRecordedRelationForElement(variable, IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(testUnitElement, 'V; // imp'));
    _assertRecordedRelation(indexableSetter, IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, 'V = 5; // q'));
    _assertRecordedRelation(indexableGetter, IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, 'V); // q'));
    _assertRecordedRelation(indexableSetter, IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, 'V = 5; // nq'));
    _assertRecordedRelation(indexableGetter, IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(mainElement, 'V); // nq'));
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
    _assertRecordedRelationForElement(
        classElementA,
        IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(variableElement, 'A myVariable'));
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
    IndexableElement indexable = new IndexableElement(typeParameterElement);
    // verify
    _assertRecordedRelation(indexable, IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(fieldElement, 'T f'));
    _assertRecordedRelation(indexable, IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(parameterElement, 'T p'));
    _assertRecordedRelation(indexable, IndexConstants.IS_REFERENCED_BY,
        _expectedLocation(variableElement, 'T v'));
  }

  void test_isWrittenBy_ConstructorFieldInitializer() {
    _indexTestUnit('''
class A {
  int field;
  A() : field = 5;
}
''');
    // prepare elements
    ClassElement classElement = findElement('A');
    ConstructorElement constructorElement = classElement.constructors[0];
    FieldElement fieldElement = findElement("field");
    // verify
    _assertRecordedRelationForElement(
        fieldElement,
        IndexConstants.IS_WRITTEN_BY,
        _expectedLocation(constructorElement, 'field = 5'));
  }

  void test_isWrittenBy_FieldElement_fieldFormalParameter() {
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
    _assertRecordedRelationForElement(
        fieldElement,
        IndexConstants.IS_WRITTEN_BY,
        _expectedLocation(fieldParameterElement, 'field);'));
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
    _assertRecordedRelationForElement(pElement, IndexConstants.IS_WRITTEN_BY,
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
    _assertRecordedRelationForElement(vElement, IndexConstants.IS_WRITTEN_BY,
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
    IndexableName indexable = new IndexableName('test');
    // verify
    _assertRecordedRelation(indexable, IndexConstants.IS_INVOKED_BY,
        _expectedLocationQ(mainElement, 'test(1)'));
    _assertRecordedRelation(indexable, IndexConstants.IS_INVOKED_BY,
        _expectedLocationQU(mainElement, 'test(2)'));
    _assertNoRecordedRelation(indexable, IndexConstants.IS_READ_BY,
        _expectedLocationQU(mainElement, 'test(2)'));
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
    IndexableName indexable = new IndexableName('test');
    // verify
    _assertRecordedRelation(indexable, IndexConstants.IS_READ_BY,
        _expectedLocationQ(mainElement, 'test); // a'));
    _assertRecordedRelation(indexable, IndexConstants.IS_READ_BY,
        _expectedLocationQU(mainElement, 'test); // p'));
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
    IndexableName indexable = new IndexableName('test');
    // verify
    _assertRecordedRelation(indexable, IndexConstants.IS_READ_WRITTEN_BY,
        _expectedLocationQ(mainElement, 'test += 1'));
    _assertRecordedRelation(indexable, IndexConstants.IS_READ_WRITTEN_BY,
        _expectedLocationQU(mainElement, 'test += 2'));
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
    IndexableName indexable = new IndexableName('test');
    // verify
    _assertRecordedRelation(indexable, IndexConstants.IS_WRITTEN_BY,
        _expectedLocationQ(mainElement, 'test = 1'));
    _assertRecordedRelation(indexable, IndexConstants.IS_WRITTEN_BY,
        _expectedLocationQU(mainElement, 'test = 2'));
  }

  void test_nullUnit() {
    indexDartUnit(store, context, null);
  }

  void test_nullUnitElement() {
    CompilationUnit unit = new CompilationUnit(null, null, [], [], null);
    indexDartUnit(store, context, unit);
  }

  void _assertDefinesTopLevelElement(Element element) {
    ExpectedLocation location = new ExpectedLocation(
        new IndexableElement(element),
        element.nameOffset,
        element.nameLength,
        false,
        true);
    _assertRecordedRelationForElement(
        testLibraryElement, IndexConstants.DEFINES, location);
    expect(recordedTopElements, contains(element));
  }

  /**
   * Asserts that [recordedRelations] has no item with the specified properties.
   */
  void _assertNoRecordedRelation(IndexableObject expectedIndexable,
      RelationshipImpl relationship, ExpectedLocation location) {
    for (RecordedRelation recordedRelation in recordedRelations) {
      if (_equalsRecordedRelation(
          recordedRelation, expectedIndexable, relationship, location)) {
        fail('not expected: $recordedRelation in\n' +
            recordedRelations.join('\n'));
      }
    }
  }

  /**
   * Asserts that [recordedRelations] has no item with the specified properties.
   */
  void _assertNoRecordedRelationForElement(Element expectedElement,
      RelationshipImpl relationship, ExpectedLocation location) {
    _assertNoRecordedRelation(
        new IndexableElement(expectedElement), relationship, location);
  }

  /**
   * Asserts that [recordedRelations] has an item with the expected properties.
   */
  LocationImpl _assertRecordedRelation(
      IndexableObject expectedIndexable,
      RelationshipImpl expectedRelationship,
      ExpectedLocation expectedLocation) {
    for (RecordedRelation recordedRelation in recordedRelations) {
      if (_equalsRecordedRelation(recordedRelation, expectedIndexable,
          expectedRelationship, expectedLocation)) {
        return recordedRelation.location;
      }
    }
    fail("not found\n$expectedIndexable $expectedRelationship "
        "in $expectedLocation in\n" +
        recordedRelations.join('\n'));
    return null;
  }

  /**
   * Asserts that [recordedRelations] has an item with the expected properties.
   */
  LocationImpl _assertRecordedRelationForElement(
      Element expectedElement,
      RelationshipImpl expectedRelationship,
      ExpectedLocation expectedLocation) {
    return _assertRecordedRelationForIndexable(
        new IndexableElement(expectedElement),
        expectedRelationship,
        expectedLocation);
  }

  /**
   * Asserts that [recordedRelations] has an item with the expected properties.
   */
  LocationImpl _assertRecordedRelationForIndexable(
      IndexableObject expectedIndexable,
      RelationshipImpl expectedRelationship,
      ExpectedLocation expectedLocation) {
    return _assertRecordedRelation(
        expectedIndexable, expectedRelationship, expectedLocation);
  }

  /**
   * Asserts that [recordedRelations] has an item with the expected properties.
   */
  LocationImpl _assertRecordedRelationForName(
      String expectedName,
      RelationshipImpl expectedRelationship,
      ExpectedLocation expectedLocation) {
    return _assertRecordedRelationForIndexable(new IndexableName(expectedName),
        expectedRelationship, expectedLocation);
  }

  ExpectedLocation _expectedLocation(Element element, String search,
      {int length: -1, bool isQualified: false, bool isResolved: true}) {
    int offset = findOffset(search);
    if (length == -1) {
      length = getLeadingIdentifierLength(search);
    }
    IndexableObject indexable =
        element != null ? new IndexableElement(element) : null;
    return new ExpectedLocation(
        indexable, offset, length, isQualified, isResolved);
  }

  ExpectedLocation _expectedLocationQ(Element element, String search,
      {int length: -1}) {
    return _expectedLocation(element, search,
        length: length, isQualified: true);
  }

  ExpectedLocation _expectedLocationQU(Element element, String search,
      {int length: -1}) {
    return _expectedLocation(element, search,
        length: length, isQualified: true, isResolved: false);
  }

  void _indexTestUnit(String code) {
    resolveTestUnit(code);
    indexDartUnit(store, context, testUnit);
  }
}

class ExpectedLocation {
  IndexableObject indexable;
  int offset;
  int length;
  bool isQualified;
  bool isResolved;

  ExpectedLocation(this.indexable, this.offset, this.length, this.isQualified,
      this.isResolved);

  @override
  String toString() {
    return 'ExpectedLocation(indexable=$indexable; offset=$offset; length=$length;'
        ' isQualified=$isQualified isResolved=$isResolved)';
  }
}

class MockIndexStore extends TypedMock implements InternalIndexStore {}

/**
 * Information about a relation recorded into {@link IndexStore}.
 */
class RecordedRelation {
  final IndexableObject indexable;
  final RelationshipImpl relationship;
  final LocationImpl location;

  RecordedRelation(this.indexable, this.relationship, this.location);

  @override
  String toString() {
    return 'RecordedRelation(indexable=$indexable; relationship=$relationship; '
        'location=$location; flags='
        '${location.isQualified ? "Q" : ""}'
        '${location.isResolved ? "R" : ""})';
  }
}
