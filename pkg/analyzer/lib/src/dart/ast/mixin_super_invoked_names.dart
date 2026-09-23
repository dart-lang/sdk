// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// Visitor that collects super-invoked names in a mixin declaration.
class MixinSuperInvokedNamesCollector extends RecursiveAstVisitor2<void> {
  final Set<String> _names;

  MixinSuperInvokedNamesCollector(this._names);

  @override
  void visitBinaryOperatorInvocation(BinaryOperatorInvocation node) {
    if (node.leftOperand is SuperReference) {
      _names.add(node.operator.lexeme);
    }
    super.visitBinaryOperatorInvocation(node);
  }

  @override
  void visitCascadeIndexAssignmentTarget(CascadeIndexAssignmentTarget node) {
    if (_cascadeTarget(node) is SuperReference) {
      if (node.hasRead) {
        _names.add('[]');
      }
      _names.add('[]=');
    }
    super.visitCascadeIndexAssignmentTarget(node);
  }

  @override
  void visitCascadeIndexExpression(CascadeIndexExpression node) {
    if (_cascadeTarget(node) is SuperReference) {
      _names.add('[]');
    }
    super.visitCascadeIndexExpression(node);
  }

  @override
  void visitCascadePropertyAssignmentTarget(
    CascadePropertyAssignmentTarget node,
  ) {
    if (_cascadeTarget(node) is SuperReference) {
      if (node.parent2 is CompoundAssignment ||
          node.parent2 is IfNullAssignment) {
        _names.add(node.name.lexeme);
      }
      _names.add('${node.name.lexeme}=');
    }
    super.visitCascadePropertyAssignmentTarget(node);
  }

  @override
  void visitCascadePropertyExtraction(CascadePropertyExtraction node) {
    if (_cascadeTarget(node) is SuperReference) {
      _names.add(node.name.lexeme);
    }
    super.visitCascadePropertyExtraction(node);
  }

  @override
  void visitIncrementOrDecrementExpression(
    IncrementOrDecrementExpression node,
  ) {
    if (node.position == IncrementOrDecrementPosition.prefix) {
      if (node.target is InvalidSuperAssignmentTarget) {
        _names.add(node.operation.binaryOperatorName);
      }
    }
    node.visitChildren2(this);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    if (node.target2 is SuperExpression) {
      if (node.inGetterContext()) {
        _names.add('[]');
      }
      if (node.inSetterContext()) {
        _names.add('[]=');
      }
    }
    super.visitIndexExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.target2 is SuperExpression) {
      _names.add(node.methodName.name);
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitParsedNameAccess(ParsedNameAccess node) {
    if (node.operand is SuperReference) {
      _names.add(node.name.lexeme);
    }
    super.visitParsedNameAccess(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.target2 is SuperExpression) {
      var name = node.propertyName.name;
      if (node.propertyName.inGetterContext()) {
        _names.add(name);
      }
      if (node.propertyName.inSetterContext()) {
        _names.add('$name=');
      }
    }
    super.visitPropertyAccess(node);
  }

  @override
  void visitReceiverIndexAssignmentTarget(ReceiverIndexAssignmentTarget node) {
    if (node.receiver is SuperReference) {
      if (node.parent2 is CompoundAssignment ||
          node.parent2 is IfNullAssignment) {
        _names.add('[]');
      }
      _names.add('[]=');
    }
    super.visitReceiverIndexAssignmentTarget(node);
  }

  @override
  void visitReceiverIndexExpression(ReceiverIndexExpression node) {
    if (node.receiver is SuperReference) {
      _names.add('[]');
    }
    super.visitReceiverIndexExpression(node);
  }

  @override
  void visitReceiverMethodInvocation(ReceiverMethodInvocation node) {
    if (node.receiver is SuperReference) {
      _names.add(node.name.lexeme);
    }
    super.visitReceiverMethodInvocation(node);
  }

  @override
  void visitReceiverPropertyAssignmentTarget(
    ReceiverPropertyAssignmentTarget node,
  ) {
    if (node.receiver is SuperReference) {
      if (node.hasRead) _names.add(node.name.lexeme);
      _names.add('${node.name.lexeme}=');
    }
    super.visitReceiverPropertyAssignmentTarget(node);
  }

  @override
  void visitReceiverPropertyExtraction(ReceiverPropertyExtraction node) {
    if (node.receiver is SuperReference) {
      _names.add(node.name.lexeme);
    }
    super.visitReceiverPropertyExtraction(node);
  }

  @override
  void visitUnaryOperatorInvocation(UnaryOperatorInvocation node) {
    if (node.operand is SuperReference) {
      _names.add(switch (node.unaryOperator) {
        UnaryOperator.negate => 'unary-',
        UnaryOperator.bitwiseComplement => '~',
      });
    }
    super.visitUnaryOperatorInvocation(node);
  }

  Expression? _cascadeTarget(AstNode node) {
    for (
      AstNode? ancestor = node.parent2;
      ancestor != null;
      ancestor = ancestor.parent2
    ) {
      if (ancestor is CascadeExpression) return ancestor.target2;
    }
    return null;
  }
}
