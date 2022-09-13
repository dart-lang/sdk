// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReferenceFinderTest);
  });
}

@reflectiveTest
class ReferenceFinderTest {
  late final Element _tail;
  final List<ConstantEvaluationTarget> _dependencies = [];

  void test_visitSimpleIdentifier_const() {
    _visitNode(_makeTailVariable("v2", true));
    _assertOneArc(_tail);
  }

  void test_visitSuperConstructorInvocation_const() {
    _visitNode(_makeTailSuperConstructorInvocation("A", true));
    _assertOneArc(_tail);
  }

  void test_visitSuperConstructorInvocation_nonConst() {
    _visitNode(_makeTailSuperConstructorInvocation("A", false));
    _assertOneArc(_tail);
  }

  void test_visitSuperConstructorInvocation_unresolved() {
    SuperConstructorInvocation superConstructorInvocation =
        AstTestFactory.superConstructorInvocation();
    _visitNode(superConstructorInvocation);
    _assertNoArcs();
  }

  void _assertNoArcs() {
    expect(_dependencies, isEmpty);
  }

  void _assertOneArc(Element tail) {
    expect(_dependencies, hasLength(1));
    expect(_dependencies[0], same(tail));
  }

  SuperConstructorInvocation _makeTailSuperConstructorInvocation(
      String name, bool isConst) {
    List<ConstructorInitializer> initializers = <ConstructorInitializer>[];
    var constructorDeclaration = AstTestFactory.constructorDeclaration(
        AstTestFactory.identifier3(name),
        null,
        AstTestFactory.formalParameterList(),
        initializers);
    if (isConst) {
      constructorDeclaration.constKeyword = KeywordToken(Keyword.CONST, 0);
    }
    ClassElementImpl classElement = ElementFactory.classElement2(name);
    var superConstructorInvocation =
        AstTestFactory.superConstructorInvocation();
    ConstructorElementImpl constructorElement =
        ElementFactory.constructorElement(classElement, name, isConst);
    _tail = constructorElement;
    superConstructorInvocation.staticElement = constructorElement;
    return superConstructorInvocation;
  }

  SimpleIdentifier _makeTailVariable(String name, bool isConst) {
    VariableDeclaration variableDeclaration =
        AstTestFactory.variableDeclaration(name);
    ConstLocalVariableElementImpl variableElement =
        ElementFactory.constLocalVariableElement(name);
    _tail = variableElement;
    variableElement.isConst = isConst;
    AstTestFactory.variableDeclarationList2(
        isConst ? Keyword.CONST : Keyword.VAR, [variableDeclaration]);
    var identifier = AstTestFactory.identifier3(name);
    identifier.staticElement = variableElement;
    return identifier;
  }

  void _visitNode(AstNode node) {
    var referenceFinder = ReferenceFinder((dependency) {
      _dependencies.add(dependency);
    });
    node.accept(referenceFinder);
  }
}
