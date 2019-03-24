// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// [RecursiveAstVisitor] that delegates visit methods to functions.
class FunctionAstVisitor extends RecursiveAstVisitor<void> {
  final void Function(FunctionDeclarationStatement)
      functionDeclarationStatement;
  final void Function(SimpleIdentifier) simpleIdentifier;
  final void Function(VariableDeclaration) variableDeclaration;

  FunctionAstVisitor(
      {this.functionDeclarationStatement,
      this.simpleIdentifier,
      this.variableDeclaration});

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    if (functionDeclarationStatement != null) {
      functionDeclarationStatement(node);
    }
    super.visitFunctionDeclarationStatement(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (simpleIdentifier != null) {
      simpleIdentifier(node);
    }
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (variableDeclaration != null) {
      variableDeclaration(node);
    }
    super.visitVariableDeclaration(node);
  }
}
