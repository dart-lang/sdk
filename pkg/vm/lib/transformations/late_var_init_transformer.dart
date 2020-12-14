// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

/// Wraps the initializers of late local variables in closures.
class LateVarInitTransformer {
  const LateVarInitTransformer();

  bool _shouldApplyTransform(Statement s) {
    if (s is VariableDeclaration) {
      // This transform only applies to late variables.
      if (!s.isLate) return false;

      // Const variables are ignored.
      if (s.isConst) return false;

      // Variables with no initializer or a trivial initializer are ignored.
      if (s.initializer == null) return false;
      final Expression init = s.initializer;
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

  List<Statement> _transformVariableDeclaration(VariableDeclaration node) {
    final fnNode =
        FunctionNode(ReturnStatement(node.initializer), returnType: node.type);
    final fn = FunctionDeclaration(
        VariableDeclaration("#${node.name}#initializer",
            type: fnNode.computeThisFunctionType(Nullability.legacy)),
        fnNode);
    node.initializer =
        MethodInvocation(VariableGet(fn.variable), Name("call"), Arguments([]))
          ..parent = node;

    return [fn, node];
  }

  List<Statement> _transformStatements(List<Statement> statements) {
    if (!statements.any((s) => _shouldApplyTransform(s))) return null;
    final List<Statement> newStatements = <Statement>[];
    for (Statement s in statements) {
      if (_shouldApplyTransform(s)) {
        newStatements.addAll(_transformVariableDeclaration(s));
      } else {
        newStatements.add(s);
      }
    }
    return newStatements;
  }

  Block transformBlock(Block node) {
    final statements = _transformStatements(node.statements);
    if (statements == null) return node;
    return Block(statements)..fileOffset = node.fileOffset;
  }

  AssertBlock transformAssertBlock(AssertBlock node) {
    final statements = _transformStatements(node.statements);
    if (statements == null) return node;
    return AssertBlock(statements)..fileOffset = node.fileOffset;
  }
}
