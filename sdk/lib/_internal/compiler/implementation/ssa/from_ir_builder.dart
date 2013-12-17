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

        SsaFromIrBuilder builder = new SsaFromIrBuilder(backend, work);

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
abstract class SsaFromIrMixin implements SsaGraphBuilderMixin<IrNode> {
  /**
   * Maps IR expressions to the generated [HInstruction]. Because the IR is
   * in an SSA form, the arguments of an [IrNode] have already been visited
   * prior to the node. This map is used to obtain the corresponding generated
   * SSA node.
   */
  final Map<IrExpression, HInstruction> emitted =
      new Map<IrExpression, HInstruction>();

  Compiler get compiler;

  void emitReturn(HInstruction value, IrReturn node);

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
    // See comment in [SsaBuilder.providedArgumentsKnownToBeComplete].
    return false;
  }

  List<HInstruction> toInstructionList(List<IrNode> nodes) {
    return nodes.map((e) => emitted[e]).toList(growable: false);
  }

  bool canInline(FunctionElement function) {
    // The [SsaFromIrBuilder] can currently only inline IR functions.
    // TODO(lry): fix that.
    return (this is !SsaFromIrBuilder) || compiler.irBuilder.hasIr(function);
  }

  void addInvokeStatic(IrInvokeStatic node,
                       FunctionElement function,
                       List<HInstruction> arguments,
                       [TypeMask type]) {
    if (canInline(function) &&
        tryInlineMethod(function, null, arguments, node)) {
      // If we are in an [SsaFromIrBuilder], the [emitted] map is updated in
      // [emitReturn]. Otherwise, the builder is an [SsaFromIrBuilder] and the
      // map is updated in [SsaFromIrBuilder.leaveInlinedMethod].
      assert(emitted[node] != null);
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
 * This builder generates SSA nodes for elements that have an IR representation.
 * It mixes in [SsaGraphBuilderMixin] to share functionality with the
 * [SsaBuilder] that creates SSA nodes from trees.
 */
class SsaFromIrBuilder extends IrNodesVisitor with
    SsaGraphBuilderMixin<IrNode>,
    SsaFromIrMixin,
    SsaGraphBuilderFields<IrNode> {
  final Compiler compiler;

  final JavaScriptBackend backend;

  SsaFromIrBuilder(JavaScriptBackend backend, CodegenWorkItem work)
   : this.backend = backend,
     this.compiler = backend.compiler {
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

  void setupInliningState(FunctionElement function,
                          IrNode callNode,
                          List<HInstruction> compiledArguments) {
    if (compiler.irBuilder.hasIr(function)) {
      // TODO(lry): once the IR supports functions with parameters or dynamic
      // invocations, map the parameters (and [:this:]) to the argument
      // instructions by extending the [emitted] mapping.
      assert(function.computeSignature(compiler).parameterCount == 0);

      IrInliningState state = new IrInliningState(function, callNode);
      inliningStack.add(state);
    } else {
      // TODO(lry): inline AST function when building from IR.
      throw "setup inlining for AST $function";
    }
  }

  void leaveInlinedMethod() {
    inliningStack.removeLast();
  }

  void doInline(FunctionElement function) {
    if (compiler.irBuilder.hasIr(function)) {
      IrFunction functionNode = compiler.irBuilder.getIr(function);
      visitAll(functionNode.statements);
    } else {
      // TODO(lry): inline AST function when building from IR.
      throw "inlining for AST $function";
    }
  }
}
