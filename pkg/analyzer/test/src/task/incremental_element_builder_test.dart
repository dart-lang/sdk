// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.src.task.incremental_element_builder_test;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/incremental_element_builder.dart';
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

  void _buildNewUnit(String newCode) {
    this.newCode = newCode;
    context.setContents(source, newCode);
    newUnit = context.parseCompilationUnit(source);
    IncrementalCompilationUnitElementBuilder builder =
        new IncrementalCompilationUnitElementBuilder(oldUnit, newUnit);
    builder.build();
    unitDelta = builder.unitDelta;
    expect(newUnit.element, unitElement);
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
}
