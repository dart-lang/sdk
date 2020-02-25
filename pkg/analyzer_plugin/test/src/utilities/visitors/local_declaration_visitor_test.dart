// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/src/utilities/visitors/local_declaration_visitor.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LocalDeclarationVisitorTest);
  });
}

@reflectiveTest
class LocalDeclarationVisitorTest {
  CompilationUnit parseCompilationUnit(String content) {
    return parseString(content: content).unit;
  }

  void test_visitForEachStatement() {
    CompilationUnit unit = parseCompilationUnit('''
class MyClass {}
f(List<MyClass> list) {
  for(x in list) {}
}
''');
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(2));
    FunctionDeclaration f = declarations[1] as FunctionDeclaration;
    expect(f, isNotNull);
    BlockFunctionBody body = f.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ForStatement;
    expect(statement.forLoopParts, const TypeMatcher<ForEachParts>());
    statement.accept(TestVisitor(statement.offset));
  }
}

class TestVisitor extends LocalDeclarationVisitor {
  TestVisitor(int offset) : super(offset);

  @override
  void declaredClass(ClassDeclaration declaration) {}

  @override
  void declaredClassTypeAlias(ClassTypeAlias declaration) {}

  @override
  void declaredExtension(ExtensionDeclaration declaration) {}

  @override
  void declaredField(FieldDeclaration fieldDecl, VariableDeclaration varDecl) {}

  @override
  void declaredFunction(FunctionDeclaration declaration) {}

  @override
  void declaredFunctionTypeAlias(FunctionTypeAlias declaration) {}

  @override
  void declaredGenericTypeAlias(GenericTypeAlias declaration) {}

  @override
  void declaredLabel(Label label, bool isCaseLabel) {}

  @override
  void declaredLocalVar(SimpleIdentifier name, TypeAnnotation type) {
    expect(name, isNotNull);
  }

  @override
  void declaredMethod(MethodDeclaration declaration) {}

  @override
  void declaredParam(SimpleIdentifier name, TypeAnnotation type) {}

  @override
  void declaredTopLevelVar(
      VariableDeclarationList varList, VariableDeclaration varDecl) {}
}
