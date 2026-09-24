// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

class _SuperVisitor extends RecursiveAstVisitor2<void> {
  final String name;
  final _Usage _usage;

  /// Set to `true` if a super invocation with the [name] is found.
  bool hasSuperInvocation = false;

  _SuperVisitor(this.name, this._usage);

  @override
  void visitBinaryOperatorInvocation(BinaryOperatorInvocation node) {
    if (_usage == _Usage.reading) {
      if (node.leftOperand is SuperReference && node.operator.lexeme == name) {
        hasSuperInvocation = true;
        return;
      }
    }
    super.visitBinaryOperatorInvocation(node);
  }

  @override
  void visitParsedNameAccess(ParsedNameAccess node) {
    if (_usage == _Usage.reading &&
        node.operand is SuperReference &&
        node.name.lexeme == name) {
      hasSuperInvocation = true;
      return;
    }
    super.visitParsedNameAccess(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (_usage == _Usage.reading) {
      var parent = node.parent2;
      if (parent is AssignmentExpression && parent.leftHandSide2 == node) {
        // Not reading, skip.
      } else {
        if (node.target2 is SuperExpression && node.propertyName.name == name) {
          hasSuperInvocation = true;
          return;
        }
      }
    }
    super.visitPropertyAccess(node);
  }

  @override
  void visitReceiverMethodInvocation(ReceiverMethodInvocation node) {
    if (_usage == _Usage.reading &&
        node.receiver is SuperReference &&
        node.name.lexeme == name) {
      hasSuperInvocation = true;
      return;
    }
    super.visitReceiverMethodInvocation(node);
  }

  @override
  void visitReceiverPropertyAssignmentTarget(
    ReceiverPropertyAssignmentTarget node,
  ) {
    if (node.receiver is SuperReference &&
        node.name.lexeme == name &&
        (_usage == _Usage.writing || node.hasRead)) {
      hasSuperInvocation = true;
      return;
    }
    super.visitReceiverPropertyAssignmentTarget(node);
  }

  @override
  void visitReceiverPropertyExtraction(ReceiverPropertyExtraction node) {
    if (_usage == _Usage.reading &&
        node.receiver is SuperReference &&
        node.name.lexeme == name) {
      hasSuperInvocation = true;
      return;
    }
    super.visitReceiverPropertyExtraction(node);
  }
}

enum _Usage { writing, reading }

extension MethodDeclarationExtension on MethodDeclaration {
  bool get invokesSuperSelf {
    var visitor = _SuperVisitor(
      name.lexeme,
      isSetter ? _Usage.writing : _Usage.reading,
    );
    body.accept2(visitor);
    return visitor.hasSuperInvocation;
  }
}
