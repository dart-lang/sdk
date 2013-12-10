// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of ssa;

class SsaFromIrInliner extends IrNodesVisitor with SsaFromIrMixin {
  final SsaBuilder builder;

  SsaFromIrInliner(this.builder);

  Compiler get compiler => builder.compiler;

  Element get sourceElement => builder.sourceElementStack.last;

  HGraph get graph => builder.graph;

  HBasicBlock get current => builder.current;

  bool get isReachable => builder.isReachable;

  void emitReturn(HInstruction value, IrReturn node) {
    builder.localsHandler.updateLocal(builder.returnElement, value);
  }
}

class IrInlineWeeder extends IrNodesVisitor {
  static bool canBeInlined(IrFunction irFunction,
                           int maxInliningNodes,
                           bool useMaxInliningNodes) {
    IrInlineWeeder weeder =
        new IrInlineWeeder(maxInliningNodes, useMaxInliningNodes);
    weeder.visitAll(irFunction.statements);
    return !weeder.tooDifficult;
  }

  final int maxInliningNodes;
  final bool useMaxInliningNodes;

  IrInlineWeeder(this.maxInliningNodes, this.useMaxInliningNodes);

  bool seenReturn = false;
  bool tooDifficult = false;
  int nodeCount = 0;

  bool registerNode() {
    if (!useMaxInliningNodes) return true;
    if (nodeCount++ > maxInliningNodes) {
      tooDifficult = true;
      return false;
    } else {
      return true;
    }
  }

  void visitIrNode(IrNode node) {
    if (!registerNode()) return;
    if (seenReturn) {
      tooDifficult = true;
    }
  }

  void visitIrReturn(IrReturn node) {
    visitIrNode(node);
    seenReturn = true;
  }

  void visitIrFunction(IrFunction node) {
    tooDifficult = true;
  }
}