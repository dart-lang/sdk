// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

/// Wraps the initializers of late local variables in closures.
class LateVarInitTransformer {
  const LateVarInitTransformer();

  bool _shouldApplyTransform(Statement s) {
    if (s is VariableStatement) {
      // This transform only applies to late variables.
      if (!s.declaration.variable.isLate) return false;

      // Const variables are ignored.
      if (s.declaration.variable.isConst) return false;

      // Variables with no initializer or a trivial initializer are ignored.
      if (s.declaration.variable.initializer == null) return false;
      final Expression? init = s.declaration.variable.initializer;
      if (init is StringLiteral) return false;
      if (init is BoolLiteral) return false;
      if (init is IntLiteral) return false;
      if (init is DoubleLiteral) return false;
      if (init is NullLiteral) return false;
      if (init is ConstantExpression && init.constant is PrimitiveConstant) {
        return false;
      }

      return true;
    }
    return false;
  }

  List<Statement> _transformVariableDeclaration(
    VariableStatement node,
    LocalFunctionIdGenerator localFunctionIdGenerator,
  ) {
    final fnNode = FunctionNode(
      ReturnStatement(node.declaration.variable.initializer),
      returnType: node.declaration.variable.type,
    );
    final functionType = fnNode.computeThisFunctionType(
      Nullability.nonNullable,
    );
    final fn = FunctionDeclaration(
      LocalFunctionVariable(
        name: "#${node.declaration.variable.cosmeticName}#initializer",
        type: functionType,
        isSynthesized: true,
      ),
      fnNode,
    )..id = localFunctionIdGenerator.allocateId();
    node.declaration.variable.initializer = LocalFunctionInvocation(
      fn.variable,
      Arguments([]),
      functionType: functionType,
    )..parent = node.declaration.variable;

    return [fn, node];
  }

  List<Statement>? _transformStatements(
    List<Statement> statements,
    LocalFunctionIdGenerator localFunctionIdGenerator,
  ) {
    if (!statements.any((s) => _shouldApplyTransform(s))) return null;
    final List<Statement> newStatements = <Statement>[];
    for (Statement s in statements) {
      if (_shouldApplyTransform(s)) {
        newStatements.addAll(
          _transformVariableDeclaration(
            s as VariableStatement,
            localFunctionIdGenerator,
          ),
        );
      } else {
        newStatements.add(s);
      }
    }
    return newStatements;
  }

  Block transformBlock(
    Block node,
    LocalFunctionIdGenerator localFunctionIdGenerator,
  ) {
    final statements = _transformStatements(
      node.statements,
      localFunctionIdGenerator,
    );
    if (statements == null) return node;
    return Block(statements)..fileOffset = node.fileOffset;
  }

  AssertBlock transformAssertBlock(
    AssertBlock node,
    LocalFunctionIdGenerator localFunctionIdGenerator,
  ) {
    final statements = _transformStatements(
      node.statements,
      localFunctionIdGenerator,
    );
    if (statements == null) return node;
    return AssertBlock(statements)..fileOffset = node.fileOffset;
  }
}
