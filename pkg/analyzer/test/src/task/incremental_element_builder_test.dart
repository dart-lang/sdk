// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.task.incremental_element_builder_test;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/src/task/incremental_element_builder.dart';
import 'package:analyzer/task/dart.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import '../../utils.dart';
import '../context/abstract_context.dart';

main() {
  initializeTestEnvironment();
  runReflectiveTests(IncrementalCompilationUnitElementBuilderTest);
}

@reflectiveTest
class IncrementalCompilationUnitElementBuilderTest extends AbstractContextTest {
  Source source;

  String oldCode;
  CompilationUnit oldUnit;
  CompilationUnitElement unitElement;

  String newCode;
  CompilationUnit newUnit;

  CompilationUnitElementDelta unitDelta;

  String getNodeText(AstNode node) {
    return newCode.substring(node.offset, node.end);
  }

  test_classDelta_constructor_0to1() {
    var helper = new _ClassDeltaHelper('A');
    _buildOldUnit(r'''
class A {
}
''');
    helper.initOld(oldUnit);
    ConstructorElement oldConstructorElement =
        helper.element.unnamedConstructor;
    _buildNewUnit(r'''
class A {
  A.a();
}
''');
    helper.initNew(newUnit, unitDelta);
    // nodes
    ClassMember newConstructorNode = helper.newMembers[0];
    // elements
    ConstructorElement newConstructorElement = newConstructorNode.element;
    expect(newConstructorElement, isNotNull);
    expect(newConstructorElement.name, 'a');
    // classElement.constructors
    ClassElement classElement = helper.element;
    expect(classElement.constructors, unorderedEquals([newConstructorElement]));
    // verify delta
    expect(helper.delta.addedConstructors,
        unorderedEquals([newConstructorElement]));
    expect(helper.delta.removedConstructors,
        unorderedEquals([oldConstructorElement]));
    expect(helper.delta.addedAccessors, isEmpty);
    expect(helper.delta.removedAccessors, isEmpty);
    expect(helper.delta.addedMethods, isEmpty);
    expect(helper.delta.removedMethods, isEmpty);
  }

  test_classDelta_constructor_1to0() {
    var helper = new _ClassDeltaHelper('A');
    _buildOldUnit(r'''
class A {
  A.a();
}
''');
    helper.initOld(oldUnit);
    ConstructorElement oldElementA = helper.element.getNamedConstructor('a');
    _buildNewUnit(r'''
class A {
}
''');
    helper.initNew(newUnit, unitDelta);
    // classElement.constructors
    ClassElement classElement = helper.element;
    {
      List<ConstructorElement> constructors = classElement.constructors;
      expect(constructors, hasLength(1));
      expect(constructors[0].isDefaultConstructor, isTrue);
      expect(constructors[0].isSynthetic, isTrue);
    }
    // verify delta
    expect(helper.delta.addedConstructors, unorderedEquals([]));
    expect(helper.delta.removedConstructors, unorderedEquals([oldElementA]));
    expect(helper.delta.addedAccessors, isEmpty);
    expect(helper.delta.removedAccessors, isEmpty);
    expect(helper.delta.addedMethods, isEmpty);
    expect(helper.delta.removedMethods, isEmpty);
  }

  test_classDelta_constructor_1to2() {
    var helper = new _ClassDeltaHelper('A');
    _buildOldUnit(r'''
class A {
  A.a();
}
''');
    helper.initOld(oldUnit);
    _buildNewUnit(r'''
class A {
  A.a();
  A.b();
}
''');
    helper.initNew(newUnit, unitDelta);
    // nodes
    ClassMember nodeA = helper.newMembers[0];
    ClassMember nodeB = helper.newMembers[1];
    expect(nodeA, same(helper.oldMembers[0]));
    // elements
    ConstructorElement elementA = nodeA.element;
    ConstructorElement elementB = nodeB.element;
    expect(elementA, isNotNull);
    expect(elementB, isNotNull);
    expect(elementA.name, 'a');
    expect(elementB.name, 'b');
    // classElement.constructors
    ClassElement classElement = helper.element;
    expect(classElement.constructors, unorderedEquals([elementA, elementB]));
    // verify delta
    expect(helper.delta.addedConstructors, unorderedEquals([elementB]));
    expect(helper.delta.removedConstructors, unorderedEquals([]));
    expect(helper.delta.addedAccessors, isEmpty);
    expect(helper.delta.removedAccessors, isEmpty);
    expect(helper.delta.addedMethods, isEmpty);
    expect(helper.delta.removedMethods, isEmpty);
  }

  test_classDelta_constructor_2to1() {
    var helper = new _ClassDeltaHelper('A');
    _buildOldUnit(r'''
class A {
  A.a();
  A.b();
}
''');
    helper.initOld(oldUnit);
    ConstructorElement oldElementA = helper.element.getNamedConstructor('a');
    _buildNewUnit(r'''
class A {
  A.b();
}
''');
    helper.initNew(newUnit, unitDelta);
    // nodes
    ClassMember nodeB = helper.newMembers[0];
    expect(nodeB, same(helper.oldMembers[1]));
    // elements
    ConstructorElement elementB = nodeB.element;
    expect(elementB, isNotNull);
    expect(elementB.name, 'b');
    // classElement.constructors
    ClassElement classElement = helper.element;
    expect(classElement.constructors, unorderedEquals([elementB]));
    // verify delta
    expect(helper.delta.addedConstructors, unorderedEquals([]));
    expect(helper.delta.removedConstructors, unorderedEquals([oldElementA]));
    expect(helper.delta.addedAccessors, isEmpty);
    expect(helper.delta.removedAccessors, isEmpty);
    expect(helper.delta.addedMethods, isEmpty);
    expect(helper.delta.removedMethods, isEmpty);
  }

  test_classDelta_constructor_2to2_reorder() {
    var helper = new _ClassDeltaHelper('A');
    _buildOldUnit(r'''
class A {
  A.a();
  A.b();
}
''');
    helper.initOld(oldUnit);
    _buildNewUnit(r'''
class A {
  A.b();
  A.a();
}
''');
    helper.initNew(newUnit, unitDelta);
    // nodes
    ClassMember nodeB = helper.newMembers[0];
    ClassMember nodeA = helper.newMembers[1];
    expect(nodeB, same(helper.oldMembers[1]));
    expect(nodeA, same(helper.oldMembers[0]));
    // elements
    ConstructorElement elementB = nodeB.element;
    ConstructorElement elementA = nodeA.element;
    expect(elementB, isNotNull);
    expect(elementA, isNotNull);
    expect(elementB.name, 'b');
    expect(elementA.name, 'a');
    // classElement.constructors
    ClassElement classElement = helper.element;
    expect(classElement.constructors, unorderedEquals([elementB, elementA]));
    // verify delta
    expect(helper.delta.addedConstructors, isEmpty);
    expect(helper.delta.removedConstructors, isEmpty);
    expect(helper.delta.addedAccessors, isEmpty);
    expect(helper.delta.removedAccessors, isEmpty);
    expect(helper.delta.addedMethods, isEmpty);
    expect(helper.delta.removedMethods, isEmpty);
  }

  test_classDelta_constructor_fieldReference_initializer() {
    var helper = new _ClassDeltaHelper('A');
    _buildOldUnit(r'''
class A {
  final int f;
  A() : f = 1 {}
}
''');
    helper.initOld(oldUnit);
    _buildNewUnit(r'''
class A {
  final int f;
  A() : f = 1;
}
''');
    helper.initNew(newUnit, unitDelta);
  }

  test_classDelta_constructor_fieldReference_parameter() {
    var helper = new _ClassDeltaHelper('A');
    _buildOldUnit(r'''
class A {
  final int f;
  A(this.f) {}
}
''');
    helper.initOld(oldUnit);
    _buildNewUnit(r'''
class A {
  final int f;
  A(this.f);
}
''');
    helper.initNew(newUnit, unitDelta);
  }

  test_classDelta_constructor_fieldReference_parameter_default() {
    var helper = new _ClassDeltaHelper('A');
    _buildOldUnit(r'''
class A {
  final int f;
  A([this.f = 1]) {}
}
''');
    helper.initOld(oldUnit);
    _buildNewUnit(r'''
class A {
  final int f;
  A([this.f = 1]);
}
''');
    helper.initNew(newUnit, unitDelta);
  }

  test_classDelta_duplicate_constructor() {
    var helper = new _ClassDeltaHelper('A');
    _buildOldUnit(r'''
class A {
  A() {}
}
''');
    helper.initOld(oldUnit);
    _buildNewUnit(r'''
class A {
  A() {}
  A() {}
}
''');
    helper.initNew(newUnit, unitDelta);
    // nodes
    ConstructorDeclaration oldNode = helper.oldMembers[0];
    ConstructorDeclaration newNode1 = helper.newMembers[0];
    ConstructorDeclaration newNode2 = helper.newMembers[1];
    // elements
    ConstructorElement oldElement = oldNode.element;
    ConstructorElement newElement1 = newNode1.element;
    ConstructorElement newElement2 = newNode2.element;
    expect(newElement1, same(oldElement));
    expect(newElement2, isNot(same(oldElement)));
    expect(oldElement.name, '');
    expect(newElement1.name, '');
    expect(newElement2.name, '');
    // verify delta
    expect(helper.delta.addedConstructors, unorderedEquals([newElement2]));
    expect(helper.delta.removedConstructors, isEmpty);
    expect(helper.delta.addedAccessors, isEmpty);
    expect(helper.delta.removedAccessors, isEmpty);
    expect(helper.delta.addedMethods, isEmpty);
    expect(helper.delta.removedMethods, isEmpty);
  }

  test_classDelta_duplicate_method() {
    var helper = new _ClassDeltaHelper('A');
    _buildOldUnit(r'''
class A {
  m() {}
}
''');
    helper.initOld(oldUnit);
    _buildNewUnit(r'''
class A {
  m() {}
  m() {}
}
''');
    helper.initNew(newUnit, unitDelta);
    // nodes
    MethodDeclaration oldNode = helper.oldMembers[0];
    MethodDeclaration newNode1 = helper.newMembers[0];
    MethodDeclaration newNode2 = helper.newMembers[1];
    // elements
    MethodElement oldElement = oldNode.element;
    MethodElement newElement1 = newNode1.element;
    MethodElement newElement2 = newNode2.element;
    expect(newElement1, same(oldElement));
    expect(newElement2, isNot(same(oldElement)));
    expect(oldElement.name, 'm');
    expect(newElement1.name, 'm');
    expect(newElement2.name, 'm');
    // verify delta
    expect(helper.delta.addedConstructors, isEmpty);
    expect(helper.delta.removedConstructors, isEmpty);
    expect(helper.delta.addedAccessors, isEmpty);
    expect(helper.delta.removedAccessors, isEmpty);
    expect(helper.delta.addedMethods, unorderedEquals([newElement2]));
    expect(helper.delta.removedMethods, isEmpty);
  }

  test_classDelta_field_add() {
    var helper = new _ClassDeltaHelper('A');
    _buildOldUnit(r'''
class A {
  int aaa;
}
''');
    helper.initOld(oldUnit);
    _buildNewUnit(r'''
class A {
  int aaa;
  int bbb;
}
''');
    helper.initNew(newUnit, unitDelta);
    // nodes
    FieldDeclaration nodeA = helper.newMembers[0];
    FieldDeclaration newNodeB = helper.newMembers[1];
    List<VariableDeclaration> newFieldsB = newNodeB.fields.variables;
    expect(nodeA, same(helper.oldMembers[0]));
    expect(newFieldsB, hasLength(1));
    // elements
    FieldElement newFieldElementB = newFieldsB[0].name.staticElement;
    expect(newFieldElementB.name, 'bbb');
    // verify delta
    expect(helper.delta.addedConstructors, isEmpty);
    expect(helper.delta.removedConstructors, isEmpty);
    expect(helper.delta.addedAccessors,
        unorderedEquals([newFieldElementB.getter, newFieldElementB.setter]));
    expect(helper.delta.removedAccessors, isEmpty);
    expect(helper.delta.addedMethods, isEmpty);
    expect(helper.delta.removedMethods, isEmpty);
  }

  test_classDelta_field_remove() {
    var helper = new _ClassDeltaHelper('A');
    _buildOldUnit(r'''
class A {
  int aaa;
  int bbb;
}
''');
    helper.initOld(oldUnit);
    _buildNewUnit(r'''
class A {
  int aaa;
}
''');
    helper.initNew(newUnit, unitDelta);
    // nodes
    FieldDeclaration nodeA = helper.newMembers[0];
    FieldDeclaration oldNodeB = helper.oldMembers[1];
    List<VariableDeclaration> oldFieldsB = oldNodeB.fields.variables;
    expect(nodeA, same(helper.oldMembers[0]));
    // elements
    FieldElement oldFieldElementB = oldFieldsB[0].name.staticElement;
    expect(oldFieldElementB.name, 'bbb');
    // verify delta
    expect(helper.delta.addedConstructors, isEmpty);
    expect(helper.delta.removedConstructors, isEmpty);
    expect(helper.delta.addedAccessors, isEmpty);
    expect(helper.delta.removedAccessors,
        unorderedEquals([oldFieldElementB.getter, oldFieldElementB.setter]));
    expect(helper.delta.addedMethods, isEmpty);
    expect(helper.delta.removedMethods, isEmpty);
  }

  test_classDelta_getter_add() {
    var helper = new _ClassDeltaHelper('A');
    _buildOldUnit(r'''
class A {
  int get aaa => 1;
}
''');
    helper.initOld(oldUnit);
    _buildNewUnit(r'''
class A {
  int get aaa => 1;
  int get bbb => 2;
}
''');
    helper.initNew(newUnit, unitDelta);
    // nodes
    MethodDeclaration nodeA = helper.oldMembers[0];
    MethodDeclaration newNodeB = helper.newMembers[1];
    expect(nodeA, same(helper.oldMembers[0]));
    // elements
    PropertyAccessorElement elementA = nodeA.element;
    PropertyAccessorElement newElementB = newNodeB.element;
    expect(elementA, isNotNull);
    expect(elementA.name, 'aaa');
    expect(newElementB, isNotNull);
    expect(newElementB.name, 'bbb');
    // verify delta
    expect(helper.delta.addedConstructors, isEmpty);
    expect(helper.delta.removedConstructors, isEmpty);
    expect(helper.delta.addedAccessors, unorderedEquals([newElementB]));
    expect(helper.delta.removedAccessors, isEmpty);
    expect(helper.delta.addedMethods, isEmpty);
    expect(helper.delta.removedMethods, isEmpty);
  }

  test_classDelta_getter_remove() {
    var helper = new _ClassDeltaHelper('A');
    _buildOldUnit(r'''
class A {
  int get aaa => 1;
  int get bbb => 2;
}
''');
    helper.initOld(oldUnit);
    _buildNewUnit(r'''
class A {
  int get aaa => 1;
}
''');
    helper.initNew(newUnit, unitDelta);
    // nodes
    MethodDeclaration nodeA = helper.oldMembers[0];
    MethodDeclaration oldNodeB = helper.oldMembers[1];
    expect(nodeA, same(helper.oldMembers[0]));
    // elements
    PropertyAccessorElement elementA = nodeA.element;
    PropertyAccessorElement oldElementB = oldNodeB.element;
    expect(elementA, isNotNull);
    expect(elementA.name, 'aaa');
    // verify delta
    expect(helper.delta.addedConstructors, isEmpty);
    expect(helper.delta.removedConstructors, isEmpty);
    expect(helper.delta.addedAccessors, isEmpty);
    expect(helper.delta.removedAccessors, unorderedEquals([oldElementB]));
    expect(helper.delta.addedMethods, isEmpty);
    expect(helper.delta.removedMethods, isEmpty);
  }

  test_classDelta_method_add() {
    var helper = new _ClassDeltaHelper('A');
    _buildOldUnit(r'''
class A {
  aaa() {}
}
''');
    helper.initOld(oldUnit);
    _buildNewUnit(r'''
class A {
  aaa() {}
  bbb() {}
}
''');
    helper.initNew(newUnit, unitDelta);
    // nodes
    ClassMember nodeA = helper.oldMembers[0];
    ClassMember newNodeB = helper.newMembers[1];
    expect(nodeA, same(helper.oldMembers[0]));
    // elements
    MethodElement elementA = nodeA.element;
    MethodElement newElementB = newNodeB.element;
    expect(elementA, isNotNull);
    expect(elementA.name, 'aaa');
    expect(newElementB, isNotNull);
    expect(newElementB.name, 'bbb');
    // verify delta
    expect(helper.delta.addedConstructors, isEmpty);
    expect(helper.delta.removedConstructors, isEmpty);
    expect(helper.delta.addedAccessors, isEmpty);
    expect(helper.delta.removedAccessors, isEmpty);
    expect(helper.delta.addedMethods, unorderedEquals([newElementB]));
    expect(helper.delta.removedMethods, isEmpty);
  }

  test_classDelta_method_addParameter() {
    var helper = new _ClassDeltaHelper('A');
    _buildOldUnit(r'''
class A {
  aaa() {}
  bbb() {}
}
''');
    helper.initOld(oldUnit);
    _buildNewUnit(r'''
class A {
  aaa(int p) {}
  bbb() {}
}
''');
    helper.initNew(newUnit, unitDelta);
    // nodes
    ClassMember oldNodeA = helper.oldMembers[0];
    ClassMember newNodeA = helper.newMembers[0];
    ClassMember nodeB = helper.newMembers[1];
    expect(newNodeA, isNot(same(oldNodeA)));
    expect(nodeB, same(helper.oldMembers[1]));
    // elements
    MethodElement oldElementA = oldNodeA.element;
    MethodElement newElementA = newNodeA.element;
    MethodElement elementB = nodeB.element;
    expect(newElementA, isNotNull);
    expect(newElementA.name, 'aaa');
    expect(oldElementA.parameters, hasLength(0));
    expect(newElementA.parameters, hasLength(1));
    expect(elementB, isNotNull);
    expect(elementB.name, 'bbb');
    // verify delta
    expect(helper.delta.addedConstructors, isEmpty);
    expect(helper.delta.removedConstructors, isEmpty);
    expect(helper.delta.addedAccessors, isEmpty);
    expect(helper.delta.removedAccessors, isEmpty);
    expect(helper.delta.addedMethods, unorderedEquals([newElementA]));
    expect(helper.delta.removedMethods, unorderedEquals([oldElementA]));
  }

  test_classDelta_method_changeName() {
    var helper = new _ClassDeltaHelper('A');
    _buildOldUnit(r'''
class A {
  aaa(int ap) {
    int av = 1;
    af(afp) {}
  }
  bbb(int bp) {
    int bv = 1;
    bf(bfp) {}
  }
}
''');
    helper.initOld(oldUnit);
    ConstructorElement oldConstructor = helper.element.unnamedConstructor;
    _buildNewUnit(r'''
class A {
  aaa2(int ap) {
    int av = 1;
    af(afp) {}
  }
  bbb(int bp) {
    int bv = 1;
    bf(bfp) {}
  }
}
''');
    helper.initNew(newUnit, unitDelta);
    expect(helper.element.unnamedConstructor, same(oldConstructor));
    // nodes
    ClassMember oldNodeA = helper.oldMembers[0];
    ClassMember newNodeA = helper.newMembers[0];
    ClassMember nodeB = helper.newMembers[1];
    expect(nodeB, same(helper.oldMembers[1]));
    // elements
    MethodElement oldElementA = oldNodeA.element;
    MethodElement newElementA = newNodeA.element;
    MethodElement elementB = nodeB.element;
    expect(newElementA, isNotNull);
    expect(newElementA.name, 'aaa2');
    expect(elementB, isNotNull);
    expect(elementB.name, 'bbb');
    // verify delta
    expect(helper.delta.addedConstructors, isEmpty);
    expect(helper.delta.removedConstructors, isEmpty);
    expect(helper.delta.addedAccessors, isEmpty);
    expect(helper.delta.removedAccessors, isEmpty);
    expect(helper.delta.addedMethods, unorderedEquals([newElementA]));
    expect(helper.delta.removedMethods, unorderedEquals([oldElementA]));
  }

  test_classDelta_method_remove() {
    var helper = new _ClassDeltaHelper('A');
    _buildOldUnit(r'''
class A {
  aaa() {}
  bbb() {}
}
''');
    helper.initOld(oldUnit);
    _buildNewUnit(r'''
class A {
  aaa() {}
}
''');
    helper.initNew(newUnit, unitDelta);
    // nodes
    ClassMember nodeA = helper.oldMembers[0];
    ClassMember oldNodeB = helper.oldMembers[1];
    expect(nodeA, same(helper.oldMembers[0]));
    // elements
    MethodElement elementA = nodeA.element;
    MethodElement oldElementB = oldNodeB.element;
    expect(elementA, isNotNull);
    expect(elementA.name, 'aaa');
    // verify delta
    expect(helper.delta.addedConstructors, isEmpty);
    expect(helper.delta.removedConstructors, isEmpty);
    expect(helper.delta.addedAccessors, isEmpty);
    expect(helper.delta.removedAccessors, isEmpty);
    expect(helper.delta.addedMethods, isEmpty);
    expect(helper.delta.removedMethods, unorderedEquals([oldElementB]));
  }

  test_classDelta_method_removeParameter() {
    var helper = new _ClassDeltaHelper('A');
    _buildOldUnit(r'''
class A {
  aaa(int p) {}
  bbb() {}
}
''');
    helper.initOld(oldUnit);
    _buildNewUnit(r'''
class A {
  aaa() {}
  bbb() {}
}
''');
    helper.initNew(newUnit, unitDelta);
    // nodes
    ClassMember oldNodeA = helper.oldMembers[0];
    ClassMember newNodeA = helper.newMembers[0];
    ClassMember nodeB = helper.newMembers[1];
    expect(newNodeA, isNot(same(oldNodeA)));
    expect(nodeB, same(helper.oldMembers[1]));
    // elements
    MethodElement oldElementA = oldNodeA.element;
    MethodElement newElementA = newNodeA.element;
    MethodElement elementB = nodeB.element;
    expect(newElementA, isNotNull);
    expect(newElementA.name, 'aaa');
    expect(oldElementA.parameters, hasLength(1));
    expect(newElementA.parameters, hasLength(0));
    expect(elementB, isNotNull);
    expect(elementB.name, 'bbb');
    // verify delta
    expect(helper.delta.addedConstructors, isEmpty);
    expect(helper.delta.removedConstructors, isEmpty);
    expect(helper.delta.addedAccessors, isEmpty);
    expect(helper.delta.removedAccessors, isEmpty);
    expect(helper.delta.addedMethods, unorderedEquals([newElementA]));
    expect(helper.delta.removedMethods, unorderedEquals([oldElementA]));
  }

  test_classDelta_null_extendsClause_add() {
    _verifyNoClassDeltaForTheLast(
        r'''
class A {}
class B {}
''',
        r'''
class A {}
class B extends A {}
''');
  }

  test_classDelta_null_extendsClause_change() {
    _verifyNoClassDeltaForTheLast(
        r'''
class A1 {}
class A2 {}
class B extends A1 {}
''',
        r'''
class A1 {}
class A2 {}
class B extends A2 {}
''');
  }

  test_classDelta_null_extendsClause_remove() {
    _verifyNoClassDeltaForTheLast(
        r'''
class A {}
class B extends A {}
''',
        r'''
class A {}
class B {}
''');
  }

  test_classDelta_null_implementsClause_add() {
    _verifyNoClassDeltaForTheLast(
        r'''
class A {}
class B {}
''',
        r'''
class A {}
class B implements A {}
''');
  }

  test_classDelta_null_implementsClause_change() {
    _verifyNoClassDeltaForTheLast(
        r'''
class A1 {}
class A2 {}
class B implements A1 {}
''',
        r'''
class A1 {}
class A2 {}
class B implements A2 {}
''');
  }

  test_classDelta_null_implementsClause_remove() {
    _verifyNoClassDeltaForTheLast(
        r'''
class A {}
class B implements A {}
''',
        r'''
class A {}
class B {}
''');
  }

  test_classDelta_null_typeParameters_change() {
    _verifyNoClassDeltaForTheLast(
        r'''
class A {}
class B<T> {}
''',
        r'''
class A {}
class B<T extends A> {}
''');
  }

  test_classDelta_null_withClause_add() {
    _verifyNoClassDeltaForTheLast(
        r'''
class A {}
class M {}
class B extends A {}
''',
        r'''
class A {}
class M {}
class B extends A with M {}
''');
  }

  test_classDelta_null_withClause_change1() {
    _verifyNoClassDeltaForTheLast(
        r'''
class A {}
class M1 {}
class M2 {}
class B extends A with M1 {}
''',
        r'''
class A {}
class M1 {}
class M2 {}
class B extends A with M2 {}
''');
  }

  test_classDelta_null_withClause_change2() {
    _verifyNoClassDeltaForTheLast(
        r'''
class A {}
class M1 {}
class M2 {}
class B extends A with M1, M2 {}
''',
        r'''
class A {}
class M1 {}
class M2 {}
class B extends A with M2, M1 {}
''');
  }

  test_classDelta_null_withClause_remove() {
    _verifyNoClassDeltaForTheLast(
        r'''
class A {}
class M {}
class B extends A with M {}
''',
        r'''
class A {}
class M {}
class B extends A {}
''');
  }

  test_classDelta_setter_add() {
    var helper = new _ClassDeltaHelper('A');
    _buildOldUnit(r'''
class A {
  void set aaa(int pa) {}
}
''');
    helper.initOld(oldUnit);
    _buildNewUnit(r'''
class A {
  void set aaa(int pa) {}
  void set bbb(int pb) {}
}
''');
    helper.initNew(newUnit, unitDelta);
    // nodes
    MethodDeclaration nodeA = helper.oldMembers[0];
    MethodDeclaration newNodeB = helper.newMembers[1];
    expect(nodeA, same(helper.oldMembers[0]));
    // elements
    PropertyAccessorElement elementA = nodeA.element;
    PropertyAccessorElement newElementB = newNodeB.element;
    expect(elementA, isNotNull);
    expect(elementA.name, 'aaa=');
    expect(newElementB, isNotNull);
    expect(newElementB.name, 'bbb=');
    // verify delta
    expect(helper.delta.addedConstructors, isEmpty);
    expect(helper.delta.removedConstructors, isEmpty);
    expect(helper.delta.addedAccessors, unorderedEquals([newElementB]));
    expect(helper.delta.removedAccessors, isEmpty);
    expect(helper.delta.addedMethods, isEmpty);
    expect(helper.delta.removedMethods, isEmpty);
  }

  test_classDelta_setter_remove() {
    var helper = new _ClassDeltaHelper('A');
    _buildOldUnit(r'''
class A {
  void set aaa(int pa) {}
  void set bbb(int pb) {}
}
''');
    helper.initOld(oldUnit);
    _buildNewUnit(r'''
class A {
  void set aaa(int pa) {}
}
''');
    helper.initNew(newUnit, unitDelta);
    // nodes
    MethodDeclaration nodeA = helper.oldMembers[0];
    MethodDeclaration oldNodeB = helper.oldMembers[1];
    expect(nodeA, same(helper.oldMembers[0]));
    // elements
    PropertyAccessorElement elementA = nodeA.element;
    PropertyAccessorElement oldElementB = oldNodeB.element;
    expect(elementA, isNotNull);
    expect(elementA.name, 'aaa=');
    // verify delta
    expect(helper.delta.addedConstructors, isEmpty);
    expect(helper.delta.removedConstructors, isEmpty);
    expect(helper.delta.addedAccessors, isEmpty);
    expect(helper.delta.removedAccessors, unorderedEquals([oldElementB]));
    expect(helper.delta.addedMethods, isEmpty);
    expect(helper.delta.removedMethods, isEmpty);
  }

  test_classDelta_typeParameter_same() {
    _buildOldUnit(r'''
class A<T> {
  m() {}
}
''');
    _buildNewUnit(r'''
class A<T> {
  m2() {}
}
''');
  }

  test_directives_add() {
    _buildOldUnit(r'''
library test;
import 'dart:math';
''');
    List<Directive> oldDirectives = oldUnit.directives.toList();
    _buildNewUnit(r'''
library test;
import 'dart:async';
import 'dart:math';
''');
    List<Directive> newDirectives = newUnit.directives;
    {
      Directive newNode = newDirectives[0];
      expect(newNode, same(oldDirectives[0]));
      expect(getNodeText(newNode), "library test;");
      LibraryElement element = newNode.element;
      expect(element, isNotNull);
      expect(element.nameOffset, newCode.indexOf('test;'));
    }
    {
      Directive newNode = newDirectives[1];
      expect(getNodeText(newNode), "import 'dart:async';");
      ImportElement element = newNode.element;
      expect(element, isNull);
    }
    {
      Directive newNode = newDirectives[2];
      expect(newNode, same(oldDirectives[1]));
      expect(getNodeText(newNode), "import 'dart:math';");
      ImportElement element = newNode.element;
      expect(element, isNotNull);
      expect(element.nameOffset, newCode.indexOf("import 'dart:math';"));
    }
    expect(unitDelta.hasDirectiveChange, isTrue);
  }

  test_directives_keepOffset_partOf() {
    String libCode = '''
// comment to shift tokens
library my_lib;
part 'test.dart';
''';
    Source libSource = newSource('/lib.dart', libCode);
    _buildOldUnit(
        r'''
part of my_lib;
class A {}
''',
        libSource);
    List<Directive> oldDirectives = oldUnit.directives.toList();
    _buildNewUnit(r'''
part of my_lib;
class A {}
''');
    List<Directive> newDirectives = newUnit.directives;
    {
      Directive newNode = newDirectives[0];
      expect(newNode, same(oldDirectives[0]));
      expect(getNodeText(newNode), 'part of my_lib;');
      LibraryElement element = newNode.element;
      expect(element, isNotNull);
      expect(element.nameOffset, libCode.indexOf('my_lib;'));
    }
  }

  test_directives_remove() {
    _buildOldUnit(r'''
library test;
import 'dart:async';
import 'dart:math';
''');
    List<Directive> oldDirectives = oldUnit.directives.toList();
    _buildNewUnit(r'''
library test;
import 'dart:math';
''');
    List<Directive> newDirectives = newUnit.directives;
    {
      Directive newNode = newDirectives[0];
      expect(newNode, same(oldDirectives[0]));
      expect(getNodeText(newNode), "library test;");
      LibraryElement element = newNode.element;
      expect(element, isNotNull);
      expect(element.nameOffset, newCode.indexOf('test;'));
    }
    {
      Directive newNode = newDirectives[1];
      expect(newNode, same(oldDirectives[2]));
      expect(getNodeText(newNode), "import 'dart:math';");
      ImportElement element = newNode.element;
      expect(element, isNotNull);
      expect(element.nameOffset, newCode.indexOf("import 'dart:math';"));
    }
    expect(unitDelta.hasDirectiveChange, isTrue);
  }

  test_directives_reorder() {
    _buildOldUnit(r'''
library test;
import  'dart:math' as m;
import 'dart:async';
''');
    List<Directive> oldDirectives = oldUnit.directives.toList();
    _buildNewUnit(r'''
library test;
import 'dart:async';
import 'dart:math' as m;
''');
    List<Directive> newDirectives = newUnit.directives;
    {
      Directive newNode = newDirectives[0];
      expect(newNode, same(oldDirectives[0]));
      expect(getNodeText(newNode), "library test;");
      LibraryElement element = newNode.element;
      expect(element, isNotNull);
      expect(element.nameOffset, newCode.indexOf('test;'));
    }
    {
      Directive newNode = newDirectives[1];
      expect(newNode, same(oldDirectives[2]));
      expect(getNodeText(newNode), "import 'dart:async';");
      ImportElement element = newNode.element;
      expect(element, isNotNull);
      expect(element.nameOffset, newCode.indexOf("import 'dart:async';"));
    }
    {
      Directive newNode = newDirectives[2];
      expect(newNode, same(oldDirectives[1]));
      expect(getNodeText(newNode), "import 'dart:math' as m;");
      ImportElement element = newNode.element;
      expect(element, isNotNull);
      expect(element.nameOffset, newCode.indexOf("import 'dart:math' as m;"));
      expect(element.prefix.nameOffset, newCode.indexOf("m;"));
    }
    expect(unitDelta.hasDirectiveChange, isFalse);
  }

  test_directives_sameOrder_insertSpaces() {
    _buildOldUnit(r'''
library test;
import 'dart:async';
import 'dart:math';
''');
    List<Directive> oldDirectives = oldUnit.directives.toList();
    _buildNewUnit(r'''
library test;

import 'dart:async' ;
import  'dart:math';
''');
    List<Directive> newDirectives = newUnit.directives;
    {
      Directive newNode = newDirectives[0];
      expect(newNode, same(oldDirectives[0]));
      expect(getNodeText(newNode), "library test;");
      LibraryElement element = newNode.element;
      expect(element, isNotNull);
      expect(element.nameOffset, newCode.indexOf('test;'));
    }
    {
      Directive newNode = newDirectives[1];
      expect(newNode, same(oldDirectives[1]));
      expect(getNodeText(newNode), "import 'dart:async' ;");
      ImportElement element = newNode.element;
      expect(element, isNotNull);
      expect(element.nameOffset, newCode.indexOf("import 'dart:async' ;"));
    }
    {
      Directive newNode = newDirectives[2];
      expect(newNode, same(oldDirectives[2]));
      expect(getNodeText(newNode), "import  'dart:math';");
      ImportElement element = newNode.element;
      expect(element, isNotNull);
      expect(element.nameOffset, newCode.indexOf("import  'dart:math';"));
    }
    expect(unitDelta.hasDirectiveChange, isFalse);
  }

  test_directives_sameOrder_removeSpaces() {
    _buildOldUnit(r'''
library test;

import 'dart:async' ;
import  'dart:math';
''');
    List<Directive> oldDirectives = oldUnit.directives.toList();
    _buildNewUnit(r'''
library test;
import 'dart:async';
import 'dart:math';
''');
    List<Directive> newDirectives = newUnit.directives;
    {
      Directive newNode = newDirectives[0];
      expect(newNode, same(oldDirectives[0]));
      expect(getNodeText(newNode), "library test;");
      LibraryElement element = newNode.element;
      expect(element, isNotNull);
      expect(element.nameOffset, newCode.indexOf('test;'));
    }
    {
      Directive newNode = newDirectives[1];
      expect(newNode, same(oldDirectives[1]));
      expect(getNodeText(newNode), "import 'dart:async';");
      ImportElement element = newNode.element;
      expect(element, isNotNull);
      expect(element.nameOffset, newCode.indexOf("import 'dart:async';"));
    }
    {
      Directive newNode = newDirectives[2];
      expect(newNode, same(oldDirectives[2]));
      expect(getNodeText(newNode), "import 'dart:math';");
      ImportElement element = newNode.element;
      expect(element, isNotNull);
      expect(element.nameOffset, newCode.indexOf("import 'dart:math';"));
    }
    expect(unitDelta.hasDirectiveChange, isFalse);
  }

  test_unitMembers_accessor_add() {
    _buildOldUnit(r'''
get a => 1;
''');
    List<CompilationUnitMember> oldNodes = oldUnit.declarations.toList();
    _buildNewUnit(r'''
get a => 1;
get b => 2;
''');
    List<CompilationUnitMember> newNodes = newUnit.declarations;
    // nodes
    FunctionDeclaration node1 = newNodes[0];
    FunctionDeclaration node2 = newNodes[1];
    expect(node1, same(oldNodes[0]));
    // elements
    PropertyAccessorElement elementA = node1.element;
    PropertyAccessorElement elementB = node2.element;
    expect(elementA, isNotNull);
    expect(elementB, isNotNull);
    expect(elementA.name, 'a');
    expect(elementB.name, 'b');
    // unit.types
    expect(unitElement.topLevelVariables,
        unorderedEquals([elementA.variable, elementB.variable]));
    expect(unitElement.accessors, unorderedEquals([elementA, elementB]));
  }

  test_unitMembers_class_add() {
    _buildOldUnit(r'''
class A {}
''');
    List<CompilationUnitMember> oldNodes = oldUnit.declarations.toList();
    _buildNewUnit(r'''
class A {}
class B {}
''');
    List<CompilationUnitMember> newNodes = newUnit.declarations;
    // nodes
    CompilationUnitMember nodeA = newNodes[0];
    CompilationUnitMember nodeB = newNodes[1];
    expect(nodeA, same(oldNodes[0]));
    // elements
    ClassElement elementA = nodeA.element;
    ClassElement elementB = nodeB.element;
    expect(elementA, isNotNull);
    expect(elementB, isNotNull);
    expect(elementA.name, 'A');
    expect(elementB.name, 'B');
    // unit.types
    expect(unitElement.types, unorderedEquals([elementA, elementB]));
    // verify delta
    expect(unitDelta.addedDeclarations, unorderedEquals([elementB]));
    expect(unitDelta.removedDeclarations, unorderedEquals([]));
  }

  test_unitMembers_class_comments() {
    _buildOldUnit(r'''
/// reference [bool] type.
class A {}
/// reference [int] type.
class B {}
/// reference [double] and [B] types.
class C {}
''');
    List<CompilationUnitMember> oldNodes = oldUnit.declarations.toList();
    _buildNewUnit(r'''
/// reference [double] and [B] types.
class C {}
/// reference [bool] type.
class A {}
/// reference [int] type.
class B {}
''');
    List<CompilationUnitMember> newNodes = newUnit.declarations;
    {
      CompilationUnitMember newNode = newNodes[0];
      expect(newNode, same(oldNodes[2]));
      expect(
          getNodeText(newNode),
          r'''
/// reference [double] and [B] types.
class C {}''');
      ClassElement element = newNode.element;
      expect(element, isNotNull);
      expect(element.name, 'C');
      expect(element.nameOffset, newCode.indexOf('C {}'));
      // [double] and [B] are still resolved
      {
        var docReferences = newNode.documentationComment.references;
        expect(docReferences, hasLength(2));
        expect(docReferences[0].identifier.staticElement.name, 'double');
        expect(docReferences[1].identifier.staticElement,
            same(newNodes[2].element));
      }
    }
    {
      CompilationUnitMember newNode = newNodes[1];
      expect(newNode, same(oldNodes[0]));
      expect(
          getNodeText(newNode),
          r'''
/// reference [bool] type.
class A {}''');
      ClassElement element = newNode.element;
      expect(element, isNotNull);
      expect(element.name, 'A');
      expect(element.nameOffset, newCode.indexOf('A {}'));
      // [bool] is still resolved
      {
        var docReferences = newNode.documentationComment.references;
        expect(docReferences, hasLength(1));
        expect(docReferences[0].identifier.staticElement.name, 'bool');
      }
    }
    {
      CompilationUnitMember newNode = newNodes[2];
      expect(newNode, same(oldNodes[1]));
      expect(
          getNodeText(newNode),
          r'''
/// reference [int] type.
class B {}''');
      ClassElement element = newNode.element;
      expect(element, isNotNull);
      expect(element.name, 'B');
      expect(element.nameOffset, newCode.indexOf('B {}'));
      // [int] is still resolved
      {
        var docReferences = newNode.documentationComment.references;
        expect(docReferences, hasLength(1));
        expect(docReferences[0].identifier.staticElement.name, 'int');
      }
    }
    // verify delta
    expect(unitDelta.addedDeclarations, unorderedEquals([]));
    expect(unitDelta.removedDeclarations, unorderedEquals([]));
  }

  test_unitMembers_class_remove() {
    _buildOldUnit(r'''
class A {}
class B {}
''');
    List<CompilationUnitMember> oldNodes = oldUnit.declarations.toList();
    _buildNewUnit(r'''
class A {}
''');
    List<CompilationUnitMember> newNodes = newUnit.declarations;
    // nodes
    CompilationUnitMember nodeA = newNodes[0];
    CompilationUnitMember nodeB = oldNodes[1];
    expect(nodeA, same(oldNodes[0]));
    // elements
    ClassElement elementA = nodeA.element;
    ClassElement elementB = nodeB.element;
    expect(elementA, isNotNull);
    expect(elementB, isNotNull);
    expect(elementA.name, 'A');
    expect(elementB.name, 'B');
    // unit.types
    expect(unitElement.types, unorderedEquals([elementA]));
    // verify delta
    expect(unitDelta.addedDeclarations, unorderedEquals([]));
    expect(unitDelta.removedDeclarations, unorderedEquals([elementB]));
  }

  test_unitMembers_class_reorder() {
    _buildOldUnit(r'''
class A {}
class B {}
class C {}
''');
    List<CompilationUnitMember> oldNodes = oldUnit.declarations.toList();
    _buildNewUnit(r'''
class C {}
class A {}
class B {}
''');
    List<CompilationUnitMember> newNodes = newUnit.declarations;
    {
      CompilationUnitMember newNode = newNodes[0];
      expect(newNode, same(oldNodes[2]));
      expect(getNodeText(newNode), 'class C {}');
      ClassElement element = newNode.element;
      expect(element, isNotNull);
      expect(element.name, 'C');
      expect(element.nameOffset, newCode.indexOf('C {}'));
    }
    {
      CompilationUnitMember newNode = newNodes[1];
      expect(newNode, same(oldNodes[0]));
      expect(getNodeText(newNode), 'class A {}');
      ClassElement element = newNode.element;
      expect(element, isNotNull);
      expect(element.name, 'A');
      expect(element.nameOffset, newCode.indexOf('A {}'));
    }
    {
      CompilationUnitMember newNode = newNodes[2];
      expect(newNode, same(oldNodes[1]));
      expect(getNodeText(newNode), 'class B {}');
      ClassElement element = newNode.element;
      expect(element, isNotNull);
      expect(element.name, 'B');
      expect(element.nameOffset, newCode.indexOf('B {}'));
    }
    // verify delta
    expect(unitDelta.addedDeclarations, unorderedEquals([]));
    expect(unitDelta.removedDeclarations, unorderedEquals([]));
  }

  test_unitMembers_enum_add() {
    _buildOldUnit(r'''
enum A {A1, A2}
''');
    List<CompilationUnitMember> oldNodes = oldUnit.declarations.toList();
    _buildNewUnit(r'''
enum A {A1, A2}
enum B {B1, B2}
''');
    List<CompilationUnitMember> newNodes = newUnit.declarations;
    // nodes
    CompilationUnitMember nodeA = newNodes[0];
    CompilationUnitMember nodeB = newNodes[1];
    expect(nodeA, same(oldNodes[0]));
    // elements
    ClassElement elementA = nodeA.element;
    ClassElement elementB = nodeB.element;
    expect(elementA, isNotNull);
    expect(elementB, isNotNull);
    expect(elementA.name, 'A');
    expect(elementB.name, 'B');
    // unit.types
    expect(unitElement.enums, unorderedEquals([elementA, elementB]));
    // verify delta
    expect(unitDelta.addedDeclarations, unorderedEquals([elementB]));
    expect(unitDelta.removedDeclarations, unorderedEquals([]));
  }

  test_unitMembers_function_add() {
    _buildOldUnit(r'''
a() {}
''');
    List<CompilationUnitMember> oldNodes = oldUnit.declarations.toList();
    _buildNewUnit(r'''
a() {}
b() {}
''');
    List<CompilationUnitMember> newNodes = newUnit.declarations;
    // nodes
    CompilationUnitMember nodeA = newNodes[0];
    CompilationUnitMember nodeB = newNodes[1];
    expect(nodeA, same(oldNodes[0]));
    // elements
    FunctionElement elementA = nodeA.element;
    FunctionElement elementB = nodeB.element;
    expect(elementA, isNotNull);
    expect(elementB, isNotNull);
    expect(elementA.name, 'a');
    expect(elementB.name, 'b');
    // unit.types
    expect(unitElement.functions, unorderedEquals([elementA, elementB]));
    // verify delta
    expect(unitDelta.addedDeclarations, unorderedEquals([elementB]));
    expect(unitDelta.removedDeclarations, unorderedEquals([]));
  }

  test_unitMembers_functionTypeAlias_add() {
    _buildOldUnit(r'''
typedef A();
''');
    List<CompilationUnitMember> oldNodes = oldUnit.declarations.toList();
    _buildNewUnit(r'''
typedef A();
typedef B();
''');
    List<CompilationUnitMember> newNodes = newUnit.declarations;
    // nodes
    CompilationUnitMember nodeA = newNodes[0];
    CompilationUnitMember nodeB = newNodes[1];
    expect(nodeA, same(oldNodes[0]));
    // elements
    FunctionTypeAliasElement elementA = nodeA.element;
    FunctionTypeAliasElement elementB = nodeB.element;
    expect(elementA, isNotNull);
    expect(elementB, isNotNull);
    expect(elementA.name, 'A');
    expect(elementB.name, 'B');
    // unit.types
    expect(
        unitElement.functionTypeAliases, unorderedEquals([elementA, elementB]));
    // verify delta
    expect(unitDelta.addedDeclarations, unorderedEquals([elementB]));
    expect(unitDelta.removedDeclarations, unorderedEquals([]));
  }

  test_unitMembers_topLevelVariable() {
    _buildOldUnit(r'''
bool a = 1, b = 2;
int c = 3;
''');
    List<CompilationUnitMember> oldNodes = oldUnit.declarations.toList();
    _buildNewUnit(r'''
int c = 3;

bool a =1, b = 2;
''');
    List<CompilationUnitMember> newNodes = newUnit.declarations;
    {
      TopLevelVariableDeclaration newNode = newNodes[0];
      expect(newNode, same(oldNodes[1]));
      expect(getNodeText(newNode), 'int c = 3;');
      {
        TopLevelVariableElement element =
            newNode.variables.variables[0].element;
        expect(element, isNotNull);
        expect(element.name, 'c');
        expect(element.nameOffset, newCode.indexOf('c = 3'));
      }
    }
    {
      TopLevelVariableDeclaration newNode = newNodes[1];
      expect(newNode, same(oldNodes[0]));
      expect(getNodeText(newNode), 'bool a =1, b = 2;');
      {
        TopLevelVariableElement element =
            newNode.variables.variables[0].element;
        expect(element, isNotNull);
        expect(element.name, 'a');
        expect(element.nameOffset, newCode.indexOf('a =1'));
      }
      {
        TopLevelVariableElement element =
            newNode.variables.variables[1].element;
        expect(element, isNotNull);
        expect(element.name, 'b');
        expect(element.nameOffset, newCode.indexOf('b = 2'));
      }
    }
    // verify delta
    expect(unitDelta.addedDeclarations, unorderedEquals([]));
    expect(unitDelta.removedDeclarations, unorderedEquals([]));
  }

  test_unitMembers_topLevelVariable_add() {
    _buildOldUnit(r'''
int a, b;
''');
    List<CompilationUnitMember> oldNodes = oldUnit.declarations.toList();
    _buildNewUnit(r'''
int a, b;
int c, d;
''');
    List<CompilationUnitMember> newNodes = newUnit.declarations;
    // nodes
    TopLevelVariableDeclaration node1 = newNodes[0];
    TopLevelVariableDeclaration node2 = newNodes[1];
    expect(node1, same(oldNodes[0]));
    // elements
    TopLevelVariableElement elementA = node1.variables.variables[0].element;
    TopLevelVariableElement elementB = node1.variables.variables[1].element;
    TopLevelVariableElement elementC = node2.variables.variables[0].element;
    TopLevelVariableElement elementD = node2.variables.variables[1].element;
    expect(elementA, isNotNull);
    expect(elementB, isNotNull);
    expect(elementC, isNotNull);
    expect(elementD, isNotNull);
    expect(elementA.name, 'a');
    expect(elementB.name, 'b');
    expect(elementC.name, 'c');
    expect(elementD.name, 'd');
    // unit.types
    expect(unitElement.topLevelVariables,
        unorderedEquals([elementA, elementB, elementC, elementD]));
    expect(
        unitElement.accessors,
        unorderedEquals([
          elementA.getter,
          elementA.setter,
          elementB.getter,
          elementB.setter,
          elementC.getter,
          elementC.setter,
          elementD.getter,
          elementD.setter
        ]));
  }

  test_unitMembers_topLevelVariable_final() {
    _buildOldUnit(r'''
final int a = 1;
''');
    List<CompilationUnitMember> oldNodes = oldUnit.declarations.toList();
    _buildNewUnit(r'''
final int a =  1;
''');
    List<CompilationUnitMember> newNodes = newUnit.declarations;
    {
      TopLevelVariableDeclaration newNode = newNodes[0];
      expect(newNode, same(oldNodes[0]));
      expect(getNodeText(newNode), 'final int a =  1;');
      {
        TopLevelVariableElement element =
            newNode.variables.variables[0].element;
        expect(element, isNotNull);
        expect(element.name, 'a');
        expect(element.nameOffset, newCode.indexOf('a =  1'));
      }
    }
    // verify delta
    expect(unitDelta.addedDeclarations, unorderedEquals([]));
    expect(unitDelta.removedDeclarations, unorderedEquals([]));
  }

  test_update_addIdentifier_beforeConstructorWithComment() {
    _buildOldUnit(r'''
class A {
  /// CCC
  A();
}
''');
    _buildNewUnit(r'''
class A {
  b

  /// CCC
  A();
}
''');
  }

  test_update_beforeClassWithDelta_nameOffset() {
    _buildOldUnit(r'''
class A {}

class B {
  A a;
}
''');
    _buildNewUnit(r'''
class A2 {}

class B {
  A2 a;
}
''');
  }

  test_update_changeDuplicatingOffsetsMapping() {
    _buildOldUnit(r'''
class A {
  m() {
  }
}

/// X
class C {}
''');
    _buildNewUnit(r'''
class A {
  m2() {
    b
  }
}

/// X
class C {}
''');
  }

  test_update_closuresOfSyntheticInitializer() {
    _buildOldUnit(r'''
f1() {
  print(1);
}
f2() {
  B b = new B((C c) {});
}
''');
    _buildNewUnit(r'''
f1() {
  print(12);
}
f2() {
  B b = new B((C c) {});
}
''');
  }

  test_update_commentReference_empty() {
    _buildOldUnit(r'''
/// Empty [] reference.
class A {}
''');
    _buildNewUnit(r'''
/// Empty [] reference.
class A {}
''');
  }

  test_update_commentReference_notClosed() {
    _buildOldUnit(r'''
/// [c)
class A {}
''');
    _buildNewUnit(r'''
int a;
/// [c)
class A {}
''');
  }

  test_update_rewrittenConstructorName() {
    _buildOldUnit(r'''
class A {
  A();
  A.named();
}

foo() {}

main() {
  new A();
  new A.named();
}
''');
    _buildNewUnit(r'''
class A {
  A();
  A.named();
}

bar() {}

main() {
  new A();
  new A.named();
}
''');
  }

  void _buildNewUnit(String newCode) {
    this.newCode = newCode;
    AnalysisOptionsImpl analysisOptions = context.analysisOptions;
    analysisOptions.finerGrainedInvalidation = false;
    try {
      context.setContents(source, newCode);
      newUnit = context.parseCompilationUnit(source);
      IncrementalCompilationUnitElementBuilder builder =
          new IncrementalCompilationUnitElementBuilder(oldUnit, newUnit);
      builder.build();
      unitDelta = builder.unitDelta;
      expect(newUnit.element, unitElement);
      // Flush all tokens, ASTs and elements.
      context.analysisCache.flush((target, result) {
        return result == TOKEN_STREAM ||
            result == PARSED_UNIT ||
            RESOLVED_UNIT_RESULTS.contains(result) ||
            LIBRARY_ELEMENT_RESULTS.contains(result);
      });
      // Compute a new AST with built elements.
      CompilationUnit newUnitFull = context.computeResult(
          new LibrarySpecificUnit(source, source), RESOLVED_UNIT1);
      expect(newUnitFull, isNot(same(newUnit)));
      new _BuiltElementsValidator().isEqualNodes(newUnitFull, newUnit);
    } finally {
      analysisOptions.finerGrainedInvalidation = true;
    }
  }

  void _buildOldUnit(String oldCode, [Source libSource]) {
    this.oldCode = oldCode;
    source = newSource('/test.dart', oldCode);
    if (libSource == null) {
      libSource = source;
    }
    oldUnit = context.resolveCompilationUnit2(source, libSource);
    unitElement = oldUnit.element;
    expect(unitElement, isNotNull);
  }

  void _verifyNoClassDeltaForTheLast(String oldCode, String newCode) {
    _buildOldUnit(oldCode);
    List<CompilationUnitMember> oldMembers = oldUnit.declarations.toList();
    Element oldElementLast = oldMembers.last.element;
    _buildNewUnit(newCode);
    List<CompilationUnitMember> newMembers = newUnit.declarations;
    Element newElementLast = newMembers.last.element;
    expect(newElementLast, isNot(same(oldElementLast)));
    expect(unitDelta.classDeltas, isEmpty);
    expect(unitDelta.removedDeclarations, unorderedEquals([oldElementLast]));
    expect(unitDelta.addedDeclarations, unorderedEquals([newElementLast]));
  }
}

/**
 * Compares tokens and ASTs, and built elements of declared identifiers.
 */
class _BuiltElementsValidator extends AstComparator {
  @override
  bool isEqualNodes(AstNode expected, AstNode actual) {
    // Elements of nodes which are children of ClassDeclaration(s) must be
    // linked to the corresponding ClassElement(s).
    if (actual is TypeParameter) {
      TypeParameterElement element = actual.element;
      ClassDeclaration classNode = actual.parent.parent;
      expect(element.enclosingElement, same(classNode.element));
    } else if (actual is FieldDeclaration) {
      for (VariableDeclaration field in actual.fields.variables) {
        Element element = field.element;
        ClassDeclaration classNode = actual.parent;
        expect(element.enclosingElement, same(classNode.element));
      }
    } else if (actual is ClassMember) {
      Element element = actual.element;
      ClassDeclaration classNode = actual.parent;
      expect(element.enclosingElement, same(classNode.element));
    }
    // Field elements referenced by field formal parameters of constructors
    // must by fields of the enclosing class element.
    if (actual is FieldFormalParameter) {
      FieldFormalParameterElement parameterElement = actual.element;
      FieldElement element = parameterElement.field;
      ClassDeclaration classNode =
          actual.getAncestor((n) => n is ClassDeclaration);
      expect(element.enclosingElement, same(classNode.element));
    }
    // Identifiers like 'a.b' in 'new a.b()' might be rewritten if resolver
    // sees that 'a' is actually a class name, so 'b' is a constructor name.
    //
    if (expected is ConstructorName && actual is ConstructorName) {
      Identifier expectedTypeName = expected.type.name;
      Identifier actualTypeName = actual.type.name;
      if (expectedTypeName is PrefixedIdentifier &&
          actualTypeName is SimpleIdentifier) {
        return isEqualNodes(expectedTypeName.prefix, actualTypeName) &&
            isEqualNodes(expectedTypeName.identifier, actual.name);
      }
    }
    // Compare nodes.
    bool result = super.isEqualNodes(expected, actual);
    if (!result) {
      fail('|$actual| != expected |$expected|');
    }
    // Verify that declared identifiers have equal elements.
    if (expected is SimpleIdentifier && actual is SimpleIdentifier) {
      if (expected.inDeclarationContext()) {
        expect(actual.inDeclarationContext(), isTrue);
        Element expectedElement = expected.staticElement;
        Element actualElement = actual.staticElement;
        _verifyElement(expectedElement, actualElement, 'staticElement');
      }
    }
    return true;
  }

  void _verifyElement(Element expected, Element actual, String desc) {
    if (expected == null && actual == null) {
      return;
    }
    // Prefixes are built later.
    if (actual is PrefixElement) {
      return;
    }
    // Compare properties.
    _verifyEqual('$desc name', expected.name, actual.name);
    _verifyEqual('$desc nameOffset', expected.nameOffset, actual.nameOffset);
    if (expected is ElementImpl && actual is ElementImpl) {
      _verifyEqual('$desc codeOffset', expected.codeOffset, actual.codeOffset);
      _verifyEqual('$desc codeLength', expected.codeLength, actual.codeLength);
    }
    if (expected is LocalElement && actual is LocalElement) {
      _verifyEqual(
          '$desc visibleRange', expected.visibleRange, actual.visibleRange);
    }
    _verifyEqual('$desc documentationComment', expected.documentationComment,
        actual.documentationComment);
    {
      var expectedEnclosing = expected.enclosingElement;
      var actualEnclosing = actual.enclosingElement;
      if (expectedEnclosing != null) {
        expect(actualEnclosing, isNotNull, reason: '$desc enclosingElement');
        _verifyElement(expectedEnclosing, actualEnclosing,
            '${expectedEnclosing.name}.$desc');
      }
    }
  }

  void _verifyEqual(String name, expected, actual) {
    if (actual != expected) {
      fail('$name\nExpected: $expected\n  Actual: $actual');
    }
  }
}

class _ClassDeltaHelper {
  final String name;

  ClassElementDelta delta;
  ClassElement element;
  List<ClassMember> oldMembers;
  List<ClassMember> newMembers;

  _ClassDeltaHelper(this.name);

  void initNew(CompilationUnit newUnit, CompilationUnitElementDelta unitDelta) {
    ClassDeclaration newClass = _findClassNode(newUnit, name);
    expect(newClass, isNotNull);
    newMembers = newClass.members.toList();
    delta = unitDelta.classDeltas[name];
    expect(delta, isNotNull, reason: 'No delta for class: $name');
  }

  void initOld(CompilationUnit oldUnit) {
    ClassDeclaration oldClass = _findClassNode(oldUnit, name);
    expect(oldClass, isNotNull);
    element = oldClass.element;
    oldMembers = oldClass.members.toList();
  }

  ClassDeclaration _findClassNode(CompilationUnit unit, String name) =>
      unit.declarations.singleWhere((unitMember) =>
          unitMember is ClassDeclaration && unitMember.name.name == name);
}
