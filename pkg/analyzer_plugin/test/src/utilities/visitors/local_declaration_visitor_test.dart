// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer_plugin/src/utilities/visitors/local_declaration_visitor.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LocalDeclarationVisitorTest);
  });
}

@reflectiveTest
class LocalDeclarationVisitorTest {
  CompilationUnit parseCompilationUnit(String source) {
    AnalysisErrorListener listener = AnalysisErrorListener.NULL_LISTENER;
    Scanner scanner =
        new Scanner(null, new CharSequenceReader(source), listener);
    Token token = scanner.tokenize();
    Parser parser = new Parser(null, listener);
    CompilationUnit unit = parser.parseCompilationUnit(token);
    expect(unit, isNotNull);
    return unit;
  }

  test_visitForEachStatement() {
    CompilationUnit unit = parseCompilationUnit('''
class MyClass {}
f(List<MyClass> list) {
  for(MyClas( x in list) {}
}
''');
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(2));
    FunctionDeclaration f = declarations[1];
    expect(f, isNotNull);
    BlockFunctionBody body = f.functionExpression.body;
    Statement statement = body.block.statements[0];
    expect(statement, new isInstanceOf<ForEachStatement>());
    statement.accept(new TestVisitor(statement.offset));
  }
}

class TestVisitor extends LocalDeclarationVisitor {
  TestVisitor(int offset) : super(offset);

  @override
  void declaredClass(ClassDeclaration declaration) {}

  @override
  void declaredClassTypeAlias(ClassTypeAlias declaration) {}

  @override
  void declaredField(FieldDeclaration fieldDecl, VariableDeclaration varDecl) {}

  @override
  void declaredFunction(FunctionDeclaration declaration) {}

  @override
  void declaredFunctionTypeAlias(FunctionTypeAlias declaration) {}

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
