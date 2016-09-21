// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../common.dart';
import '../common/codegen.dart' show CodegenRegistry, CodegenWorkItem;
import '../common/tasks.dart' show CompilerTask;
import '../compiler.dart';
import '../dart_types.dart';
import '../elements/elements.dart';
import '../io/source_information.dart';
import '../js_backend/backend.dart' show JavaScriptBackend;
import '../kernel/kernel.dart';
import '../resolution/tree_elements.dart';
import '../tree/dartstring.dart';
import '../types/masks.dart';
import '../universe/selector.dart';

import 'graph_builder.dart';
import 'kernel_ast_adapter.dart';
import 'kernel_string_builder.dart';
import 'locals_handler.dart';
import 'loop_handler.dart';
import 'nodes.dart';
import 'ssa_branch_builder.dart';

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
      Kernel kernel = backend.kernelTask.kernel;
      KernelSsaBuilder builder = new KernelSsaBuilder(element, work.resolvedAst,
          backend.compiler, work.registry, sourceInformationFactory, kernel);
      return builder.build();
    });
  }
}

class KernelSsaBuilder extends ir.Visitor with GraphBuilder {
  ir.Node target;
  final AstElement targetElement;
  final ResolvedAst resolvedAst;
  final CodegenRegistry registry;

  JavaScriptBackend get backend => compiler.backend;

  TreeElements get elements => resolvedAst.elements;

  SourceInformationBuilder sourceInformationBuilder;
  KernelAstAdapter astAdapter;
  LoopHandler<ir.Node> loopHandler;

  KernelSsaBuilder(
      this.targetElement,
      this.resolvedAst,
      Compiler compiler,
      this.registry,
      SourceInformationStrategy sourceInformationFactory,
      Kernel kernel) {
    this.compiler = compiler;
    this.loopHandler = new KernelLoopHandler(this);
    graph.element = targetElement;
    // TODO(het): Should sourceInformationBuilder be in GraphBuilder?
    this.sourceInformationBuilder =
        sourceInformationFactory.createBuilderForContext(resolvedAst);
    graph.sourceInformation =
        sourceInformationBuilder.buildVariableDeclaration();
    this.localsHandler = new LocalsHandler(this, targetElement, null, compiler);
    this.astAdapter = new KernelAstAdapter(kernel, compiler.backend,
        resolvedAst, kernel.nodeToAst, kernel.nodeToElement);
    Element originTarget = targetElement;
    if (originTarget.isPatch) {
      originTarget = originTarget.origin;
    }
    if (originTarget is FunctionElement) {
      target = kernel.functions[originTarget];
    } else if (originTarget is FieldElement) {
      target = kernel.fields[originTarget];
    }
  }

  HGraph build() {
    // TODO(het): no reason to do this here...
    HInstruction.idCounter = 0;
    if (target is ir.Procedure) {
      buildProcedure(target);
    } else if (target is ir.Field) {
      buildField(target);
    } else if (target is ir.Constructor) {
      // TODO(het): Actually handle this correctly
      HBasicBlock block = graph.addNewBlock();
      open(graph.entry);
      close(new HGoto()).addSuccessor(block);
      open(block);
      closeAndGotoExit(new HGoto());
      graph.finalize();
    }
    assert(graph.isValid());
    return graph;
  }

  void buildField(ir.Field field) {
    openFunction();
    field.initializer.accept(this);
    HInstruction value = pop();
    closeAndGotoExit(new HReturn(value, null));
    closeFunction();
  }

  @override
  HInstruction popBoolified() {
    HInstruction value = pop();
    // TODO(het): add boolean conversion type check
    HInstruction result = new HBoolify(value, backend.boolType);
    add(result);
    return result;
  }

  // TODO(het): This implementation is shared with [SsaBuilder]. Should we just
  // allow [GraphBuilder] to access `compiler`?
  @override
  pushCheckNull(HInstruction expression) {
    push(new HIdentity(
        expression, graph.addConstantNull(compiler), null, backend.boolType));
  }

  /// Builds a SSA graph for [procedure].
  void buildProcedure(ir.Procedure procedure) {
    openFunction();
    procedure.function.body.accept(this);
    closeFunction();
  }

  void openFunction() {
    HBasicBlock block = graph.addNewBlock();
    open(graph.entry);
    localsHandler.startFunction(targetElement, resolvedAst.node);
    close(new HGoto()).addSuccessor(block);

    open(block);
  }

  void closeFunction() {
    if (!isAborted()) closeAndGotoExit(new HGoto());
    graph.finalize();
  }

  @override
  void defaultExpression(ir.Expression expression) {
    // TODO(het): This is only to get tests working
    stack.add(graph.addConstantNull(compiler));
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
  void visitExpressionStatement(ir.ExpressionStatement exprStatement) {
    exprStatement.expression.accept(this);
    pop();
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
  void visitForStatement(ir.ForStatement forStatement) {
    assert(isReachable);
    assert(forStatement.body != null);
    void buildInitializer() {
      for (ir.VariableDeclaration declaration in forStatement.variables) {
        declaration.accept(this);
      }
    }

    HInstruction buildCondition() {
      if (forStatement.condition == null) {
        return graph.addConstantBool(true, compiler);
      }
      forStatement.condition.accept(this);
      return popBoolified();
    }

    void buildUpdate() {
      for (ir.Expression expression in forStatement.updates) {
        expression.accept(this);
        assert(!isAborted());
        // The result of the update instruction isn't used, and can just
        // be dropped.
        pop();
      }
    }

    void buildBody() {
      forStatement.body.accept(this);
    }

    loopHandler.handleLoop(
        forStatement, buildInitializer, buildCondition, buildUpdate, buildBody);
  }

  @override
  void visitWhileStatement(ir.WhileStatement whileStatement) {
    assert(isReachable);
    HInstruction buildCondition() {
      whileStatement.condition.accept(this);
      return popBoolified();
    }

    loopHandler.handleLoop(whileStatement, () {}, buildCondition, () {}, () {
      whileStatement.body.accept(this);
    });
  }

  @override
  void visitIfStatement(ir.IfStatement ifStatement) {
    SsaBranchBuilder brancher = new SsaBranchBuilder(this, compiler);
    brancher.handleIf(
        () => ifStatement.condition.accept(this),
        () => ifStatement.then.accept(this),
        () => ifStatement.otherwise?.accept(this));
  }

  @override
  void visitConditionalExpression(ir.ConditionalExpression conditional) {
    SsaBranchBuilder brancher = new SsaBranchBuilder(this, compiler);
    brancher.handleConditional(
        () => conditional.condition.accept(this),
        () => conditional.then.accept(this),
        () => conditional.otherwise.accept(this));
  }

  @override
  void visitLogicalExpression(ir.LogicalExpression logicalExpression) {
    SsaBranchBuilder brancher = new SsaBranchBuilder(this, compiler);
    brancher.handleLogicalBinary(() => logicalExpression.left.accept(this),
        () => logicalExpression.right.accept(this),
        isAnd: logicalExpression.operator == '&&');
  }

  @override
  void visitIntLiteral(ir.IntLiteral intLiteral) {
    stack.add(graph.addConstantInt(intLiteral.value, compiler));
  }

  @override
  void visitDoubleLiteral(ir.DoubleLiteral doubleLiteral) {
    stack.add(graph.addConstantDouble(doubleLiteral.value, compiler));
  }

  @override
  void visitBoolLiteral(ir.BoolLiteral boolLiteral) {
    stack.add(graph.addConstantBool(boolLiteral.value, compiler));
  }

  @override
  void visitStringLiteral(ir.StringLiteral stringLiteral) {
    stack.add(graph.addConstantString(
        new DartString.literal(stringLiteral.value), compiler));
  }

  @override
  void visitSymbolLiteral(ir.SymbolLiteral symbolLiteral) {
    stack.add(graph.addConstant(
        astAdapter.getConstantForSymbol(symbolLiteral), compiler));
    registry?.registerConstSymbol(symbolLiteral.value);
  }

  @override
  void visitNullLiteral(ir.NullLiteral nullLiteral) {
    stack.add(graph.addConstantNull(compiler));
  }

  @override
  void visitListLiteral(ir.ListLiteral listLiteral) {
    HInstruction listInstruction;
    if (listLiteral.isConst) {
      listInstruction =
          graph.addConstant(astAdapter.getConstantFor(listLiteral), compiler);
    } else {
      List<HInstruction> elements = <HInstruction>[];
      for (ir.Expression element in listLiteral.expressions) {
        element.accept(this);
        elements.add(pop());
      }
      listInstruction = new HLiteralList(elements, backend.extendableArrayType);
      add(listInstruction);
      // TODO(het): set runtime type info
    }

    // TODO(het): Set the instruction type to the list type given by inference
    stack.add(listInstruction);
  }

  @override
  void visitMapLiteral(ir.MapLiteral mapLiteral) {
    if (mapLiteral.isConst) {
      stack.add(
          graph.addConstant(astAdapter.getConstantFor(mapLiteral), compiler));
      return;
    }

    // The map literal constructors take the key-value pairs as a List
    List<HInstruction> constructorArgs = <HInstruction>[];
    for (ir.MapEntry mapEntry in mapLiteral.entries) {
      mapEntry.accept(this);
      constructorArgs.add(pop());
      constructorArgs.add(pop());
    }

    // The constructor is a procedure because it's a factory.
    ir.Procedure constructor;
    List<HInstruction> inputs = <HInstruction>[];
    if (constructorArgs.isEmpty) {
      constructor = astAdapter.mapLiteralConstructorEmpty;
    } else {
      constructor = astAdapter.mapLiteralConstructor;
      HLiteralList argList =
          new HLiteralList(constructorArgs, backend.extendableArrayType);
      add(argList);
      inputs.add(argList);
    }

    // TODO(het): Add type information
    _pushStaticInvocation(constructor, inputs, backend.dynamicType);
  }

  @override
  void visitMapEntry(ir.MapEntry mapEntry) {
    // Visit value before the key because each will push an expression to the
    // stack, so when we pop them off, the key is popped first, then the value.
    mapEntry.value.accept(this);
    mapEntry.key.accept(this);
  }

  @override
  void visitStaticGet(ir.StaticGet staticGet) {
    var staticTarget = staticGet.target;
    if (staticTarget is ir.Procedure &&
        staticTarget.kind == ir.ProcedureKind.Getter) {
      // Invoke the getter
      _pushStaticInvocation(staticTarget, const <HInstruction>[],
          astAdapter.returnTypeOf(staticTarget));
    } else {
      Element element = astAdapter.getElement(staticTarget).declaration;
      push(new HStatic(element, astAdapter.inferredTypeOf(staticTarget)));
    }
  }

  @override
  void visitStaticSet(ir.StaticSet staticSet) {
    staticSet.value.accept(this);
    HInstruction value = pop();

    var staticTarget = staticSet.target;
    if (staticTarget is ir.Procedure) {
      // Invoke the setter
      _pushStaticInvocation(staticTarget, <HInstruction>[value],
          astAdapter.returnTypeOf(staticTarget));
      pop();
    } else {
      // TODO(het): check or trust type
      add(new HStaticStore(astAdapter.getElement(staticTarget), value));
    }
    stack.add(value);
  }

  @override
  void visitPropertyGet(ir.PropertyGet propertyGet) {
    propertyGet.receiver.accept(this);
    HInstruction receiver = pop();

    List<HInstruction> inputs = <HInstruction>[];
    bool isIntercepted = astAdapter.isIntercepted(propertyGet);
    if (isIntercepted) {
      HInterceptor interceptor = _interceptorFor(receiver);
      inputs.add(interceptor);
    }
    inputs.add(receiver);

    TypeMask type = astAdapter.selectorGetterTypeOf(propertyGet);

    push(new HInvokeDynamicGetter(astAdapter.getGetterSelector(propertyGet),
        astAdapter.typeOfGet(propertyGet), null, inputs, type));
  }

  @override
  void visitVariableGet(ir.VariableGet variableGet) {
    LocalElement local = astAdapter.getElement(variableGet.variable);
    stack.add(localsHandler.readLocal(local));
  }

  @override
  void visitVariableSet(ir.VariableSet variableSet) {
    variableSet.value.accept(this);
    HInstruction value = pop();
    _visitLocalSetter(variableSet.variable, value);
  }

  @override
  void visitVariableDeclaration(ir.VariableDeclaration declaration) {
    LocalElement local = astAdapter.getElement(declaration);
    if (declaration.initializer == null) {
      HInstruction initialValue = graph.addConstantNull(compiler);
      localsHandler.updateLocal(local, initialValue);
    } else {
      // TODO(het): handle case where the variable is top-level or static
      declaration.initializer.accept(this);
      HInstruction initialValue = pop();

      _visitLocalSetter(declaration, initialValue);

      // Ignore value
      pop();
    }
  }

  void _visitLocalSetter(ir.VariableDeclaration variable, HInstruction value) {
    // TODO(het): handle case where the variable is top-level or static
    LocalElement local = astAdapter.getElement(variable);

    // Give the value a name if it doesn't have one already.
    if (value.sourceElement == null) {
      value.sourceElement = local;
    }

    stack.add(value);
    // TODO(het): check or trust type
    localsHandler.updateLocal(local, value);
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
  void visitStaticInvocation(ir.StaticInvocation invocation) {
    ir.Procedure target = invocation.target;
    TypeMask typeMask = astAdapter.returnTypeOf(target);

    List<HInstruction> arguments = _visitArguments(invocation.arguments);

    _pushStaticInvocation(target, arguments, typeMask);
  }

  void _pushStaticInvocation(
      ir.Node target, List<HInstruction> arguments, TypeMask typeMask) {
    HInstruction instruction = new HInvokeStatic(
        astAdapter.getElement(target).declaration, arguments, typeMask,
        targetCanThrow: astAdapter.getCanThrow(target));
    instruction.sideEffects = astAdapter.getSideEffects(target);

    push(instruction);
  }

  // TODO(het): Decide when to inline
  @override
  void visitMethodInvocation(ir.MethodInvocation invocation) {
    invocation.receiver.accept(this);
    HInstruction receiver = pop();

    List<HInstruction> arguments = <HInstruction>[receiver]
      ..addAll(_visitArguments(invocation.arguments));

    List<HInstruction> inputs = <HInstruction>[];

    bool isIntercepted = astAdapter.isIntercepted(invocation);
    if (isIntercepted) {
      HInterceptor interceptor = _interceptorFor(receiver);
      inputs.add(interceptor);
    }
    inputs.addAll(arguments);

    TypeMask type = astAdapter.selectorTypeOf(invocation);

    push(new HInvokeDynamicMethod(astAdapter.getSelector(invocation),
        astAdapter.typeOfInvocation(invocation), inputs, type, isIntercepted));
  }

  HInterceptor _interceptorFor(HInstruction intercepted) {
    HInterceptor interceptor =
        new HInterceptor(intercepted, backend.nonNullType);
    add(interceptor);
    return interceptor;
  }

  static ir.Class _containingClass(ir.TreeNode node) {
    while (node != null) {
      if (node is ir.Class) return node;
      node = node.parent;
    }
    return null;
  }

  @override
  void visitSuperMethodInvocation(ir.SuperMethodInvocation invocation) {
    List<HInstruction> arguments = _visitArguments(invocation.arguments);
    HInstruction receiver = localsHandler.readThis();
    Selector selector = astAdapter.getSelector(invocation);
    ir.Class surroundingClass = _containingClass(invocation);

    List<HInstruction> inputs = <HInstruction>[];
    if (astAdapter.isIntercepted(invocation)) {
      inputs.add(_interceptorFor(receiver));
    }
    inputs.add(receiver);
    inputs.addAll(arguments);

    HInstruction instruction = new HInvokeSuper(
        astAdapter.getElement(invocation.interfaceTarget),
        astAdapter.getElement(surroundingClass),
        selector,
        inputs,
        astAdapter.returnTypeOf(invocation.interfaceTarget),
        null,
        isSetter: selector.isSetter || selector.isIndexSet);
    instruction.sideEffects =
        compiler.closedWorld.getSideEffectsOfSelector(selector, null);
    push(instruction);
  }

  @override
  void visitConstructorInvocation(ir.ConstructorInvocation invocation) {
    ir.Constructor target = invocation.target;
    List<HInstruction> arguments = _visitArguments(invocation.arguments);
    TypeMask typeMask = new TypeMask.nonNullExact(
        astAdapter.getElement(target.enclosingClass), compiler.closedWorld);
    _pushStaticInvocation(target, arguments, typeMask);
  }

  @override
  void visitIsExpression(ir.IsExpression isExpression) {
    isExpression.operand.accept(this);
    HInstruction expression = pop();

    DartType type = astAdapter.getDartType(isExpression.type);

    if (backend.hasDirectCheckFor(type)) {
      push(new HIs.direct(type, expression, backend.boolType));
      return;
    }

    // The interceptor is not always needed.  It is removed by optimization
    // when the receiver type or tested type permit.
    HInterceptor interceptor = _interceptorFor(expression);
    push(new HIs.raw(type, expression, interceptor, backend.boolType));
  }

  @override
  void visitThrow(ir.Throw throwNode) {
    throwNode.expression.accept(this);
    HInstruction expression = pop();
    if (isReachable) {
      push(new HThrowExpression(expression, null));
      isReachable = false;
    }
  }

  @override
  void visitThisExpression(ir.ThisExpression thisExpression) {
    stack.add(localsHandler.readThis());
  }

  @override
  void visitNot(ir.Not not) {
    not.operand.accept(this);
    push(new HNot(popBoolified(), backend.boolType));
  }

  @override
  void visitStringConcatenation(ir.StringConcatenation stringConcat) {
    KernelStringBuilder stringBuilder = new KernelStringBuilder(this);
    stringConcat.accept(stringBuilder);
    stack.add(stringBuilder.result);
  }
}
