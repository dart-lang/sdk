// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:kernel/ast.dart";
import "package:kernel/core_types.dart";
import "package:kernel/testing/mock_sdk_program.dart";
import "package:kernel/text/ast_to_text.dart";
import "package:kernel/transformations/erasure.dart";

void main([List<String> arguments = const []]) {
  new Tester().testLocalFunction();
}

class Tester {
  final Program program;

  final Library library;

  final Procedure mainMethod;

  final CoreTypes coreTypes;

  static final Uri base =
      new Uri(scheme: "org.dartlang.kernel", host: "", path: "/");

  Tester.internal(this.program, this.library, this.mainMethod)
      : coreTypes = new CoreTypes(program);

  factory Tester() {
    Program program = createMockSdkProgram();
    Library library = new Library(base.resolve("main.dart"))..parent = program;
    Procedure mainMethod = buildProcedure("main");
    library.addMember(mainMethod);
    program.libraries.add(library);
    program.mainMethod = mainMethod;
    return new Tester.internal(program, library, mainMethod);
  }

  void addStatement(Statement statement) {
    Block body = mainMethod.function.body;
    body.statements.add(statement);
    statement.parent = body;
  }

  void testLocalFunction() {
    FunctionDeclaration fDeclaration = buildFunctionDeclaration(
        "f", buildFunctionNodeWithTypesAndParameters());
    FunctionExpression functionExpression =
        new FunctionExpression(buildFunctionNodeWithTypesAndParameters());

    addStatement(fDeclaration);
    addStatement(new ExpressionStatement(functionExpression));
    Expect.stringEquals(
        "<T extends dynamic, S extends dart.core::List<T>>(S) → T",
        debugNodeToString(fDeclaration.variable.type).trim());
    Expect.stringEquals(
        "<T extends dynamic, S extends dart.core::List<T>>(S) → T",
        debugNodeToString(functionExpression.getStaticType(null)).trim());
    transformProgram(coreTypes, program);
    Expect.stringEquals("(dart.core::List<dynamic>) → dynamic",
        debugNodeToString(fDeclaration.variable.type).trim());
    Expect.stringEquals(
        "<T extends dynamic, S extends dart.core::List<dynamic>>(dart.core::List<dynamic>) → dynamic",
        debugNodeToString(functionExpression.getStaticType(null)).trim());
  }

  /// Builds this function: `f<T, S extends List<T>>(S argument) → T {}`.
  FunctionNode buildFunctionNodeWithTypesAndParameters() {
    TypeParameter tVariable = new TypeParameter("T", const DynamicType());
    TypeParameter sVariable = new TypeParameter("S", const DynamicType());
    TypeParameterType tType = new TypeParameterType(tVariable);
    TypeParameterType sType = new TypeParameterType(sVariable);
    sVariable.bound = new InterfaceType(coreTypes.listClass, <DartType>[tType]);
    return new FunctionNode(buildBlock(),
        positionalParameters: <VariableDeclaration>[
          new VariableDeclaration("argument", type: sType),
        ],
        typeParameters: <TypeParameter>[tVariable, sVariable],
        returnType: tType);
  }

  static Block buildBlock([List<Statement> statements]) {
    return new Block(statements ?? <Statement>[]);
  }

  static FunctionNode buildFunction([Statement body]) {
    return new FunctionNode(body ?? buildBlock());
  }

  static Procedure buildProcedure(String name, [FunctionNode function]) {
    return new Procedure(
        new Name(name), ProcedureKind.Method, function ?? buildFunction());
  }

  static FunctionDeclaration buildFunctionDeclaration(
      String name, FunctionNode function) {
    return new FunctionDeclaration(
        new VariableDeclaration(name,
            type: function.functionType, isFinal: true),
        function);
  }
}
