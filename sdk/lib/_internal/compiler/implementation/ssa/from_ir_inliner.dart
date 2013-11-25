// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of ssa;

class SsaFromIrInliner extends IrNodesVisitor {

  final SsaBuilder builder;

  SsaFromIrInliner(this.builder);

  final Map<IrNode, HInstruction> emitted = new Map<IrNode, HInstruction>();

  Compiler get compiler => builder.compiler;

  void visitIrReturn(IrReturn node) {
    HInstruction hValue = emitted[node.value];
    builder.localsHandler.updateLocal(builder.returnElement, hValue);
  }

  void visitIrConstant(IrConstant node) {
    emitted[node] = builder.graph.addConstant(node.value, compiler);
  }

  void visitNode(IrNode node) {
    compiler.internalError('Unexpected IrNode $node');
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

  void visitNode(IrNode node) {
    if (!registerNode()) return;
    if (seenReturn) {
      tooDifficult = true;
    }
  }

  void visitIrReturn(IrReturn node) {
    visitNode(node);
    seenReturn = true;
  }

  void visitIrFunction(IrFunction node) {
    tooDifficult = true;
  }

}