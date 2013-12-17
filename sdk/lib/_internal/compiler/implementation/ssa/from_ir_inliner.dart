// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of ssa;

/**
 * This class implements an [IrNodesVisitor] that inlines a function represented
 * as IR into an [SsaBuilder].
 */
class SsaFromIrInliner
    extends IrNodesVisitor with SsaGraphBuilderMixin<IrNode>, SsaFromIrMixin {
  final SsaBuilder builder;

  SsaFromIrInliner(this.builder);

  final List<IrExpression> inlinedCalls = <IrExpression>[];

  Compiler get compiler => builder.compiler;

  JavaScriptBackend get backend => builder.backend;

  Element get sourceElement => builder.sourceElementStack.last;

  HGraph get graph => builder.graph;

  HBasicBlock get current => builder.current;

  void set current(HBasicBlock block) {
    builder.current = block;
  }

  HBasicBlock get lastOpenedBlock => builder.lastOpenedBlock;

  void set lastOpenedBlock(HBasicBlock block) {
    builder.lastOpenedBlock = block;
  }

  bool get isReachable => builder.isReachable;

  void set isReachable(bool value) {
    builder.isReachable = value;
  }

  bool get inThrowExpression => builder.inThrowExpression;

  int get loopNesting => builder.loopNesting;

  List<InliningState> get inliningStack => builder.inliningStack;

  List<Element> get sourceElementStack => builder.sourceElementStack;

  void setupInliningState(FunctionElement function,
                          IrNode callNode,
                          List<HInstruction> compiledArguments) {
    inlinedCalls.add(callNode);
    // The [SsaBuilder] does not use the [currentNode].
    builder.setupInliningState(function, null, compiledArguments);
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