// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of native;

class SideEffectsVisitor extends js.BaseVisitor {
  final SideEffects sideEffects;
  SideEffectsVisitor(this.sideEffects);

  void visit(js.Node node) {
    node.accept(this);
  }

  void visitLiteralExpression(js.LiteralExpression node) {
    sideEffects.setAllSideEffects();
    sideEffects.setDependsOnSomething();
    node.visitChildren(this);
  }

  void visitLiteralStatement(js.LiteralStatement node) {
    sideEffects.setAllSideEffects();
    sideEffects.setDependsOnSomething();
    node.visitChildren(this);
  }

  void visitAssignment(js.Assignment node) {
    sideEffects.setChangesStaticProperty();
    sideEffects.setChangesInstanceProperty();
    sideEffects.setChangesIndex();
    node.visitChildren(this);
  }

  void visitVariableInitialization(js.VariableInitialization node) {
    node.visitChildren(this);
  }

  void visitCall(js.Call node) {
    sideEffects.setAllSideEffects();
    sideEffects.setDependsOnSomething();
    node.visitChildren(this);
  }

  void visitBinary(js.Binary node) {
    node.visitChildren(this);
  }

  void visitThrow(js.Throw node) {
    // TODO(ngeoffray): Incorporate a mayThrow flag in the
    // [SideEffects] class.
    sideEffects.setAllSideEffects();
  }

  void visitNew(js.New node) {
    sideEffects.setAllSideEffects();
    sideEffects.setDependsOnSomething();
    node.visitChildren(this);
  }

  void visitPrefix(js.Prefix node) {
    if (node.op == 'delete') {
      sideEffects.setChangesStaticProperty();
      sideEffects.setChangesInstanceProperty();
      sideEffects.setChangesIndex();
    }
    node.visitChildren(this);
  }

  void visitVariableUse(js.VariableUse node) {
    sideEffects.setDependsOnStaticPropertyStore();
  }

  void visitPostfix(js.Postfix node) {
    node.visitChildren(this);
  }

  void visitAccess(js.PropertyAccess node) {
    sideEffects.setDependsOnIndexStore();
    sideEffects.setDependsOnInstancePropertyStore();
    sideEffects.setDependsOnStaticPropertyStore();
    node.visitChildren(this);
  }
}
