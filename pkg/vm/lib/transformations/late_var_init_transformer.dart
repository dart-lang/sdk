// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

/// Wraps the initializers of late local variables in closures.
void transformLibraries(List<Library> libraries) {
  const transformer = _LateVarInitTransformer();
  libraries.forEach(transformer.visitLibrary);
}

class _LateVarInitTransformer extends Transformer {
  const _LateVarInitTransformer();

  bool _shouldApplyTransform(VariableDeclaration v) {
    // This transform only applies to late variables.
    if (!v.isLate) return false;

    // Const variables are ignored.
    if (v.isConst) return false;

    // Variables with no initializer or a trivial initializer are ignored.
    if (v.initializer == null) return false;
    final Expression init = v.initializer;
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

  List<Statement> _transformVariableDeclaration(
      TreeNode parent, VariableDeclaration node) {
    super.visitVariableDeclaration(node);

    final fnNode =
        FunctionNode(ReturnStatement(node.initializer), returnType: node.type);
    final fn = FunctionDeclaration(
        VariableDeclaration("#${node.name}#initializer",
            type: fnNode.thisFunctionType),
        fnNode)
      ..parent = parent;
    node.initializer =
        MethodInvocation(VariableGet(fn.variable), Name("call"), Arguments([]))
          ..parent = node;

    return [fn, node];
  }

  void _transformStatements(TreeNode parent, List<Statement> statements) {
    List<Statement> oldStatements = statements;
    for (var i = 0; i < oldStatements.length; ++i) {
      Statement s = oldStatements[i];
      if (s is VariableDeclaration && _shouldApplyTransform(s)) {
        if (oldStatements == statements) {
          oldStatements = List<Statement>.of(statements);
          statements.clear();
        }
        statements.addAll(_transformVariableDeclaration(parent, s));
      } else if (oldStatements != statements) {
        statements.add(s.accept<TreeNode>(this)..parent = parent);
      } else {
        statements[i] = s.accept<TreeNode>(this)..parent = parent;
      }
    }
  }

  @override
  visitBlock(Block node) {
    _transformStatements(node, node.statements);
    return node;
  }

  @override
  visitAssertBlock(AssertBlock node) {
    _transformStatements(node, node.statements);
    return node;
  }
}
