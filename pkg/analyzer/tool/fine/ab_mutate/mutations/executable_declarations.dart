// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// Collect both top-level functions and class/extension/mixin/enum methods.
class CollectExecutablesVisitor extends RecursiveAstVisitor2<void> {
  final List<ExecutableDeclaration> _out;

  new _internal(this._out);

  @override
  void visitGetterDeclaration(GetterDeclaration node) {
    _out.add(ExecutableDeclaration(node.offset, null, node.returnType));
    super.visitGetterDeclaration(node);
  }

  @override
  void visitLocalFunctionDeclaration(LocalFunctionDeclaration node) {
    _out.add(
      ExecutableDeclaration(
        node.offset,
        node.formalParameters,
        node.returnType,
      ),
    );
    super.visitLocalFunctionDeclaration(node);
  }

  @override
  void visitMethodDeclaration2(MethodDeclaration2 node) {
    _out.add(
      ExecutableDeclaration(
        node.offset,
        node.formalParameters,
        node.returnType,
      ),
    );
    super.visitMethodDeclaration2(node);
  }

  @override
  void visitOperatorDeclaration(OperatorDeclaration node) {
    _out.add(
      ExecutableDeclaration(
        node.offset,
        node.formalParameters,
        node.returnType,
      ),
    );
    super.visitOperatorDeclaration(node);
  }

  @override
  void visitSetterDeclaration(SetterDeclaration node) {
    _out.add(
      ExecutableDeclaration(
        node.offset,
        node.formalParameters,
        node.returnType,
      ),
    );
    super.visitSetterDeclaration(node);
  }

  @override
  void visitTopLevelFunctionDeclaration(TopLevelFunctionDeclaration node) {
    _out.add(
      ExecutableDeclaration(
        node.offset,
        node.formalParameters,
        node.returnType,
      ),
    );
    super.visitTopLevelFunctionDeclaration(node);
  }

  @override
  void visitTopLevelGetterDeclaration(TopLevelGetterDeclaration node) {
    _out.add(ExecutableDeclaration(node.offset, null, node.returnType));
    super.visitTopLevelGetterDeclaration(node);
  }

  @override
  void visitTopLevelSetterDeclaration(TopLevelSetterDeclaration node) {
    _out.add(
      ExecutableDeclaration(
        node.offset,
        node.formalParameters,
        node.returnType,
      ),
    );
    super.visitTopLevelSetterDeclaration(node);
  }

  /// Collect all top-level functions and class methods in [unit].
  static List<ExecutableDeclaration> collectFrom(CompilationUnit unit) {
    var executables = <ExecutableDeclaration>[];
    unit.visitChildren2(CollectExecutablesVisitor._internal(executables));
    return executables;
  }
}

/// Aggregated executable info for API mutations.
class ExecutableDeclaration {
  final int declarationOffset;
  final FormalParameterList? formalParameters;
  final TypeAnnotation? returnType;

  new(this.declarationOffset, this.formalParameters, this.returnType);
}
