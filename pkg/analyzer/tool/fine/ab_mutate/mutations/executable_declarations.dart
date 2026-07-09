// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// Collect both top-level functions and class/extension/mixin/enum methods.
class CollectExecutablesVisitor extends RecursiveAstVisitor<void> {
  final List<ExecutableDeclaration> _out;

  CollectExecutablesVisitor._internal(this._out);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _out.add(
      ExecutableDeclaration(
        node.offset,
        node.functionExpression.parameters,
        node.returnType,
      ),
    );
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _out.add(
      ExecutableDeclaration(node.offset, node.parameters, node.returnType),
    );
    super.visitMethodDeclaration(node);
  }

  /// Collect all top-level functions and class methods in [unit].
  static List<ExecutableDeclaration> collectFrom(CompilationUnit unit) {
    var executables = <ExecutableDeclaration>[];
    unit.visitChildren(CollectExecutablesVisitor._internal(executables));
    return executables;
  }
}

/// Aggregated executable info for API mutations.
class ExecutableDeclaration {
  final int declarationOffset;
  final FormalParameterList? formalParameters;
  final TypeAnnotation? returnType;

  ExecutableDeclaration(
    this.declarationOffset,
    this.formalParameters,
    this.returnType,
  );
}
