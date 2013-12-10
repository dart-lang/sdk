// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of ssa;

class SsaFromIrBuilderTask extends CompilerTask {
  SsaFromIrBuilderTask(Compiler compiler) : super(compiler);

  HGraph build(CodegenWorkItem work) {
    return measure(() {
      Element element = work.element.implementation;
      return compiler.withCurrentElement(element, () {
        HInstruction.idCounter = 0;
        SsaFromIrBuilder builder = new SsaFromIrBuilder(compiler, element);

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
abstract class SsaFromIrMixin {
  /**
   * Maps IR expressions to the generated [HInstruction]. Because the IR is
   * in an SSA form, the arguments of an [IrNode] have already been visited
   * prior to the node. This map is used to obtain the corresponding generated
   * SSA node.
   */
  final Map<IrExpression, HInstruction> emitted =
      new Map<IrExpression, HInstruction>();

  Compiler get compiler;

  Element get sourceElement;

  HGraph get graph;

  HBasicBlock get current;

  bool get isReachable;

  void emitReturn(HInstruction value, IrReturn node);

  HInstruction addExpression(IrExpression irNode, HInstruction ssaNode) {
    current.add(emitted[irNode] = ssaNode);
    return ssaNode;
  }

  HInstruction attachPosition(HInstruction target, IrNode node) {
    target.sourcePosition = sourceFileLocation(node);
    return target;
  }

  SourceFileLocation sourceFileLocation(IrNode node) {
    Element element = sourceElement;
    // TODO(johnniwinther): remove the 'element.patch' hack.
    if (element is FunctionElement) {
      FunctionElement functionElement = element;
      if (functionElement.patch != null) element = functionElement.patch;
    }
    Script script = element.getCompilationUnit().script;
    SourceFile sourceFile = script.file;
    SourceFileLocation location =
        new OffsetSourceFileLocation(sourceFile, node.offset, node.sourceName);
    if (!location.isValid()) {
      throw MessageKind.INVALID_SOURCE_FILE_LOCATION.message(
          {'offset': node.offset,
           'fileName': sourceFile.filename,
           'length': sourceFile.length});
    }
    return location;
  }

  List<HInstruction> toInstructionList(List<IrNode> nodes) {
    return nodes.map((e) => emitted[e]).toList(growable: false);
  }

  HInstruction createInvokeStatic(IrNode node,
                                  Element element,
                                  List<HInstruction> arguments,
                                  [TypeMask type]) {
    if (type == null) {
      type = TypeMaskFactory.inferredReturnTypeForElement(element, compiler);
    }
    bool targetCanThrow = !compiler.world.getCannotThrow(element);
    HInvokeStatic instruction = new HInvokeStatic(
        element.declaration, arguments, type, targetCanThrow: targetCanThrow);
    instruction.sideEffects = compiler.world.getSideEffectsOfElement(element);
    return attachPosition(instruction, node);
  }

  void visitIrConstant(IrConstant node) {
    emitted[node] = graph.addConstant(node.value, compiler);
  }

  void visitIrInvokeStatic(IrInvokeStatic node) {
    Element element = node.target;
    assert(element.isFunction());
    List<HInstruction> arguments = toInstructionList(node.arguments);
    // Note: the AST to SSA builder attempts to inline here.
    HInstruction instruction = createInvokeStatic(node, element, arguments);
    addExpression(node, instruction);
  }

  void visitIrNode(IrNode node) {
    compiler.internalError('Cannot build SSA from IR for $node');
  }

  void visitIrReturn(IrReturn node) {
    assert(isReachable);
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
class SsaFromIrBuilder
    extends IrNodesVisitor with SsaFromIrMixin, SsaGraphBuilderMixin {
  final Compiler compiler;

  final Element sourceElement;

  SsaFromIrBuilder(this.compiler, this.sourceElement);

  HGraph buildMethod() {
    graph.calledInLoop = compiler.world.isCalledInLoop(sourceElement);

    open(graph.entry);
    HBasicBlock block = graph.addNewBlock();
    close(new HGoto()).addSuccessor(block);
    open(block);

    IrFunction function = compiler.irBuilder.getIr(sourceElement);
    visitAll(function.statements);
    if (!isAborted()) closeAndGotoExit(new HGoto());
    graph.finalize();
    return graph;
  }

  void emitReturn(HInstruction value, IrReturn node) {
    closeAndGotoExit(attachPosition(new HReturn(value), node));
  }
}
