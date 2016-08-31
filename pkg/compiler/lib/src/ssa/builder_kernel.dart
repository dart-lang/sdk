// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../common/codegen.dart' show CodegenRegistry, CodegenWorkItem;
import '../common/tasks.dart' show CompilerTask;
import '../compiler.dart';
import '../diagnostics/spannable.dart';
import '../elements/elements.dart';
import '../io/source_information.dart';
import '../js_backend/backend.dart' show JavaScriptBackend;
import '../kernel/kernel.dart';
import '../kernel/kernel_visitor.dart';
import '../resolution/tree_elements.dart';
import '../tree/dartstring.dart';
import '../types/masks.dart';

import 'graph_builder.dart';
import 'kernel_ast_adapter.dart';
import 'locals_handler.dart';
import 'nodes.dart';

class SsaKernelBuilderTask extends CompilerTask {
  final JavaScriptBackend backend;
  final SourceInformationStrategy sourceInformationFactory;

  String get name => 'SSA kernel builder';

  SsaKernelBuilderTask(JavaScriptBackend backend, this.sourceInformationFactory)
      : backend = backend,
        super(backend.compiler.measurer);

  HGraph build(CodegenWorkItem work) {
    return measure(() {
      AstElement element = work.element.implementation;
      TreeElements treeElements = work.resolvedAst.elements;
      Kernel kernel = new Kernel(backend.compiler);
      KernelVisitor visitor = new KernelVisitor(element, treeElements, kernel);
      IrFunction function;
      try {
        function = visitor.buildFunction();
      } catch (e) {
        throw "Failed to convert to Kernel IR: $e";
      }
      KernelSsaBuilder builder = new KernelSsaBuilder(
          function,
          element,
          work.resolvedAst,
          backend.compiler,
          work.registry,
          sourceInformationFactory,
          visitor,
          kernel);
      return builder.build();
    });
  }
}

class KernelSsaBuilder extends ir.Visitor with GraphBuilder {
  final IrFunction function;
  final FunctionElement functionElement;
  final ResolvedAst resolvedAst;
  final Compiler compiler;
  final CodegenRegistry registry;

  JavaScriptBackend get backend => compiler.backend;

  LocalsHandler localsHandler;
  SourceInformationBuilder sourceInformationBuilder;
  KernelAstAdapter astAdapter;

  KernelSsaBuilder(
      this.function,
      this.functionElement,
      this.resolvedAst,
      this.compiler,
      this.registry,
      SourceInformationStrategy sourceInformationFactory,
      KernelVisitor visitor,
      Kernel kernel) {
    graph.element = functionElement;
    // TODO(het): Should sourceInformationBuilder be in GraphBuilder?
    this.sourceInformationBuilder =
        sourceInformationFactory.createBuilderForContext(resolvedAst);
    graph.sourceInformation =
        sourceInformationBuilder.buildVariableDeclaration();
    this.localsHandler =
        new LocalsHandler(this, functionElement, null, compiler);
    this.astAdapter = new KernelAstAdapter(
        compiler.backend,
        resolvedAst,
        visitor.nodeToAst,
        visitor.nodeToElement,
        kernel.functions,
        kernel.libraries);
  }

  HGraph build() {
    // TODO(het): no reason to do this here...
    HInstruction.idCounter = 0;
    if (function.kind == ir.ProcedureKind.Method ||
        function.kind == ir.ProcedureKind.Operator) {
      buildMethod(function, functionElement);
    } else {
      compiler.reporter.internalError(
          functionElement,
          "Unable to convert this kind of Kernel "
          "procedure to SSA: ${function.kind}");
    }
    assert(graph.isValid());
    return graph;
  }

  /// Builds a SSA graph for [method].
  void buildMethod(IrFunction method, FunctionElement functionElement) {
    openFunction(method, functionElement);
    method.node.body.accept(this);
    closeFunction();
  }

  void openFunction(IrFunction method, FunctionElement functionElement) {
    HBasicBlock block = graph.addNewBlock();
    open(graph.entry);
    localsHandler.startFunction(functionElement, resolvedAst.node);
    close(new HGoto()).addSuccessor(block);

    open(block);
  }

  void closeFunction() {
    if (!isAborted()) closeAndGotoExit(new HGoto());
    graph.finalize();
  }

  @override
  void visitBlock(ir.Block block) {
    assert(!isAborted());
    for (ir.Statement statement in block.statements) {
      statement.accept(this);
      if (!isReachable) {
        // The block has been aborted by a return or a throw.
        if (stack.isNotEmpty) {
          compiler.reporter.internalError(
              NO_LOCATION_SPANNABLE, 'Non-empty instruction stack.');
        }
        return;
      }
    }
    assert(!current.isClosed());
    if (stack.isNotEmpty) {
      compiler.reporter
          .internalError(NO_LOCATION_SPANNABLE, 'Non-empty instruction stack');
    }
  }

  @override
  void visitReturnStatement(ir.ReturnStatement returnStatement) {
    HInstruction value;
    if (returnStatement.expression == null) {
      value = graph.addConstantNull(compiler);
    } else {
      returnStatement.expression.accept(this);
      value = pop();
      // TODO(het): Check or trust the type of value
    }
    // TODO(het): Add source information
    // TODO(het): Set a return value instead of closing the function when we
    // support inlining.
    closeAndGotoExit(new HReturn(value, null));
  }

  @override
  void visitIntLiteral(ir.IntLiteral intLiteral) {
    stack.add(graph.addConstantInt(intLiteral.value, compiler));
  }

  @override
  visitDoubleLiteral(ir.DoubleLiteral doubleLiteral) {
    stack.add(graph.addConstantDouble(doubleLiteral.value, compiler));
  }

  @override
  visitBoolLiteral(ir.BoolLiteral boolLiteral) {
    stack.add(graph.addConstantBool(boolLiteral.value, compiler));
  }

  @override
  visitStringLiteral(ir.StringLiteral stringLiteral) {
    stack.add(graph.addConstantString(
        new DartString.literal(stringLiteral.value), compiler));
  }

  @override
  visitSymbolLiteral(ir.SymbolLiteral symbolLiteral) {
    stack.add(graph.addConstant(
        astAdapter.getConstantForSymbol(symbolLiteral), compiler));
    registry?.registerConstSymbol(symbolLiteral.value);
  }

  @override
  visitNullLiteral(ir.NullLiteral nullLiteral) {
    stack.add(graph.addConstantNull(compiler));
  }

  @override
  visitVariableGet(ir.VariableGet variableGet) {
    LocalElement local = astAdapter.getElement(variableGet.variable);
    stack.add(localsHandler.readLocal(local));
  }

  // TODO(het): Also extract type arguments
  /// Extracts the list of instructions for the expressions in the arguments.
  List<HInstruction> _visitArguments(ir.Arguments arguments) {
    List<HInstruction> result = <HInstruction>[];

    for (ir.Expression argument in arguments.positional) {
      argument.accept(this);
      result.add(pop());
    }
    for (ir.NamedExpression argument in arguments.named) {
      argument.value.accept(this);
      result.add(pop());
    }

    return result;
  }

  @override
  visitStaticInvocation(ir.StaticInvocation invocation) {
    ir.Procedure target = invocation.target;
    bool targetCanThrow = astAdapter.getCanThrow(target);
    TypeMask typeMask = astAdapter.returnTypeOf(target);

    var arguments = _visitArguments(invocation.arguments);

    HInstruction instruction = new HInvokeStatic(
        astAdapter.getElement(target).declaration, arguments, typeMask,
        targetCanThrow: targetCanThrow);
    instruction.sideEffects = astAdapter.getSideEffects(target);

    push(instruction);
  }

  // TODO(het): Decide when to inline
  @override
  visitMethodInvocation(ir.MethodInvocation invocation) {
    invocation.receiver.accept(this);
    HInstruction receiver = pop();

    List<HInstruction> arguments = <HInstruction>[receiver]
      ..addAll(_visitArguments(invocation.arguments));

    List<HInstruction> inputs = <HInstruction>[];

    bool isIntercepted = astAdapter.isIntercepted(invocation);
    if (isIntercepted) {
      HInterceptor interceptor =
          new HInterceptor(receiver, backend.nonNullType);
      add(interceptor);
      inputs.add(interceptor);
    }
    inputs.addAll(arguments);

    TypeMask type = astAdapter.selectorTypeOf(invocation);

    push(new HInvokeDynamicMethod(astAdapter.getSelector(invocation),
        astAdapter.getTypeMask(invocation), inputs, type, isIntercepted));
  }

  @override
  visitThisExpression(ir.ThisExpression thisExpression) {
    stack.add(localsHandler.readThis());
  }

  @override
  visitExpressionStatement(ir.ExpressionStatement exprStatement) {
    exprStatement.expression.accept(this);
    pop();
  }
}
