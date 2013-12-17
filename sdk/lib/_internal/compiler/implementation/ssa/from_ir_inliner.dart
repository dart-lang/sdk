// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of ssa;

/**
 * This class implements an [IrNodesVisitor] that inlines a function represented
 * as IR into an [SsaFromAstBuilder].
 */
class SsaFromIrInliner extends IrNodesVisitor with
    SsaBuilderMixin<IrNode>,
    SsaFromIrMixin,
    SsaBuilderDelegate<IrNode, Node> {
  final SsaFromAstBuilder builder;

  SsaFromIrInliner.internal(this.builder);

  factory SsaFromIrInliner(SsaFromAstBuilder builder,
                           FunctionElement function,
                           List<HInstruction> compiledArguments) {
    SsaFromIrInliner irInliner = new SsaFromIrInliner.internal(builder);
    irInliner.setupStateForInlining(function, compiledArguments);
    return irInliner;
  }

  final List<IrExpression> inlinedCalls = <IrExpression>[];

  /**
   * This function is invoked when we are currently inlining an IR function
   * into an AST builder, and we encounter an infocation that is inlined.
   */
  void enterInlinedMethod(FunctionElement function,
                          IrNode callNode,
                          List<HInstruction> compiledArguments) {
    assert(callNode != null);
    inlinedCalls.add(callNode);
    builder.enterInlinedMethod(function, null, compiledArguments);
  }

  void leaveInlinedMethod() {
    builder.leaveInlinedMethod();
    // [leaveInlinedMethod] pushes the returned value on the builder's stack,
    // no matter if the inlined function is represented in AST or IR.
    emitted[inlinedCalls.removeLast()] = builder.pop();
  }

  void doInline(FunctionElement function) {
    builder.doInline(function);
  }

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