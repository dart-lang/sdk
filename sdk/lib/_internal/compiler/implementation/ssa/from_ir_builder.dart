// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of ssa;

class SsaFromIrBuilderTask extends CompilerTask {
  final JavaScriptBackend backend;

  SsaFromIrBuilderTask(JavaScriptBackend backend)
    : this.backend = backend,
      super(backend.compiler);

  HGraph build(CodegenWorkItem work) {
    return measure(() {
      Element element = work.element.implementation;
      return compiler.withCurrentElement(element, () {
        HInstruction.idCounter = 0;
        SsaFromIrBuilder builder =
            new SsaFromIrBuilder(backend, work, backend.emitter.nativeEmitter);
        HGraph graph;
        ElementKind kind = element.kind;
        if (kind == ElementKind.GENERATIVE_CONSTRUCTOR) {
          throw "Build HGraph for constructor from IR";
//          graph = compileConstructor(builder, work);
        } else if (kind == ElementKind.GENERATIVE_CONSTRUCTOR_BODY ||
                   kind == ElementKind.FUNCTION ||
                   kind == ElementKind.GETTER ||
                   kind == ElementKind.SETTER) {
          graph = builder.buildMethod();
        } else if (kind == ElementKind.FIELD) {
          throw "Build HGraph for field from IR";
//          assert(!element.isInstanceMember());
//          graph = builder.buildLazyInitializer(element);
        } else {
          compiler.internalErrorOnElement(element,
                                          'unexpected element kind $kind');
        }
        assert(graph.isValid());
        // TODO(lry): for default arguments, register constants in backend.
        // TODO(lry): tracing (factor out code in SsaBuilderTask).
        return graph;
      });
    });
  }
}

/**
 * This class contains code that is shared between [SsaFromIrBuilder] and
 * [SsaFromIrInliner].
 */
abstract class SsaFromIrMixin
    implements IrNodesVisitor, SsaBuilderMixin<IrNode> {
  /**
   * Maps IR expressions to the generated [HInstruction]. Because the IR is
   * in an SSA form, the arguments of an [IrNode] have already been visited
   * prior to the node. This map is used to obtain the corresponding generated
   * SSA node.
   */
  final Map<IrExpression, HInstruction> emitted =
      new Map<IrExpression, HInstruction>();

  /**
   * This method sets up the state of the IR visitor for inlining an invocation
   * of [function].
   */
  void setupStateForInlining(FunctionElement function,
                             List<HInstruction> compiledArguments) {
    // TODO(lry): once the IR supports functions with parameters or dynamic
    // invocations, map the parameters (and [:this:]) to the argument
    // instructions by extending the [emitted] mapping.
    assert(function.computeSignature(compiler).parameterCount == 0);
  }

  /**
   * Run this builder on the body of the [function] to be inlined.
   */
  void visitInlinedFunction(FunctionElement function) {
    assert(compiler.irBuilder.hasIr(function));
    potentiallyCheckInlinedParameterTypes(function);
    IrFunction functionNode = compiler.irBuilder.getIr(function);
    visitAll(functionNode.statements);
  }

  void addExpression(IrExpression irNode, HInstruction ssaNode) {
    current.add(emitted[irNode] = ssaNode);
  }

  HInstruction attachPosition(HInstruction target, IrNode node) {
    target.sourcePosition = sourceFileLocation(node);
    return target;
  }

  SourceFileLocation sourceFileLocation(IrNode node) {
    SourceFile sourceFile = currentSourceFile();
    SourceFileLocation location =
        new OffsetSourceFileLocation(sourceFile, node.offset, node.sourceName);
    checkValidSourceFileLocation(location, sourceFile, node.offset);
    return location;
  }

  void potentiallyCheckInlinedParameterTypes(FunctionElement function) {
    // TODO(lry): in checked mode, generate code for parameter type checks.
    assert(!compiler.enableTypeAssertions);
  }

  bool providedArgumentsKnownToBeComplete(IrNode currentNode) {
    // See comment in [SsaFromAstBuilder.providedArgumentsKnownToBeComplete].
    return false;
  }

  List<HInstruction> toInstructionList(List<IrNode> nodes) {
    return nodes.map((e) => emitted[e]).toList(growable: false);
  }

  void addInvokeStatic(IrInvokeStatic node,
                       FunctionElement function,
                       List<HInstruction> arguments,
                       [TypeMask type]) {
    if (tryInlineMethod(function, null, arguments, node)) {
      // When encountering a [:return:] instruction in the inlined function,
      // the value in the [emitted] map is updated. This is performed either
      // by [SsaFromIrBuilder.emitReturn] (if this is an [SsaFromIrBuilder] or
      // and [SsaFromAstInliner]), or by [SsaFromAstInliner.leaveInlinedMethod]
      // if this is an [SsaFromIrInliner].
      // If the inlined function is in AST form, it might not have an explicit
      // [:return:] statement and therefore the return value can be [:null:].
      if (emitted[node] == null) {
        // IR functions should always have an explicit [:return:].
        assert(!compiler.irBuilder.hasIr(function.implementation));
        emitted[node] = graph.addConstantNull(compiler);
      }
      return;
    }
    if (type == null) {
      type = TypeMaskFactory.inferredReturnTypeForElement(function, compiler);
    }
    bool targetCanThrow = !compiler.world.getCannotThrow(function);
    HInvokeStatic instruction = new HInvokeStatic(
        function.declaration, arguments, type, targetCanThrow: targetCanThrow);
    instruction.sideEffects = compiler.world.getSideEffectsOfElement(function);
    addExpression(node, attachPosition(instruction, node));
  }

  void visitIrConstant(IrConstant node) {
    emitted[node] = graph.addConstant(node.value, compiler);
  }

  void visitIrInvokeStatic(IrInvokeStatic node) {
    FunctionElement function = node.target;
    List<HInstruction> arguments = toInstructionList(node.arguments);
    addInvokeStatic(node, function, arguments);
  }

  void visitIrNode(IrNode node) {
    compiler.internalError('Cannot build SSA from IR for $node');
  }

  void visitIrReturn(IrReturn node) {
    HInstruction value = emitted[node.value];
    // TODO(lry): add code for dynamic type check.
    // value = potentiallyCheckType(value, returnType);
    emitReturn(value, node);
  }
}

/**
 * This builder generates SSA nodes for IR functions. It mixes in
 * [SsaBuilderMixin] to share functionality with the [SsaFromAstBuilder] that
 * creates SSA nodes from trees.
 */
class SsaFromIrBuilder extends IrNodesVisitor with
    SsaBuilderMixin<IrNode>,
    SsaFromIrMixin,
    SsaBuilderFields<IrNode> {
  final Compiler compiler;
  final JavaScriptBackend backend;
  final CodegenWorkItem work;

  /* See comment on [SsaFromAstBuilder.nativeEmitter]. */
  final NativeEmitter nativeEmitter;

  SsaFromIrBuilder(JavaScriptBackend backend,
                   CodegenWorkItem work,
                   this.nativeEmitter)
   : this.backend = backend,
     this.compiler = backend.compiler,
     this.work = work {
    sourceElementStack.add(work.element);
  }

  final List<IrInliningState> inliningStack = <IrInliningState>[];

  HGraph buildMethod() {
    FunctionElement functionElement = sourceElement.implementation;
    graph.calledInLoop = compiler.world.isCalledInLoop(functionElement);

    open(graph.entry);
    HBasicBlock block = graph.addNewBlock();
    close(new HGoto()).addSuccessor(block);
    open(block);

    IrFunction function = compiler.irBuilder.getIr(functionElement);
    visitAll(function.statements);
    if (!isAborted()) closeAndGotoExit(new HGoto());
    graph.finalize();
    return graph;
  }

  void emitReturn(HInstruction value, IrReturn node) {
    if (inliningStack.isEmpty) {
      closeAndGotoExit(attachPosition(new HReturn(value), node));
    } else {
      IrInliningState state = inliningStack.last;
      emitted[state.invokeNode] = value;
    }
  }

  /**
   * This method is invoked before inlining the body of [function] into this
   * [SsaFromIrBuilder]. The inlined function can be either in AST or IR.
   *
   * The method is also invoked from the [SsaFromAstInliner], that is, if we
   * are currently inlining an AST function and encounter a function invocation
   * that should be inlined.
   */
  void enterInlinedMethod(FunctionElement function,
                          IrNode callNode,
                          List<HInstruction> compiledArguments) {
    bool hasIr = compiler.irBuilder.hasIr(function);

    SsaFromAstInliner astInliner;
    if (!hasIr) {
      astInliner = new SsaFromAstInliner(this, function, compiledArguments);
    }

    IrInliningState state = new IrInliningState(function, callNode, astInliner);
    inliningStack.add(state);
    if (hasIr) {
      setupStateForInlining(function, compiledArguments);
    }
  }

  void leaveInlinedMethod() {
    inliningStack.removeLast();
  }

  void doInline(FunctionElement function) {
    if (compiler.irBuilder.hasIr(function)) {
      visitInlinedFunction(function);
    } else {
      IrInliningState state = inliningStack.last;
      state.astInliner.visitInlinedFunction(function);
    }
  }
}
